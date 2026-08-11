import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

const migrationsDirectory = join(process.cwd(), "supabase", "migrations");
const databaseTestsDirectory = join(process.cwd(), "supabase", "tests");

async function readSqlDirectory(directory: string) {
  const files = (await readdir(directory)).filter((file) => file.endsWith(".sql")).sort();
  const contents = await Promise.all(files.map((file) => readFile(join(directory, file), "utf8")));

  return { files, sql: contents.join("\n") };
}

describe("tenancy database contract", () => {
  it("keeps every exposed table behind explicit RLS and grants", async () => {
    const { sql } = await readSqlDirectory(migrationsDirectory);
    const exposedTables = [
      "profiles",
      "organizations",
      "branches",
      "organization_memberships",
      "branch_memberships",
      "role_assignments",
      "audit_events",
    ];

    for (const table of exposedTables) {
      expect(sql).toContain(`alter table public.${table} enable row level security;`);
      expect(sql).toContain(`alter table public.${table} force row level security;`);
      expect(sql).toContain(
        `revoke all on table public.${table} from public, anon, authenticated;`,
      );
    }
  });

  it("derives authorization from trusted rows instead of user-editable metadata", async () => {
    const { sql } = await readSqlDirectory(migrationsDirectory);
    const policySql = sql.slice(sql.indexOf("create policy profiles_select_authorized"));

    expect(policySql).not.toContain("raw_user_meta_data");
    expect(policySql).not.toContain("user_metadata");
    expect(policySql).not.toContain("auth.jwt()");
    expect(policySql).toContain("private.is_organization_member");
    expect(policySql).toContain("private.can_manage_branch");
  });

  it("keeps private helpers off the Data API and audit history append-only", async () => {
    const { sql } = await readSqlDirectory(migrationsDirectory);

    expect(sql).toContain("revoke all on schema private from anon, authenticated;");
    expect(sql).toContain("create trigger audit_events_reject_mutation");
    expect(sql).toContain("raise exception 'audit events are append-only'");
    expect(sql).not.toContain("grant usage on schema private to authenticated");
  });

  it("commits an adversarial rollback suite with the migrations", async () => {
    const { files, sql } = await readSqlDirectory(databaseTestsDirectory);

    expect(files).toEqual(["001_tenancy_rbac_rls.sql"]);
    expect(sql).toContain("teacher tenant isolation failed");
    expect(sql).toContain("branch manager modified another branch");
    expect(sql).toContain("cross-tenant branch membership bypassed composite foreign keys");
    expect(sql).toContain("rollback;");
  });
});
