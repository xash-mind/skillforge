import { describe, expect, it } from "vitest";

import { safeClassroomFilename, validateClassroomUpload } from "./upload-policy";

describe("classroom upload policy", () => {
  it("accepts representative transcript and resource files", () => {
    expect(validateClassroomUpload({ name: "lesson.txt", size: 1200, type: "text/plain" }).ok).toBe(
      true,
    );
    expect(
      validateClassroomUpload({ name: "worksheet.pdf", size: 2400, type: "application/pdf" }).ok,
    ).toBe(true);
  });

  it("rejects empty, oversized, and unsupported uploads with recovery messages", () => {
    expect(validateClassroomUpload({ name: "empty.txt", size: 0, type: "text/plain" })).toMatchObject({
      ok: false,
    });
    expect(
      validateClassroomUpload({ name: "huge.pdf", size: 11 * 1024 * 1024, type: "application/pdf" }),
    ).toMatchObject({ ok: false });
    expect(validateClassroomUpload({ name: "script.exe", size: 10, type: "application/x-msdownload" })).toMatchObject({
      ok: false,
    });
  });

  it("normalizes filenames before they enter a storage path", () => {
    expect(safeClassroomFilename(" ../Week 1 / notes?.pdf ")).toBe("Week-1-notes-.pdf");
  });
});
