import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";

type StatusPageProps = {
  eyebrow: string;
  title: string;
  description: string;
  tone?: "ink" | "violet";
};

export function StatusPage({ eyebrow, title, description, tone = "ink" }: StatusPageProps) {
  return (
    <main className={`status-page status-page--${tone}`}>
      <header className="status-page__header">
        <BrandMark />
      </header>
      <section className="status-page__panel" aria-labelledby="status-title">
        <p className="eyebrow">{eyebrow}</p>
        <h1 id="status-title">{title}</h1>
        <p>{description}</p>
        <Link className="button button--primary" href="/">
          Return to SkillForge
        </Link>
      </section>
    </main>
  );
}
