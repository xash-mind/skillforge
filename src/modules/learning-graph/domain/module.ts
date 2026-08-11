import { defineModule } from "@/modules/_shared/domain/module-definition";

export const learningGraphModule = defineModule({
  key: "learning-graph",
  name: "Learning graph",
  purpose:
    "Continuously evolving relationships between evidence, learners, and syllabus objectives.",
  dependsOn: ["academic", "evidence"],
});
