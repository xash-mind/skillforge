import type { Metadata, Route } from "next";
import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";
import {
  lessonSessionStates,
  sessionRecoveryMessage,
  sessionStepIndex,
  type LessonSessionState,
} from "@/modules/classroom/domain/session-state";
import { requireTeacherClassContext } from "@/modules/classroom/server/teacher-class-context";

import {
  assignHomeworkAction,
  confirmEvidenceAction,
  confirmTeacherReviewAction,
  prepareAiReviewAction,
  publishSessionAction,
  saveAttendanceAction,
  startClassAction,
} from "../../actions";

export const metadata: Metadata = { title: "Teacher class lifecycle" };
export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ organizationSlug: string; classId: string }>;
  searchParams: Promise<{ error?: string | string[]; notice?: string | string[] }>;
};

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

function stateLabel(state: LessonSessionState) {
  return state.replaceAll("_", " ");
}

function SessionFields({
  organizationSlug,
  classId,
  sessionId,
  expectedState,
}: {
  organizationSlug: string;
  classId: number;
  sessionId: number;
  expectedState: LessonSessionState;
}) {
  return (
    <>
      <input type="hidden" name="organizationSlug" value={organizationSlug} />
      <input type="hidden" name="classId" value={classId} />
      <input type="hidden" name="sessionId" value={sessionId} />
      <input type="hidden" name="expectedState" value={expectedState} />
    </>
  );
}

