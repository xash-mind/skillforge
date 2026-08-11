import type { Metadata } from "next";
import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";
import { canManageAcademicBranch, weekdayLabel } from "@/modules/academic/domain/academic-access";
import { requireAcademicManagerContext } from "@/modules/academic/server/academic-manager-context";

import {
  assignTeacherAction,
  createClassAction,
  createCustomSyllabusAction,
  createSubjectAction,
  enrollStudentAction,
} from "./actions";

export const metadata: Metadata = { title: "Academic setup" };
export const dynamic = "force-dynamic";

type PageProps = {
  params: Promise<{ organizationSlug: string }>;
  searchParams: Promise<{ error?: string | string[]; notice?: string | string[] }>;
};

function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default async function AcademicSetupPage({ params, searchParams }: PageProps) {
  const { organizationSlug } = await params;
  const query = await searchParams;
  const context = await requireAcademicManagerContext(organizationSlug);
  const organizationId = context.organization.id;

  const [
    branchesResult,
    syllabusesResult,
    versionsResult,
    objectivesResult,
    subjectsResult,
    classesResult,
    classObjectivesResult,
    timetableResult,
    roleAssignmentsResult,
    membershipsResult,
  ] = await Promise.all([
    context.supabase
      .from("branches")
      .select("id, name, code")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .order("name"),
    context.supabase
      .from("syllabuses")
      .select("id, organization_id, code, title, scope, status")
      .eq("status", "published")
      .order("title"),
    context.supabase
      .from("syllabus_versions")
      .select("id, syllabus_id, version_label, status")
      .eq("status", "published")
      .order("syllabus_id"),
    context.supabase
      .from("syllabus_objectives")
      .select("id, syllabus_id, syllabus_version_id, code, title, sequence_number")
      .order("sequence_number"),
    context.supabase
      .from("subjects")
      .select("id, code, name, syllabus_id, syllabus_version_id, status")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .order("name"),
    context.supabase
      .from("classes")
      .select("id, branch_id, subject_id, code, name, academic_year, status")
      .eq("organization_id", organizationId)
      .in("status", ["planned", "active"])
      .order("name"),
    context.supabase
      .from("class_objectives")
      .select("class_id, objective_id")
      .eq("organization_id", organizationId),
    context.supabase
      .from("timetable_entries")
      .select("id, class_id, branch_id, weekday, starts_at, ends_at, room, effective_from, effective_to")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .order("weekday"),
    context.supabase
      .from("role_assignments")
      .select("organization_membership_id, branch_id, role")
      .eq("organization_id", organizationId)
      .eq("status", "active")
      .in("role", ["teacher", "student"]),
    context.supabase
      .from("organization_memberships")
      .select("id, user_id")
      .eq("organization_id", organizationId)
      .eq("status", "active"),
  ]);

  const results = [
    branchesResult,
    syllabusesResult,
    versionsResult,
    objectivesResult,
    subjectsResult,
    classesResult,
    classObjectivesResult,
    timetableResult,
    roleAssignmentsResult,
    membershipsResult,
  ];

  if (results.some((result) => result.error)) {
    throw new Error("The academic workspace could not be loaded safely.");
  }

  const branches = branchesResult.data;
  const syllabuses = syllabusesResult.data;
  const versions = versionsResult.data;
  const objectives = objectivesResult.data;
  const subjects = subjectsResult.data;
  const classes = classesResult.data;
  const classObjectives = classObjectivesResult.data;
  const timetableEntries = timetableResult.data;
  const roleAssignments = roleAssignmentsResult.data;
  const memberships = membershipsResult.data;
  const manageableBranches = branches.filter((branch) =>
    canManageAcademicBranch(context.scope, branch.id),
  );

  const profileIds = memberships.map((membership) => membership.user_id);
  const profilesResult = profileIds.length
    ? await context.supabase.from("profiles").select("id, display_name").in("id", profileIds)
    : { data: [], error: null };

  if (profilesResult.error) {
    throw new Error("Academic participant names could not be loaded.");
  }

  const profileNameById = new Map(profilesResult.data.map((profile) => [profile.id, profile.display_name]));
  const membershipById = new Map(memberships.map((membership) => [membership.id, membership]));
  const branchById = new Map(branches.map((branch) => [branch.id, branch]));
  const subjectById = new Map(subjects.map((subject) => [subject.id, subject]));
  const objectiveById = new Map(objectives.map((objective) => [objective.id, objective]));
  const syllabusById = new Map(syllabuses.map((syllabus) => [syllabus.id, syllabus]));
  const classObjectiveByClassId = new Map(
    classObjectives.map((classObjective) => [classObjective.class_id, classObjective]),
  );
  const timetableByClassId = new Map<number, typeof timetableEntries>();

  for (const entry of timetableEntries) {
    const entries = timetableByClassId.get(entry.class_id) ?? [];
    entries.push(entry);
    timetableByClassId.set(entry.class_id, entries);
  }

  const participantOptions = roleAssignments.flatMap((assignment) => {
    if (assignment.branch_id === null) return [];
    const membership = membershipById.get(assignment.organization_membership_id);
    if (!membership) return [];
    return [
      {
        branchId: assignment.branch_id,
        membershipId: assignment.organization_membership_id,
        role: assignment.role,
        name: profileNameById.get(membership.user_id) ?? `Member ${assignment.organization_membership_id}`,
      },
    ];
  });

  const notice = first(query.notice);
  const error = first(query.error);

  return (
    <main className="academic-page">
      <header className="workspace-header">
        <BrandMark />
        <Link className="button button--quiet" href="/workspace">
          Back to workspaces
        </Link>
      </header>

      <section className="academic-hero" aria-labelledby="academic-title">
        <p className="eyebrow">Academic operations · {context.organization.name}</p>
        <h1 id="academic-title">Build curriculum once, operate classes by branch.</h1>
        <p>
          Subjects stay pinned to a published syllabus version. Every class is branch-scoped and keeps
          an explicit objective and timetable lineage.
        </p>
        <div className="academic-metrics" aria-label="Academic configuration summary">
          <span><strong>{manageableBranches.length}</strong> manageable branches</span>
          <span><strong>{subjects.length}</strong> subjects</span>
          <span><strong>{classes.length}</strong> classes</span>
          <span><strong>{objectives.length}</strong> visible objectives</span>
        </div>
      </section>

      {notice ? <p className="academic-message academic-message--success" role="status">{notice}</p> : null}
      {error ? <p className="academic-message academic-message--error" role="alert">{error}</p> : null}

      {context.scope.canManageCurriculum ? (
        <section className="academic-section" aria-labelledby="curriculum-title">
          <div className="academic-section__heading">
            <div>
              <p className="eyebrow">Organization curriculum</p>
              <h2 id="curriculum-title">Syllabuses and subjects</h2>
            </div>
            <p>Organization owners can publish custom curriculum or reuse a visible library syllabus.</p>
          </div>

          <div className="academic-grid academic-grid--forms">
            <form className="academic-card academic-form" action={createCustomSyllabusAction}>
              <input type="hidden" name="organizationSlug" value={organizationSlug} />
              <h3>Publish a custom syllabus</h3>
              <label>Code<input name="syllabusCode" placeholder="MATH-10" required /></label>
              <label>Title<input name="syllabusTitle" placeholder="Grade 10 Mathematics" required /></label>
              <label>Description<textarea name="syllabusDescription" rows={2} /></label>
              <label>Version<input name="versionLabel" placeholder="2026-27" required /></label>
              <label>First objective code<input name="objectiveCode" placeholder="ALG.1" required /></label>
              <label>First objective<input name="objectiveTitle" placeholder="Solve linear equations" required /></label>
              <label>Objective context<textarea name="objectiveDescription" rows={2} /></label>
              <button className="button" type="submit">Publish syllabus</button>
            </form>

            <form className="academic-card academic-form" action={createSubjectAction}>
              <input type="hidden" name="organizationSlug" value={organizationSlug} />
              <h3>Create a subject</h3>
              <label>Code<input name="subjectCode" placeholder="MATH" required /></label>
              <label>Name<input name="subjectName" placeholder="Mathematics" required /></label>
              <label>
                Published syllabus version
                <select name="syllabusVersionId" required defaultValue="">
                  <option value="" disabled>Select a version</option>
                  {versions.map((version) => {
                    const syllabus = syllabusById.get(version.syllabus_id);
                    return (
                      <option key={version.id} value={version.id}>
                        {syllabus?.title ?? `Syllabus ${version.syllabus_id}`} · {version.version_label}
                      </option>
                    );
                  })}
                </select>
              </label>
              <label>
                Syllabus
                <select name="syllabusId" required defaultValue="">
                  <option value="" disabled>Select the matching syllabus</option>
                  {syllabuses.map((syllabus) => (
                    <option key={syllabus.id} value={syllabus.id}>
                      {syllabus.code} · {syllabus.title}
                    </option>
                  ))}
                </select>
              </label>
              <p className="academic-form__hint">The database rejects a version that does not belong to the selected syllabus.</p>
              <button className="button" type="submit">Create subject</button>
            </form>
          </div>
        </section>
      ) : null}

      <section className="academic-section" aria-labelledby="classes-title">
        <div className="academic-section__heading">
          <div>
            <p className="eyebrow">Branch operation</p>
            <h2 id="classes-title">Classes and timetables</h2>
          </div>
          <p>Only branches in your management scope are available for creation and assignment.</p>
        </div>

        {manageableBranches.length && subjects.length && objectives.length ? (
          <form className="academic-card academic-form academic-form--wide" action={createClassAction}>
            <input type="hidden" name="organizationSlug" value={organizationSlug} />
            <div className="academic-form__row">
              <label>Branch<select name="branchId" required>{manageableBranches.map((branch) => <option key={branch.id} value={branch.id}>{branch.name} · {branch.code}</option>)}</select></label>
              <label>Subject<select name="subjectId" required>{subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name} · {subject.code}</option>)}</select></label>
              <label>Objective<select name="objectiveId" required>{objectives.map((objective) => <option key={objective.id} value={objective.id}>{objective.code} · {objective.title}</option>)}</select></label>
            </div>
            <div className="academic-form__row">
              <label>Class code<input name="classCode" placeholder="MATH-10-A" required /></label>
              <label>Class name<input name="className" placeholder="Grade 10 Mathematics A" required /></label>
              <label>Academic year<input name="academicYear" placeholder="2026-27" required /></label>
            </div>
            <div className="academic-form__row">
              <label>Weekday<select name="weekday" defaultValue="1">{[1,2,3,4,5,6,7].map((day) => <option key={day} value={day}>{weekdayLabel(day)}</option>)}</select></label>
              <label>Starts<input type="time" name="startsAt" required /></label>
              <label>Ends<input type="time" name="endsAt" required /></label>
              <label>Room<input name="room" placeholder="Room 3" /></label>
            </div>
            <div className="academic-form__row">
              <label>Effective from<input type="date" name="effectiveFrom" required /></label>
              <label>Effective to (optional)<input type="date" name="effectiveTo" /></label>
            </div>
            <p className="academic-form__hint">The selected objective must belong to the subject&apos;s pinned syllabus version; mismatches are rejected atomically.</p>
            <button className="button" type="submit">Create class and timetable</button>
          </form>
        ) : (
          <p className="academic-empty">A manageable branch, subject, and published objective are required before a class can be created.</p>
        )}

        <div className="academic-grid" aria-label="Configured classes">
          {classes.map((classRow) => {
            const branch = branchById.get(classRow.branch_id);
            const subject = subjectById.get(classRow.subject_id);
            const objectiveLink = classObjectiveByClassId.get(classRow.id);
            const objective = objectiveLink ? objectiveById.get(objectiveLink.objective_id) : undefined;
            const entries = timetableByClassId.get(classRow.id) ?? [];
            const teacherOptions = participantOptions.filter((option) => option.branchId === classRow.branch_id && option.role === "teacher");
            const studentOptions = participantOptions.filter((option) => option.branchId === classRow.branch_id && option.role === "student");

            return (
              <article className="academic-card" key={classRow.id}>
                <span className="workspace-list__status">{branch?.name ?? `Branch ${classRow.branch_id}`}</span>
                <h3>{classRow.name}</h3>
                <p>{subject?.name ?? `Subject ${classRow.subject_id}`} · {classRow.academic_year}</p>
                <p className="academic-lineage">Objective: {objective ? `${objective.code} · ${objective.title}` : "Lineage unavailable"}</p>
                <ul className="academic-schedule">
                  {entries.map((entry) => (
                    <li key={entry.id}>
                      {weekdayLabel(entry.weekday)} · {entry.starts_at.slice(0, 5)}–{entry.ends_at.slice(0, 5)}
                      {entry.room ? ` · ${entry.room}` : ""}
                    </li>
                  ))}
                </ul>

                {canManageAcademicBranch(context.scope, classRow.branch_id) ? (
                  <div className="academic-assignments">
                    <form action={assignTeacherAction}>
                      <input type="hidden" name="organizationSlug" value={organizationSlug} />
                      <input type="hidden" name="branchId" value={classRow.branch_id} />
                      <input type="hidden" name="classId" value={classRow.id} />
                      <label>
                        Teacher
                        <select name="membershipId" required defaultValue="">
                          <option value="" disabled>Select teacher</option>
                          {teacherOptions.map((option) => <option key={option.membershipId} value={option.membershipId}>{option.name}</option>)}
                        </select>
                      </label>
                      <button className="button button--quiet" type="submit" disabled={!teacherOptions.length}>Assign</button>
                    </form>
                    <form action={enrollStudentAction}>
                      <input type="hidden" name="organizationSlug" value={organizationSlug} />
                      <input type="hidden" name="branchId" value={classRow.branch_id} />
                      <input type="hidden" name="classId" value={classRow.id} />
                      <label>
                        Student
                        <select name="membershipId" required defaultValue="">
                          <option value="" disabled>Select student</option>
                          {studentOptions.map((option) => <option key={option.membershipId} value={option.membershipId}>{option.name}</option>)}
                        </select>
                      </label>
                      <button className="button button--quiet" type="submit" disabled={!studentOptions.length}>Enroll</button>
                    </form>
                  </div>
                ) : null}
              </article>
            );
          })}
        </div>
      </section>
    </main>
  );
}
