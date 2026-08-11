import type { Metadata } from "next";
import Link from "next/link";

import { BrandMark } from "@/components/brand-mark";

import { signIn } from "./actions";

export const metadata: Metadata = {
  title: "Sign in",
};

const errorMessages = {
  invalid_input: "Enter a valid email address and password.",
  invalid_credentials: "Those details did not match an active SkillForge account.",
  callback: "That sign-in link is invalid or has expired. Ask your institute for a new one.",
} as const;

type SignInPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function SignInPage({ searchParams }: SignInPageProps) {
  const { error } = await searchParams;
  const errorMessage =
    error && error in errorMessages
      ? errorMessages[error as keyof typeof errorMessages]
      : undefined;

  return (
    <main className="auth-page">
      <header className="auth-page__header">
        <Link href="/" aria-label="Return to SkillForge home">
          <BrandMark />
        </Link>
      </header>
      <section className="auth-panel" aria-labelledby="sign-in-title">
        <div className="auth-panel__intro">
          <p className="eyebrow">Your learning workspace</p>
          <h1 id="sign-in-title">Sign in to see what comes next.</h1>
          <p>
            Your institute controls access. SkillForge uses trusted memberships and roles—not
            editable profile claims—to decide what you can see and do.
          </p>
        </div>

        <form action={signIn} className="auth-form">
          {errorMessage ? (
            <p className="auth-form__error" role="alert">
              {errorMessage}
            </p>
          ) : null}
          <label htmlFor="email">Email address</label>
          <input
            autoComplete="email"
            id="email"
            inputMode="email"
            name="email"
            required
            type="email"
          />
          <label htmlFor="password">Password</label>
          <input
            autoComplete="current-password"
            id="password"
            name="password"
            required
            type="password"
          />
          <button className="button button--primary" type="submit">
            Continue securely
          </button>
          <p className="auth-form__note">
            Accounts are created or invited by an authorized SkillForge administrator. Public
            registration is disabled.
          </p>
        </form>
      </section>
    </main>
  );
}
