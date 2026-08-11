export const organizationRoles = [
  "organization_owner",
  "branch_manager",
  "teacher",
  "student",
  "parent",
] as const;

export type OrganizationRole = (typeof organizationRoles)[number];

export const capabilities = [
  "manage_organization",
  "manage_branch",
  "manage_organization_roles",
  "manage_branch_roles",
  "teach",
  "learn",
  "support_student",
] as const;

export type Capability = (typeof capabilities)[number];

const roleCapabilities: Readonly<Record<OrganizationRole, readonly Capability[]>> = {
  organization_owner: [
    "manage_organization",
    "manage_branch",
    "manage_organization_roles",
    "manage_branch_roles",
  ],
  branch_manager: ["manage_branch", "manage_branch_roles"],
  teacher: ["teach"],
  student: ["learn"],
  parent: ["support_student"],
};

const roleLabels: Readonly<Record<OrganizationRole, string>> = {
  organization_owner: "Organization owner",
  branch_manager: "Branch manager",
  teacher: "Teacher",
  student: "Student",
  parent: "Parent",
};

export type TrustedRoleAssignment = Readonly<{
  organizationId: number;
  branchId: number | null;
  role: OrganizationRole;
  status: "active" | "revoked";
}>;

export type AuthorizationScope = Readonly<{
  organizationId: number;
  branchId?: number;
}>;

export function roleLabel(role: OrganizationRole) {
  return roleLabels[role];
}

export function canAssignRole(actor: OrganizationRole, roleToAssign: OrganizationRole) {
  if (actor === "organization_owner") {
    return true;
  }

  return (
    actor === "branch_manager" &&
    (["teacher", "student", "parent"] as const).includes(
      roleToAssign as "teacher" | "student" | "parent",
    )
  );
}

export function hasCapability(
  assignments: readonly TrustedRoleAssignment[],
  capability: Capability,
  scope: AuthorizationScope,
) {
  return assignments.some((assignment) => {
    if (
      assignment.status !== "active" ||
      assignment.organizationId !== scope.organizationId ||
      !roleCapabilities[assignment.role].includes(capability)
    ) {
      return false;
    }

    if (assignment.role === "organization_owner") {
      return assignment.branchId === null;
    }

    return scope.branchId === undefined || assignment.branchId === scope.branchId;
  });
}
