# Architecture

## Overview

This workspace implements a **copy-sync customization system** for RHDH Local that maintains complete separation between the official project and local customizations. Customization files are copied (not symlinked) into `rhdh-local/` so that container volume mounts see real files.

## Design Goals

1. **Project Purity** -- Keep `rhdh-local/` pristine and matching the upstream repository
2. **Easy Updates** -- Update RHDH Local with `git pull` without merge conflicts
3. **Portability** -- Share complete setups across team members and systems
4. **Flexibility** -- Test with or without customizations easily
5. **Clarity** -- Clear separation between defaults and user configuration

## Directory Structure

```
rhdh-lab/
├── up.sh                             # Start RHDH (manages customizations automatically)
├── down.sh                           # Stop RHDH (always restores pristine state)
├── backup.sh                         # Create portable backup archive
│
├── rhdh-customizations/              # ALL CUSTOMIZATIONS HERE
│   ├── apply-customizations.sh       # Copy customizations into rhdh-local
│   ├── remove-customizations.sh      # Remove copies (restore pristine state)
│   ├── .env                          # Environment variable overrides
│   ├── compose.override.yaml         # Compose overrides (extra services, ports)
│   ├── configs/
│   │   ├── app-config/
│   │   │   └── app-config.local.yaml
│   │   ├── dynamic-plugins/
│   │   │   └── dynamic-plugins.override.yaml
│   │   ├── catalog-entities/
│   │   │   └── users.override.yaml
│   │   ├── extra-files/
│   │   │   └── github-app-credentials.yaml
│   │   └── translations/
│   │       └── *.json
│   └── developer-lightspeed/
│       └── configs/app-config/
│           └── app-config.lightspeed.local.yaml
│
├── rhdh-local/                       # PRISTINE -- upstream git submodule
│   ├── compose.yaml                  # Base compose configuration
│   ├── default.env                   # Default environment variables
│   ├── configs/                      # Default configuration files
│   └── ...
│
└── docs/                             # Documentation
```

## The Copy-Sync System

### How It Works

1. **Single source of truth** -- All user configuration lives in `rhdh-customizations/`
2. **Copy sync** -- `apply-customizations.sh` copies files into `rhdh-local/` so containers see real files (symlinks would break inside container volume mounts)
3. **RHDH reads expected paths** -- The RHDH container and plugin installer read configuration from their standard locations inside `rhdh-local/`
4. **Re-sync after edits** -- After editing files in `rhdh-customizations/`, run `apply-customizations.sh` to update the copies

### Copy Map

| Destination (in `rhdh-local/`) | Source (in `rhdh-customizations/`) |
|---|---|
| `.env` | `.env` |
| `compose.override.yaml` | `compose.override.yaml` |
| `configs/app-config/app-config.local.yaml` | `configs/app-config/app-config.local.yaml` |
| `configs/dynamic-plugins/dynamic-plugins.override.yaml` | `configs/dynamic-plugins/dynamic-plugins.override.yaml` |
| `configs/catalog-entities/users.override.yaml` | `configs/catalog-entities/users.override.yaml` |
| `configs/extra-files/github-app-credentials.yaml` | `configs/extra-files/github-app-credentials.yaml` (if present) |
| `developer-lightspeed/.../app-config.lightspeed.local.yaml` | `developer-lightspeed/.../app-config.lightspeed.local.yaml` |

### Why Copies Instead of Symlinks?

Docker and Podman mount host directories into containers. If `rhdh-local/configs/` is mounted, a symlink pointing to `../../rhdh-customizations/some-file` resolves on the host but **not inside the container** (the target path does not exist in the container filesystem). Copying the actual file content ensures containers always see valid files.

## Configuration Precedence

When RHDH loads configuration (highest precedence wins):

1. Environment variables (from `.env`, copied into `rhdh-local/`)
2. `app-config.local.yaml` (copied) -- **highest file precedence**
3. `app-config.lightspeed.local.yaml` (copied, if Lightspeed enabled)
4. `dynamic-plugins.override.yaml` (copied)
5. `app-config.yaml` (default, in `rhdh-local/`)
6. `dynamic-plugins.default.yaml` (default, in `rhdh-local/`)
7. `default.env` (in `rhdh-local/`) -- **lowest precedence**

## Two Operating Modes

### Customized Mode (copies applied)

Your custom settings are active: plugins, authentication, branding, integrations.

```bash
./up.sh --customized
```

### Baseline Mode (copies removed)

Pristine RHDH defaults only: guest authentication, default plugins, no integrations.

```bash
./up.sh --baseline
```

See the [Testing Guide](testing.md) for detailed workflows comparing the two modes.

## Git Integration

### rhdh-local/ as a Submodule

The `rhdh-local/` directory is a git submodule pointing to `https://github.com/redhat-developer/rhdh-local.git`. This means:

- The parent repo tracks a specific commit of the upstream project
- `git clone --recurse-submodules` fetches everything in one step
- Updates are deliberate: `git submodule update --remote`
- The `.gitignore` inside `rhdh-local/` excludes all customization file patterns, so copied files never appear as submodule modifications

### Why the Submodule Stays Clean

The upstream `.gitignore` in `rhdh-local/` already ignores patterns like `*.local.yaml`, `*.override.yaml`, `.env`, and `compose.override.yaml`. After `apply-customizations.sh` copies files in, `git status` inside the submodule still shows a clean working tree.

## Design Principles

1. **Separation of Concerns** -- Official project separate from customizations
2. **Container-Safe** -- Real file copies so container mounts work correctly
3. **Simplicity** -- Two scripts to apply or remove customizations
4. **Safety** -- Original project is never modified; only gitignored copies are added
5. **Portability** -- Entire setup can be archived, shared, and restored
6. **Flexibility** -- Switch between pristine and customized modes in seconds

## Benefits

**For individual users:**
- Clean `git pull` updates with no merge conflicts
- One directory contains all customizations (easy backup)
- Quick switching between pristine and customized modes

**For teams:**
- Portable setups via git clone or backup archives
- Consistent environments across machines
- Fast onboarding for new team members

**For maintainers:**
- Clear boundary between upstream project and user configuration
- Easy to test pristine vs. customized behavior for debugging
- No risk of accidentally modifying upstream tracked files
