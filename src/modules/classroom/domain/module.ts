import { defineModule } from "@/modules/_shared/domain/module-definition";

export const classroomModule = defineModule({
  key: "classroom",
  name: "Class lifecycle",
  purpose: "Lesson sessions, attendance, resources, assignments, and publication workflow.",
  dependsOn: ["identity", "tenancy", "academic"],
});
