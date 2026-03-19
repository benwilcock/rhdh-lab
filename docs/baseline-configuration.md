# Baseline Configuration Reference

Reference documentation for all enabled plugins and configuration in this RHDH instance.

## Dynamic Plugins

### GitHub Integration Suite

Provides GitHub authentication, catalog import, scaffolder actions, and PR/Issues integration.

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-plugin-catalog-backend-module-github-dynamic` | GitHub catalog integration | Container built-in |
| `backstage-plugin-catalog-backend-module-github-org-dynamic` | GitHub organization ingestion | Container built-in |
| `backstage-plugin-scaffolder-backend-module-github-dynamic` | GitHub scaffolder actions | Container built-in |
| `roadiehq-backstage-plugin-github-pull-requests` | Display GitHub pull requests | Container built-in |
| `backstage-community-plugin-github-issues` | Display GitHub issues on entity pages | Container built-in |

### Role-Based Access Control (RBAC)

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-community-plugin-rbac` | Permission management | Container built-in |

### Quay Integration

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-community-plugin-quay` | Quay container registry information | Container built-in |

### TechDocs Addons

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-plugin-techdocs-module-addons-contrib` | TextSize, ReportIssue, LightBox addons | Container built-in |

### Bulk Import

| Plugin | Purpose | Source |
|--------|---------|--------|
| `red-hat-developer-hub-backstage-plugin-bulk-import-backend-dynamic` | Bulk import backend | Container built-in |
| `red-hat-developer-hub-backstage-plugin-bulk-import` | Bulk import frontend | Container built-in |

### Jenkins Integration

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-community-plugin-jenkins-backend-dynamic` | Jenkins backend integration | Container built-in |
| `backstage-community-plugin-jenkins` | Jenkins frontend display | Container built-in |

Jenkins runs as part of the unified RHDH compose stack via `compose.override.yaml`. See [Jenkins Integration](jenkins-integration.md) for details.

### TODO Integration

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-community-plugin-todo` | Display TODO comments from code | OCI Registry |
| `backstage-community-plugin-todo-backend` | TODO scanning backend | OCI Registry |

### Marketplace

| Plugin | Purpose | Source |
|--------|---------|--------|
| `red-hat-developer-hub-backstage-plugin-marketplace-backend-dynamic` | Plugin installation via Extensions UI | Container built-in |

### Feedback

| Plugin | Purpose | Source |
|--------|---------|--------|
| `@janus-idp/backstage-plugin-feedback-backend-dynamic` | Feedback collection backend (Jira + email) | NPM |
| `@janus-idp/backstage-plugin-feedback` | Feedback collection frontend | NPM |

### Notifications System

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-plugin-signals-backend-dynamic` | Real-time signals backend | Container built-in |
| `backstage-plugin-signals` | Signals frontend handler | Container built-in |
| `backstage-plugin-notifications` | Notifications frontend | Container built-in |
| `backstage-plugin-notifications-backend-dynamic` | Notifications backend | Container built-in |
| `backstage-plugin-notifications-backend-module-email-dynamic` | Email notifications processor | Container built-in |

### Model Context Protocol (MCP)

| Plugin | Purpose | Source |
|--------|---------|--------|
| `backstage-plugin-mcp-actions-backend` | MCP scaffolder actions | OCI Registry |
| `red-hat-developer-hub-backstage-plugin-software-catalog-mcp-tool` | Software catalog MCP tool | OCI Registry |
| `red-hat-developer-hub-backstage-plugin-techdocs-mcp-tool` | TechDocs MCP tool | OCI Registry |

### Scorecard -- Project Health Metrics

Provides component health monitoring via GitHub and Jira metrics, displayed as color-coded scorecards.

| Plugin | Purpose | Source |
|--------|---------|--------|
| `red-hat-developer-hub-backstage-plugin-scorecard` | Scorecard frontend | OCI Registry |
| `red-hat-developer-hub-backstage-plugin-scorecard-backend` | Scorecard backend | OCI Registry |
| `red-hat-developer-hub-backstage-plugin-scorecard-backend-module-github` | GitHub metrics (open PRs) | OCI Registry |
| `red-hat-developer-hub-backstage-plugin-scorecard-backend-module-jira` | Jira metrics (open issues) | OCI Registry |

Scorecard thresholds (configured in `app-config.local.yaml`):
- GitHub open PRs: success < 10, warning 10-50, error > 50
- Jira open issues: success < 10, warning 10-50, error > 50

---

## App Configuration Highlights

### Authentication

- GitHub OAuth with `usernameMatchingUserEntityName` sign-in resolver
- RBAC enabled with configurable admin users
- Supports both `development` and `production` auth environments

### Integrations

- **GitHub**: OAuth, org sync, PRs, issues, scaffolder actions
- **Quay**: Container registry display via proxy
- **Jenkins**: CI/CD integration (unified compose stack)
- **Jira**: Scorecard metrics via Jira Cloud API
- **MCP**: Model Context Protocol for AI tool integration

### Content

- TechDocs with local builder and YouTube iframe support
- Bulk import for GitHub repositories
- Software templates (RHDH official + AI)
- AI Model catalog integration

### User Experience

- Custom branding and theming (light/dark mode)
- Floating action buttons for quick access
- Notifications with email support
- Feedback collection (Jira + email)
- Internationalization (English, French, Japanese, Italian)

---

## Required Environment Variables

See [`.env.example`](../rhdh-customizations/.env.example) for the complete list with descriptions. Key variables:

| Variable | Purpose |
|----------|---------|
| `AUTH_GITHUB_CLIENT_ID` | GitHub OAuth app client ID |
| `AUTH_GITHUB_CLIENT_SECRET` | GitHub OAuth app client secret |
| `GITHUB_ORG` | GitHub organization name |
| `GITHUB_TOKEN` | GitHub PAT for scorecard integration |
| `JENKINS_URL` | Jenkins server URL |
| `JENKINS_USERNAME` / `JENKINS_TOKEN` | Jenkins API credentials |
| `JIRA_BASE_URL` / `JIRA_TOKEN` | Jira Cloud credentials |
| `EMAIL_*` | SMTP configuration for notifications |

---

## Validation Commands

```bash
# Check plugin installation
cd rhdh-local
podman compose logs rhdh | grep -i "plugin"

# Verify environment variables
podman compose exec rhdh env | grep -E "(GITHUB|JENKINS|EMAIL)"

# Restart after config changes
podman compose restart rhdh

# Reinstall plugins after plugin config changes
podman compose run install-dynamic-plugins
podman compose restart rhdh
```
