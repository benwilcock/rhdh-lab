# RHDH Customizations

This directory contains all local customizations for your RHDH Local instance. These files are kept separate from the official `rhdh-local/` directory to maintain a clean separation between the upstream project and your local configuration.

## Directory Structure

```
rhdh-customizations/
├── README.md                           # This file
├── .env.example                        # Environment variable template
├── apply-customizations.sh             # Copy customizations into rhdh-local (apply/sync)
├── remove-customizations.sh            # Remove copies from rhdh-local (pristine state)
├── .env                                # Environment variable overrides
├── compose.override.yaml               # Compose overrides (extra_hosts, networks, etc.)
├── configs/
│   ├── app-config/
│   │   └── app-config.local.yaml       # Application configuration overrides
│   ├── dynamic-plugins/
│   │   └── dynamic-plugins.override.yaml  # Plugin configuration overrides
│   └── extra-files/
│       └── github-app-credentials.yaml # GitHub App credentials (if using)
└── developer-lightspeed/
    └── configs/
        └── app-config/
            └── app-config.lightspeed.local.yaml  # Lightspeed configuration
```

## How It Works

Customization files in this directory are **copied** into `rhdh-local/` when you run `apply-customizations.sh`. Containers only see the mounted `rhdh-local/configs/` (and similar) directories, so they need real files there—symlinks to paths outside the mount would be broken inside the container. Copy sync keeps a single source of truth here while making real files available where RHDH expects them.

1. **Clean Separation**: The `rhdh-local/` directory stays pristine; copied files are gitignored
2. **Easy Updates**: Run `git pull` in `rhdh-local/` without conflicts; re-run `apply-customizations.sh` to re-apply customizations
3. **Centralized Management**: Edit only in `rhdh-customizations/`; run `apply-customizations.sh` after changes to sync
4. **Version Control**: You can version control this directory separately if desired
5. **Easy Testing**: Run `remove-customizations.sh` to remove copies and test pristine RHDH Local, then `apply-customizations.sh` to restore

## Files Copied (by apply-customizations.sh)

When you run `./apply-customizations.sh`, these files are copied from here into `rhdh-local/`:

- `compose.override.yaml` → `rhdh-local/compose.override.yaml` (automatically merged by Compose)
- `.env` → `rhdh-local/.env`
- `configs/app-config/app-config.local.yaml` → `rhdh-local/configs/app-config/`
- `configs/dynamic-plugins/dynamic-plugins.override.yaml` → `rhdh-local/configs/dynamic-plugins/`
- `developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml` → `rhdh-local/developer-lightspeed/configs/app-config/`
- `configs/extra-files/github-app-credentials.yaml` → `rhdh-local/configs/extra-files/` (if present)

## Making Changes

### Modifying Configuration

Simply edit the files in this directory:

```bash
# Edit app configuration
code rhdh-customizations/configs/app-config/app-config.local.yaml

# Edit plugin configuration
code rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml

# Edit environment variables
code rhdh-customizations/.env
```

### Applying Changes

After modifying configuration files, **sync copies into rhdh-local**, then restart as needed:

```bash
# 1. Sync (required after any edit so containers see the latest config)
cd rhdh-customizations
./apply-customizations.sh

# 2. Restart from rhdh-local
cd ../rhdh-local
```

**Choose the right restart method based on what changed:**

| Changed File | Command | Reason |
|--------------|---------|--------|
| `app-config.*.yaml` | `podman compose restart rhdh` | Mounted config files are re-read on restart |
| `dynamic-plugins.*.yaml` | `podman compose run install-dynamic-plugins && podman compose restart rhdh` | Plugins must be reinstalled first |
| `.env` | `podman compose down && podman compose up -d` | Env vars are baked in at container creation |
| `compose.override.yaml` | `podman compose down && podman compose up -d` | Compose overrides require container recreation |

**Important:** `podman compose restart` does NOT reload `.env` or `compose.override.yaml` changes. These values are only read when the container is **created**. You must use `down` + `up` to recreate the container with new environment variables or compose overrides (like `extra_hosts`).

## Backup Strategy

### Manual Backup

To backup your customizations:

```bash
cd /Users/bwilcock/Code/redhat-developer
tar -czf ~/rhdh-customizations-backup-$(date +%Y-%m-%d).tar.gz rhdh-customizations/
```

### Using the Backup Script

The root-level `backup.sh` script should be updated to backup from this directory instead.

## Updating RHDH Local

When a new version of RHDH Local is released:

```bash
cd rhdh-local
git pull
cd ..
podman compose down
podman compose up -d
```

Your customizations remain intact in `rhdh-customizations/`. Re-run `./apply-customizations.sh` from `rhdh-customizations/` after `git pull` to sync copies into `rhdh-local/` again.

