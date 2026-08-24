export const lessonSessionStates = [
  "draft",
  "started",
  "attendance_marked",
  "evidence_uploaded",
  "homework_assigned",
  "ai_review_ready",
  "teacher_reviewed",
  "published",
] as const;

export type LessonSessionState = (typeof lessonSessionStates)[number];

const nextStateByState: Readonly<Partial<Record<LessonSessionState, LessonSessionState>>> = {
  draft: "started",
  started: "attendance_marked",
  attendance_marked: "evidence_uploaded",
  evidence_uploaded: "homework_assigned",
  homework_assigned: "ai_review_ready",
  ai_review_ready: "teacher_reviewed",
  teacher_reviewed: "published",
};

export function nextLessonSessionState(state: LessonSessionState): LessonSessionState | null {
  return nextStateByState[state] ?? null;
}

export function canAdvanceLessonSession(
  currentState: LessonSessionState,
  nextState: LessonSessionState,
): boolean {
  return nextLessonSessionState(currentState) === nextState;
}

export function sessionStepIndex(state: LessonSessionState): number {
  return lessonSessionStates.indexOf(state);
}

export function sessionRecoveryMessage(state: LessonSessionState): string {
  switch (state) {
    case "draft":
      return "Start the class before recording attendance.";
    case "started":
      return "Record attendance for every enrolled student before continuing.";
    case "attendance_marked":
      return "Upload at least one transcript and one class resource before confirming evidence.";
    case "evidence_uploaded":
      return "Assign homework before preparing the AI review placeholder.";
    case "homework_assigned":
      return "Prepare the AI review placeholder. No production AI inference runs in this task.";
    case "ai_review_ready":
      return "Review the class evidence and explicitly confirm teacher review before publishing.";
    case "teacher_reviewed":
      return "Teacher review is complete. Publish when the class record is ready for students.";
    case "published":
      return "This class session is published and cannot move to another lifecycle state.";
  }
}
