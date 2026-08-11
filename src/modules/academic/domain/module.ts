import { defineModule } from "@/modules/_shared/domain/module-definition";

export const academicModule = defineModule({
  key: "academic",
  name: "Academic structure",
  purpose: "Syllabuses, subjects, objectives, classes, and timetables.",
  dependsOn: ["tenancy"],
});
