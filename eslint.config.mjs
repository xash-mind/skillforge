import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypeScript from "eslint-config-next/typescript";
import prettier from "eslint-config-prettier/flat";

export default defineConfig([
  ...nextVitals,
  ...nextTypeScript,
  prettier,
  {
    files: ["src/modules/**/domain/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          paths: [
            {
              name: "react",
              message: "Domain modules must remain framework-independent.",
            },
            {
              name: "next",
              message: "Domain modules must remain framework-independent.",
            },
          ],
          patterns: [
            {
              group: [
                "next/**",
                "@/app/**",
                "@/components/**",
                "@/providers/**",
                "**/app/**",
                "**/components/**",
                "**/providers/**",
              ],
              message: "Domain modules cannot depend on UI or provider implementations.",
            },
          ],
        },
      ],
    },
  },
  globalIgnores([".next/**", "coverage/**", "next-env.d.ts"]),
]);
