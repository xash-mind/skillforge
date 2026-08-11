import type { Metadata } from "next";

import { StatusPage } from "@/components/status-page";

export const metadata: Metadata = {
  title: "Access restricted",
};

export default function ForbiddenPage() {
  return (
    <StatusPage
      eyebrow="Access restricted"
      title="This workspace belongs to another role."
      description="Ask your organization administrator if you believe your access should be updated."
    />
  );
}
