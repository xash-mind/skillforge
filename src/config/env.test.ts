import { describe, expect, it } from "vitest";

import { parsePublicEnvironment } from "@/config/env";

describe("public environment", () => {
  it("allows an unconfigured local scaffold", () => {
    expect(parsePublicEnvironment({ NODE_ENV: "test" })).toEqual({ NODE_ENV: "test" });
  });

  it("accepts a complete Supabase public configuration", () => {
    expect(
      parsePublicEnvironment({
        NODE_ENV: "production",
        NEXT_PUBLIC_SUPABASE_URL: "https://project-ref.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
      }),
    ).toMatchObject({
      NEXT_PUBLIC_SUPABASE_URL: "https://project-ref.supabase.co",
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
    });
  });

  it("rejects a partial Supabase public configuration", () => {
    expect(() =>
      parsePublicEnvironment({
        NODE_ENV: "production",
        NEXT_PUBLIC_SUPABASE_URL: "https://project-ref.supabase.co",
      }),
    ).toThrow(/must be configured together/);
  });

  it("normalizes empty optional values", () => {
    expect(
      parsePublicEnvironment({
        NODE_ENV: "development",
        NEXT_PUBLIC_RELEASE_SHA: "  ",
      }),
    ).toEqual({ NODE_ENV: "development" });
  });
});
