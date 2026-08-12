import type { ReactNode } from "react";

import "../../workspace/[organizationSlug]/academic/academic.css";

export default function AcademicBrowserFixtureLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return children;
}
