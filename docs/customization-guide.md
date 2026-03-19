# Customization Guide

How to customize your RHDH Local instance using the copy-sync system.

## Overview

All customizations live in `rhdh-customizations/`. Files there are copied into `rhdh-local/` by `apply-customizations.sh` so that containers can read them. The `up.sh` and `down.sh` scripts manage this automatically.

## Directory Layout

```
rhdh-customizations/
├── .env                              # Environment variable overrides
├── .env.example                      # Template with placeholder values
├── compose.override.yaml             # Compose overrides (extra services, ports)
├── apply-customizations.sh           # Copy customizations into rhdh-local
├── remove-customizations.sh          # Remove copies (restore pristine state)
├── configs/
│   ├── app-config/
│   │   └── app-config.local.yaml     # Application configuration overrides
│   ├── dynamic-plugins/
│   │   └── dynamic-plugins.override.yaml  # Plugin configuration
│   ├── catalog-entities/
│   │   └── users.override.yaml       # Custom user/group entities
│   ├── extra-files/
│   │   └── github-app-credentials.yaml  # GitHub App credentials (if used)
│   └── translations/
│       └── *.json                    # i18n translation files
└── developer-lightspeed/
    └── configs/app-config/
        └── app-config.lightspeed.local.yaml  # Lightspeed configuration
```

## Making Changes

### 1. Edit files in `rhdh-customizations/`

```bash
# App configuration
code rhdh-customizations/configs/app-config/app-config.local.yaml

# Plugin configuration
code rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml

# Environment variables
code rhdh-customizations/.env
```

### 2. Restart to apply

The restart method depends on what changed:

| Changed File | Restart Method | Why |
|---|---|---|
| `app-config.*.yaml` | `podman compose restart rhdh` | Config files are re-read on restart |
| `dynamic-plugins.*.yaml` | `podman compose run install-dynamic-plugins && podman compose restart rhdh` | Plugins must be reinstalled |
| `.env` | `podman compose down && podman compose up -d` | Env vars are baked in at container creation |
| `compose.override.yaml` | `podman compose down && podman compose up -d` | Compose overrides require container recreation |

Or use the lifecycle scripts, which handle everything:

```bash
./down.sh --keep-volumes
./up.sh --customized
```

## Key Configuration Files

### `.env` -- Environment Variables

Overrides values from `rhdh-local/default.env`. Contains credentials, URLs, and feature flags. See `.env.example` for all available variables with descriptions.

### `app-config.local.yaml` -- Application Configuration

The primary RHDH configuration file. Controls:
- Authentication providers (GitHub OAuth)
- RBAC and permissions
- Branding and theming
- Catalog locations and providers
- Proxy endpoints
- Frontend plugin settings

### `dynamic-plugins.override.yaml` -- Plugin Configuration

Controls which dynamic plugins are enabled and how they are configured:

```yaml
includes:
  - dynamic-plugins.default.yaml

plugins:
  - package: ./path/to/plugin
    disabled: false
    pluginConfig:
      # plugin-specific settings
```

### `compose.override.yaml` -- Compose Overrides

Automatically merged with the base `compose.yaml` by Docker/Podman Compose. Use this to:
- Add extra services (e.g., Jenkins) to the RHDH stack
- Expose additional ports
- Add volume mounts
- Configure dependencies between services

Services defined here share the same Docker network as RHDH, enabling direct container-to-container communication via DNS.

## Initial Setup

If starting from scratch (no existing `.env`):

```bash
cd rhdh-customizations
cp .env.example .env
# Edit .env with your credentials
```

Then start RHDH:

```bash
cd ..
./up.sh --customized
```

## Backup

Your customizations are the most important thing to preserve. The backup script archives them:

```bash
./backup.sh
```

See [Backup and Restore](backup.md) for details.