## Testing Pristine RHDH Local

To test RHDH Local without any customizations (useful for troubleshooting or comparing behavior):

1. **Remove customization copies** from rhdh-local (files in `rhdh-customizations/` are NOT deleted):
   ```bash
   cd rhdh-customizations
   ./remove-customizations.sh
   ```

2. **Test pristine RHDH**:
   ```bash
   cd ../rhdh-local
   podman compose down --volumes
   podman compose up -d
   ```

3. **Restore your customizations** when done:
   ```bash
   cd ../rhdh-customizations
   ./apply-customizations.sh
   ```

Your customization files remain safe in `rhdh-customizations/` throughout this process.

## Restoring from Scratch

If you need to restore or clone this setup on another machine:

1. Clone the RHDH Local repository:
   ```bash
   git clone https://github.com/redhat-developer/rhdh-local.git
   ```

2. Create the customizations directory:
   ```bash
   mkdir -p rhdh-customizations/configs/app-config
   mkdir -p rhdh-customizations/configs/dynamic-plugins
   mkdir -p rhdh-customizations/developer-lightspeed/configs/app-config
   ```

3. Copy your customization files to the appropriate locations in `rhdh-customizations/`

4. Apply customizations (copy into rhdh-local):
   ```bash
   cd rhdh-customizations
   ./apply-customizations.sh
   ```

5. Start RHDH:
   ```bash
   cd ../rhdh-local
   podman compose up -d
   ```

## Key Files

### compose.override.yaml
Compose override file that is automatically merged by Podman/Docker Compose. Used to add additional services and network configuration to the RHDH stack.

**Additional Services:** The `compose.override.yaml` can add entirely new services to the RHDH stack:
- Jenkins CI/CD server (unified management)
- Custom databases, caches, or tools
- Development utilities

Services defined in the override are automatically merged with the base `compose.yaml` and share the same Docker network by default, enabling direct container-to-container communication via DNS (using service/container names).

### .env
Environment variables that override `rhdh-local/default.env`. Contains:
- Database configuration
- GitHub integration credentials
- Email/SMTP settings
- Jenkins integration details
- Developer Lightspeed configuration

### configs/app-config/app-config.local.yaml
Application configuration overrides. Includes:
- Authentication (GitHub OAuth)
- RBAC permissions
- Branding and theming
- Catalog locations
- Proxy endpoints
- Frontend plugin configurations

### configs/dynamic-plugins/dynamic-plugins.override.yaml
Dynamic plugin configuration. Includes:
- GitHub integration plugins
- RBAC plugin
- Quay plugin
- Jenkins plugin
- TODO plugin
- Feedback plugin
- Notifications system
- MCP plugins

### .env.example
Template with all available environment variables and placeholder values. Copy to `.env` and fill in your credentials.

## Troubleshooting

### Customizations Not Applied

If customizations aren't taking effect, re-sync them:
```bash
cd rhdh-customizations
./apply-customizations.sh
```

Then restart RHDH (use `down`/`up` for compose.override.yaml or .env changes):
```bash
cd ../rhdh-local
podman compose down && podman compose up -d
```

### Want to Test Without Customizations

Remove customizations temporarily:
```bash
cd rhdh-customizations
./remove-customizations.sh
```

Restore when done:
```bash
./apply-customizations.sh
```

### Configuration Not Loading

Verify copied files exist:
```bash
ls -la rhdh-local/.env
ls -la rhdh-local/compose.override.yaml
ls -la rhdh-local/configs/app-config/app-config.local.yaml
```

### Service Connection Issues (Jenkins, etc.)

**For services in the unified compose stack** (like Jenkins):

If RHDH can't connect to a service defined in `compose.override.yaml`:

1. Verify the service is running:
   ```bash
   podman ps | grep service-name
   ```

2. Test connectivity using the container name and internal port:
   ```bash
   podman exec rhdh curl http://service-name:internal-port/api/json
   ```

3. Check environment variables are set correctly:
   ```bash
   podman exec rhdh env | grep SERVICE
   ```

**For external services** (not in the compose stack):

If RHDH needs to connect to external services, use the service's external hostname and ensure it's reachable from the container network.

4. If the service moves to another machine, remove its `extra_hosts` entry.

### RHDH Not Starting

Check that all referenced environment variables in `.env` and configuration files are properly set.

## Related Documentation

- [Customization Guide](../docs/customization-guide.md) -- detailed customization instructions
- [Baseline Configuration](../docs/baseline-configuration.md) -- complete list of enabled plugins and settings
- [Architecture](../docs/architecture.md) -- copy-sync system design
- [Backup and Restore](../docs/backup.md) -- creating and restoring backups
