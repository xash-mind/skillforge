import { defineModule } from "@/modules/_shared/domain/module-definition";

export const auditOperationsModule = defineModule({
  key: "audit-operations",
  name: "Audit and operations",
  purpose: "Append-only accountability, operational events, and support diagnostics.",
  dependsOn: ["identity", "tenancy", "governance"],
});
