import { z } from "zod";

const optionalTrimmedString = z.preprocess(
  (value) => (typeof value === "string" && value.trim() === "" ? undefined : value),
  z.string().trim().min(1).optional(),
);

const publicEnvironmentSchema = z
  .object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    VERCEL_ENV: z.enum(["development", "preview", "production"]).optional(),
    NEXT_PUBLIC_SUPABASE_URL: z.preprocess(
      (value) => (typeof value === "string" && value.trim() === "" ? undefined : value),
      z.url().optional(),
    ),
    NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: optionalTrimmedString,
    NEXT_PUBLIC_RELEASE_SHA: optionalTrimmedString,
  })
  .superRefine((value, context) => {
    const hasUrl = value.NEXT_PUBLIC_SUPABASE_URL !== undefined;
    const hasKey = value.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY !== undefined;

    if (hasUrl !== hasKey) {
      context.addIssue({
        code: "custom",
        message:
          "NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY must be configured together.",
        path: hasUrl ? ["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"] : ["NEXT_PUBLIC_SUPABASE_URL"],
      });
    }
  });

export type PublicEnvironment = z.infer<typeof publicEnvironmentSchema>;

export function parsePublicEnvironment(
  source: Record<string, string | undefined>,
): PublicEnvironment {
  return publicEnvironmentSchema.parse(source);
}

export const publicEnvironment = parsePublicEnvironment({
  NODE_ENV: process.env.NODE_ENV,
  VERCEL_ENV: process.env.VERCEL_ENV,
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_RELEASE_SHA: process.env.NEXT_PUBLIC_RELEASE_SHA,
});
