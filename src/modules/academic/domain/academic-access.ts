export type AcademicRoleAssignment = {
  branch_id: number | null;
  role: string;
  status?: string;
};

export type AcademicManagementScope = {
  canManageCurriculum: boolean;
  canManageAllBranches: boolean;
  managedBranchIds: readonly number[];
};

export function getAcademicManagementScope(
  assignments: readonly AcademicRoleAssignment[],
): AcademicManagementScope {
  const active = assignments.filter((assignment) => assignment.status !== "revoked");
  const organizationOwner = active.some(
    (assignment) => assignment.role === "organization_owner" && assignment.branch_id === null,
  );

  if (organizationOwner) {
    return {
      canManageCurriculum: true,
      canManageAllBranches: true,
      managedBranchIds: [],
    };
  }

  const managedBranchIds = Array.from(
    new Set(
      active
        .filter(
          (assignment): assignment is AcademicRoleAssignment & { branch_id: number } =>
            assignment.role === "branch_manager" && assignment.branch_id !== null,
        )
        .map((assignment) => assignment.branch_id),
    ),
  ).sort((left, right) => left - right);

  return {
    canManageCurriculum: false,
    canManageAllBranches: false,
    managedBranchIds,
  };
}

export function canManageAcademicBranch(scope: AcademicManagementScope, branchId: number): boolean {
  return scope.canManageAllBranches || scope.managedBranchIds.includes(branchId);
}

export function hasAcademicManagementAccess(scope: AcademicManagementScope): boolean {
  return scope.canManageAllBranches || scope.managedBranchIds.length > 0;
}

export function weekdayLabel(weekday: number): string {
  return (
    ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][weekday - 1] ??
    `Day ${weekday}`
  );
}