export default async function TeacherClassPage({ params, searchParams }: PageProps) {
  const resolvedParams = await params;
  const organizationSlug = resolvedParams.organizationSlug;
  const classId = Number(resolvedParams.classId);
  if (!Number.isInteger(classId) || classId <= 0) throw new Error("Invalid class identifier.");
  const query = await searchParams;
  const context = await requireTeacherClassContext(organizationSlug, classId);

  const [subjectResult, branchResult, enrollmentsResult, sessionResult] = await Promise.all([
    context.supabase
      .from("subjects")
      .select("name, code")
      .eq("id", context.classRow.subject_id)
      .maybeSingle(),
    context.supabase
      .from("branches")
      .select("name, code")
      .eq("id", context.classRow.branch_id)
      .maybeSingle(),
    context.supabase
      .from("class_enrollments")
      .select("organization_membership_id")
      .eq("class_id", classId)
      .eq("status", "enrolled")
      .order("organization_membership_id"),
    context.supabase
      .from("lesson_sessions")
      .select("id, state, title, session_date, teacher_reviewed_at, published_at")
      .eq("class_id", classId)
      .neq("state", "published")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);

  if (subjectResult.error || branchResult.error || enrollmentsResult.error || sessionResult.error) {
    throw new Error("The live class workspace could not be loaded safely.");
  }

  const enrollments = enrollmentsResult.data ?? [];
  const membershipIds = enrollments.map((enrollment) => enrollment.organization_membership_id);
  const membershipsResult = membershipIds.length
    ? await context.supabase
        .from("organization_memberships")
        .select("id, user_id")
        .in("id", membershipIds)
    : { data: [], error: null };
  if (membershipsResult.error) throw new Error("Student memberships could not be loaded.");

  const profileIds = (membershipsResult.data ?? []).map((membership) => membership.user_id);
  const profilesResult = profileIds.length
    ? await context.supabase.from("profiles").select("id, display_name").in("id", profileIds)
    : { data: [], error: null };
  if (profilesResult.error) throw new Error("Student names could not be loaded.");

  const profileById = new Map(
    (profilesResult.data ?? []).map((profile) => [profile.id, profile.display_name]),
  );
  const membershipById = new Map(
    (membershipsResult.data ?? []).map((membership) => [membership.id, membership]),
  );
  const students = enrollments.map((enrollment) => {
    const membership = membershipById.get(enrollment.organization_membership_id);
    return {
      membershipId: enrollment.organization_membership_id,
      name: membership
        ? (profileById.get(membership.user_id) ?? `Student ${membership.id}`)
        : `Student ${enrollment.organization_membership_id}`,
    };
  });

  const session = sessionResult.data;
  const sessionState = session?.state as LessonSessionState | undefined;
  const [attendanceResult, uploadsResult, homeworkResult] = session
    ? await Promise.all([
        context.supabase
          .from("attendance_records")
          .select("organization_membership_id, status")
          .eq("lesson_session_id", session.id),
        context.supabase
          .from("lesson_uploads")
          .select("id, kind, original_name, status, failure_message, retry_count")
          .eq("lesson_session_id", session.id)
          .order("created_at"),
        context.supabase
          .from("homework_assignments")
          .select("id, title, instructions, due_at")
          .eq("lesson_session_id", session.id)
          .order("created_at", { ascending: false })
          .limit(1),
      ])
    : [{ data: [], error: null }, { data: [], error: null }, { data: [], error: null }];

  if (attendanceResult.error || uploadsResult.error || homeworkResult.error) {
    throw new Error("The current class evidence could not be loaded safely.");
  }

  const attendanceByMembership = new Map(
    (attendanceResult.data ?? []).map((record) => [record.organization_membership_id, record.status]),
  );
  const uploads = uploadsResult.data ?? [];
  const homework = (homeworkResult.data ?? [])[0];
  const notice = first(query.notice);
  const error = first(query.error);

  return (
    <main className="teacher-page teacher-session-page">
      <header className="workspace-header">
        <BrandMark />
        <Link
          className="button button--quiet"
          href={`/workspace/${organizationSlug}/teacher` as Route}
        >
          All classes
        </Link>
      </header>

      <section className="teacher-hero" aria-labelledby="class-session-title">
        <p className="eyebrow">
          {branchResult.data?.name ?? "Assigned branch"} · {subjectResult.data?.name ?? "Subject"}
        </p>
        <h1 id="class-session-title">{context.classRow.name}</h1>
        <p>
          {context.classRow.code}. The database enforces the lifecycle order; each card below tells
          you exactly what is required next.
        </p>
      </section>

      {notice ? (
        <p className="teacher-message teacher-message--success" role="status">
          {notice}
        </p>
      ) : null}
      {error ? (
        <p className="teacher-message teacher-message--error" role="alert">
          {error}
        </p>
      ) : null}

      {!session ? (
        <section className="teacher-panel teacher-start" aria-labelledby="start-class-title">
          <div>
            <p className="eyebrow">Step 1</p>
            <h2 id="start-class-title">Start Class</h2>
            <p>
              Starting creates the single active session for this class and locks the next step to
              attendance.
            </p>
          </div>
          <form action={startClassAction}>
            <input type="hidden" name="organizationSlug" value={organizationSlug} />
            <input type="hidden" name="classId" value={classId} />
            <label>
              Session title
              <input
                name="title"
                defaultValue="Class session"
                minLength={2}
                maxLength={180}
                required
              />
            </label>
            <button className="button" type="submit">
              Start Class
            </button>
          </form>
        </section>
      ) : (
        <>
          <nav className="teacher-progress" aria-label="Class lifecycle progress">
            <ol>
              {lessonSessionStates.slice(1).map((step) => {
                const reached = sessionStepIndex(sessionState!) >= sessionStepIndex(step);
                return (
                  <li
                    key={step}
                    aria-current={sessionState === step ? "step" : undefined}
                    data-complete={reached}
                  >
                    {stateLabel(step)}
                  </li>
                );
              })}
            </ol>
          </nav>

          <aside className="teacher-recovery" aria-live="polite">
            <strong>Current state: {stateLabel(sessionState!)}</strong>
            <span>{sessionRecoveryMessage(sessionState!)}</span>
          </aside>

          <section
            className="teacher-panel"
            aria-labelledby="attendance-title"
            data-active={sessionState === "started"}
          >
            <div>
              <p className="eyebrow">Step 2</p>
              <h2 id="attendance-title">Attendance</h2>
              <p>Every enrolled student needs a status before the session can advance.</p>
            </div>
            <form action={saveAttendanceAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <fieldset disabled={sessionState !== "started"}>
                <legend>Student attendance</legend>
                {students.length ? (
                  students.map((student) => (
                    <label key={student.membershipId}>
                      {student.name}
                      <select
                        name={`attendance-${student.membershipId}`}
                        defaultValue={attendanceByMembership.get(student.membershipId) ?? "present"}
                        required
                      >
                        <option value="present">Present</option>
                        <option value="late">Late</option>
                        <option value="absent">Absent</option>
                        <option value="excused">Excused</option>
                      </select>
                    </label>
                  ))
                ) : (
                  <p role="alert">
                    No enrolled students are available. Ask an administrator to enroll students
                    before continuing.
                  </p>
                )}
              </fieldset>
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "started" || !students.length}
              >
                Save attendance and continue
              </button>
            </form>
          </section>

          <section
            className="teacher-panel"
            aria-labelledby="evidence-title"
            data-active={sessionState === "attendance_marked"}
          >
            <div>
              <p className="eyebrow">Step 3</p>
              <h2 id="evidence-title">Transcript & resources</h2>
              <p>
                Both a transcript and a class resource must upload successfully. Failed uploads
                remain visible and retryable.
              </p>
            </div>
            {sessionState === "attendance_marked" ? (
              <div className="teacher-upload-grid">
                {(["transcript", "resource"] as const).map((kind) => (
                  <form
                    key={kind}
                    action={`/workspace/${organizationSlug}/teacher/classes/${classId}/upload`}
                    method="post"
                    encType="multipart/form-data"
                  >
                    <input type="hidden" name="sessionId" value={session.id} />
                    <input type="hidden" name="kind" value={kind} />
                    <label>
                      {kind === "transcript" ? "Transcript file" : "Class resource"}
                      <input
                        type="file"
                        name="file"
                        required
                        accept={
                          kind === "transcript"
                            ? ".txt,.pdf,.docx,.mp3,.wav,.m4a,audio/*"
                            : ".pdf,.docx,.pptx,.txt,.jpg,.jpeg,.png"
                        }
                      />
                    </label>
                    <button className="button button--quiet" type="submit">
                      Upload {kind}
                    </button>
                  </form>
                ))}
              </div>
            ) : null}
            <ul className="teacher-upload-list" aria-label="Class uploads">
              {uploads.map((upload) => (
                <li key={upload.id} data-status={upload.status}>
                  <div>
                    <strong>
                      {upload.kind}: {upload.original_name}
                    </strong>
                    <span>
                      {upload.status}
                      {upload.retry_count ? ` · ${upload.retry_count} retries` : ""}
                    </span>
                    {upload.failure_message ? <span role="alert">{upload.failure_message}</span> : null}
                  </div>
                  {upload.status === "failed" && sessionState === "attendance_marked" ? (
                    <form
                      action={`/workspace/${organizationSlug}/teacher/classes/${classId}/upload`}
                      method="post"
                      encType="multipart/form-data"
                    >
                      <input type="hidden" name="sessionId" value={session.id} />
                      <input type="hidden" name="kind" value={upload.kind} />
                      <input type="hidden" name="retryUploadId" value={upload.id} />
                      <label>
                        Choose the file again
                        <input type="file" name="file" required />
                      </label>
                      <button className="button button--quiet" type="submit">
                        Retry upload
                      </button>
                    </form>
                  ) : null}
                </li>
              ))}
            </ul>
            <form action={confirmEvidenceAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "attendance_marked"}
              >
                Confirm successful evidence and continue
              </button>
            </form>
          </section>

          <section
            className="teacher-panel"
            aria-labelledby="homework-title"
            data-active={sessionState === "evidence_uploaded"}
          >
            <div>
              <p className="eyebrow">Step 4</p>
              <h2 id="homework-title">Homework</h2>
              <p>Set the follow-up work before preparing the review placeholder.</p>
            </div>
            {homework ? (
              <p className="teacher-summary">
                <strong>{homework.title}</strong>
                {homework.instructions ? ` · ${homework.instructions}` : ""}
              </p>
            ) : null}
            <form action={assignHomeworkAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <label>
                Homework title
                <input
                  name="homeworkTitle"
                  minLength={2}
                  maxLength={180}
                  required
                  disabled={sessionState !== "evidence_uploaded"}
                />
              </label>
              <label>
                Instructions
                <textarea
                  name="homeworkInstructions"
                  maxLength={4000}
                  disabled={sessionState !== "evidence_uploaded"}
                />
              </label>
              <label>
                Due date and time
                <input
                  type="datetime-local"
                  name="dueAt"
                  disabled={sessionState !== "evidence_uploaded"}
                />
              </label>
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "evidence_uploaded"}
              >
                Assign homework and continue
              </button>
            </form>
          </section>

          <section
            className="teacher-panel"
            aria-labelledby="ai-review-title"
            data-active={sessionState === "homework_assigned"}
          >
            <div>
              <p className="eyebrow">Step 5</p>
              <h2 id="ai-review-title">AI review placeholder</h2>
              <p>
                No production AI inference runs here. TASK-004 only proves the lifecycle boundary
                that later AI adapters will occupy.
              </p>
            </div>
            <form action={prepareAiReviewAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "homework_assigned"}
              >
                Prepare review placeholder
              </button>
            </form>
          </section>

          <section
            className="teacher-panel"
            aria-labelledby="teacher-review-title"
            data-active={sessionState === "ai_review_ready"}
          >
            <div>
              <p className="eyebrow">Step 6</p>
              <h2 id="teacher-review-title">Teacher review</h2>
              <p>
                Publishing stays locked until you explicitly confirm that you reviewed the evidence
                and homework.
              </p>
            </div>
            <form action={confirmTeacherReviewAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <label className="teacher-checkbox">
                <input
                  type="checkbox"
                  name="teacherConfirmed"
                  value="yes"
                  required
                  disabled={sessionState !== "ai_review_ready"}
                />
                I reviewed the class evidence and homework.
              </label>
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "ai_review_ready"}
              >
                Confirm teacher review
              </button>
            </form>
          </section>

          <section
            className="teacher-panel teacher-publish"
            aria-labelledby="publish-title"
            data-active={sessionState === "teacher_reviewed"}
          >
            <div>
              <p className="eyebrow">Step 7</p>
              <h2 id="publish-title">Publish</h2>
              <p>The trusted database gate allows this transition only after teacher review.</p>
            </div>
            <form action={publishSessionAction}>
              <SessionFields
                organizationSlug={organizationSlug}
                classId={classId}
                sessionId={session.id}
                expectedState={sessionState!}
              />
              <button
                className="button"
                type="submit"
                disabled={sessionState !== "teacher_reviewed"}
              >
                Publish class session
              </button>
            </form>
          </section>
        </>
      )}
    </main>
  );
}
