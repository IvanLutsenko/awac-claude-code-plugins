import { describe, expect, it } from "vitest";
import fs from "fs";

import packageJson from "./package.json";

describe("MCP server metadata", () => {
  it("keeps the server version aligned with package.json", () => {
    const source = fs.readFileSync(new URL("./index.ts", import.meta.url), "utf8");

    expect(source).toContain(
      `{ name: "obsidian-tracker", version: "${packageJson.version}" }`
    );
  });
});
