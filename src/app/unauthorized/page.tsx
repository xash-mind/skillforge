import type { Metadata } from "next";

import { StatusPage } from "@/components/status-page";

export const metadata: Metadata = {
  title: "Sign in required",
};

export default function UnauthorizedPage() {
  return (
    <StatusPage
      eyebrow="Sign in required"
      title="Let’s get you back to your workspace."
      description="Your session may have ended. Sign in again to continue where you left off."
      tone="violet"
    />
  );
}
