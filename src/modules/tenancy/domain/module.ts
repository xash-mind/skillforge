import { defineModule } from "@/modules/_shared/domain/module-definition";

export const tenancyModule = defineModule({
  key: "tenancy",
  name: "Organizations and branches",
  purpose: "Tenant ownership, branch boundaries, and organization configuration.",
  dependsOn: ["identity"],
});
