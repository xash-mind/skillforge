import type { Metadata, Route } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const metadata: Metadata = { title: "Teacher classes" };
export const dynamic = "force-dynamic";

type PageProps = { params: Promise<{ organizationSlug: string }> };

export default async function TeacherClassesPage({ params }: PageProps) {
  const { organizationSlug } = await params;
  const supabase = await createServerSupabaseClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;
  if (claimsError || !userId) {
    redirect(`/auth/sign-in?next=${encodeURIComponent(`/workspace/${organizationSlug}/teacher`)}`);
  }

  const { data: organization, error: organizationError } = await supabase
    .from("organizations")
    .select("id, name, slug")
    .eq("slug", organizationSlug)
    .eq("status", "active")
    .maybeSingle();
  if (organizationError) throw new Error("The teacher workspace could not be loaded.");
  if (!organization) redirect("/forbidden");

  const { data: membership, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("id")
    .eq("organization_id", organization.id)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();
  if (membershipError) throw new Error("Your teacher membership could not be loaded.");
  if (!membership) redirect("/forbidden");

  const { data: assignments, error: assignmentError } = await supabase
    .from("class_teachers")
    .select("class_id, branch_id")
    .eq("organization_id", organization.id)
    .eq("organization_membership_id", membership.id)
    .eq("status", "active");
  if (assignmentError) throw new Error("Your assigned classes could not be loaded.");

  const classIds = assignments.map((assignment) => assignment.class_id);
  const [classesResult, branchesResult] = await Promise.all([
    classIds.length
      ? supabase
          .from("classes")
          .select("id, branch_id, code, name, academic_year")
          .in("id", classIds)
          .in("status", ["planned", "active"])
          .order("name")
      : Promise.resolve({ data: [], error: null }),
    supabase
      .from("branches")
      .select("id, name")
      .eq("organization_id", organization.id)
      .eq("status", "active"),
  ]);
  if (classesResult.error || branchesResult.error) {
    throw new Error("Your teacher class list could not be loaded safely.");
  }

  const classes = classesResult.data ?? [];
  const branchById = new Map((branchesResult.data ?? []).map((branch) => [branch.id, branch.name]));

  return (
    <main className="teacher-page">
      <header className="workspace-header">
        <BrandMark />
        <Link className="button button--quiet" href="/workspace">
          Back to workspaces
        </Link>
      </header>
      <section className="teacher-hero" aria-labelledby="teacher-classes-title">
        <p className="eyebrow">Teacher workflow · {organization.name}</p>
        <h1 id="teacher-classes-title">Your live classes, one guided step at a time.</h1>
        <p>
          Start a class, record attendance, upload evidence, assign homework, review the
          placeholder, and publish only after your explicit review.
        </p>
      </section>
      {classes.length ? (
        <ul className="teacher-class-list" aria-label="Assigned classes">
          {classes.map((classRow) => (
            <li key={classRow.id}>
              <div>
                <p className="eyebrow">{branchById.get(classRow.branch_id) ?? "Assigned branch"}</p>
                <h2>{classRow.name}</h2>
                <p>
                  {classRow.code} · {classRow.academic_year}
                </p>
              </div>
              <Link
                className="button"
                href={`/workspace/${organizationSlug}/teacher/classes/${classRow.id}` as Route}
              >
                Open class
              </Link>
            </li>
          ))}
        </ul>
      ) : (
        <aside className="teacher-empty">
          <strong>No active class assignment yet.</strong>
          <p>
            An organization owner or branch manager must assign you to a class before it appears
            here.
          </p>
        </aside>
      )}
    </main>
  );
}
