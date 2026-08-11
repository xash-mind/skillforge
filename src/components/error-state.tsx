"use client";

import { BrandMark } from "@/components/brand-mark";

type ErrorStateProps = {
  reset: () => void;
  digest: string | undefined;
};

export function ErrorState({ reset, digest }: ErrorStateProps) {
  return (
    <main className="status-page status-page--violet">
      <header className="status-page__header">
        <BrandMark />
      </header>
      <section className="status-page__panel" aria-labelledby="error-title">
        <p className="eyebrow">A brief pause</p>
        <h1 id="error-title">This workspace did not load.</h1>
        <p>Your work is safe. Try the request again, or return in a moment.</p>
        {digest ? <p className="status-page__reference">Reference: {digest}</p> : null}
        <button className="button button--primary" type="button" onClick={reset}>
          Try again
        </button>
      </section>
    </main>
  );
}
