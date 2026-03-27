# AI Assistant Rules and Skills

This project ships with structured guidance that AI coding assistants use to understand the project's architecture, workflows, and constraints. These files live in `.cursor/rules/` and `.cursor/skills/` and are designed for [Cursor](https://cursor.com/), but the knowledge they contain is valuable regardless of which AI coding tool you use.

## What Are Rules and Skills?

**Rules** (`.cursor/rules/*.mdc`) are contextual instructions that activate automatically based on which files you're editing, or that you can invoke manually. They teach the AI assistant project conventions, guard rails, and standard workflows.

**Skills** (`.cursor/skills/*/SKILL.md`) are task-oriented guides that the AI assistant follows when performing specific operations like starting RHDH or managing plugins. They contain step-by-step procedures, flag references, and troubleshooting tables.

Together, rules and skills give an AI assistant deep project-specific knowledge -- the kind of context that would normally require reading dozens of documentation pages and learning from hard-won mistakes (like the 504 Gateway Timeout caused by network namespace desynchronization).

## Rules

| Rule | Activation | What It Does |
|------|-----------|--------------|
| `core-architecture.mdc` | Always active | Provides project context, the 5 critical rules, copy-sync system overview, and configuration precedence. This is the foundational rule that all other rules build on. |
| `copy-sync-workflow.mdc` | Manual, or auto when editing `rhdh-customizations/**` | Explains the file mapping between `rhdh-customizations/` and `rhdh-local/`, the standard edit-sync-restart workflow, configuration layers, and what to never do. |
| `container-lifecycle.mdc` | Always active | Documents `up.sh`/`down.sh` usage, the critical network namespace sharing behavior (and why ignoring it causes 504 errors), compose file merging, and service details. |
| `rhdh-local-protection.mdc` | Auto when editing `rhdh-local/**` | Guard rail that prevents accidental modification of upstream files. Explains what to do instead and lists exceptions. |
| `always-document.mdc` | Always active | Documentation standards: when to document, what to document, where documentation lives, quality standards, and anti-patterns. |
| `shell-scripts.mdc` | Auto when editing `**/*.sh` | Shell script standards: error handling, runtime compatibility (Podman/Docker), output conventions, and script reference. |
| `git-github.mdc` | Always active | Git and GitHub conventions: commit message standards, noreply email protection, secret safety checks before commits, submodule awareness, and force push guardrails. |

## Skills

### rhdh-lifecycle

**Trigger phrases:** "start RHDH", "stop RHDH", "restart RHDH", "apply customizations", "view logs", "check status", "update RHDH", "backup"

Manages the full container lifecycle: starting with various flag combinations, stopping with volume options, restarting (stop then start), applying configuration changes, viewing logs, checking health, updating the upstream project, and creating backups. Includes a troubleshooting table for common issues (504 errors, plugin failures, port conflicts).

**Files:** `.cursor/skills/rhdh-lifecycle/SKILL.md` (main skill) and `reference.md` (extended troubleshooting and operational details).

### plugin-management

**Trigger phrases:** "add a plugin", "enable a plugin", "disable a plugin", "configure a plugin", "list plugins", "install plugin"

End-to-end workflow for discovering, enabling, disabling, and configuring RHDH dynamic plugins. Uses the [rhdh-plugin-export-overlays](https://github.com/redhat-developer/rhdh-plugin-export-overlays) repository as the authoritative plugin catalog. Covers OCI artifact references, frontend mount point configuration, backend app-config integration, environment variable setup, and common issues.

**Files:** `.cursor/skills/plugin-management/SKILL.md`

### dynamic-plugins

**Trigger phrases:** "dynamic plugin configuration", "plugin override yaml", "local plugin development", "OCI plugin", "Lightspeed plugins", "Orchestrator plugins"

Covers plugin configuration files, plugin sources (OCI, tarball, local), the add/modify/restart workflow, and optional component plugins (Lightspeed, Orchestrator). Migrated from the former `dynamic-plugins.mdc` rule; use alongside **plugin-management** for catalog-driven enable/disable workflows.

**Files:** `.cursor/skills/dynamic-plugins/SKILL.md`

### rhdh-local-task-recipes

**Trigger phrases:** "how do I add a plugin", "change app config", "pristine mode", "update rhdh-local", "add Jenkins", "backup setup", "view logs", "customizations not applied"

Short recipe-style steps for specific tasks (plugins, app-config, env, image, compose services, baseline, backup, logs, troubleshooting). Complements **rhdh-lifecycle**, which covers general start/stop/restart and operational flags.

**Files:** `.cursor/skills/rhdh-local-task-recipes/SKILL.md`

## Using with Cursor

If you open this project in [Cursor](https://cursor.com/), the rules and skills are loaded automatically. Rules with glob patterns (like `rhdh-customizations/**`) activate when you edit matching files. Skills are invoked when you ask the assistant to perform matching tasks (like "start RHDH" or "add a plugin").

No setup is required -- just open the workspace in Cursor and start chatting with the AI assistant.

## Using with Other AI Coding Tools

The rules and skills are written in markdown (with `.mdc` extension for rules), so they are readable and usable by any AI coding assistant. Here's how to leverage them on other platforms:

### Claude Code (Anthropic)

Claude Code uses `CLAUDE.md` files for project context. You can reference the rules and skills directly:

1. Create a `CLAUDE.md` file at the project root
2. Include a directive to read the core rules as project context, for example:

```markdown
# Project Instructions

Read and follow the project rules in `.cursor/rules/core-architecture.mdc` -- these
describe the critical constraints for this project (copy-sync system, container lifecycle,
pristine submodule protection).

For operational tasks, follow the skill procedures in:
- `.cursor/skills/rhdh-lifecycle/SKILL.md` -- starting, stopping, configuring RHDH
- `.cursor/skills/plugin-management/SKILL.md` -- adding and managing dynamic plugins
- `.cursor/skills/dynamic-plugins/SKILL.md` -- plugin file layout, sources, and local development

Additional rules in `.cursor/rules/` cover specific topics (container lifecycle, shell
script standards) -- read them when working on related files.
```

### GitHub Copilot

Copilot in VS Code can be given project context through `.github/copilot-instructions.md`. A similar approach to the Claude Code example above works -- point the instructions file at the rules and skills as reference material.

### Windsurf, Aider, and Others

Most agentic coding tools support some form of project-level instructions or context files. The `.cursor/rules/` and `.cursor/skills/` directories contain plain markdown that any tool can read. The key files to point your tool at:

- `.cursor/rules/core-architecture.mdc` -- the essential project context (start here)
- `.cursor/skills/rhdh-lifecycle/SKILL.md` -- operational procedures
- `.cursor/skills/plugin-management/SKILL.md` -- plugin workflows
- `.cursor/skills/dynamic-plugins/SKILL.md` -- dynamic plugin files and local development

### Manual Reference

Even without any AI tool, the rules and skills serve as concise, well-structured reference documentation:

- **Rules** in `.cursor/rules/` describe project conventions and guard rails -- read `core-architecture.mdc` first for the big picture
- **Skills** in `.cursor/skills/` contain detailed operational procedures -- read `rhdh-lifecycle/SKILL.md` for day-to-day operations, `plugin-management/SKILL.md` and `dynamic-plugins/SKILL.md` for plugin workflows
