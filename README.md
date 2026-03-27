# rhdh-lab

A customizable development and testing environment for [Red Hat Developer Hub](https://developers.redhat.com/rhdh) (RHDH). Wraps the official [rhdh-local](https://github.com/redhat-developer/rhdh-local) project with a copy-sync customization system, lifecycle scripts, and plugin management.

![RHDH running locally with customized plugins -- catalog, APIs, TechDocs, Tech Radar, RBAC, Orchestrator, Notifications, and more](docs/img/rhdh-local-screenshot.png)

> **Note:** This is for development and testing only, not for production use.

## Prerequisites

- [Podman](https://podman.io/docs/installation) v5.4.1+ (recommended) or [Docker](https://docs.docker.com/engine/) v28.1.0+ with Compose support
- [Git](https://git-scm.com/)
- ~10 GB disk space for container images

## Quick Start

### 1. Clone the repository

```bash
git clone --recurse-submodules https://github.com/benwilcock/rhdh-lab.git rhdh-lab
cd rhdh-lab
```

### 2. Configure your environment

```bash
cp rhdh-customizations/.env.example rhdh-customizations/.env
```

Edit `rhdh-customizations/.env` and fill in your credentials (GitHub OAuth, email, etc.). See the comments in `.env.example` for guidance on each variable. For a full walkthrough, see the [Customization Guide](docs/customization-guide.md).

### 3. Start RHDH

```bash
./up.sh --customized
```

### 4. Open RHDH

Browse to <http://localhost:7007> and log in.

### 5. Stop RHDH

```bash
./down.sh
```

## Project Structure

```
rhdh-lab/
├── up.sh                        # Start RHDH with various configurations
├── down.sh                      # Stop RHDH (always restores pristine state)
├── backup.sh                    # Create portable backup archive
├── rhdh-customizations/         # Your configuration files (edit here)
├── rhdh-local/                  # Upstream RHDH Local project (git submodule)
└── docs/                        # Documentation
```

**Key principle:** All configuration edits go in `rhdh-customizations/`. The `rhdh-local/` directory is a pristine git submodule of the upstream project and should never be modified directly.

## What's Included

- **[Lifecycle scripts](docs/scripts.md)** (`up.sh`, `down.sh`) -- start and stop RHDH with interactive or non-interactive modes, supporting baseline, Lightspeed, and Orchestrator configurations
- **[Copy-sync customization system](docs/architecture.md)** -- keeps your configuration separate from the upstream project for conflict-free updates
- **[Plugin management](docs/baseline-configuration.md)** -- pre-configured dynamic plugins for GitHub, Jenkins, RBAC, TechDocs, notifications, scorecards, and more
- **[Backup and restore](docs/backup.md)** (`backup.sh`) -- portable archives of your setup
- **[AI coding assistant rules and skills](docs/cursor-rules-and-skills.md)** -- structured guidance in `.cursor/rules/` and `.cursor/skills/` that teaches AI assistants the project's architecture, workflows, and constraints. Works with any assistant using the `*.mdc` format including Claude Code if you ask Claude to add a sutable `CLAUDE.md` file.

## Common Commands

The bash scripts let you launch RHDH Local in various configuration states depending on your needs.

```bash
./up.sh --customized                 # Start with your config
./up.sh --baseline                   # Start pristine RHDH (no customizations)
./up.sh --customized --lightspeed    # Start with Developer Lightspeed AI
./down.sh --keep-volumes             # Stop, keep data for fast restart
./down.sh --volumes                  # Stop, clean slate
./backup.sh                          # Backup customizations
```

Run `./up.sh --help` or `./down.sh --help` for all options.

## Documentation

See the [docs/](docs/README.md) folder for detailed guides:

- [Architecture](docs/architecture.md) -- copy-sync system, directory layout, design principles
- [Scripts Reference](docs/scripts.md) -- `up.sh`, `down.sh`, `backup.sh` in detail
- [Quick Reference](docs/quick-reference.md) -- command cheat sheet
- [Customization Guide](docs/customization-guide.md) -- how to configure RHDH
- [Backup and Restore](docs/backup.md) -- creating and restoring backups
- [Testing Guide](docs/testing.md) -- workflows for customized and pristine modes
- [Baseline Configuration](docs/baseline-configuration.md) -- all enabled plugins and settings
- [Jenkins Integration](docs/jenkins-integration.md) -- Jenkins CI/CD setup
- [Cursor Rules and Skills](docs/cursor-rules-and-skills.md) -- AI assistant guidance for this project

## Updating RHDH Local

One of the main reasons I created this project was because it made it easier to stay up to date with changes in RHDH Local.

```bash
./down.sh
cd rhdh-local && git pull && cd ..
./up.sh --baseline # Handy for checking everything starts up OK before customizing further
```

## Troubleshooting

### `compose.yaml` not found or submodule clone fails

If `./up.sh` fails with `open .../rhdh-local/compose.yaml: no such file or directory`, the **rhdh-local** submodule was never checked out. The `rhdh-local/` directory must contain the full upstream tree (including `compose.yaml`), not only files copied from `rhdh-customizations/`.

- **Fresh clone:** use `git clone --recurse-submodules <url>` so `rhdh-local` is populated automatically.
- **Existing clone:** run `git submodule update --init --recursive` from the repo root.

If Git reports that `rhdh-local` already exists and is not empty, something created a partial directory without cloning the submodule. Rename or remove that directory (after saving anything you need from `rhdh-customizations/`), then run `git submodule update --init --recursive` again. Re-run `rhdh-customizations/apply-customizations.sh` afterward.

### GitHub sign-in: "Auth provider registered for 'github' is misconfigured"

That response usually means the **OAuth client ID and secret are not set inside the `rhdh` container**, or **`BASE_URL` does not match the URL in the browser**.

1. **Secrets:** Ensure `rhdh-customizations/.env` defines `AUTH_GITHUB_CLIENT_ID` and `AUTH_GITHUB_CLIENT_SECRET` (see `.env.example`). Run `rhdh-customizations/apply-customizations.sh`, then restart with `./down.sh` and `./up.sh` so `rhdh-local/.env` is loaded by Compose.
2. **Same origin:** Set `BASE_URL` in that same `.env` to the origin users use (for example `https://your-host.example` if you access RHDH over HTTPS on a hostname, not `http://localhost:7007`).
3. **GitHub OAuth App:** In the GitHub Developer Settings for your OAuth App, set the authorization callback URL to  
   `{BASE_URL}/api/auth/github/handler/frame`  
   (replace `{BASE_URL}` with the same value as in `.env`, with no trailing slash).

4. **GitHub App credentials file (`github-app-credentials.yaml`):** If `rhdh-customizations/configs/app-config/app-config.local.yaml` references  
   `$include: ../extra-files/github-app-credentials.yaml` under `integrations.github`, you **must** supply that file (or recreate it after a new clone or machine). Put it at:

   `rhdh-customizations/configs/extra-files/github-app-credentials.yaml`

   It is not in the repo (secrets). Run `apply-customizations.sh` after adding or updating it so a copy exists at `rhdh-local/configs/extra-files/github-app-credentials.yaml` for the container. If the file is missing, the backend fails at startup with an error about failing to read the include. If you are not using a GitHub App for integrations, remove or comment out the `apps:` / `$include` block and rely on `GITHUB_TOKEN` in `.env` instead.

## License

- **RHDH Local**: Apache 2.0 (see `rhdh-local/LICENSE`)
- **This workspace**: Apache 2.0
