---
name: rhdh-lifecycle
description: Performs common RHDH Local tasks -- starting, stopping, restarting containers, applying customizations, viewing logs, updating, and backing up. Use when the user asks to "start RHDH", "stop RHDH", "restart RHDH", "bring up RHDH", "bring down RHDH", "apply customizations", "view logs", "check status", "update RHDH", "backup", "run baseline", "run with lightspeed", "run with orchestrator", "run with ollama", or mentions starting, stopping, restarting, or managing the RHDH Local environment.
---

# RHDH Local Lifecycle Management

Manage the RHDH Local development environment: start, stop, restart, apply configuration changes, view logs, check status, update, and back up.

> Complements the `plugin-management` skill (which covers discovering and configuring plugins). This skill covers container lifecycle and day-to-day operational workflows.

## Key Paths

All commands run from the **workspace root** (the directory containing `up.sh` and `down.sh`) unless noted otherwise.

| Item | Path |
|------|------|
| Startup script | `./up.sh` |
| Shutdown script | `./down.sh` |
| Apply customizations | `cd rhdh-customizations && ./apply-customizations.sh` |
| Remove customizations | `cd rhdh-customizations && ./remove-customizations.sh` |
| Backup script | `./backup.sh` |
| Environment overrides | `rhdh-customizations/.env` |
| App config overrides | `rhdh-customizations/configs/app-config/app-config.local.yaml` |
| Plugin overrides | `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml` |
| Compose overrides | `rhdh-customizations/compose.override.yaml` |
| Lightspeed config | `rhdh-customizations/developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml` |

## Starting RHDH

Use `./up.sh` with flags. Never use `podman compose up` directly.

### Flag Reference

| Flag | Effect |
|------|--------|
| `--baseline` | Pristine RHDH, no customizations |
| `--customized` | Apply customizations from `rhdh-customizations/` |
| `--lightspeed` | Enable Developer Lightspeed (BYOM -- requires external LLM config) |
| `--ollama` | Enable Lightspeed with local Ollama LLM |
| `--safety-guard` | Enable Llama Guard content filtering (with Lightspeed) |
| `--orchestrator` | Enable Orchestrator (Sonataflow) |
| `--both` | Enable both Lightspeed and Orchestrator |
| `--follow-logs` / `-f` | Tail container logs after startup |
| `--last` | Repeat last successful startup (reads `.last-run-settings`; no other config flags) |

### Common Start Commands

```bash
# Customized RHDH only
./up.sh --customized

# Customized with local Ollama Lightspeed
./up.sh --customized --ollama

# Customized with Ollama + safety guard
./up.sh --customized --ollama --safety-guard

# Customized with external LLM Lightspeed (BYOM)
./up.sh --customized --lightspeed

# Customized with Orchestrator
./up.sh --customized --orchestrator

# Full stack (Lightspeed + Orchestrator + Ollama)
./up.sh --customized --both --ollama

# Full stack and tail logs
./up.sh --customized --both --ollama --follow-logs

# Pristine baseline (no customizations)
./up.sh --baseline

# Interactive mode (prompts for options)
./up.sh

# Same flags as your last successful start (after one successful run)
./up.sh --last
```

### Choosing Start Flags

Ask the user what they need, or infer from context:

- **Just testing catalog/plugins/config?** --> `--customized`
- **Testing AI assistant?** --> `--customized --ollama` (local) or `--customized --lightspeed` (remote LLM)
- **Testing workflows?** --> `--customized --orchestrator`
- **Need everything?** --> `--customized --both --ollama`
- **Testing pristine upstream?** --> `--baseline`

## Stopping RHDH

Use `./down.sh`. Never use `podman compose down` directly.

```bash
# Stop, keep volumes (fast restart)
./down.sh --keep-volumes

# Stop, remove all volumes (clean slate)
./down.sh --volumes

# Interactive mode (prompts for volume choice)
./down.sh
```

`down.sh` always removes customization copies from `rhdh-local/` to restore pristine state. Customization source files in `rhdh-customizations/` are never touched.

## Restarting RHDH

There is no restart script. Always stop then start:

