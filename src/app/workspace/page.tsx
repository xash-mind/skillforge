import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import { roleLabel, type OrganizationRole } from "@/modules/identity/domain/access-control";

export const metadata: Metadata = { title: "Workspace" };
export const dynamic = "force-dynamic";

export default async function WorkspacePage() {
  const supabase = await createServerSupabaseClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;
  if (claimsError || !userId) redirect("/auth/sign-in");

  const { data: memberships, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("id, organization_id")
    .eq("user_id", userId)
    .eq("status", "active");
  if (membershipError) throw new Error("Your trusted SkillForge membership could not be loaded.");

  const organizationIds = memberships.map((membership) => membership.organization_id);
  const membershipIds = memberships.map((membership) => membership.id);
  const [organizationsResult, rolesResult] = await Promise.all([
    organizationIds.length
      ? supabase.from("organizations").select("id, name, slug, status").in("id", organizationIds)
      : Promise.resolve({ data: [], error: null }),
    membershipIds.length
      ? supabase
          .from("role_assignments")
          .select("organization_id, branch_id, role")
          .in("organization_membership_id", membershipIds)
          .eq("status", "active")
      : Promise.resolve({ data: [], error: null }),
  ]);
  if (organizationsResult.error || rolesResult.error)
    throw new Error("Your authorized SkillForge workspace could not be loaded.");

  const organizations = organizationsResult.data;
  const roles = rolesResult.data;
  const rolesByOrganization = new Map<number, typeof roles>();
  for (const assignment of roles) {
    const organizationRoles = rolesByOrganization.get(assignment.organization_id) ?? [];
    organizationRoles.push(assignment);
    rolesByOrganization.set(assignment.organization_id, organizationRoles);
  }

  return (
    <main className="workspace-page">
      <header className="workspace-header">
        <BrandMark />
        <form action="/auth/sign-out" method="post">
          <button className="button button--quiet" type="submit">
            Sign out
          </button>
        </form>
      </header>
      <section className="workspace-hero" aria-labelledby="workspace-title">
        <p className="eyebrow">Trusted access</p>
        <h1 id="workspace-title">
          {organizations.length ? "Choose your next workspace." : "Your access is being prepared."}
        </h1>
        <p>
          {organizations.length
            ? "Only organizations and roles recorded by an authorized administrator appear here."
            : "You are signed in, but an administrator has not activated an organization membership yet."}
        </p>
      </section>
      {organizations.length ? (
        <ul className="workspace-list" aria-label="Authorized organizations">
          {organizations.map((organization) => {
            const organizationRoles = rolesByOrganization.get(organization.id) ?? [];
            const canManageAcademics = organizationRoles.some(
              (assignment) =>
                assignment.role === "organization_owner" ||
                (assignment.role === "branch_manager" && assignment.branch_id !== null),
            );
            const canTeach = organizationRoles.some(
              (assignment) => assignment.role === "teacher" && assignment.branch_id !== null,
            );
            return (
              <li key={organization.id}>
                <div>
                  <span className="workspace-list__status">{organization.status}</span>
                  <h2>{organization.name}</h2>
                  <p>{organization.slug}</p>
                  {canManageAcademics ? (
                    <Link
                      className="button button--quiet"
                      href={`/workspace/${organization.slug}/academic`}
                    >
                      Configure academics
                    </Link>
                  ) : null}
                  {canTeach ? (
                    <Link
                      className="button button--quiet"
                      href={`/workspace/${organization.slug}/teacher`}
                    >
                      Open teacher classes
                    </Link>
                  ) : null}
                </div>
                <ul className="workspace-list__roles" aria-label={`Roles in ${organization.name}`}>
                  {organizationRoles.map((assignment) => (
                    <li key={`${assignment.role}-${assignment.branch_id ?? "organization"}`}>
                      {roleLabel(assignment.role as OrganizationRole)}
                      {assignment.branch_id
                        ? ` · branch ${assignment.branch_id}`
                        : " · organization"}
                    </li>
                  ))}
                </ul>
              </li>
            );
          })}
        </ul>
      ) : (
        <aside className="workspace-empty">
          <strong>What happens next?</strong>
          <p>
            Your organization owner or branch manager will assign the appropriate teacher, student,
            parent, or management access. Editing your profile cannot change authorization.
          </p>
        </aside>
      )}
    </main>
  );
}
