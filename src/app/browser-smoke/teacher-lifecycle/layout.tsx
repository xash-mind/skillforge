import type { ReactNode } from "react";

import "../../workspace/[organizationSlug]/teacher/teacher.css";

export default function TeacherLifecycleBrowserLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return children;
}
