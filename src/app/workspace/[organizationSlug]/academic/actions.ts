"use server";

import type { Route } from "next";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { canManageAcademicBranch } from "@/modules/academic/domain/academic-access";
import { requireAcademicManagerContext } from "@/modules/academic/server/academic-manager-context";

const code = z
  .string()
  .trim()
  .min(2)
  .max(40)
  .transform((value) => value.toUpperCase())
  .pipe(z.string().regex(/^[A-Z0-9]+(?:-[A-Z0-9]+)*$/));
const id = z.coerce.number().int().positive();
const shortText = z.string().trim().min(2).max(180);
const optionalText = z.string().trim().max(2000).default("");
const date = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const time = z.string().regex(/^\d{2}:\d{2}$/);

const syllabusSchema = z.object({
  organizationSlug: z.string().trim().min(1),
  syllabusCode: code,
  syllabusTitle: shortText,
  syllabusDescription: optionalText,
  versionLabel: z.string().trim().min(1).max(80),
  objectiveCode: z
    .string()
    .trim()
    .min(1)
    .max(50)
    .transform((value) => value.toUpperCase()),
  objectiveTitle: z.string().trim().min(2).max(240),
  objectiveDescription: z.string().trim().max(4000).default(""),
});

const subjectSchema = z.object({
  organizationSlug: z.string().trim().min(1),
  syllabusId: id,
  syllabusVersionId: id,
  subjectCode: code,
  subjectName: z.string().trim().min(2).max(120),
});

const classSchema = z.object({
  organizationSlug: z.string().trim().min(1),
  branchId: id,
  subjectId: id,
  objectiveId: id,
  classCode: code,
  className: z.string().trim().min(2).max(140),
  academicYear: z.string().trim().min(4).max(24),
  weekday: z.coerce.number().int().min(1).max(7),
  startsAt: time,
  endsAt: time,
  room: z.string().trim().max(120).default(""),
  effectiveFrom: date,
  effectiveTo: z.string().trim().default(""),
});

const participantSchema = z.object({
  organizationSlug: z.string().trim().min(1),
  branchId: id,
  classId: id,
  membershipId: id,
});

function field(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === "string" ? value : "";
}

function formObject(formData: FormData, names: readonly string[]): Record<string, string> {
  return Object.fromEntries(names.map((name) => [name, field(formData, name)]));
}

function academicPath(organizationSlug: string, kind: "error" | "notice", message: string): Route {
  return `/workspace/${organizationSlug}/academic?${new URLSearchParams({ [kind]: message })}` as Route;
}

function fail(organizationSlug: string, error: unknown): never {
  let message = "The academic change could not be saved.";

  if (error instanceof z.ZodError) {
    message = "Check the academic form values and try again.";
  } else if (typeof error === "object" && error && "code" in error) {
    const codeValue = String(error.code);
    if (codeValue === "23505") message = "That academic code or assignment already exists.";
    if (["23503", "23514", "42501", "PGRST301"].includes(codeValue)) {
      message =
        "That change is outside the permitted organization, branch, role, or syllabus scope.";
    }
  }

  redirect(academicPath(organizationSlug, "error", message));
}

function parseOrFail<T>(organizationSlug: string, parser: () => T): T {
  try {
    return parser();
  } catch (error) {
    fail(organizationSlug, error);
  }
}

function succeed(organizationSlug: string, message: string): never {
  const path = `/workspace/${organizationSlug}/academic`;
  revalidatePath(path);
  redirect(academicPath(organizationSlug, "notice", message));
}

export async function createCustomSyllabusAction(formData: FormData) {
  const organizationSlug = field(formData, "organizationSlug");
  const input = parseOrFail(organizationSlug, () =>
    syllabusSchema.parse(
      formObject(formData, [
        "organizationSlug",
        "syllabusCode",
        "syllabusTitle",
        "syllabusDescription",
        "versionLabel",
        "objectiveCode",
        "objectiveTitle",
        "objectiveDescription",
      ]),
    ),
  );
  const context = await requireAcademicManagerContext(input.organizationSlug);

  if (!context.scope.canManageCurriculum) redirect("/forbidden");

  const { error } = await context.supabase.rpc("create_custom_syllabus_bundle", {
    organization_id_input: context.organization.id,
    syllabus_code_input: input.syllabusCode,
    syllabus_title_input: input.syllabusTitle,
    syllabus_description_input: input.syllabusDescription,
    version_label_input: input.versionLabel,
    objective_code_input: input.objectiveCode,
    objective_title_input: input.objectiveTitle,
    objective_description_input: input.objectiveDescription,
  });

  if (error) fail(organizationSlug, error);
  succeed(organizationSlug, "Custom syllabus published with its first version and objective.");
}

