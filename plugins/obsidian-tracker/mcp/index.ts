#!/usr/bin/env node

/**
 * Obsidian Tracker MCP Server
 *
 * Provides integration with Obsidian vault for project tracking,
 * bug logging, and session management.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs/promises";
import path from "path";
import os from "os";

// Config file path
const CONFIG_DIR = path.join(os.homedir(), ".config", "obsidian-tracker");
const CONFIG_FILE = path.join(CONFIG_DIR, "config.json");

// Config interface
interface Config {
  vaultPath?: string;
  initialized: boolean;
}

// Default config
const DEFAULT_CONFIG: Config = {
  initialized: false,
};

/**
 * Load config from file
 */
async function loadConfig(): Promise<Config> {
  try {
    const data = await fs.readFile(CONFIG_FILE, "utf-8");
    return { ...DEFAULT_CONFIG, ...JSON.parse(data) };
  } catch {
    return DEFAULT_CONFIG;
  }
}

/**
 * Save config to file
 */
async function saveConfig(config: Config): Promise<void> {
  await fs.mkdir(CONFIG_DIR, { recursive: true });
  await fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2));
}

/**
 * Get vault path with validation
 */
async function getVaultPath(): Promise<string | null> {
  // First check environment variable
  if (process.env.OBSIDIAN_VAULT) {
    return process.env.OBSIDIAN_VAULT;
  }

  // Then check config file
  const config = await loadConfig();
  return config.vaultPath || null;
}

/**
 * Validate vault path exists
 */
async function validateVaultPath(vaultPath: string): Promise<boolean> {
  try {
    const stat = await fs.stat(vaultPath);
    return stat.isDirectory();
  } catch {
    return false;
  }
}

// Create server
const server = new Server(
  {
    name: "obsidian-tracker",
    version: "1.2.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * List all available tools
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "initVault",
        description: "Initialize Obsidian Tracker with vault path. MUST be called first before using other tools.",
        inputSchema: {
          type: "object",
          properties: {
            vaultPath: {
              type: "string",
              description: "Full path to Obsidian vault Projects folder (e.g., /Users/username/Documents/Obsidian/Projects)",
            },
          },
          required: ["vaultPath"],
        },
      },
      {
        name: "getConfig",
        description: "Get current Obsidian Tracker configuration",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "listProjects",
        description: "List all projects from Obsidian vault",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "getProject",
        description: "Get details for a specific project",
        inputSchema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "Project name",
            },
          },
          required: ["name"],
        },
      },
      {
        name: "createProject",
        description: "Create a new project in Obsidian",
        inputSchema: {
          type: "object",
          properties: {
            name: {
              type: "string",
              description: "Project name",
            },
            description: {
              type: "string",
              description: "Project description",
            },
            repository: {
              type: "string",
              description: "Repository URL",
            },
            localPath: {
              type: "string",
              description: "Local file path",
            },
          },
          required: ["name", "description"],
        },
      },
      {
        name: "addBug",
        description: "Add a bug report to a project",
        inputSchema: {
          type: "object",
          properties: {
            project: {
              type: "string",
              description: "Project name",
            },
            title: {
              type: "string",
              description: "Bug title",
            },
            description: {
              type: "string",
              description: "Bug description",
            },
            priority: {
              type: "string",
              enum: ["critical", "high", "medium", "low"],
              description: "Bug priority",
            },
          },
          required: ["project", "title", "description"],
        },
      },
      {
        name: "addSession",
        description: "Add a session log to a project",
        inputSchema: {
          type: "object",
          properties: {
            project: {
              type: "string",
              description: "Project name",
            },
            goal: {
              type: "string",
              description: "Session goal",
            },
            actions: {
              type: "array",
              items: { type: "string" },
              description: "Actions taken",
            },
            results: {
              type: "string",
              description: "Results achieved",
            },
            nextSteps: {
              type: "string",
              description: "Next steps",
            },
          },
          required: ["project", "goal"],
        },
      },
      {
        name: "search",
        description: "Search projects by tags or content",
        inputSchema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "Search query (supports tag: syntax)",
            },
          },
          required: ["query"],
        },
      },
    ],
  };
});

