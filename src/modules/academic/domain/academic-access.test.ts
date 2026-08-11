import { describe, expect, it } from "vitest";

import {
  canManageAcademicBranch,
  getAcademicManagementScope,
  hasAcademicManagementAccess,
  weekdayLabel,
} from "./academic-access";

describe("academic management access", () => {
  it("gives an organization owner curriculum and all-branch management", () => {
    const scope = getAcademicManagementScope([
      { role: "organization_owner", branch_id: null },
      { role: "branch_manager", branch_id: 12 },
    ]);
    expect(scope.canManageCurriculum).toBe(true);
    expect(scope.canManageAllBranches).toBe(true);
    expect(scope.managedBranchIds).toEqual([]);
    expect(canManageAcademicBranch(scope, 999)).toBe(true);
  });

  it("limits branch managers to the branches explicitly assigned to them", () => {
    const scope = getAcademicManagementScope([
      { role: "branch_manager", branch_id: 9 },
      { role: "teacher", branch_id: 11 },
      { role: "branch_manager", branch_id: 3 },
      { role: "branch_manager", branch_id: 9 },
    ]);
    expect(scope.canManageCurriculum).toBe(false);
    expect(scope.managedBranchIds).toEqual([3, 9]);
    expect(canManageAcademicBranch(scope, 3)).toBe(true);
    expect(canManageAcademicBranch(scope, 11)).toBe(false);
  });

  it("does not mistake teaching or student roles for academic administration", () => {
    const scope = getAcademicManagementScope([
      { role: "teacher", branch_id: 2 },
      { role: "student", branch_id: 2 },
    ]);
    expect(hasAcademicManagementAccess(scope)).toBe(false);
  });

  it("labels timetable weekdays consistently", () => {
    expect(weekdayLabel(1)).toBe("Monday");
    expect(weekdayLabel(7)).toBe("Sunday");
    expect(weekdayLabel(8)).toBe("Day 8");
  });
});
