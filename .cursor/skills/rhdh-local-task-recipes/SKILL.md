---
name: rhdh-local-task-recipes
description: "Short recipe-style procedures for specific RHDH Local tasks -- dynamic plugins, app-config, env and image changes, apply-customizations and restarts, pristine baseline, compose overrides and external services, backup, logs, troubleshooting customizations, and rhdh-local git updates. For general container start/stop/restart, flags, health, and day-to-day operations, prefer the rhdh-lifecycle skill. Use when the user asks how to perform these specific tasks or when editing rhdh-customizations/ or root lifecycle scripts (up.sh, down.sh, backup.sh)."
---

# RHDH Local Task Recipes

Reference guide for common RHDH Local tasks. Mention `@rhdh-local-task-recipes` in chat to load this skill explicitly.

## Add a Plugin

1. Edit: `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml`
2. Sync: `cd rhdh-customizations && ./apply-customizations.sh`
3. Restart: `cd .. && ./down.sh && ./up.sh --customized [flags]` (or `./up.sh --last` after a successful start)

## Change Application Configuration

1. Edit: `rhdh-customizations/configs/app-config/app-config.local.yaml`
2. Sync: `cd rhdh-customizations && ./apply-customizations.sh`
3. Restart: `cd .. && ./down.sh && ./up.sh --customized [flags]`

## Change RHDH Container Image

1. Edit: `rhdh-customizations/.env` (set `RHDH_IMAGE=...`)
2. Sync: `cd rhdh-customizations && ./apply-customizations.sh`
3. Restart: `cd .. && ./down.sh && ./up.sh --customized [flags]`

## Change Environment Variables

1. Edit: `rhdh-customizations/.env`
2. Sync: `cd rhdh-customizations && ./apply-customizations.sh`
3. Restart: `cd .. && ./down.sh && ./up.sh --customized [flags]`

## Test Without Customizations (Pristine Mode)

```bash
./down.sh                                    # Stop containers (removes customization copies)
./up.sh --baseline                           # Start pristine RHDH
# Test at http://localhost:7007
# When done, restore:
cd rhdh-customizations && ./apply-customizations.sh
cd .. && ./down.sh && ./up.sh --customized [flags]
```

## Update rhdh-local (git pull)

```bash
./down.sh                                    # Stop and remove customization copies
cd rhdh-local && git pull && cd ..           # Update the project
cd rhdh-customizations && ./apply-customizations.sh  # Reapply customizations
cd .. && ./up.sh --customized [flags]        # Restart
```

## Add an Additional Containerized Service (e.g. A Jenkins Container)

1. Add service to: `rhdh-customizations/compose.override.yaml`
   - Define image, ports, volumes, environment
   - Use container names for internal networking (e.g. `http://jenkins:8080`)
2. Add env vars to: `rhdh-customizations/.env`
3. Sync: `cd rhdh-customizations && ./apply-customizations.sh`
4. Restart: `cd .. && ./down.sh && ./up.sh --customized [flags]`

Benefits: Unified lifecycle with `up.sh`/`down.sh`, shared network, no extra_hosts workarounds.

## Share Setup with Team

```bash
./backup.sh                                  # Creates archive in ~/rhdh-local-backups/
# Share the archive; recipients follow RESTORE.md inside it
```

## View Logs

```bash
./up.sh --customized --follow-logs           # Auto-tail after startup
# Or manually:
cd rhdh-local
podman compose logs -f rhdh                  # Main RHDH logs
podman compose logs -f                       # All services
podman compose logs install-dynamic-plugins  # Plugin installation
```

## Troubleshooting: Customizations Not Applied

```bash
cd rhdh-customizations && ./apply-customizations.sh
ls -la ../rhdh-local/.env                    # Verify copy exists
ls -la ../rhdh-local/configs/dynamic-plugins/dynamic-plugins.override.yaml
cd .. && ./down.sh && ./up.sh --customized [flags]
```

## Clean Slate (Remove Everything)

```bash
./down.sh --volumes                          # Stop + remove all data
cd rhdh-customizations && ./apply-customizations.sh
cd .. && ./up.sh --customized [flags]
```
