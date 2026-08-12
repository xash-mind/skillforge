import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const hardeningMigrationPath = join(
  process.cwd(),
  "supabase",
  "migrations",
  "20260812072000_teacher_class_lifecycle_hardening.sql",
);
const adversarialTestPath = join(
  process.cwd(),
  "supabase",
  "tests",
  "003_teacher_class_lifecycle_rls.sql",
);

describe("teacher lifecycle trusted-boundary hardening", () => {
  it("prevents direct session, evidence, and post-step mutation bypasses", async () => {
    const sql = await readFile(hardeningMigrationPath, "utf8");

    expect(sql).toContain("lesson sessions must begin in draft without lifecycle timestamps");
    expect(sql).toContain("lesson lifecycle timestamps are transition-controlled");
    expect(sql).toContain("attendance can only be recorded while the session is started");
    expect(sql).toContain("class evidence can only change during the evidence upload step");
    expect(sql).toContain("uploaded lesson evidence requires a matching storage object");
    expect(sql).toContain("homework can only change during the homework step");
    expect(sql).toContain("published lesson sessions are immutable");
  });

  it("binds storage writes to a real numeric session in the evidence-upload state", async () => {
    const sql = await readFile(hardeningMigrationPath, "utf8");

    expect(sql).toContain("private.can_read_classroom_evidence");
    expect(sql).toContain("private.can_write_classroom_evidence");
    expect(sql).toContain("session.state = 'attendance_marked'");
    expect(sql).toContain("(storage.foldername(name))[4] ~ '^[0-9]+$'");
    expect(sql).not.toContain("create policy classroom_evidence_update_teacher");
  });

  it("extends adversarial proof to the direct Data API and storage bypass paths", async () => {
    const sql = await readFile(adversarialTestPath, "utf8");

    expect(sql).toContain("teacher inserted a pre-published lesson session");
    expect(sql).toContain("west teacher wrote into main classroom storage");
    expect(sql).toContain("teacher forged uploaded metadata without a storage object");
    expect(sql).toContain("attendance changed after evidence progression");
    expect(sql).toContain("lesson evidence changed after homework progression");
    expect(sql).toContain("homework changed after review progression");
    expect(sql).toContain("published lesson session was mutable");
    expect(sql).toContain("rollback;");
  });
});
