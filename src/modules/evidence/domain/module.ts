import { defineModule } from "@/modules/_shared/domain/module-definition";

export const evidenceModule = defineModule({
  key: "evidence",
  name: "Learning evidence",
  purpose:
    "Immutable provenance for transcripts, notes, assessments, attendance, and observations.",
  dependsOn: ["tenancy", "academic", "classroom"],
});
