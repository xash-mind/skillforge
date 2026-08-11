import { defineModule } from "@/modules/_shared/domain/module-definition";

export const billingModule = defineModule({
  key: "billing",
  name: "Billing and metering",
  purpose: "Manually activated student metering with plans and invoice records.",
  dependsOn: ["tenancy", "identity"],
});
