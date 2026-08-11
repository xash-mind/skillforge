import { rmSync } from "node:fs";
import { fileURLToPath } from "node:url";

const developmentTypeCache = fileURLToPath(new URL("../.next/dev", import.meta.url));

// An interrupted `next dev` can leave an incomplete route-type cache. Production type generation has
// its own cache, so remove only the disposable development subtree before a deterministic build.
rmSync(developmentTypeCache, { force: true, recursive: true });
