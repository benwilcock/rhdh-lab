# Cursor Rules and Skills

This project ships with [Cursor](https://cursor.com/) rules and skills -- structured guidance that AI coding assistants use to understand the project's architecture, workflows, and constraints. Cursor users get these automatically when they open the workspace. Non-Cursor users can read them as reference documentation.

## What Are Rules and Skills?

**Rules** (`.cursor/rules/*.mdc`) are contextual instructions that activate automatically based on which files you're editing, or that you can invoke manually. They teach the AI assistant project conventions, guard rails, and standard workflows.

**Skills** (`.cursor/skills/*/SKILL.md`) are task-oriented guides that the AI assistant follows when performing specific operations like starting RHDH or managing plugins. They contain step-by-step procedures, flag references, and troubleshooting tables.

## Rules

| Rule | Activation | What It Does |
|------|-----------|--------------|
| `core-architecture.mdc` | Always active | Provides project context, the 5 critical rules, copy-sync system overview, and configuration precedence. This is the foundational rule that all other rules build on. |
| `copy-sync-workflow.mdc` | Manual, or auto when editing `rhdh-customizations/**` | Explains the file mapping between `rhdh-customizations/` and `rhdh-local/`, the standard edit-sync-restart workflow, configuration layers, and what to never do. |
| `container-lifecycle.mdc` | Manual | Documents `up.sh`/`down.sh` usage, the critical network namespace sharing behavior (and why ignoring it causes 504 errors), compose file merging, and service details. |
| `dynamic-plugins.mdc` | Manual | Covers plugin configuration files, plugin sources (OCI, tarball, local), the add/modify/restart workflow, and optional component plugins (Lightspeed, Orchestrator). |
| `rhdh-local-protection.mdc` | Auto when editing `rhdh-local/**` | Guard rail that prevents accidental modification of upstream files. Explains what to do instead and lists exceptions. |
| `common-workflows.mdc` | Manual | Step-by-step recipes for common tasks: add a plugin, change config, update rhdh-local, test pristine mode, add external services, share setup, view logs, troubleshoot. |
| `always-document.mdc` | Manual | Documentation standards: when to document, what to document, where documentation lives, quality standards, and anti-patterns. |
| `shell-scripts.mdc` | Auto when editing `**/*.sh` | Shell script standards: error handling, runtime compatibility (Podman/Docker), output conventions, and script reference. |

## Skills

### rhdh-lifecycle

**Trigger phrases:** "start RHDH", "stop RHDH", "restart RHDH", "apply customizations", "view logs", "check status", "update RHDH", "backup"

Manages the full container lifecycle: starting with various flag combinations, stopping with volume options, restarting (stop then start), applying configuration changes, viewing logs, checking health, updating the upstream project, and creating backups. Includes a troubleshooting table for common issues (504 errors, plugin failures, port conflicts).

**Files:** `.cursor/skills/rhdh-lifecycle/SKILL.md` (main skill) and `reference.md` (extended troubleshooting and operational details).

### plugin-management

**Trigger phrases:** "add a plugin", "enable a plugin", "disable a plugin", "configure a plugin", "list plugins", "install plugin"

End-to-end workflow for discovering, enabling, disabling, and configuring RHDH dynamic plugins. Uses the [rhdh-plugin-export-overlays](https://github.com/redhat-developer/rhdh-plugin-export-overlays) repository as the authoritative plugin catalog. Covers OCI artifact references, frontend mount point configuration, backend app-config integration, environment variable setup, and common issues.

**Files:** `.cursor/skills/plugin-management/SKILL.md`

## For Non-Cursor Users

If you don't use Cursor, these files still serve as excellent reference documentation:

- **Rules** in `.cursor/rules/` describe project conventions and guard rails -- read `core-architecture.mdc` first for the big picture
- **Skills** in `.cursor/skills/` contain detailed operational procedures -- read `rhdh-lifecycle/SKILL.md` for day-to-day operations and `plugin-management/SKILL.md` for plugin workflows
