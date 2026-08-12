"use server";

import type { Route } from "next";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import type { LessonSessionState } from "@/modules/classroom/domain/session-state";
import { requireTeacherClassContext } from "@/modules/classroom/server/teacher-class-context";

const id = z.coerce.number().int().positive();
const shortText = z.string().trim().min(2).max(180);
const optionalLongText = z.string().trim().max(4000).default("");
const state = z.enum([
  "draft",
  "started",
  "attendance_marked",
  "evidence_uploaded",
  "homework_assigned",
  "ai_review_ready",
  "teacher_reviewed",
  "published",
]);
const attendanceStatus = z.enum(["present", "absent", "late", "excused"]);

function value(formData: FormData, name: string): string {
  const raw = formData.get(name);
  return typeof raw === "string" ? raw : "";
}

function teacherPath(
  organizationSlug: string,
  classId: number,
  kind?: "error" | "notice",
  message?: string,
): Route {
  const base = `/workspace/${organizationSlug}/teacher/classes/${classId}`;
  if (!kind || !message) return base as Route;
  return `${base}?${new URLSearchParams({ [kind]: message })}` as Route;
}

function fail(organizationSlug: string, classId: number, error: unknown): never {
  let message = "That class step could not be saved. Review the current step and try again.";
  if (error instanceof z.ZodError) message = "Check the required class details and try again.";
  if (typeof error === "object" && error && "message" in error) {
    const databaseMessage = String(error.message);
    if (databaseMessage.includes("attendance for every")) {
      message = "Record attendance for every enrolled student before continuing.";
    } else if (databaseMessage.includes("transcript")) {
      message = "Upload a transcript successfully before confirming class evidence.";
    } else if (databaseMessage.includes("class resource")) {
      message = "Upload a class resource successfully before confirming class evidence.";
    } else if (databaseMessage.includes("homework")) {
      message = "Assign homework before continuing to the AI review placeholder.";
    } else if (databaseMessage.includes("teacher review")) {
      message = "Complete the explicit teacher review before publishing.";
    } else if (databaseMessage.includes("session state changed")) {
      message = "This session changed in another tab. Reload the step shown here and try again.";
    }
  }
  redirect(teacherPath(organizationSlug, classId, "error", message));
}

function succeed(organizationSlug: string, classId: number, message: string): never {
  const path = teacherPath(organizationSlug, classId);
  revalidatePath(path);
  redirect(teacherPath(organizationSlug, classId, "notice", message));
}

async function sessionContext(formData: FormData) {
  const organizationSlug = value(formData, "organizationSlug");
  const classId = id.parse(value(formData, "classId"));
  const sessionId = id.parse(value(formData, "sessionId"));
  const expectedState = state.parse(value(formData, "expectedState"));
  const context = await requireTeacherClassContext(organizationSlug, classId);
  const { data: session, error } = await context.supabase
    .from("lesson_sessions")
    .select("id, state")
    .eq("id", sessionId)
    .eq("class_id", classId)
    .maybeSingle();
  if (error || !session) fail(organizationSlug, classId, error ?? new Error("Session unavailable"));
  if (session.state !== expectedState) {
    fail(organizationSlug, classId, new Error("session state changed"));
  }
  return { organizationSlug, classId, sessionId, expectedState, context };
}

async function advance(
  organizationSlug: string,
  classId: number,
  sessionId: number,
  expectedState: LessonSessionState,
  nextState: LessonSessionState,
) {
  const context = await requireTeacherClassContext(organizationSlug, classId);
  const { error } = await context.supabase.rpc("advance_lesson_session", {
    lesson_session_id_input: sessionId,
    expected_state_input: expectedState,
    next_state_input: nextState,
  });
  if (error) fail(organizationSlug, classId, error);
}

export async function startClassAction(formData: FormData) {
  const organizationSlug = value(formData, "organizationSlug");
  const classId = id.parse(value(formData, "classId"));
  const titleRaw = value(formData, "title");
  const title = titleRaw ? shortText.parse(titleRaw) : "Class session";
  const context = await requireTeacherClassContext(organizationSlug, classId);
  const { error } = await context.supabase.rpc("start_lesson_session", {
    class_id_input: classId,
    title_input: title,
  });
  if (error) fail(organizationSlug, classId, error);
  succeed(
    organizationSlug,
    classId,
    "Class started. Record attendance for every enrolled student.",
  );
}

