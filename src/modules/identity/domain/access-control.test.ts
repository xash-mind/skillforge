import { describe, expect, it } from "vitest";

import {
  canAssignRole,
  hasCapability,
  type TrustedRoleAssignment,
} from "@/modules/identity/domain/access-control";

const manager: TrustedRoleAssignment = {
  organizationId: 7,
  branchId: 70,
  role: "branch_manager",
  status: "active",
};

describe("trusted role authorization", () => {
  it("allows an organization owner to administer the organization", () => {
    expect(
      hasCapability(
        [
          {
            organizationId: 7,
            branchId: null,
            role: "organization_owner",
            status: "active",
          },
        ],
        "manage_organization",
        { organizationId: 7 },
      ),
    ).toBe(true);
  });

  it("keeps a branch manager inside the assigned branch", () => {
    expect(hasCapability([manager], "manage_branch", { organizationId: 7, branchId: 70 })).toBe(
      true,
    );
    expect(hasCapability([manager], "manage_branch", { organizationId: 7, branchId: 71 })).toBe(
      false,
    );
  });

  it("rejects revoked and foreign-tenant assignments", () => {
    expect(
      hasCapability([{ ...manager, status: "revoked" }], "manage_branch", {
        organizationId: 7,
        branchId: 70,
      }),
    ).toBe(false);
    expect(hasCapability([manager], "manage_branch", { organizationId: 8, branchId: 70 })).toBe(
      false,
    );
  });

  it("limits branch-manager delegation to non-manager branch roles", () => {
    expect(canAssignRole("branch_manager", "teacher")).toBe(true);
    expect(canAssignRole("branch_manager", "parent")).toBe(true);
    expect(canAssignRole("branch_manager", "branch_manager")).toBe(false);
    expect(canAssignRole("teacher", "student")).toBe(false);
  });
});
