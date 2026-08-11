import { BrandMark } from "@/components/brand-mark";
import { moduleCatalog } from "@/modules/catalog";

const classLifecycle = [
  { step: "01", label: "Start class", detail: "Open today’s guided session" },
  { step: "02", label: "Mark attendance", detail: "Capture presence in a few taps" },
  { step: "03", label: "Add evidence", detail: "Upload transcript and resources" },
  { step: "04", label: "Assign homework", detail: "Connect work to objectives" },
  { step: "05", label: "Review AI", detail: "Accept, edit, or reject suggestions" },
  { step: "06", label: "Publish class", detail: "Share teacher-approved progress" },
] as const;

const evidenceTypes = [
  "Lesson transcripts",
  "Student notes",
  "Assignments",
  "Worksheets",
  "Homework",
  "Quizzes & exams",
  "Attendance",
  "Teacher observations",
] as const;

export default function Home() {
  return (
    <main>
      <header className="site-header">
        <BrandMark />
        <span className="site-header__badge">Foundation preview</span>
      </header>

      <section className="hero" aria-labelledby="hero-title">
        <div className="hero__copy">
          <p className="eyebrow">Learning, made visible</p>
          <h1 id="hero-title">Every class becomes a clear next step.</h1>
          <p className="hero__lead">
            SkillForge connects what was taught, what each student understood, and what a teacher
            decides should happen next.
          </p>
          <div className="hero__principle">
            <span className="hero__principle-icon" aria-hidden="true">
              ✓
            </span>
            <p>
              <strong>AI assists. Teachers decide.</strong>
              <span>Nothing academic is published without teacher approval.</span>
            </p>
          </div>
        </div>

        <aside className="next-card" aria-label="Teacher workflow preview">
          <div className="next-card__topline">
            <span>Monday · Grade 9 Physics</span>
            <span className="live-dot">Next</span>
          </div>
          <div className="next-card__time">4:00 PM</div>
          <h2>Motion &amp; acceleration</h2>
          <p>24 students · Green Park branch</p>
          <button type="button" disabled aria-describedby="preview-note">
            Start class <span aria-hidden="true">→</span>
          </button>
          <p id="preview-note" className="next-card__note">
            Interactive workflows arrive in the next milestone.
          </p>
        </aside>
      </section>

      <section className="workflow-section" aria-labelledby="workflow-title">
        <div className="section-heading">
          <p className="eyebrow">One guided rhythm</p>
          <h2 id="workflow-title">The complete class lifecycle</h2>
          <p>Less menu hunting. One calm workflow from arrival to parent-ready update.</p>
        </div>
        <ol className="lifecycle-list">
          {classLifecycle.map((item) => (
            <li key={item.step}>
              <span className="lifecycle-list__step">{item.step}</span>
              <span className="lifecycle-list__copy">
                <strong>{item.label}</strong>
                <small>{item.detail}</small>
              </span>
              <span className="lifecycle-list__arrow" aria-hidden="true">
                →
              </span>
            </li>
          ))}
        </ol>
      </section>

      <section className="evidence-section" aria-labelledby="evidence-title">
        <div className="evidence-section__copy">
          <p className="eyebrow">Beyond isolated grades</p>
          <h2 id="evidence-title">A living picture of how each student learns.</h2>
          <p>
            Every lesson adds structured evidence to a continuously evolving Learning Graph—so
            progress has context, gaps have provenance, and support can be timely.
          </p>
          <ul className="evidence-tags" aria-label="Learning evidence types">
            {evidenceTypes.map((type) => (
              <li key={type}>{type}</li>
            ))}
          </ul>
        </div>
        <div className="learning-map" aria-label="Illustration of connected learning evidence">
          <div className="learning-map__orbit learning-map__orbit--one" aria-hidden="true" />
          <div className="learning-map__orbit learning-map__orbit--two" aria-hidden="true" />
          <div className="learning-map__node learning-map__node--centre">
            <span>Learning</span>
            <strong>Graph</strong>
          </div>
          <div className="learning-map__node learning-map__node--top">Notes</div>
          <div className="learning-map__node learning-map__node--right">Objectives</div>
          <div className="learning-map__node learning-map__node--bottom">Evidence</div>
          <div className="learning-map__node learning-map__node--left">Lessons</div>
        </div>
      </section>

      <section className="architecture-strip" aria-labelledby="architecture-title">
        <div>
          <p className="eyebrow">Built to grow safely</p>
          <h2 id="architecture-title">A modular foundation for the whole institution.</h2>
        </div>
        <p>
          {moduleCatalog.length} independent domain boundaries keep identity, teaching, evidence,
          intelligence, governance, and operations extensible as SkillForge grows.
        </p>
      </section>

      <footer className="site-footer">
        <BrandMark />
        <p>AI-powered learning operations, with teachers in control.</p>
      </footer>
    </main>
  );
}
