"use client";

import { createBrowserClient } from "@supabase/ssr";

import { requireSupabasePublicConfig } from "@/lib/supabase/config";
import type { Database } from "@/types/database";

export function createBrowserSupabaseClient() {
  const config = requireSupabasePublicConfig();

  return createBrowserClient<Database>(config.url, config.publishableKey);
}
