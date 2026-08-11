import type { Metadata, Viewport } from "next";

import "@/app/globals.css";
import { publicEnvironment } from "@/config/env";

export const metadata: Metadata = {
  title: {
    default: "SkillForge",
    template: "%s · SkillForge",
  },
  description:
    "The AI-powered Learning Operating System for tuition centres and coaching institutes.",
};

export const viewport: Viewport = {
  colorScheme: "light",
  themeColor: "#f7f4ed",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  // Importing validated configuration here makes malformed public deployment settings fail fast.
  void publicEnvironment;

  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
