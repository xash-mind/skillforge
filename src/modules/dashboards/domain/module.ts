import { defineModule } from "@/modules/_shared/domain/module-definition";

export const dashboardsModule = defineModule({
  key: "dashboards",
  name: "Role workspaces",
  purpose: "Task-led organization, teacher, student, and parent experiences.",
  dependsOn: ["identity", "classroom", "learning-graph"],
});
