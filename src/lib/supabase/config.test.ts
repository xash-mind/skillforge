import { describe, expect, it } from "vitest";

import { hasSupabasePublicConfig, requireSupabasePublicConfig } from "@/lib/supabase/config";

describe("Supabase public configuration", () => {
  it("reports an intentionally unconfigured development environment", () => {
    expect(hasSupabasePublicConfig({ NODE_ENV: "development" })).toBe(false);
  });

  it("returns only browser-safe connection values", () => {
    expect(
      requireSupabasePublicConfig({
        NODE_ENV: "production",
        NEXT_PUBLIC_SUPABASE_URL: "https://project-ref.supabase.co",
        NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: "sb_publishable_example",
      }),
    ).toEqual({
      url: "https://project-ref.supabase.co",
      publishableKey: "sb_publishable_example",
    });
  });

  it("fails clearly when the integration is unavailable", () => {
    expect(() => requireSupabasePublicConfig({ NODE_ENV: "test" })).toThrow(
      /Supabase is not configured/,
    );
  });
});
