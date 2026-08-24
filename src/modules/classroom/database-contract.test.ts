import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const migrationPath = join(
  process.cwd(),
  "supabase",
  "migrations",
  "20260812072724_teacher_class_lifecycle.sql",
);
const testPath = join(process.cwd(), "supabase", "tests", "003_teacher_class_lifecycle_rls.sql");

describe("teacher class lifecycle database contract", () => {
  it("keeps the sequential lifecycle and teacher review gate at the database boundary", async () => {
    const sql = await readFile(migrationPath, "utf8");
    expect(sql).toContain("invalid lesson session transition");
    expect(sql).toContain("record attendance for every enrolled student before continuing");
    expect(sql).toContain("upload a transcript before confirming class evidence");
    expect(sql).toContain("upload a class resource before confirming class evidence");
    expect(sql).toContain("assign homework before continuing");
    expect(sql).toContain("teacher review is required before publishing");
    expect(sql).toContain("teacher_reviewed_by := (select auth.uid())");
  });

  it("forces RLS on lifecycle records and private storage paths", async () => {
    const sql = await readFile(migrationPath, "utf8");
    for (const table of [
      "lesson_sessions",
      "attendance_records",
      "lesson_uploads",
      "homework_assignments",
    ]) {
      expect(sql).toContain(`alter table public.${table} enable row level security;`);
      expect(sql).toContain(`alter table public.${table} force row level security;`);
      expect(sql).toContain(
        `revoke all on table public.${table} from public, anon, authenticated;`,
      );
    }
    expect(sql).toContain("'classroom-evidence'");
    expect(sql).toContain("classroom_evidence_insert_teacher");
    expect(sql).toContain("storage.foldername(name)");
    expect(sql).toContain("private.is_class_teacher");
  });

  it("commits rollback-safe adversarial transition, branch, retry, and recovery proof", async () => {
    const sql = await readFile(testPath, "utf8");
    expect(sql).toContain("west teacher could read main lesson session");
    expect(sql).toContain("invalid started-to-published transition succeeded");
    expect(sql).toContain("attendance completed without every enrolled student");
    expect(sql).toContain("pending upload did not block evidence confirmation");
    expect(sql).toContain("second pending upload for the same kind was accepted");
    expect(sql).toContain("publish bypassed teacher review");
    expect(sql).toContain("upload retry state was not preserved");
    expect(sql).toContain("rollback;");
  });
});
