import { randomUUID } from "node:crypto";

import { NextResponse } from "next/server";
import { z } from "zod";

import {
  type ClassroomUploadKind,
  validateClassroomUpload,
} from "@/modules/classroom/domain/upload-policy";
import { requireTeacherClassContext } from "@/modules/classroom/server/teacher-class-context";

const id = z.coerce.number().int().positive();
const kindSchema = z.enum(["transcript", "resource"]);

type RouteContext = { params: Promise<{ organizationSlug: string; classId: string }> };

function destination(
  request: Request,
  organizationSlug: string,
  classId: number,
  kind: "error" | "notice",
  message: string,
) {
  const url = new URL(`/workspace/${organizationSlug}/teacher/classes/${classId}`, request.url);
  url.searchParams.set(kind, message);
  return NextResponse.redirect(url, { status: 303 });
}

function uploadLabel(kind: ClassroomUploadKind) {
  return kind === "transcript" ? "Transcript" : "Class resource";
}

export async function POST(request: Request, routeContext: RouteContext) {
  const { organizationSlug, classId: classIdRaw } = await routeContext.params;
  const classId = id.parse(classIdRaw);
  const formData = await request.formData();
  const sessionId = id.parse(formData.get("sessionId"));
  const kind = kindSchema.parse(formData.get("kind")) as ClassroomUploadKind;
  const retryUploadIdRaw = formData.get("retryUploadId");
  const retryUploadId = retryUploadIdRaw ? id.parse(retryUploadIdRaw) : null;
  const recoverUploadIdRaw = formData.get("recoverUploadId");
  const recoverUploadId = recoverUploadIdRaw ? id.parse(recoverUploadIdRaw) : null;

  const context = await requireTeacherClassContext(organizationSlug, classId);
  const { data: session, error: sessionError } = await context.supabase
    .from("lesson_sessions")
    .select("id, state")
    .eq("id", sessionId)
    .eq("class_id", classId)
    .maybeSingle();

  if (sessionError || !session || session.state !== "attendance_marked") {
    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      "Uploads are only available after attendance and before evidence confirmation.",
    );
  }

  if (recoverUploadId) {
    const { data: pendingUpload, error: pendingUploadError } = await context.supabase
      .from("lesson_uploads")
      .select("id, kind, status")
      .eq("id", recoverUploadId)
      .eq("lesson_session_id", sessionId)
      .eq("class_id", classId)
      .maybeSingle();

    if (
      pendingUploadError ||
      !pendingUpload ||
      pendingUpload.status !== "pending" ||
      pendingUpload.kind !== kind
    ) {
      return destination(
        request,
        organizationSlug,
        classId,
        "error",
        "That pending upload is no longer recoverable. Reload the class and review its current state.",
      );
    }

    const { data: finalized, error: finalizeError } = await context.supabase
      .from("lesson_uploads")
      .update({
        status: "uploaded",
        failure_message: null,
        uploaded_at: new Date().toISOString(),
      })
      .eq("id", pendingUpload.id)
      .eq("status", "pending")
      .select("id")
      .single();

    if (!finalizeError && finalized) {
      return destination(
        request,
        organizationSlug,
        classId,
        "notice",
        `${uploadLabel(kind)} recovered from its already stored file.`,
      );
    }

    if (finalizeError?.message.includes("matching storage object")) {
      const { error: markFailedError } = await context.supabase
        .from("lesson_uploads")
        .update({
          status: "failed",
          failure_message:
            "The interrupted attempt has no stored file. Choose the file again and retry.",
          uploaded_at: null,
        })
        .eq("id", pendingUpload.id)
        .eq("status", "pending");

      return destination(
        request,
        organizationSlug,
        classId,
        "error",
        markFailedError
          ? "The interrupted upload is still pending. Reload and retry recovery before continuing."
          : "The interrupted upload had no stored file. It is now ready for a normal retry.",
      );
    }

    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      "The stored upload could not be finalized yet. Reload and retry recovery before continuing.",
    );
  }

  const fileValue = formData.get("file");
  if (!(fileValue instanceof File)) {
    return destination(request, organizationSlug, classId, "error", "Choose a file and try again.");
  }

  const validation = validateClassroomUpload(fileValue);
  if (!validation.ok) {
    return destination(request, organizationSlug, classId, "error", validation.message);
  }

  const { data: existingPending, error: pendingLookupError } = await context.supabase
    .from("lesson_uploads")
    .select("id")
    .eq("lesson_session_id", sessionId)
    .eq("class_id", classId)
    .eq("kind", kind)
    .eq("status", "pending")
    .limit(1)
    .maybeSingle();

  if (pendingLookupError) {
    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      "The current upload state could not be checked safely. Reload the class and try again.",
    );
  }
  if (existingPending) {
    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      `Recover the pending ${kind} attempt before uploading another file of that kind.`,
    );
  }

  const storagePath = `${context.organization.id}/${context.classRow.branch_id}/${classId}/${sessionId}/${randomUUID()}-${validation.safeFilename}`;
  let uploadId: number;

  if (retryUploadId) {
    const { data: failedUpload, error: failedUploadError } = await context.supabase
      .from("lesson_uploads")
      .select("id, retry_count, kind, status")
      .eq("id", retryUploadId)
      .eq("lesson_session_id", sessionId)
      .eq("class_id", classId)
      .maybeSingle();

    if (
      failedUploadError ||
      !failedUpload ||
      failedUpload.status !== "failed" ||
      failedUpload.kind !== kind
    ) {
      return destination(
        request,
        organizationSlug,
        classId,
        "error",
        "That failed upload is no longer retryable. Reload the class and try again.",
      );
    }

    const { data: retried, error: retryError } = await context.supabase
      .from("lesson_uploads")
      .update({
        storage_path: storagePath,
        original_name: validation.safeFilename,
        mime_type: fileValue.type,
        size_bytes: fileValue.size,
        status: "pending",
        failure_message: null,
        uploaded_at: null,
        retry_count: failedUpload.retry_count + 1,
      })
      .eq("id", failedUpload.id)
      .select("id")
      .single();

    if (retryError || !retried) {
      return destination(
        request,
        organizationSlug,
        classId,
        "error",
        "The upload retry could not be prepared. Reload the class and try again.",
      );
    }
    uploadId = retried.id;
  } else {
    const { data: created, error: createError } = await context.supabase
      .from("lesson_uploads")
      .insert({
        organization_id: context.organization.id,
        branch_id: context.classRow.branch_id,
        class_id: classId,
        lesson_session_id: sessionId,
        kind,
        storage_path: storagePath,
        original_name: validation.safeFilename,
        mime_type: fileValue.type,
        size_bytes: fileValue.size,
        status: "pending",
        created_by: context.userId,
      })
      .select("id")
      .single();

    if (createError || !created) {
      return destination(
        request,
        organizationSlug,
        classId,
        "error",
        "The upload could not be prepared safely. Reload the class and try again.",
      );
    }
    uploadId = created.id;
  }

  const { error: uploadError } = await context.supabase.storage
    .from("classroom-evidence")
    .upload(storagePath, fileValue, { contentType: fileValue.type, upsert: false });

  if (uploadError) {
    await context.supabase
      .from("lesson_uploads")
      .update({
        status: "failed",
        failure_message: "Upload failed. Choose the file again and retry.",
        uploaded_at: null,
      })
      .eq("id", uploadId)
      .eq("status", "pending");

    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      "Upload failed. The attempt is preserved so you can recover it or choose the file again and retry.",
    );
  }

  const { data: finalized, error: finalizeError } = await context.supabase
    .from("lesson_uploads")
    .update({
      status: "uploaded",
      failure_message: null,
      uploaded_at: new Date().toISOString(),
    })
    .eq("id", uploadId)
    .eq("status", "pending")
    .select("id")
    .single();

  if (finalizeError || !finalized) {
    return destination(
      request,
      organizationSlug,
      classId,
      "error",
      "The file reached storage but its class record could not be finalized. Reload and use Recover stored upload; do not upload a duplicate file.",
    );
  }

  return destination(
    request,
    organizationSlug,
    classId,
    "notice",
    `${uploadLabel(kind)} uploaded successfully.`,
  );
}
