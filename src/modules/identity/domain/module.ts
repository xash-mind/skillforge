import { defineModule } from "@/modules/_shared/domain/module-definition";

export const identityModule = defineModule({
  key: "identity",
  name: "Identity and access",
  purpose: "Authentication, memberships, role assignments, and authorization policy.",
  dependsOn: [],
});
