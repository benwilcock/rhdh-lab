---
name: plugin-management
description: Manages dynamic plugins for RHDH -- discovering, enabling, disabling, and configuring plugins using the rhdh-plugin-export-overlays repository. Use when the user asks to "manage a plugin", "add a plugin to RHDH", "enable a plugin", "disable a plugin", "configure a plugin", "list available plugins", "show plugins", "install plugin", "remove plugin", "configure dynamic plugins", "add dynamic plugin", or mentions enabling, disabling, or configuring dynamic plugins.
---

# Manage Dynamic Plugins

This skill guides users through adding, enabling, disabling, and configuring dynamic plugins on RHDH. It covers the full workflow: discovering plugins, reading plugin metadata, integrating and configuring plugins, applying changes to containers, and troubleshooting.

> **Note**: This skill complements the `dynamic-plugins` workspace skill. That skill covers file layout and local plugin development; this skill covers the full end-to-end workflow for discovering and adding plugins from external sources.

## Plugin Configuration

This section helps users enable, disable, and configure dynamic plugins. It uses the [rhdh-plugin-export-overlays](https://github.com/redhat-developer/rhdh-plugin-export-overlays) repository as the authoritative source for available plugins, their packages, and configuration.

### Data Sources

All plugin information comes from the `rhdh-plugin-export-overlays` repo on the `main` branch:

- **Available plugins catalog**: `https://raw.githubusercontent.com/redhat-developer/rhdh-plugin-export-overlays/refs/heads/main/catalog-entities/extensions/plugins/all.yaml`
- **Package metadata (OCI artifact + config examples)**: `https://raw.githubusercontent.com/redhat-developer/rhdh-plugin-export-overlays/main/workspaces/<plugin-name>/metadata/<package-name>.yaml`

To list all available plugin names:
```bash
curl -s https://api.github.com/repos/redhat-developer/rhdh-plugin-export-overlays/contents/catalog-entities/extensions/plugins | jq -r '.[].name' | sed 's/\.yaml$//'
```

### Workflow: Enabling a Plugin

#### Step 1: Identify the Plugin

- Ask the user which plugin to enable. List all plugins available in the plugins catalog.
- Validate that the plugin name is valid and exists in the plugins catalog. If not try to fetch information for similar plugin names and ask user to select the correct plugin.

#### Step 2: Fetch Plugin Definition

Fetch the plugin definition YAML:
```
curl -s https://raw.githubusercontent.com/redhat-developer/rhdh-plugin-export-overlays/main/catalog-entities/extensions/plugins/<plugin-name>.yaml
```

From this file, extract:
- `metadata.name` — canonical plugin name
- `metadata.title` — display name
- `spec.packages` — the list of package names that make up this plugin
- `spec.categories` — plugin category

#### Step 3: Fetch Package Metadata

For each package listed in `spec.packages`, fetch its metadata. The metadata files live under `workspaces/<plugin-name>/metadata/`:
```
curl -s https://raw.githubusercontent.com/redhat-developer/rhdh-plugin-export-overlays/main/workspaces/<plugin-name>/metadata/<package-name>.yaml
```

From each package metadata file, extract:
- `spec.dynamicArtifact` — the OCI image reference (e.g., `oci://ghcr.io/...`)
- `spec.backstage.role` — `frontend-plugin`, `backend-plugin`, or `backend-plugin-module`
- `spec.appConfigExamples` — example configuration snippets
- `spec.partOf` — which plugin(s) this package belongs to

**Important**: Some packages may belong to a different workspace than the plugin name. If a package metadata file is not found under the plugin's workspace, check the package's own workspace (derived from the package name pattern). For example, `backstage-plugin-kubernetes-backend` lives under `workspaces/kubernetes/metadata/`.

#### Step 4: Add Packages to dynamic-plugins.override.yaml

Edit `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml` to add each package under the existing `plugins:` list.

**Critical**: The file starts with an `includes` block that loads default and base plugins. Never remove or overwrite this block -- append new entries to the existing `plugins:` list. If creating the file from scratch, ensure it begins with:
```yaml
includes:
   - dynamic-plugins.default.yaml
   - dynamic-plugins.yaml
```

Three package reference formats exist:

**OCI-based from rhdh-plugin-export-overlays** (most common — use `spec.dynamicArtifact` value):
```yaml
plugins:
  - package: 'oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-argocd:bs_1.45.3__2.4.3!backstage-community-plugin-argocd'
    disabled: false
```

**OCI-based from Red Hat registry** (for Red Hat-shipped plugins):
```yaml
plugins:
  - package: 'oci://registry.access.redhat.com/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator:{{inherit}}'
    disabled: false
```

**Local path** (built-in plugins already bundled):
```yaml
plugins:
  - package: ./dynamic-plugins/dist/backstage-community-plugin-catalog-backend-module-keycloak-dynamic
    disabled: false
```

**For packages with frontend plugin configuration** (mount points, translation resources, etc.):
```yaml
plugins:
  - package: 'oci://ghcr.io/...'
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          <plugin-config-key>:
            mountPoints:
              - mountPoint: entity.page.overview/cards
                importName: ComponentName
                config:
                  layout:
                    gridColumnEnd:
                      lg: span 8
                      xs: span 12
                  if:
                    allOf:
                      - conditionName
            translationResources:
              - importName: translationImport
                module: ModuleName
                ref: translationRef
```

The `pluginConfig` content comes directly from `spec.appConfigExamples[].content.dynamicPlugins` in the package metadata. Include it exactly as specified.

**For packages with dependencies** on other plugins:
```yaml
plugins:
  - package: 'oci://...'
    disabled: false
    dependencies:
      - ref: sonataflow
```

**Common mount points:**

| Mount Point | Location |
|---|---|
| `entity.page.overview/cards` | Entity overview page cards |
| `entity.page.ci/cards` | Entity CI tab cards |
| `entity.page.cd/cards` | Entity CD tab cards |
| `entity.page.kubernetes/cards` | Entity Kubernetes tab cards |
| `entity.page.topology/cards` | Entity Topology tab cards |
| `entity.page.api/cards` | Entity API tab cards |

#### Step 5: Add Backend Configuration (if needed)

If any package metadata includes `spec.appConfigExamples` with backend configuration (anything outside the `dynamicPlugins` key), add that configuration to `rhdh-customizations/configs/app-config/app-config.local.yaml`.

**Service integration example (ArgoCD):**
```yaml
argocd:
  username: ${ARGOCD_USERNAME}
  password: ${ARGOCD_PASSWORD}
  appLocatorMethods:
    - type: config
      instances:
        - name: argoInstance1
          url: ${ARGOCD_INSTANCE1_URL}
          token: ${ARGOCD_AUTH_TOKEN}
```

**Kubernetes plugin example:**
```yaml
kubernetes:
  serviceLocatorMethod:
    type: multiTenant
  clusterLocatorMethods:
    - type: config
      clusters:
        - url: ${K8S_CLUSTER_URL}
          name: cluster-name
          authProvider: serviceAccount
          serviceAccountToken: ${K8S_SA_TOKEN}
```

#### Step 6: Add Required Secrets/Environment Variables

If the backend configuration references environment variables (e.g., `${ARGOCD_USERNAME}`), inform the user they need to add the values to the `rhdh-customizations/.env` file using bare `VAR=value` format (no `export`, no quotes):
```
ARGOCD_USERNAME=my-username
ARGOCD_PASSWORD=my-password
```
This file overrides `rhdh-local/default.env` and is copied into `rhdh-local/.env` by `apply-customizations.sh`.

#### Step 7: Present Summary

After making changes, present a summary:
- Which packages were added to `dynamic-plugins.override.yaml`
- What app-config was added (if any)
- What environment variables need to be set in `.env` (if any)
- The apply-and-restart commands from Step 8

#### Step 8: Apply and Restart

Configuration edits in `rhdh-customizations/` must be copied into `rhdh-local/` and containers restarted for changes to take effect. Run:
```bash
cd rhdh-customizations && ./apply-customizations.sh
cd .. && ./down.sh && ./up.sh --customized
```
Add `--lightspeed`, `--orchestrator`, or `--both` flags if those components are enabled.

### Workflow: Disabling a Plugin

1. Read `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml`
2. Find the package entries for the plugin
3. Either set `disabled: true` or remove the entries entirely
4. If removing, also clean up any related configuration from `rhdh-customizations/configs/app-config/app-config.local.yaml`
5. Apply and restart (see Step 8 above)

### Workflow: Checking Current Plugin Configuration

1. Read `rhdh-customizations/configs/dynamic-plugins/dynamic-plugins.override.yaml` to show currently enabled plugins
2. Cross-reference with the plugin catalog to identify plugin names

### Plugin Configuration Notes

- **Package names vs plugin names**: A single plugin (e.g., `argocd`) consists of multiple packages (e.g., `backstage-community-plugin-redhat-argocd` frontend + `backstage-community-plugin-redhat-argocd-backend`). ALL packages for a plugin MUST be enabled together.
- **OCI references**: Always use the `spec.dynamicArtifact` value from the package metadata as the package reference. DO NOT construct OCI references manually.
- **Frontend plugin config**: Frontend plugins typically require `pluginConfig` with mount points and other UI wiring. Always include the config from `appConfigExamples`.
- **`{{inherit}}`**: Some older plugins use `{{inherit}}` in their OCI reference — this is a special marker for the Red Hat registry. For plugins from the export-overlays repo, always use the full OCI reference from `spec.dynamicArtifact`.
- **Order matters**: Backend plugins should generally be listed before their corresponding frontend plugins in `dynamic-plugins.override.yaml`.

### Handling Data Source Failures

The GitHub API has a 60 request/hour rate limit for unauthenticated requests. If `curl` calls fail:
- **403 rate limit**: Wait and retry, or ask the user for a GitHub personal access token to pass via `Authorization: token <PAT>` header.
- **404 not found**: The repo structure may have changed. Ask the user to verify the plugin name, or browse the repo manually at `https://github.com/redhat-developer/rhdh-plugin-export-overlays`.
- **Package metadata not found**: Some packages live in a different workspace directory than the plugin name (see Step 3 note). Try deriving the workspace name from the package name itself.

### Common Issues

- **Missing environment variables**: Backend plugin modules may require config values (e.g., `jira.baseUrl`) backed by env vars that aren't set. Fix: either add the values to `.env` or disable the module that requires them.
- **Plugin initialization failure**: One failing plugin module can block the entire RHDH startup. Check logs for `threw an error during startup` messages to identify which module is failing.
- **Homepage 404s after plugin changes**: The `includes` block at the top of `dynamic-plugins.override.yaml` was likely removed. Ensure `dynamic-plugins.default.yaml` is included.