export const moduleKeys = [
  "identity",
  "tenancy",
  "academic",
  "classroom",
  "evidence",
  "learning-graph",
  "ai",
  "dashboards",
  "billing",
  "governance",
  "audit-operations",
] as const;

export type ModuleKey = (typeof moduleKeys)[number];

export type ModuleDefinition = Readonly<{
  key: ModuleKey;
  name: string;
  purpose: string;
  dependsOn: readonly ModuleKey[];
}>;

export function defineModule(definition: ModuleDefinition): ModuleDefinition {
  return Object.freeze({
    ...definition,
    dependsOn: Object.freeze([...definition.dependsOn]),
  });
}
