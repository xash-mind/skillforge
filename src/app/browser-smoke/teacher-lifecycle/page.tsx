import { notFound } from "next/navigation";

export const dynamic = "force-dynamic";

export default function TeacherLifecycleBrowserFixturePage() {
  if (process.env.SKILLFORGE_BROWSER_SMOKE !== "1") notFound();

  return (
    <main className="teacher-page teacher-session-page" data-browser-smoke="teacher-lifecycle">
      <section className="teacher-hero" aria-labelledby="fixture-title">
        <p className="eyebrow">Teacher workflow · Northstar Learning</p>
        <h1 id="fixture-title">Grade 10 Mathematics</h1>
        <p>Mobile proxy fixture for the complete guided class lifecycle and keyboard order.</p>
      </section>

      <nav className="teacher-progress" aria-label="Class lifecycle progress">
        <ol>
          <li data-complete="true">started</li>
          <li data-complete="true">attendance marked</li>
          <li aria-current="step">evidence uploaded</li>
          <li>homework assigned</li>
          <li>ai review ready</li>
          <li>teacher reviewed</li>
          <li>published</li>
        </ol>
      </nav>

      <aside className="teacher-recovery" aria-live="polite">
        <strong>Recovery is explicit</strong>
        <span>
          Failed uploads remain visible. Choose the file again and retry without losing the session.
        </span>
      </aside>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-start">
        <div>
          <p className="eyebrow">Step 1</p>
          <h2 id="fixture-start">Start Class</h2>
        </div>
        <form>
          <label>
            Session title
            <input data-keyboard-order="title" defaultValue="Linear equations" />
          </label>
          <button className="button" data-keyboard-order="start" type="button">
            Start Class
          </button>
        </form>
      </section>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-attendance">
        <div>
          <p className="eyebrow">Step 2</p>
          <h2 id="fixture-attendance">Attendance</h2>
        </div>
        <fieldset>
          <legend>Student attendance</legend>
          <label>
            Arun
            <select data-keyboard-order="attendance" defaultValue="present">
              <option value="present">Present</option>
              <option value="absent">Absent</option>
            </select>
          </label>
        </fieldset>
      </section>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-evidence">
        <div>
          <p className="eyebrow">Step 3</p>
          <h2 id="fixture-evidence">Transcript & resources</h2>
          <p>Both files are required before continuing.</p>
        </div>
        <div className="teacher-upload-grid">
          <label>
            Transcript file
            <input data-keyboard-order="transcript" type="file" />
          </label>
          <label>
            Class resource
            <input data-keyboard-order="resource" type="file" />
          </label>
        </div>
        <ul className="teacher-upload-list">
          <li data-status="failed">
            <div>
              <strong>resource: equations.pdf</strong>
              <span role="alert">Upload failed. Choose the file again and retry.</span>
            </div>
          </li>
        </ul>
      </section>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-homework">
        <div>
          <p className="eyebrow">Step 4</p>
          <h2 id="fixture-homework">Homework</h2>
        </div>
        <label>
          Homework title
          <input data-keyboard-order="homework" defaultValue="Practice set 3" />
        </label>
      </section>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-ai">
        <div>
          <p className="eyebrow">Step 5</p>
          <h2 id="fixture-ai">AI review placeholder</h2>
          <p>No production AI inference runs in TASK-004.</p>
        </div>
        <button className="button" data-keyboard-order="ai" type="button">
          Prepare review placeholder
        </button>
      </section>

      <section className="teacher-panel" data-active="true" aria-labelledby="fixture-review">
        <div>
          <p className="eyebrow">Step 6</p>
          <h2 id="fixture-review">Teacher review</h2>
          <p>Publish remains locked until explicit teacher review.</p>
        </div>
        <label className="teacher-checkbox">
          <input data-keyboard-order="review" type="checkbox" />I reviewed the class evidence and homework.
        </label>
      </section>

      <section
        className="teacher-panel teacher-publish"
        data-active="true"
        aria-labelledby="fixture-publish"
      >
        <div>
          <p className="eyebrow">Step 7</p>
          <h2 id="fixture-publish">Publish</h2>
        </div>
        <button className="button" data-keyboard-order="publish" type="button">
          Publish class session
        </button>
      </section>
    </main>
  );
}
