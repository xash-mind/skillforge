import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const hardeningMigrationPath = join(
  process.cwd(),
  "supabase",
  "migrations",
  "20260812072834_teacher_class_lifecycle_hardening.sql",
);
const recoveryMigrationPath = join(
  process.cwd(),
  "supabase",
  "migrations",
  "20260824110054_teacher_class_lifecycle_recovery.sql",
);
const storageRepairMigrationPath = join(
  process.cwd(),
  "supabase",
  "migrations",
  "20260824110447_teacher_class_lifecycle_storage_policy_repair.sql",
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

  it("allows authenticated Storage policies to evaluate their private security-definer helpers", async () => {
    const sql = await readFile(storageRepairMigrationPath, "utf8");

    expect(sql).toContain(
      "grant execute on function private.can_read_classroom_evidence(bigint, bigint, bigint, bigint)",
    );
    expect(sql).toContain(
      "grant execute on function private.can_write_classroom_evidence(bigint, bigint, bigint, bigint)",
    );
    expect(sql).toContain("to authenticated");
    expect(sql).toContain("from public, anon, service_role");
  });

  it("makes pending upload recovery a database-enforced lifecycle invariant", async () => {
    const sql = await readFile(recoveryMigrationPath, "utf8");

    expect(sql).toContain("attendance_records_enrollment_scope_idx");
    expect(sql).toContain("lesson_uploads_one_pending_per_kind_idx");
    expect(sql).toContain("where status = 'pending'");
    expect(sql).toContain("resolve pending class evidence before confirming class evidence");
  });

  it("extends adversarial proof to direct Data API, storage, and interrupted-upload paths", async () => {
    const sql = await readFile(adversarialTestPath, "utf8");

    expect(sql).toContain("teacher inserted a pre-published lesson session");
    expect(sql).toContain("west teacher wrote into main classroom storage");
    expect(sql).toContain("teacher forged uploaded metadata without a storage object");
    expect(sql).toContain("pending upload did not block evidence confirmation");
    expect(sql).toContain("second pending upload for the same kind was accepted");
    expect(sql).toContain("attendance changed after evidence progression");
    expect(sql).toContain("lesson evidence changed after homework progression");
    expect(sql).toContain("homework changed after review progression");
    expect(sql).toContain("published lesson session was mutable");
    expect(sql).toContain("rollback;");
  });
});
