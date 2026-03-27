---
name: dynamic-plugins
description: "Dynamic plugin configuration, installation, sources, and local development for RHDH"
---

# Dynamic Plugin System

## Plugin Configuration Files

- `dynamic-plugins.default.yaml` in `rhdh-local/configs/dynamic-plugins/` -- Default plugins (version-controlled, don't edit)
- `dynamic-plugins.override.yaml` in `rhdh-customizations/configs/dynamic-plugins/` -- Your plugin overrides (edit this one)
- `dynamic-plugins.override.example.yaml` in `rhdh-local/configs/dynamic-plugins/` -- Template for creating overrides
- `dynamic-plugins.extensions.yaml` -- Generated at runtime by the Extensions UI

## Plugin Sources

Plugins can be loaded from:

- **Container registry**: `oci://docker.io/org/image:tag!plugin-name`
- **Tarball URL**: `https://example.com/plugin.tgz`
- **Local directory**: `./local-plugins/plugin-name`
- **Container path**: `./dynamic-plugins/dist/plugin-name`

## Adding or Modifying Plugins

1. Edit the override file:
   ```bash
   code rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml
   ```

2. Add your plugin configuration:
   ```yaml
   includes:
     - dynamic-plugins.default.yaml

   plugins:
     - package: oci://docker.io/org/image:tag!plugin-name
       disabled: false
       pluginConfig:
         # Plugin-specific configuration
   ```

3. Sync and restart:
   ```bash
   cd rhdh-customizations && ./apply-customizations.sh
   cd .. && ./down.sh && ./up.sh --customized [flags]
   ```

## Local Plugin Development

1. Place plugins in `rhdh-local/local-plugins/`
2. Use `compose-dynamic-plugins-root.yaml` to mount the host directory
3. Reference in your override:
   ```yaml
   plugins:
     - package: ./local-plugins/your-plugin
       disabled: false
   ```

## Optional Component Plugins

### Developer Lightspeed
- Plugin config: `developer-lightspeed/configs/dynamic-plugins/dynamic-plugins.lightspeed.yaml`
- Enable by including in your override file
- Start with: `./up.sh --customized --lightspeed` (or `--both`)

### Orchestrator
- Plugin config: `orchestrator/configs/dynamic-plugins/dynamic-plugins.yaml`
- Enable by including in your override file
- Start with: `./up.sh --customized --orchestrator` (or `--both`)
