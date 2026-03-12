#!/usr/bin/env node

/**
 * Obsidian Tracker MCP Server v3.0.0
 *
 * Project tracking, task management with kanban boards,
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

const BOARD_COLUMNS = ["Backlog", "In Progress", "Review", "Done"];

const CONFIG_DIR = path.join(os.homedir(), ".config", "obsidian-tracker");
const CONFIG_FILE = path.join(CONFIG_DIR, "config.json");

interface Config {
  vaultPath?: string;
  initialized: boolean;
}

const DEFAULT_CONFIG: Config = { initialized: false };

async function loadConfig(): Promise<Config> {
  try {
    const data = await fs.readFile(CONFIG_FILE, "utf-8");
    return { ...DEFAULT_CONFIG, ...JSON.parse(data) };
  } catch {
    return DEFAULT_CONFIG;
  }
}

async function saveConfig(config: Config): Promise<void> {
  await fs.mkdir(CONFIG_DIR, { recursive: true });
  await fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2));
}

async function getVaultPath(): Promise<string | null> {
  const config = await loadConfig();
  if (config.vaultPath) return config.vaultPath;
  if (process.env.OBSIDIAN_VAULT) {
    let envPath = process.env.OBSIDIAN_VAULT;
    if (envPath.includes("$HOME")) {
      envPath = envPath.replace(/\$HOME/g, os.homedir());
    }
    return envPath;
  }
  return null;
}

async function validateVaultPath(vaultPath: string): Promise<boolean> {
  try {
    const stat = await fs.stat(vaultPath);
    return stat.isDirectory();
  } catch {
    return false;
  }
}

// --- Markdown helpers ---

async function parseMarkdown(filePath: string) {
  const content = await fs.readFile(filePath, "utf-8");
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n/);
  let frontmatter: Record<string, any> = {};
  let body = content;

  if (frontmatterMatch) {
    const fm = frontmatterMatch[1];
    body = content.slice(frontmatterMatch[0].length);
    for (const line of fm.split("\n")) {
      const match = line.match(/^(\w+):\s*(.+)$/);
      if (match) {
        const [, key, value] = match;
        frontmatter[key] = value.replace(/^["']|["']$/g, "");
      }
    }
  }

  return { frontmatter, body };
}

// --- Board (kanban) helpers ---

async function parseBoard(boardPath: string): Promise<Map<string, string[]>> {
  const columns = new Map<string, string[]>();
  for (const col of BOARD_COLUMNS) columns.set(col, []);

  try {
    const content = await fs.readFile(boardPath, "utf-8");
    let currentColumn: string | null = null;

    for (const line of content.split("\n")) {
      const headerMatch = line.match(/^## (.+)$/);
      if (headerMatch) {
        const colName = headerMatch[1].trim();
        if (BOARD_COLUMNS.includes(colName)) currentColumn = colName;
        continue;
      }
      if (currentColumn && line.match(/^- \[[ x]\] /)) {
        columns.get(currentColumn)!.push(line);
      }
    }
  } catch {
    // Board doesn't exist yet
  }

  return columns;
}

async function writeBoard(boardPath: string, columns: Map<string, string[]>): Promise<void> {
  let content = "---\nkanban-plugin: basic\n---\n";
  for (const col of BOARD_COLUMNS) {
    content += `\n## ${col}\n`;
    for (const item of columns.get(col) || []) {
      content += `${item}\n`;
    }
  }
  await fs.writeFile(boardPath, content);
}

async function getNextTaskId(projectPath: string): Promise<number> {
  try {
    const files = await fs.readdir(projectPath);
    const ids = files
      .map(f => f.match(/^TASK-(\d+)/))
      .filter((m): m is RegExpMatchArray => m !== null)
      .map(m => parseInt(m[1], 10));
    return ids.length > 0 ? Math.max(...ids) + 1 : 1;
  } catch {
    return 1;
  }
}

async function updateTaskFrontmatter(taskPath: string, updates: Record<string, string>): Promise<void> {
  let content = await fs.readFile(taskPath, "utf-8");
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);

  if (fmMatch) {
    let fm = fmMatch[1];
    for (const [key, value] of Object.entries(updates)) {
      const regex = new RegExp(`^${key}:.*$`, "m");
      if (regex.test(fm)) {
        fm = fm.replace(regex, `${key}: ${value}`);
      } else {
        fm += `\n${key}: ${value}`;
      }
    }
    content = `---\n${fm}\n---` + content.slice(fmMatch[0].length);
    await fs.writeFile(taskPath, content);
  }
}

// --- Path helpers ---

function getProjectPath(vaultPath: string, name: string) {
  return path.join(vaultPath, name);
}

async function requireVault(): Promise<string> {
  const vaultPath = await getVaultPath();
  if (!vaultPath) {
    throw new Error("Obsidian Tracker not initialized. Please run initVault first.");
  }
  const isValid = await validateVaultPath(vaultPath);
  if (!isValid) {
    throw new Error(`Vault path "${vaultPath}" does not exist or is not a directory.`);
  }
  return vaultPath;
}

// --- Server ---

const server = new Server(
  { name: "obsidian-tracker", version: "3.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "initVault",
        description: "Initialize Obsidian Tracker with vault path",
        inputSchema: {
          type: "object",
          properties: {
            vaultPath: {
              type: "string",
              description: "Full path to Obsidian vault Projects folder",
            },
          },
          required: ["vaultPath"],
        },
      },
      {
        name: "getConfig",
        description: "Get current Obsidian Tracker configuration",
        inputSchema: { type: "object", properties: {} },
      },
      {
        name: "listProjects",
        description: "List all projects from Obsidian vault",
        inputSchema: {
          type: "object",
          properties: {
            includeArchived: {
              type: "boolean",
              description: "Include archived projects (default: false)",
            },
          },
        },
      },
      {
        name: "getProject",
        description: "Get details for a specific project",
        inputSchema: {
          type: "object",
          properties: {
            name: { type: "string", description: "Project name" },
          },
          required: ["name"],
        },
      },
      {
        name: "createProject",
        description: "Create a new project in Obsidian with kanban board",
        inputSchema: {
          type: "object",
          properties: {
            name: { type: "string", description: "Project name" },
            description: { type: "string", description: "Project description" },
            repository: { type: "string", description: "Repository URL" },
            localPath: { type: "string", description: "Local file path" },
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
            project: { type: "string", description: "Project name" },
            title: { type: "string", description: "Bug title" },
            description: { type: "string", description: "Bug description" },
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
            project: { type: "string", description: "Project name" },
            goal: { type: "string", description: "Session goal" },
            actions: {
              type: "array",
              items: { type: "string" },
              description: "Actions taken",
            },
            results: { type: "string", description: "Results achieved" },
            nextSteps: { type: "string", description: "Next steps" },
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
            query: { type: "string", description: "Search query (supports tag: syntax)" },
          },
          required: ["query"],
        },
      },
      {
        name: "archiveProject",
        description: "Archive a project (move to _archive folder)",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
          },
          required: ["project"],
        },
      },
      {
        name: "restoreProject",
        description: "Restore an archived project back to active",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
          },
          required: ["project"],
        },
      },
      {
        name: "deleteProject",
        description: "Permanently delete a project",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
            fromArchive: {
              type: "boolean",
              description: "Delete from archive (default: true). Set false to delete active project.",
            },
          },
          required: ["project"],
        },
      },
      {
        name: "addTask",
        description: "Create a task with auto-increment ID and add to kanban board",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
            title: { type: "string", description: "Task title" },
            priority: {
              type: "string",
              enum: ["critical", "high", "medium", "low"],
              description: "Task priority (default: medium)",
            },
            effort: { type: "string", description: "Estimated effort (e.g., '2h', '1d')" },
            assignee: { type: "string", description: "Assignee name" },
            extra: {
              type: "object",
              description: "Additional custom YAML fields",
              additionalProperties: true,
            },
          },
          required: ["project", "title"],
        },
      },
      {
        name: "updateTask",
        description: "Move a task between kanban board columns",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
            taskId: { type: "number", description: "Task ID number" },
            status: {
              type: "string",
              enum: ["Backlog", "In Progress", "Review", "Done"],
              description: "Target column",
            },
            actual: { type: "string", description: "Actual time spent (e.g., '1h')" },
          },
          required: ["project", "taskId", "status"],
        },
      },
      {
        name: "listTasks",
        description: "List tasks from kanban board with statuses",
        inputSchema: {
          type: "object",
          properties: {
            project: { type: "string", description: "Project name" },
            status: {
              type: "string",
              enum: ["Backlog", "In Progress", "Review", "Done"],
              description: "Filter by status (optional)",
            },
          },
          required: ["project"],
        },
      },
    ],
  };
});

// --- Tool implementations ---

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "initVault": {
        if (!args) throw new Error("Missing arguments");
        const vaultPath = args.vaultPath as string;

        const isValid = await validateVaultPath(vaultPath);
        if (!isValid) {
          try {
            await fs.mkdir(vaultPath, { recursive: true });
          } catch (e) {
            throw new Error(`Cannot create vault path "${vaultPath}": ${(e as Error).message}`);
          }
        }

        await saveConfig({ vaultPath, initialized: true });

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              message: "Obsidian Tracker initialized successfully!",
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
        const includeArchived = (args?.includeArchived as boolean) ?? false;
        const entries = await fs.readdir(vaultPath, { withFileTypes: true });
        const projects = [];

        for (const entry of entries) {
          if (entry.isDirectory() && entry.name !== "_archive") {
            const projectPath = path.join(vaultPath, entry.name);
            const dashboardPath = path.join(projectPath, "!Project Dashboard.md");

            try {
              const { frontmatter } = await parseMarkdown(dashboardPath);
              const files = await fs.readdir(projectPath);
              const bugCount = files.filter(f => f.startsWith("BUG -")).length;
              const taskCount = files.filter(f => /^TASK-\d+/.test(f)).length;

              projects.push({
                name: entry.name,
                status: frontmatter.status || "Unknown",
                description: frontmatter.description || "",
                bugs: bugCount,
                tasks: taskCount,
                archived: false,
                path: projectPath,
              });
            } catch {
              // No dashboard, skip
            }
          }
        }

        if (includeArchived) {
          const archivePath = path.join(vaultPath, "_archive");
          try {
            const archiveEntries = await fs.readdir(archivePath, { withFileTypes: true });
            for (const entry of archiveEntries) {
              if (entry.isDirectory()) {
                const projectPath = path.join(archivePath, entry.name);
                const dashboardPath = path.join(projectPath, "!Project Dashboard.md");

                try {
                  const { frontmatter } = await parseMarkdown(dashboardPath);
                  const files = await fs.readdir(projectPath);
                  const bugCount = files.filter(f => f.startsWith("BUG -")).length;
                  const taskCount = files.filter(f => /^TASK-\d+/.test(f)).length;

                  projects.push({
                    name: entry.name,
                    status: frontmatter.status || "Archived",
                    description: frontmatter.description || "",
                    bugs: bugCount,
                    tasks: taskCount,
                    archived: true,
                    path: projectPath,
                  });
                } catch {
                  // No dashboard, skip
                }
              }
            }
          } catch {
            // No _archive directory
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

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found in vault`);

        const dashboardPath = path.join(projectPath, "!Project Dashboard.md");
        let frontmatter: Record<string, any> = {};
        let body = "";

        try {
          const parsed = await parseMarkdown(dashboardPath);
          frontmatter = parsed.frontmatter;
          body = parsed.body;
        } catch {
          body = "No dashboard found";
        }

        let bugFiles: string[] = [];
        try {
          bugFiles = (await fs.readdir(projectPath))
            .filter(f => f.startsWith("BUG -"))
            .map(f => f.replace("BUG - ", "").replace(".md", ""));
        } catch {}

        const sessionsPath = path.join(projectPath, "Sessions");
        let sessions: string[] = [];
        try {
          sessions = (await fs.readdir(sessionsPath)).filter(f => f.endsWith(".md"));
        } catch {}

        // Task summary from board
        const boardPath = path.join(projectPath, "Board.md");
        const columns = await parseBoard(boardPath);
        const taskSummary = {
          backlog: columns.get("Backlog")?.length ?? 0,
          inProgress: columns.get("In Progress")?.length ?? 0,
          review: columns.get("Review")?.length ?? 0,
          done: columns.get("Done")?.length ?? 0,
        };

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              name: projectName,
              path: projectPath,
              frontmatter,
              dashboard: body,
              bugs: bugFiles,
              sessions,
              tasks: taskSummary,
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

        const createdDate = new Date().toISOString().split("T")[0];
        const projectTag = projectName.toLowerCase().replace(/\s+/g, "-");
        const dashboard = `---
status: Active
description: ${args.description ?? ""}
repository: ${args.repository ?? ""}
localPath: ${args.localPath ?? ""}
created: ${createdDate}
tags: [project, ${projectTag}]
---

# ${projectName} - Dashboard

## Status
- **Description:** ${args.description ?? "N/A"}
- **Repository:** ${args.repository ?? "N/A"}
- **Local path:** ${args.localPath ?? "N/A"}
- **Status:** Active
- **Created:** ${createdDate}

## Plugins/Subprojects

## Known Issues

## Quick Commands

---
#project #${projectTag}
`;

        await fs.writeFile(path.join(projectPath, "!Project Dashboard.md"), dashboard);
        await fs.writeFile(path.join(projectPath, "README.md"), `# ${projectName}\n\n${args.description ?? "N/A"}\n`);

        // Kanban board
        const boardContent = "---\nkanban-plugin: basic\n---\n\n## Backlog\n\n## In Progress\n\n## Review\n\n## Done\n";
        await fs.writeFile(path.join(projectPath, "Board.md"), boardContent);

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

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found in vault`);

        const title = args.title as string;
        const priority = (args.priority as string) ?? "medium";
        const description = args.description as string;
        const date = new Date().toISOString().split("T")[0];

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

        const bugPath = path.join(projectPath, `BUG - ${title}.md`);
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

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found in vault`);

        const sessionsPath = path.join(projectPath, "Sessions");
        await fs.mkdir(sessionsPath, { recursive: true });

        const now = new Date();
        const date = now.toISOString().split("T")[0];
        const time = now.toISOString().split("T")[1].slice(0, 5);
        const sessionPath = path.join(sessionsPath, `Session - ${date}.md`);

        let existingContent = "";
        try {
          existingContent = await fs.readFile(sessionPath, "utf-8");
        } catch {}

        const actions = args.actions as string[] | undefined;
        const actionsText = actions && actions.length > 0
          ? actions.map((a: string) => `- ${a}`).join("\n")
          : "- No actions recorded";

        const sessionEntry = `

## Session - ${time} UTC

### Goal
${args.goal ?? "No goal specified"}

### Actions
${actionsText}

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
        const searchTerm = isTagSearch ? query.slice(4).trim() : query.toLowerCase();

        for (const entry of entries) {
          if (entry.isDirectory()) {
            const projectPath = path.join(vaultPath, entry.name);
            let files: string[];
            try {
              files = await fs.readdir(projectPath);
            } catch {
              continue;
            }

            for (const file of files) {
              if (file.endsWith(".md")) {
                try {
                  const content = await fs.readFile(path.join(projectPath, file), "utf-8");
                  if (isTagSearch) {
                    const tagRegex = new RegExp(`#${searchTerm}(?:\\s|$|\\])`, "i");
                    if (tagRegex.test(content)) {
                      results.push({ project: entry.name, file, match: `tag:#${searchTerm}` });
                    }
                  } else {
                    if (content.toLowerCase().includes(searchTerm)) {
                      results.push({ project: entry.name, file, match: "content" });
                    }
                  }
                } catch {}
              }
            }
          }
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({ query, results, count: results.length }, null, 2),
          }],
        };
      }

      // --- Archive / Restore / Delete ---

      case "archiveProject": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found in vault`);

        const archivePath = path.join(vaultPath, "_archive");
        await fs.mkdir(archivePath, { recursive: true });

        const dashboardPath = path.join(projectPath, "!Project Dashboard.md");
        try {
          await updateTaskFrontmatter(dashboardPath, { status: "Archived" });
        } catch {
          // Dashboard may not exist, proceed anyway
        }

        const archivedPath = path.join(archivePath, projectName);
        await fs.rename(projectPath, archivedPath);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              message: `Project "${projectName}" archived`,
              archivedPath,
            }, null, 2),
          }],
        };
      }

      case "restoreProject": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const archivedPath = path.join(vaultPath, "_archive", projectName);

        const exists = await validateVaultPath(archivedPath);
        if (!exists) throw new Error(`Archived project "${projectName}" not found in _archive`);

        const dashboardPath = path.join(archivedPath, "!Project Dashboard.md");
        try {
          await updateTaskFrontmatter(dashboardPath, { status: "Active" });
        } catch {
          // Dashboard may not exist
        }

        const restoredPath = getProjectPath(vaultPath, projectName);
        await fs.rename(archivedPath, restoredPath);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              message: `Project "${projectName}" restored`,
              restoredPath,
            }, null, 2),
          }],
        };
      }

      case "deleteProject": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const fromArchive = (args.fromArchive as boolean) ?? true;

        const targetPath = fromArchive
          ? path.join(vaultPath, "_archive", projectName)
          : getProjectPath(vaultPath, projectName);

        const exists = await validateVaultPath(targetPath);
        if (!exists) {
          const location = fromArchive ? "_archive" : "vault";
          throw new Error(`Project "${projectName}" not found in ${location}`);
        }

        await fs.rm(targetPath, { recursive: true, force: true });

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              message: `Project "${projectName}" permanently deleted`,
              deletedPath: targetPath,
            }, null, 2),
          }],
        };
      }

      // --- Task management ---

      case "addTask": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found`);

        const title = args.title as string;
        const priority = (args.priority as string) ?? "medium";
        const effort = (args.effort as string) ?? "";
        const assignee = (args.assignee as string) ?? "";
        const extra = (args.extra as Record<string, any>) ?? {};
        const createdDate = new Date().toISOString().split("T")[0];

        const taskId = await getNextTaskId(projectPath);
        const taskFileName = `TASK-${taskId} - ${title}.md`;
        const taskPath = path.join(projectPath, taskFileName);

        let yaml = `---\npriority: ${priority}\n`;
        if (effort) yaml += `effort: ${effort}\n`;
        if (assignee) yaml += `assignee: ${assignee}\n`;
        yaml += `created: ${createdDate}\n`;
        for (const [key, value] of Object.entries(extra)) {
          yaml += `${key}: ${value}\n`;
        }
        yaml += `---\n`;

        const taskContent = `${yaml}
# TASK-${taskId}: ${title}

## Description

## Notes

---
#task #${priority}
`;

        await fs.writeFile(taskPath, taskContent);

        // Add to board
        const boardPath = path.join(projectPath, "Board.md");
        const columns = await parseBoard(boardPath);
        columns.get("Backlog")!.push(`- [ ] [[TASK-${taskId} - ${title}]]`);
        await writeBoard(boardPath, columns);

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              taskId,
              path: taskPath,
              message: `Task TASK-${taskId} created: "${title}"`,
            }, null, 2),
          }],
        };
      }

      case "updateTask": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found`);

        const taskId = args.taskId as number;
        const targetStatus = args.status as string;
        const actual = args.actual as string | undefined;

        const boardPath = path.join(projectPath, "Board.md");
        const columns = await parseBoard(boardPath);

        // Find and remove task from current column
        let taskLine: string | null = null;
        let sourceColumn: string | null = null;
        const taskPattern = new RegExp(`\\[\\[TASK-${taskId}\\s*-`);

        for (const [col, items] of columns) {
          const idx = items.findIndex(line => taskPattern.test(line));
          if (idx !== -1) {
            taskLine = items[idx];
            sourceColumn = col;
            items.splice(idx, 1);
            break;
          }
        }

        if (!taskLine) throw new Error(`Task TASK-${taskId} not found on board`);

        // Update checkbox
        if (targetStatus === "Done") {
          taskLine = taskLine.replace("- [ ]", "- [x]");
        } else {
          taskLine = taskLine.replace("- [x]", "- [ ]");
        }

        columns.get(targetStatus)!.push(taskLine);
        await writeBoard(boardPath, columns);

        // Update task file frontmatter
        if (actual || targetStatus === "Done") {
          const files = await fs.readdir(projectPath);
          const taskFile = files.find(f => f.startsWith(`TASK-${taskId} `));
          if (taskFile) {
            const updates: Record<string, string> = {};
            if (actual) updates.actual = actual;
            if (targetStatus === "Done") {
              updates.completed = new Date().toISOString().split("T")[0];
            }
            await updateTaskFrontmatter(path.join(projectPath, taskFile), updates);
          }
        }

        return {
          content: [{
            type: "text",
            text: JSON.stringify({
              success: true,
              taskId,
              from: sourceColumn,
              to: targetStatus,
              actual: actual ?? null,
              message: `Task TASK-${taskId}: ${sourceColumn} → ${targetStatus}`,
            }, null, 2),
          }],
        };
      }

      case "listTasks": {
        const vaultPath = await requireVault();
        if (!args) throw new Error("Missing arguments");
        const projectName = args.project as string;
        const projectPath = getProjectPath(vaultPath, projectName);

        const projectExists = await validateVaultPath(projectPath);
        if (!projectExists) throw new Error(`Project "${projectName}" not found`);

        const statusFilter = args.status as string | undefined;
        const boardPath = path.join(projectPath, "Board.md");
        const columns = await parseBoard(boardPath);

        const tasks: Array<{ id: number; title: string; status: string }> = [];

        for (const [col, items] of columns) {
          if (statusFilter && col !== statusFilter) continue;
          for (const item of items) {
            const match = item.match(/\[\[TASK-(\d+)\s*-\s*(.+?)\]\]/);
            if (match) {
              tasks.push({
                id: parseInt(match[1], 10),
                title: match[2].trim(),
                status: col,
              });
            }
          }
        }

        tasks.sort((a, b) => a.id - b.id);

        const summary = {
          backlog: columns.get("Backlog")?.length ?? 0,
          inProgress: columns.get("In Progress")?.length ?? 0,
          review: columns.get("Review")?.length ?? 0,
          done: columns.get("Done")?.length ?? 0,
        };

        return {
          content: [{
            type: "text",
            text: JSON.stringify({ project: projectName, tasks, summary }, null, 2),
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
        text: JSON.stringify({ error: (error as Error).message }, null, 2),
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
