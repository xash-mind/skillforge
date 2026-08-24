import { describe, expect, it } from "vitest";

import {
  canAdvanceLessonSession,
  lessonSessionStates,
  nextLessonSessionState,
  sessionRecoveryMessage,
} from "./session-state";

describe("teacher class lifecycle", () => {
  it("permits only the approved forward transitions", () => {
    for (const [index, state] of lessonSessionStates.entries()) {
      const expected = lessonSessionStates[index + 1] ?? null;
      expect(nextLessonSessionState(state)).toBe(expected);

      for (const candidate of lessonSessionStates) {
        expect(canAdvanceLessonSession(state, candidate)).toBe(candidate === expected);
      }
    }
  });

  it("keeps publish behind explicit teacher review", () => {
    expect(canAdvanceLessonSession("ai_review_ready", "published")).toBe(false);
    expect(canAdvanceLessonSession("teacher_reviewed", "published")).toBe(true);
  });

  it("provides actionable recovery guidance for every state", () => {
    for (const state of lessonSessionStates) {
      expect(sessionRecoveryMessage(state).length).toBeGreaterThan(20);
    }
  });
});
