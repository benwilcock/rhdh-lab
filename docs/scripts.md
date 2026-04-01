# Scripts Reference

Complete reference for all scripts in this workspace.

## up.sh -- Start RHDH

Starts RHDH Local with your choice of mode, optional components, and Lightspeed configuration.

**Location:** `./up.sh` (workspace root)

### Usage

```bash
./up.sh [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--baseline` | Start without customizations (pristine RHDH) |
| `--customized` | Start with customizations applied (default) |
| `--lightspeed` | Include Developer Lightspeed |
| `--orchestrator` | Include Orchestrator |
| `--both` | Include both Lightspeed and Orchestrator |
| `--ollama` | Lightspeed with Ollama local LLM (implies `--lightspeed`) |
| `--safety-guard` | Enable safety guard (implies `--lightspeed`) |
| `--follow-logs`, `-f` | Tail logs after startup |
| `--last` | Reuse the last successful startup options (see below) |
| `--help`, `-h` | Show help message |

### Last run settings (`--last`)

After a successful `podman compose up -d` / `docker compose up -d`, `up.sh` writes the effective configuration to **`.last-run-settings`** in the workspace root (gitignored). The file stores mode, Lightspeed/Orchestrator toggles, Lightspeed provider, safety guard, and follow-logs — not the container runtime, which is always auto-detected on each run.

Use `./up.sh --last` to start again with those saved options (non-interactive, no other configuration flags). If the file is missing or invalid, the script exits with an error until you complete at least one successful start with explicit flags or interactive mode.

### Behavior

1. Detects container runtime (Podman or Docker)
2. Manages customizations:
   - `--customized`: runs `apply-customizations.sh` to copy files into `rhdh-local/`
   - `--baseline`: runs `remove-customizations.sh` to remove copies
3. Builds the compose command with appropriate `-f` flags for selected components
4. Executes `podman compose up -d` (or `docker compose`)
5. On success, writes `.last-run-settings` for a future `./up.sh --last`
6. Displays access URL and log commands

### Interactive Mode

When run without arguments, the script prompts for:
1. Mode (customized or baseline)
2. Optional components (none, Lightspeed, Orchestrator, or both)
3. Lightspeed configuration (provider and safety guard, if applicable)
4. Whether to follow logs after startup
5. Confirmation before proceeding

### Compose File Merging

The script builds compose commands by stacking `-f` flags:

```bash
# Base only
podman compose -f compose.yaml up -d

# With Lightspeed
podman compose -f compose.yaml -f developer-lightspeed/compose.yaml up -d

# With both components
podman compose -f compose.yaml \
  -f developer-lightspeed/compose.yaml \
  -f orchestrator/compose.yaml up -d
```

Lightspeed has additional compose files for provider and safety guard combinations:
- `developer-lightspeed/compose.yaml` -- base
- `developer-lightspeed/compose-with-ollama.yaml` -- includes Ollama container
- `developer-lightspeed/compose-with-safety-guard.yaml` -- base with safety guard
- `developer-lightspeed/compose-with-safety-guard-ollama.yaml` -- Ollama with safety guard

---

## down.sh -- Stop RHDH

Stops RHDH Local containers and always removes customization copies to restore pristine state.

**Location:** `./down.sh` (workspace root)

### Usage

```bash
./down.sh [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--volumes`, `-v` | Remove volumes (clears plugin cache and database) |
| `--keep-volumes` | Keep volumes intact (default) |
| `--help`, `-h` | Show help message |

### Behavior

1. Detects container runtime
2. Checks for running containers
3. **Always removes customization copies** from `rhdh-local/` (runs `remove-customizations.sh`)
4. Includes all possible compose files in the `down` command to ensure every container is stopped
5. Executes `podman compose down` with optional `--volumes`

Your source files in `rhdh-customizations/` are never touched.

### Volume Removal

**When to remove volumes (`--volumes`):**
- Troubleshooting plugin issues
- Testing clean installations
- Clearing corrupted data
- Switching between major RHDH versions

**When to keep volumes (default):**
- Normal shutdown for a fast restart
- Preserving catalog data and installed plugins
- Day-to-day development

### Why All Compose Files Are Included

`compose down` is non-destructive for services that are not running. Including all compose files (base, Lightspeed, Orchestrator) ensures every possible container is stopped, regardless of which combination was used at startup.

---

## backup.sh -- Backup Workspace

Creates a portable backup archive of your customizations and workspace files.

**Location:** `./backup.sh` (workspace root)

### Usage

```bash
./backup.sh              # Interactive
./backup.sh --auto       # Non-interactive
```

### What Gets Backed Up

- `rhdh-customizations/` -- all configuration files and scripts
- `backup.sh` -- the backup script itself
- Auto-generated `RESTORE.md` with step-by-step restore instructions

### Backup Location

```
~/rhdh-local-backups/
└── rhdh-local-setup-backup_YYYY-MM-DD_HH-MM-SS.tar.gz
```

See [Backup and Restore](backup.md) for full documentation.

---

## apply-customizations.sh -- Sync Customizations

Copies customization files from `rhdh-customizations/` into `rhdh-local/` so containers can read them.

**Location:** `rhdh-customizations/apply-customizations.sh`

```bash
cd rhdh-customizations && ./apply-customizations.sh
```

`up.sh --customized` calls this automatically.

---

## remove-customizations.sh -- Remove Customizations

Removes customization copies from `rhdh-local/` to restore pristine state. Source files in `rhdh-customizations/` are never touched.

**Location:** `rhdh-customizations/remove-customizations.sh`

```bash
cd rhdh-customizations && ./remove-customizations.sh
```

`up.sh --baseline` and `down.sh` call this automatically.

---

## Script Relationships

```
up.sh ──────────┬── apply-customizations.sh   (customized mode)
                └── remove-customizations.sh  (baseline mode)

down.sh ────────── remove-customizations.sh   (always)
                   podman compose down

backup.sh ──────── creates archive in ~/rhdh-local-backups/
```

### Startup Flow (Customized)

```
./up.sh --customized
  -> detect podman/docker
  -> run apply-customizations.sh
  -> build compose command
  -> podman compose -f compose.yaml [...] up -d
```

### Shutdown Flow

```
./down.sh
  -> detect podman/docker
  -> run remove-customizations.sh (always)
  -> podman compose down [--volumes]
```

---

## Error Handling

All scripts include:
- Container runtime detection (fails if neither Podman nor Docker is found)
- Directory validation (ensures required paths exist)
- Script availability checks
- Confirmation prompts in interactive mode
- Colored output (blue=info, green=success, yellow=warning, red=error)

---

## Best Practices

- **Always use `up.sh` and `down.sh`** for container lifecycle -- avoid running `podman compose` directly
- Use `--volumes` when troubleshooting plugin issues
- Use non-interactive flags (`--customized`, `--keep-volumes`, etc.) in automation scripts
- Run `./backup.sh` before making major configuration changes