export async function createSubjectAction(formData: FormData) {
  const organizationSlug = field(formData, "organizationSlug");
  const input = parseOrFail(organizationSlug, () =>
    subjectSchema.parse(
      formObject(formData, [
        "organizationSlug",
        "syllabusId",
        "syllabusVersionId",
        "subjectCode",
        "subjectName",
      ]),
    ),
  );
  const context = await requireAcademicManagerContext(input.organizationSlug);

  if (!context.scope.canManageCurriculum) redirect("/forbidden");

  const { error } = await context.supabase.from("subjects").insert({
    organization_id: context.organization.id,
    syllabus_id: input.syllabusId,
    syllabus_version_id: input.syllabusVersionId,
    code: input.subjectCode,
    name: input.subjectName,
    created_by: context.userId,
  });

  if (error) fail(organizationSlug, error);
  succeed(organizationSlug, "Subject created and pinned to the selected syllabus version.");
}

export async function createClassAction(formData: FormData) {
  const organizationSlug = field(formData, "organizationSlug");
  const input = parseOrFail(organizationSlug, () =>
    classSchema.parse(
      formObject(formData, [
        "organizationSlug",
        "branchId",
        "subjectId",
        "objectiveId",
        "classCode",
        "className",
        "academicYear",
        "weekday",
        "startsAt",
        "endsAt",
        "room",
        "effectiveFrom",
        "effectiveTo",
      ]),
    ),
  );
  const context = await requireAcademicManagerContext(input.organizationSlug);

  if (!canManageAcademicBranch(context.scope, input.branchId)) redirect("/forbidden");

  const { error } = await context.supabase.rpc("create_class_bundle", {
    organization_id_input: context.organization.id,
    branch_id_input: input.branchId,
    subject_id_input: input.subjectId,
    objective_id_input: input.objectiveId,
    class_code_input: input.classCode,
    class_name_input: input.className,
    academic_year_input: input.academicYear,
    weekday_input: input.weekday,
    starts_at_input: input.startsAt,
    ends_at_input: input.endsAt,
    room_input: input.room,
    effective_from_input: input.effectiveFrom,
    ...(input.effectiveTo ? { effective_to_input: date.parse(input.effectiveTo) } : {}),
  });

  if (error) fail(organizationSlug, error);
  succeed(
    organizationSlug,
    "Class created with objective traceability and its first timetable entry.",
  );
}

async function managedClassContext(organizationSlug: string, branchId: number, classId: number) {
  const context = await requireAcademicManagerContext(organizationSlug);
  if (!canManageAcademicBranch(context.scope, branchId)) redirect("/forbidden");

  const { data: classRow, error } = await context.supabase
    .from("classes")
    .select("id")
    .eq("organization_id", context.organization.id)
    .eq("branch_id", branchId)
    .eq("id", classId)
    .maybeSingle();

  if (error) fail(organizationSlug, error);
  if (!classRow)
    fail(organizationSlug, Object.assign(new Error("Class outside branch."), { code: "42501" }));
  return context;
}

export async function assignTeacherAction(formData: FormData) {
  const organizationSlug = field(formData, "organizationSlug");
  const input = parseOrFail(organizationSlug, () =>
    participantSchema.parse(
      formObject(formData, ["organizationSlug", "branchId", "classId", "membershipId"]),
    ),
  );
  const context = await managedClassContext(input.organizationSlug, input.branchId, input.classId);
  const { error } = await context.supabase.from("class_teachers").insert({
    organization_id: context.organization.id,
    branch_id: input.branchId,
    class_id: input.classId,
    organization_membership_id: input.membershipId,
    created_by: context.userId,
  });

  if (error) fail(organizationSlug, error);
  succeed(organizationSlug, "Teacher assigned to the class.");
}

export async function enrollStudentAction(formData: FormData) {
  const organizationSlug = field(formData, "organizationSlug");
  const input = parseOrFail(organizationSlug, () =>
    participantSchema.parse(
      formObject(formData, ["organizationSlug", "branchId", "classId", "membershipId"]),
    ),
  );
  const context = await managedClassContext(input.organizationSlug, input.branchId, input.classId);
  const { error } = await context.supabase.from("class_enrollments").insert({
    organization_id: context.organization.id,
    branch_id: input.branchId,
    class_id: input.classId,
    organization_membership_id: input.membershipId,
    created_by: context.userId,
  });

  if (error) fail(organizationSlug, error);
  succeed(organizationSlug, "Student enrolled in the class.");
}
