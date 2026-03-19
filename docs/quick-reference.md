# Quick Reference

Command cheat sheet for common rhdh-lab operations.

## Start RHDH

```bash
./up.sh                              # Interactive (prompts for options)
./up.sh --customized                 # With your customizations (fastest)
./up.sh --customized --lightspeed    # With Developer Lightspeed
./up.sh --customized --both          # All components enabled
./up.sh --customized --follow-logs   # Start and tail logs
./up.sh --baseline                   # Pristine RHDH (no customizations)
./up.sh --customized --ollama        # Lightspeed with local LLM (Ollama)
```

## Stop RHDH

```bash
./down.sh                            # Interactive (prompts about volumes)
./down.sh --keep-volumes             # Keep data (fast restart)
./down.sh --volumes                  # Clean slate (removes all data)
```

`down.sh` always removes customization copies from `rhdh-local/`, restoring pristine state.

## View Logs

```bash
cd rhdh-local
podman compose logs -f rhdh          # Follow RHDH logs
podman compose logs -f               # Follow all services
podman compose logs install-dynamic-plugins  # Plugin installation log
```

## Access URLs

- **RHDH**: <http://localhost:7007>
- **TechDocs**: <http://localhost:7007/docs>

## Common Workflows

### Quick Restart (keep data)

```bash
./down.sh --keep-volumes
./up.sh --customized
```

### Fresh Start (troubleshooting)

```bash
./down.sh --volumes
./up.sh --customized
```

### Apply Configuration Changes

```bash
# 1. Edit files in rhdh-customizations/
# 2. Restart
./down.sh --keep-volumes
./up.sh --customized
```

### Update rhdh-local (git pull)

```bash
./down.sh
cd rhdh-local && git pull && cd ..
./up.sh --customized
```

### Test Baseline vs. Customized

```bash
./up.sh --baseline                   # Test default behavior
# ... verify at http://localhost:7007 ...
./down.sh
./up.sh --customized                 # Compare with your config
```

### Create a Backup

```bash
./backup.sh
# Archives saved to ~/rhdh-local-backups/
```

## File Locations

### Your Customizations

```
rhdh-customizations/
├── .env                              # Environment overrides
├── compose.override.yaml             # Compose overrides
├── configs/app-config/
│   └── app-config.local.yaml         # App configuration
├── configs/dynamic-plugins/
│   └── dynamic-plugins.override.yaml # Plugin configuration
└── developer-lightspeed/configs/app-config/
    └── app-config.lightspeed.local.yaml
```

### Upstream Defaults (read-only)

```
rhdh-local/
├── compose.yaml                      # Base compose
├── default.env                       # Default environment
├── configs/app-config/
│   └── app-config.yaml               # Default app config
└── configs/dynamic-plugins/
    └── dynamic-plugins.default.yaml   # Default plugins
```

## Script Flags

### up.sh

| Flag | Description |
|------|-------------|
| `--baseline` | Start without customizations |
| `--customized` | Start with customizations (default) |
| `--lightspeed` | Include Developer Lightspeed |
| `--orchestrator` | Include Orchestrator |
| `--both` | Include Lightspeed and Orchestrator |
| `--ollama` | Lightspeed with Ollama (local LLM) |
| `--safety-guard` | Lightspeed with safety guard |
| `--follow-logs`, `-f` | Tail logs after startup |
| `--help` | Show help |

### down.sh

| Flag | Description |
|------|-------------|
| `--volumes`, `-v` | Remove volumes (clean slate) |
| `--keep-volumes` | Keep volumes (default) |
| `--help` | Show help |

## Container Commands

```bash
cd rhdh-local
podman compose ps                    # List containers
podman compose exec rhdh bash        # Shell into RHDH container
podman stats                         # Resource usage
```

## Help

```bash
./up.sh --help
./down.sh --help
```
