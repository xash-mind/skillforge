const maxClassroomUploadBytes = 10 * 1024 * 1024;

const allowedMimeTypes = new Set([
  "application/pdf",
  "audio/mpeg",
  "audio/mp4",
  "audio/wav",
  "image/jpeg",
  "image/png",
  "text/plain",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
]);

export type ClassroomUploadKind = "transcript" | "resource";

export type ClassroomUploadValidation =
  | { ok: true; safeFilename: string }
  | { ok: false; message: string };

export function safeClassroomFilename(filename: string): string {
  const normalized = filename
    .normalize("NFKD")
    .replace(/[^a-zA-Z0-9._-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^[-.]+|[-.]+$/g, "")
    .slice(0, 100);

  return normalized || "upload";
}

export function validateClassroomUpload(file: Pick<File, "name" | "size" | "type">) {
  if (file.size <= 0) {
    return { ok: false, message: "Choose a non-empty file and try again." } as const;
  }

  if (file.size > maxClassroomUploadBytes) {
    return {
      ok: false,
      message: "The file is larger than the 10 MB classroom upload limit.",
    } as const;
  }

  if (!allowedMimeTypes.has(file.type)) {
    return {
      ok: false,
      message: "Use PDF, text, Word, PowerPoint, image, MP3, MP4 audio, or WAV for this class evidence.",
    } as const;
  }

  return { ok: true, safeFilename: safeClassroomFilename(file.name) } as const;
}