```bash
# Quick restart (preserves plugin cache and DB)
./down.sh --keep-volumes
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./up.sh --customized   # add flags as needed

# Full clean restart (rebuilds everything)
./down.sh --volumes
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./up.sh --customized   # add flags as needed
```

**CRITICAL**: When Lightspeed or Orchestrator containers are running, you MUST restart all containers together. Never restart individual services -- it breaks network namespace sharing and causes 504 errors.

## Applying Configuration Changes

After editing any file in `rhdh-customizations/`:

```bash
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./down.sh --keep-volumes
./up.sh --customized   # add flags as needed
```

The apply script copies customization files into `rhdh-local/` where containers can read them.

### What Gets Copied

| Source (in `rhdh-customizations/`) | Destination (in `rhdh-local/`) |
|---|---|
| `.env` | `.env` |
| `compose.override.yaml` | `compose.override.yaml` |
| `configs/app-config/app-config.local.yaml` | `configs/app-config/app-config.local.yaml` |
| `configs/dynamic-plugins/dynamic-plugins.override.yaml` | `configs/dynamic-plugins/dynamic-plugins.override.yaml` |
| `configs/catalog-entities/*.override.yaml` | `configs/catalog-entities/*.override.yaml` |
| `configs/extra-files/*` | `configs/extra-files/*` |
| `configs/translations/*.json` | `configs/translations/*.json` |
| `developer-lightspeed/...` | `developer-lightspeed/...` |

## Viewing Logs

```bash
# Tail all container logs
cd rhdh-local && podman compose logs -f

# Tail only RHDH logs
cd rhdh-local && podman compose logs -f rhdh

# Tail only plugin installer logs
cd rhdh-local && podman compose logs -f install-dynamic-plugins

# Tail Lightspeed logs (if running)
cd rhdh-local && podman compose logs -f lightspeed-core-service

# Show last 100 lines
cd rhdh-local && podman compose logs --tail 100 rhdh
```

Replace `podman` with `docker` if using Docker.

## Checking Status

```bash
# List running containers
cd rhdh-local && podman compose ps

# Check if RHDH is responding
curl -s -o /dev/null -w "%{http_code}" http://localhost:7007

# Check RHDH health
curl -s http://localhost:7007/healthcheck
```

## Updating RHDH Local

Pull latest changes from the upstream repository:

```bash
./down.sh --keep-volumes
cd rhdh-local && git pull && cd ..
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./up.sh --customized   # add flags as needed
```

## Backing Up

```bash
# Interactive backup
./backup.sh

# Automated backup (no prompts)
./backup.sh --auto
```

Backups go to `~/rhdh-local-backups/` and include `rhdh-customizations/`, `.cursor/`, and documentation files.

## Testing Pristine vs Customized

```bash
# Test pristine (removes all customizations)
cd rhdh-customizations && ./remove-customizations.sh && cd ..
./up.sh --baseline

# Verify rhdh-local is clean
cd rhdh-local && git status   # should show "working tree clean"

# Switch back to customized
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./up.sh --customized
```

## Troubleshooting

For common issues and extended workflows, see [reference.md](reference.md).

Quick fixes:

| Symptom | Cause | Fix |
|---------|-------|-----|
| 504 Gateway Timeout | Network namespace desync | `./down.sh && ./up.sh` (restart ALL containers) |
| RHDH won't start | Plugin init failure | Check `podman compose logs install-dynamic-plugins` |
| Config changes not visible | Forgot to apply | `cd rhdh-customizations && ./apply-customizations.sh` then restart |
| `git status` dirty in `rhdh-local/` | Direct edits or stale copies | `cd rhdh-customizations && ./remove-customizations.sh` |
| Port 7007 already in use | Previous containers still running | `./down.sh --volumes` then retry |

## Architecture Reminders

1. **Edit in `rhdh-customizations/`** -- never modify `rhdh-local/` directly
2. **Use scripts** -- `up.sh`/`down.sh`, not raw `podman compose`
3. **Apply before start** -- always run `apply-customizations.sh` before `up.sh --customized`
4. **Restart together** -- when Lightspeed/Orchestrator are enabled, restart all containers as a group
5. **Document changes** -- update relevant docs when making significant changes
