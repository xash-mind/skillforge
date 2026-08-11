import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import SignInPage from "@/app/auth/sign-in/page";

describe("sign-in experience", () => {
  it("explains administrator-controlled access without offering public registration", async () => {
    render(await SignInPage({ searchParams: Promise.resolve({}) }));

    expect(screen.getByRole("heading", { name: /sign in to see what comes next/i })).toBeVisible();
    expect(screen.getByLabelText(/email address/i)).toHaveAttribute("autocomplete", "email");
    expect(screen.getByLabelText(/password/i)).toHaveAttribute("autocomplete", "current-password");
    expect(screen.getByText(/public registration is disabled/i)).toBeVisible();
    expect(screen.queryByRole("link", { name: /sign up/i })).not.toBeInTheDocument();
  });

  it("announces a sanitized authentication error", async () => {
    render(
      await SignInPage({
        searchParams: Promise.resolve({ error: "invalid_credentials" }),
      }),
    );

    expect(screen.getByRole("alert")).toHaveTextContent(/did not match an active SkillForge/i);
  });
});
