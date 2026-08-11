import { defineModule } from "@/modules/_shared/domain/module-definition";

export const aiModule = defineModule({
  key: "ai",
  name: "Teacher-controlled intelligence",
  purpose: "Provider-neutral recommendations that remain drafts until a teacher approves them.",
  dependsOn: ["evidence", "learning-graph", "governance"],
});
