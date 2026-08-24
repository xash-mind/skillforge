import { redirect } from "next/navigation";

import { createServerSupabaseClient } from "@/lib/supabase/server";

export type TeacherClassContext = {
  organization: { id: number; name: string; slug: string };
  membershipId: number;
  classRow: { id: number; branch_id: number; code: string; name: string; subject_id: number };
  supabase: Awaited<ReturnType<typeof createServerSupabaseClient>>;
  userId: string;
};

export async function requireTeacherClassContext(
  organizationSlug: string,
  classId: number,
): Promise<TeacherClassContext> {
  const supabase = await createServerSupabaseClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (claimsError || !userId) {
    redirect(
      `/auth/sign-in?next=${encodeURIComponent(`/workspace/${organizationSlug}/teacher/classes/${classId}`)}`,
    );
  }

  const { data: organization, error: organizationError } = await supabase
    .from("organizations")
    .select("id, name, slug")
    .eq("slug", organizationSlug)
    .eq("status", "active")
    .maybeSingle();

  if (organizationError) throw new Error("The organization could not be loaded.");
  if (!organization) redirect("/forbidden");

  const { data: membership, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("id")
    .eq("organization_id", organization.id)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();

  if (membershipError) throw new Error("Your organization membership could not be loaded.");
  if (!membership) redirect("/forbidden");

  const { data: classRow, error: classError } = await supabase
    .from("classes")
    .select("id, branch_id, code, name, subject_id")
    .eq("organization_id", organization.id)
    .eq("id", classId)
    .in("status", ["planned", "active"])
    .maybeSingle();

  if (classError) throw new Error("The class could not be loaded.");
  if (!classRow) redirect("/forbidden");

  const { data: teacherAssignment, error: teacherError } = await supabase
    .from("class_teachers")
    .select("id")
    .eq("organization_id", organization.id)
    .eq("branch_id", classRow.branch_id)
    .eq("class_id", classRow.id)
    .eq("organization_membership_id", membership.id)
    .eq("status", "active")
    .maybeSingle();

  if (teacherError) throw new Error("Your teacher assignment could not be verified.");
  if (!teacherAssignment) redirect("/forbidden");

  return { organization, membershipId: membership.id, classRow, supabase, userId };
}
