import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

import { moduleKeys } from "@/modules/_shared/domain/module-definition";
import { moduleCatalog } from "@/modules/catalog";

const modulesDirectory = dirname(fileURLToPath(import.meta.url));
const forbiddenDomainImport =
  /from\s+["'](?:react|next(?:\/[^"']*)?|@\/(?:app|components|providers)\/)/;

describe("module architecture", () => {
  it("registers every domain module exactly once", () => {
    const registeredKeys = moduleCatalog.map((definition) => definition.key);

    expect(new Set(registeredKeys).size).toBe(registeredKeys.length);
    expect([...registeredKeys].sort()).toEqual([...moduleKeys].sort());
  });

  it("only declares dependencies that exist in the catalog", () => {
    const registeredKeys = new Set(moduleCatalog.map((definition) => definition.key));

    for (const definition of moduleCatalog) {
      for (const dependency of definition.dependsOn) {
        expect(registeredKeys.has(dependency), `${definition.key} -> ${dependency}`).toBe(true);
      }
    }
  });

  it("keeps domain entry points independent from UI and provider implementations", async () => {
    for (const key of moduleKeys) {
      const source = await readFile(join(modulesDirectory, key, "domain", "module.ts"), "utf8");
      expect(source, `${key} domain imports`).not.toMatch(forbiddenDomainImport);
    }
  });
});
