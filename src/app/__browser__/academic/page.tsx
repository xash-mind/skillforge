import { notFound } from "next/navigation";

import { BrandMark } from "@/components/brand-mark";

export const dynamic = "force-dynamic";

export default function AcademicBrowserFixturePage() {
  if (process.env.SKILLFORGE_BROWSER_SMOKE !== "1") {
    notFound();
  }

  return (
    <main className="academic-page" data-browser-smoke="academic-admin">
      <header className="workspace-header">
        <BrandMark />
        <span className="workspace-list__status">Organization owner</span>
      </header>
      <section className="academic-hero" aria-labelledby="fixture-title">
        <p className="eyebrow">Academic operations · Northstar Learning</p>
        <h1 id="fixture-title">Build curriculum once, operate classes by branch.</h1>
        <p>Browser-only proxy fixture for the authenticated academic administration surface.</p>
        <div className="academic-metrics" aria-label="Academic configuration summary">
          <span><strong>2</strong> manageable branches</span>
          <span><strong>2</strong> subjects</span>
          <span><strong>2</strong> classes</span>
        </div>
      </section>
      <section className="academic-section" aria-labelledby="fixture-curriculum">
        <div className="academic-section__heading">
          <div><p className="eyebrow">Organization curriculum</p><h2 id="fixture-curriculum">Syllabuses and subjects</h2></div>
          <p>Organization owners can publish custom curriculum and pin subjects to versions.</p>
        </div>
        <form className="academic-card academic-form">
          <h3>Publish a custom syllabus</h3>
          <label>Code<input name="syllabusCode" defaultValue="MATH-10" /></label>
          <label>Title<input name="syllabusTitle" defaultValue="Grade 10 Mathematics" /></label>
          <label>First objective<input name="objectiveTitle" defaultValue="Solve linear equations" /></label>
          <button className="button" type="button">Publish syllabus</button>
        </form>
      </section>
      <section className="academic-section" aria-labelledby="fixture-classes">
        <div className="academic-section__heading">
          <div><p className="eyebrow">Branch operation</p><h2 id="fixture-classes">Classes and timetables</h2></div>
          <p>Only branches in the administrator&apos;s management scope are offered.</p>
        </div>
        <form className="academic-card academic-form academic-form--wide">
          <div className="academic-form__row">
            <label>Branch<select name="branch"><option>Main Campus</option><option>West Campus</option></select></label>
            <label>Subject<select name="subject"><option>Mathematics</option><option>Science</option></select></label>
            <label>Objective<select name="objective"><option>ALG.1 · Solve linear equations</option></select></label>
          </div>
          <div className="academic-form__row">
            <label>Starts<input type="time" name="startsAt" defaultValue="09:00" /></label>
            <label>Ends<input type="time" name="endsAt" defaultValue="10:00" /></label>
            <label>Effective from<input type="date" name="effectiveFrom" defaultValue="2026-06-01" /></label>
          </div>
          <button className="button" type="button">Create class and timetable</button>
        </form>
      </section>
    </main>
  );
}
