import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Home from "@/app/page";

describe("foundation experience", () => {
  it("makes the class lifecycle and teacher authority immediately clear", () => {
    render(<Home />);

    expect(
      screen.getByRole("heading", { name: "Every class becomes a clear next step." }),
    ).toBeInTheDocument();
    expect(screen.getByText("AI assists. Teachers decide.")).toBeInTheDocument();

    const workflow = screen.getByRole("heading", {
      name: "The complete class lifecycle",
    }).parentElement?.parentElement;

    expect(workflow).not.toBeNull();
    expect(within(workflow as HTMLElement).getAllByRole("listitem")).toHaveLength(6);
  });

  it("does not present preview controls as functional", () => {
    render(<Home />);

    expect(screen.getByRole("button", { name: /start class/i })).toBeDisabled();
    expect(
      screen.getByText("Interactive workflows arrive in the next milestone."),
    ).toBeInTheDocument();
  });
});
