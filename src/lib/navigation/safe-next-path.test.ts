import { describe, expect, it } from "vitest";

import { safeNextPath } from "@/lib/navigation/safe-next-path";

describe("safe auth continuation path", () => {
  it("accepts an application-relative path", () => {
    expect(safeNextPath("/workspace?organization=7")).toBe("/workspace?organization=7");
  });

  it.each([null, undefined, "https://attacker.invalid", "//attacker.invalid/path"])(
    "rejects unsafe continuation %s",
    (value) => {
      expect(safeNextPath(value)).toBe("/workspace");
    },
  );
});
