import { publicEnvironment, type PublicEnvironment } from "@/config/env";

export type SupabasePublicConfig = Readonly<{
  url: string;
  publishableKey: string;
}>;

export function hasSupabasePublicConfig(environment: PublicEnvironment = publicEnvironment) {
  return Boolean(
    environment.NEXT_PUBLIC_SUPABASE_URL && environment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  );
}

export function requireSupabasePublicConfig(
  environment: PublicEnvironment = publicEnvironment,
): SupabasePublicConfig {
  if (!environment.NEXT_PUBLIC_SUPABASE_URL || !environment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY) {
    throw new Error(
      "Supabase is not configured. Set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY together.",
    );
  }

  return Object.freeze({
    url: environment.NEXT_PUBLIC_SUPABASE_URL,
    publishableKey: environment.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  });
}