export async function saveAttendanceAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  if (resolved.expectedState !== "started") {
    fail(resolved.organizationSlug, resolved.classId, new Error("session state changed"));
  }

  const { data: enrollments, error: enrollmentError } = await resolved.context.supabase
    .from("class_enrollments")
    .select("organization_membership_id")
    .eq("class_id", resolved.classId)
    .eq("status", "enrolled");
  if (enrollmentError) fail(resolved.organizationSlug, resolved.classId, enrollmentError);
  if (!enrollments?.length) {
    fail(resolved.organizationSlug, resolved.classId, new Error("attendance for every"));
  }

  const records = enrollments.map((enrollment) => ({
    organization_id: resolved.context.organization.id,
    branch_id: resolved.context.classRow.branch_id,
    class_id: resolved.classId,
    lesson_session_id: resolved.sessionId,
    organization_membership_id: enrollment.organization_membership_id,
    status: attendanceStatus.parse(
      value(formData, `attendance-${enrollment.organization_membership_id}`),
    ),
    note: null,
    recorded_by: resolved.context.userId,
  }));

  const { error } = await resolved.context.supabase
    .from("attendance_records")
    .upsert(records, { onConflict: "lesson_session_id,organization_membership_id" });
  if (error) fail(resolved.organizationSlug, resolved.classId, error);

  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "started",
    "attendance_marked",
  );
  succeed(
    resolved.organizationSlug,
    resolved.classId,
    "Attendance saved. Upload the transcript and at least one class resource.",
  );
}

export async function confirmEvidenceAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "attendance_marked",
    "evidence_uploaded",
  );
  succeed(resolved.organizationSlug, resolved.classId, "Evidence confirmed. Assign homework next.");
}

export async function assignHomeworkAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  if (resolved.expectedState !== "evidence_uploaded") {
    fail(resolved.organizationSlug, resolved.classId, new Error("session state changed"));
  }
  const title = shortText.parse(value(formData, "homeworkTitle"));
  const instructions = optionalLongText.parse(value(formData, "homeworkInstructions"));
  const dueAt = value(formData, "dueAt");
  const { error } = await resolved.context.supabase.from("homework_assignments").insert({
    organization_id: resolved.context.organization.id,
    branch_id: resolved.context.classRow.branch_id,
    class_id: resolved.classId,
    lesson_session_id: resolved.sessionId,
    title,
    instructions: instructions || null,
    due_at: dueAt ? new Date(dueAt).toISOString() : null,
    created_by: resolved.context.userId,
  });
  if (error) fail(resolved.organizationSlug, resolved.classId, error);
  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "evidence_uploaded",
    "homework_assigned",
  );
  succeed(
    resolved.organizationSlug,
    resolved.classId,
    "Homework assigned. Prepare the AI review placeholder; no production AI runs yet.",
  );
}

export async function prepareAiReviewAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "homework_assigned",
    "ai_review_ready",
  );
  succeed(
    resolved.organizationSlug,
    resolved.classId,
    "AI review placeholder prepared. Review the evidence yourself before publishing.",
  );
}

export async function confirmTeacherReviewAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  if (value(formData, "teacherConfirmed") !== "yes") {
    fail(resolved.organizationSlug, resolved.classId, new Error("teacher review"));
  }
  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "ai_review_ready",
    "teacher_reviewed",
  );
  succeed(
    resolved.organizationSlug,
    resolved.classId,
    "Teacher review recorded. Publish is now unlocked.",
  );
}

export async function publishSessionAction(formData: FormData) {
  const resolved = await sessionContext(formData);
  await advance(
    resolved.organizationSlug,
    resolved.classId,
    resolved.sessionId,
    "teacher_reviewed",
    "published",
  );
  succeed(
    resolved.organizationSlug,
    resolved.classId,
    "Class session published after teacher review.",
  );
}