/**
 * Parse frontmatter and content from markdown file
 */
async function parseMarkdown(filePath: string) {
  const content = await fs.readFile(filePath, "utf-8");
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);

  let frontmatter: Record<string, any> = {};
  let body = content;

  if (frontmatterMatch) {
    const fm = frontmatterMatch[1];
    body = content.slice(frontmatterMatch[0].length);

    // Simple YAML parser for basic fields
    const lines = fm.split("\n");
    for (const line of lines) {
      const match = line.match(/^(\w+):\s*(.+)$/);
      if (match) {
        const [, key, value] = match;
        frontmatter[key] = value.replace(/^["']|["']$/g, "");
      }
    }
  }

  return { frontmatter, body };
}

/**
 * Get project directory path
 */
function getProjectPath(vaultPath: string, name: string) {
  return path.join(vaultPath, name);
}

/**
 * Require vault to be initialized
 */
async function requireVault(): Promise<string> {
  const vaultPath = await getVaultPath();
  if (!vaultPath) {
    throw new Error(
      "Obsidian Tracker not initialized. Please run initVault first with your Obsidian vault path."
    );
  }
  const isValid = await validateVaultPath(vaultPath);
  if (!isValid) {
    throw new Error(
      `Vault path "${vaultPath}" does not exist or is not a directory. Please run initVault with a valid path.`
    );
  }
  return vaultPath;
}

/**
 * Handle tool calls
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "initVault": {
        if (!args) throw new Error("Missing arguments");
        const vaultPath = args.vaultPath as string;

        // Validate path exists
        const isValid = await validateVaultPath(vaultPath);
        if (!isValid) {
          // Try to create it
          try {
            await fs.mkdir(vaultPath, { recursive: true });
          } catch (e) {
            throw new Error(
              `Cannot create vault path "${vaultPath}": ${(e as Error).message}`
            );
          }
        }

        // Save config
        const config: Config = {
          vaultPath,
          initialized: true,
        };
        await saveConfig(config);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              message: `Obsidian Tracker initialized successfully!`,
              vaultPath,
              configFile: CONFIG_FILE,
            }, null, 2),
          }],
        };
      }

      case "getConfig": {
        const config = await loadConfig();
        const vaultPath = await getVaultPath();

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              initialized: config.initialized,
              vaultPath: vaultPath || "NOT SET",
              configFile: CONFIG_FILE,
              envVar: process.env.OBSIDIAN_VAULT || "NOT SET",
            }, null, 2),
          }],
        };
      }

      case "listProjects": {
        const vaultPath = await requireVault();
        const entries = await fs.readdir(vaultPath, { withFileTypes: true });
        const projects = [];

        for (const entry of entries) {
          if (entry.isDirectory()) {
            const projectPath = path.join(vaultPath, entry.name);
            const dashboardPath = path.join(projectPath, "!Project Dashboard.md");

            try {
              const { frontmatter } = await parseMarkdown(dashboardPath);
              const bugFiles = (await fs.readdir(projectPath))
                .filter(f => f.startsWith("BUG -"));

              projects.push({
                name: entry.name,
                status: frontmatter.status || "Unknown",
                description: frontmatter.description || "",
                bugs: bugFiles.length,
                path: projectPath,
              });
            } catch {
              // No dashboard, skip
            }
          }
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({ projects }, null, 2),
          }],
        };
      }

      case "getProject": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.name as string;
        const projectPath = getProjectPath(vaultPath, projectName);
        const dashboardPath = path.join(projectPath, "!Project Dashboard.md");

        const { frontmatter, body } = await parseMarkdown(dashboardPath);

        // List bugs
        const bugFiles = (await fs.readdir(projectPath))
          .filter(f => f.startsWith("BUG -"))
          .map(f => f.replace("BUG - ", "").replace(".md", ""));

        // List sessions
        const sessionsPath = path.join(projectPath, "Sessions");
        let sessions: string[] = [];
        try {
          const sessionFiles = await fs.readdir(sessionsPath);
          sessions = sessionFiles.filter(f => f.endsWith(".md"));
        } catch {
          // No sessions directory
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              name: projectName,
              frontmatter,
              dashboard: body,
              bugs: bugFiles,
              sessions,
            }, null, 2),
          }],
        };
      }

      case "createProject": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.name as string;
        const projectPath = getProjectPath(vaultPath, projectName);

        await fs.mkdir(projectPath, { recursive: true });

        const dashboard = `# ${projectName} - Dashboard

## Status
- **Description:** ${args.description ?? "N/A"}
- **Repository:** ${args.repository ?? "N/A"}
- **Local path:** ${args.localPath ?? "N/A"}
- **Status:** Active
- **Created:** ${new Date().toISOString().split("T")[0]}

## Plugins/Subprojects

## Known Issues

## Quick Commands

---
#project #${projectName.toLowerCase().replace(/\s+/g, "-")}
`;

        await fs.writeFile(
          path.join(projectPath, "!Project Dashboard.md"),
          dashboard
        );

        await fs.writeFile(
          path.join(projectPath, "README.md"),
          `# ${projectName}\n\n${args.description ?? "N/A"}\n`
        );

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              path: projectPath,
              message: `Project "${projectName}" created successfully`,
            }, null, 2),
          }],
        };
      }

      case "addBug": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);
        const title = args.title as string;
        const priority = (args.priority as string) ?? "medium";
        const description = args.description as string;
        const date = new Date().toISOString().split("T")[0];

        const bugFileName = `BUG - ${title}.md`;
        const bugPath = path.join(projectPath, bugFileName);

        const bugContent = `# ${title}

## Status
- **Priority:** ${priority}
- **Status:** Open
- **Date:** ${date}

## Description
${description}

## Attempted Fixes
| # | Action | Result |
|---|--------|--------|

## Next Steps

---
#bug #${priority}
`;

        await fs.writeFile(bugPath, bugContent);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              path: bugPath,
              message: `Bug report created: "${title}"`,
            }, null, 2),
          }],
        };
      }

      case "addSession": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);
        const sessionsPath = path.join(projectPath, "Sessions");

        await fs.mkdir(sessionsPath, { recursive: true });

        const date = new Date().toISOString().split("T")[0];
        const sessionFileName = `Session - ${date}.md`;
        const sessionPath = path.join(sessionsPath, sessionFileName);

        // Check if session file already exists for today
        let existingContent = "";
        try {
          existingContent = await fs.readFile(sessionPath, "utf-8");
        } catch {
          // File doesn't exist yet
        }

        const actions = args.actions as string[] | undefined;
        const sessionEntry = `

## Session - ${new Date().toLocaleTimeString()}

### Goal
${args.goal ?? "No goal specified"}

### Actions
${(actions ?? []).map((a: string) => `- ${a}`).join("\n")}

### Results
${args.results ?? "In progress..."}

### Next Time
${args.nextSteps ?? "TBD"}

---
`;

        await fs.writeFile(sessionPath, existingContent + sessionEntry);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              path: sessionPath,
              message: "Session logged",
            }, null, 2),
          }],
        };
      }

      case "search": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const query = args.query as string;
        const entries = await fs.readdir(vaultPath, { withFileTypes: true });
        const results: Array<{ project: string; file: string; match: string }> = [];

        const isTagSearch = query.startsWith("tag:");

        if (isTagSearch) {
          const tag = query.slice(4);
          for (const entry of entries) {
            if (entry.isDirectory()) {
              const projectPath = path.join(vaultPath, entry.name);
              const files = await fs.readdir(projectPath);

              for (const file of files) {
                if (file.endsWith(".md")) {
                  const content = await fs.readFile(path.join(projectPath, file), "utf-8");
                  if (content.includes(`#${tag}`) || content.includes(`#${tag}\``)) {
                    results.push({
                      project: entry.name,
                      file,
                      match: "tag",
                    });
                  }
                }
              }
            }
          }
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({ query, results }, null, 2),
          }],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{
        type: "text",
        text: JSON.stringify({
          error: (error as Error).message,
        }, null, 2),
      }],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Obsidian Tracker MCP server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
