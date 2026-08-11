import { academicModule } from "@/modules/academic/domain/module";
import { aiModule } from "@/modules/ai/domain/module";
import { auditOperationsModule } from "@/modules/audit-operations/domain/module";
import { billingModule } from "@/modules/billing/domain/module";
import { classroomModule } from "@/modules/classroom/domain/module";
import { dashboardsModule } from "@/modules/dashboards/domain/module";
import { evidenceModule } from "@/modules/evidence/domain/module";
import { governanceModule } from "@/modules/governance/domain/module";
import { identityModule } from "@/modules/identity/domain/module";
import { learningGraphModule } from "@/modules/learning-graph/domain/module";
import { tenancyModule } from "@/modules/tenancy/domain/module";

export const moduleCatalog = [
  identityModule,
  tenancyModule,
  academicModule,
  classroomModule,
  evidenceModule,
  learningGraphModule,
  governanceModule,
  aiModule,
  dashboardsModule,
  billingModule,
  auditOperationsModule,
] as const;
