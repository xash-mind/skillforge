import { StatusPage } from "@/components/status-page";

export default function NotFound() {
  return (
    <StatusPage
      eyebrow="404 · Page not found"
      title="That page is not on today’s lesson plan."
      description="The address may have changed, or you may have followed an old link."
    />
  );
}
