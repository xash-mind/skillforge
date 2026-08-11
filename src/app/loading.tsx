export default function Loading() {
  return (
    <main className="loading-page" aria-busy="true" aria-live="polite">
      <div className="loading-mark" aria-hidden="true">
        <span />
        <span />
        <span />
      </div>
      <p>Preparing your workspace…</p>
    </main>
  );
}
