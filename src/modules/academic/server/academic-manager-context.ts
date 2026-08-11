import { redirect } from "next/navigation";

import { createServerSupabaseClient } from "@/lib/supabase/server";
import {
  getAcademicManagementScope,
  hasAcademicManagementAccess,
  type AcademicManagementScope,
} from "@/modules/academic/domain/academic-access";

export type AcademicManagerContext = {
  organization: {
    id: number;
    name: string;
    slug: string;
  };
  membershipId: number;
  scope: AcademicManagementScope;
  supabase: Awaited<ReturnType<typeof createServerSupabaseClient>>;
  userId: string;
};

export async function requireAcademicManagerContext(
  organizationSlug: string,
): Promise<AcademicManagerContext> {
  const supabase = await createServerSupabaseClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const userId = claimsData?.claims?.sub;

  if (claimsError || !userId) {
    redirect(`/auth/sign-in?next=${encodeURIComponent(`/workspace/${organizationSlug}/academic`)}`);
  }

  const { data: organization, error: organizationError } = await supabase
    .from("organizations")
    .select("id, name, slug")
    .eq("slug", organizationSlug)
    .eq("status", "active")
    .maybeSingle();

  if (organizationError) {
    throw new Error("The organization could not be loaded.");
  }

  if (!organization) {
    redirect("/forbidden");
  }

  const { data: membership, error: membershipError } = await supabase
    .from("organization_memberships")
    .select("id")
    .eq("organization_id", organization.id)
    .eq("user_id", userId)
    .eq("status", "active")
    .maybeSingle();

  if (membershipError) {
    throw new Error("Your organization membership could not be loaded.");
  }

  if (!membership) {
    redirect("/forbidden");
  }

  const { data: assignments, error: assignmentError } = await supabase
    .from("role_assignments")
    .select("branch_id, role")
    .eq("organization_id", organization.id)
    .eq("organization_membership_id", membership.id)
    .eq("status", "active");

  if (assignmentError) {
    throw new Error("Your academic management scope could not be loaded.");
  }

  const scope = getAcademicManagementScope(assignments);

  if (!hasAcademicManagementAccess(scope)) {
    redirect("/forbidden");
  }

  return {
    organization,
    membershipId: membership.id,
    scope,
    supabase,
    userId,
  };
}
