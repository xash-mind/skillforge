import { defineModule } from "@/modules/_shared/domain/module-definition";

export const governanceModule = defineModule({
  key: "governance",
  name: "Privacy and governance",
  purpose: "Region-aware consent, organization-selected retention, and data policy controls.",
  dependsOn: ["identity", "tenancy"],
});
