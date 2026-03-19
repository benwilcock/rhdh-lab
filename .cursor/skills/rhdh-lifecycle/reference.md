# RHDH Lifecycle Reference

Extended workflows, troubleshooting, and operational details.

## Container Runtime Detection

`up.sh` and `down.sh` auto-detect the container runtime:
1. Check for `podman` first
2. Fall back to `docker`
3. Fail if neither is found

To force a runtime, set the `CONTAINER_ENGINE` environment variable before running scripts.

## Compose File Merging

`up.sh` assembles the compose command by combining files:

| Configuration | Compose files |
|---|---|
| Baseline | `compose.yaml` |
| Customized | `compose.yaml` + `compose.override.yaml` |
| + Lightspeed | + `developer-lightspeed/compose.yaml` |
| + Ollama | + `developer-lightspeed/compose-with-ollama.yaml` |
| + Safety Guard | + `developer-lightspeed/compose-with-safety-guard.yaml` |
| + Safety Guard + Ollama | + `developer-lightspeed/compose-with-safety-guard-ollama.yaml` |
| + Orchestrator | + `orchestrator/compose.yaml` |

The override file (`compose.override.yaml`) is automatically picked up by Docker/Podman Compose when present.

## Services and Ports

| Service | Port | Network | Purpose |
|---------|------|---------|---------|
| `rhdh` | 7007 | Owns namespace | Main RHDH application |
| `install-dynamic-plugins` | -- | Independent | Plugin installer (runs once) |
| `lightspeed-core-service` | 8080 | Shares RHDH namespace | AI assistant backend |
| `llama-stack` | 8321 | Shares RHDH namespace | LLM inference layer |
| `sonataflow` | -- | Independent | Workflow engine |
| `ollama` | 11434 | Independent | Local LLM runtime |

## Network Namespace Sharing (Detail)

Containers with `network_mode: "service:rhdh"` share RHDH's network stack:
- They appear on `localhost` from RHDH's perspective
- If RHDH restarts, it gets a new network namespace
- Dependent containers remain in the old namespace -- they appear "running" but are unreachable
- This is why all containers must restart together

## Startup Sequence

1. `install-dynamic-plugins` runs `prepare-and-install-dynamic-plugins.sh`
2. Plugin config files are generated from override YAML
3. `rhdh` waits for plugin installation to complete (healthcheck dependency)
4. `rhdh` runs `wait-for-plugins-and-start.sh`:
   - Applies config overrides
   - Starts the Backstage application
5. Network-sharing containers attach to RHDH's namespace

## Troubleshooting Guide

### 504 Gateway Timeout

**Cause**: Network namespace desynchronization. A container sharing RHDH's network was left running while RHDH was restarted.

**Fix**:
```bash
./down.sh --keep-volumes
cd rhdh-customizations && ./apply-customizations.sh && cd ..
./up.sh --customized --both --ollama   # match your previous flags
```

### Plugin Initialization Failure

**Symptoms**: RHDH container starts but the UI is unreachable or shows errors.

**Diagnose**:
```bash
cd rhdh-local && podman compose logs install-dynamic-plugins
cd rhdh-local && podman compose logs rhdh | grep -i "error\|failed\|threw"
```

**Common causes**:
- Missing environment variables referenced by plugin config
- Invalid YAML in `dynamic-plugins.override.yaml`
- Network issues pulling OCI plugin artifacts

### Configuration Not Taking Effect

**Checklist**:
1. Did you edit in `rhdh-customizations/` (not `rhdh-local/`)?
2. Did you run `apply-customizations.sh`?
3. Did you restart containers after applying?
4. Check config precedence: `app-config.local.yaml` loads last and wins

**Verify copies are in place**:
```bash
ls -la rhdh-local/.env
ls -la rhdh-local/configs/app-config/app-config.local.yaml
ls -la rhdh-local/configs/dynamic-plugins/dynamic-plugins.override.yaml
```

### Dirty Git Status in rhdh-local

**Cause**: Customization copies were not cleaned up, or files were edited directly.

**Fix**:
```bash
cd rhdh-customizations && ./remove-customizations.sh
cd ../rhdh-local && git status   # should be clean
git checkout -- .                # reset any accidental edits
```

### Port Conflicts

**Symptom**: "address already in use" on port 7007.

**Fix**:
```bash
./down.sh --volumes
# If still bound:
lsof -i :7007
kill <PID>
```

### Ollama Model Not Available

**Symptom**: Lightspeed returns errors about missing model.

**Check**:
```bash
cd rhdh-local && podman compose logs ollama
curl http://localhost:11434/api/tags   # list available models
```

The model is configured via `OLLAMA_MODEL` in `rhdh-customizations/.env`.

## Environment Variable Reference

Key variables in `rhdh-customizations/.env`:

| Category | Variables |
|----------|-----------|
| Base URL | `BASE_URL` (default: `http://localhost:7007`) |
| Database | `POSTGRES_DB`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| GitHub | `GITHUB_ORG`, `GITHUB_HOST_DOMAIN`, `AUTH_GITHUB_CLIENT_ID`, `AUTH_GITHUB_CLIENT_SECRET` |
| Images | `RHDH_IMAGE`, `CATALOG_INDEX_IMAGE` |
| Logging | `LOG_LEVEL`, `NODE_ENV` |
| Ollama | `OLLAMA_URL`, `OLLAMA_MODEL`, `OLLAMA_MODELS_PATH` |
| vLLM | `ENABLE_VLLM`, `VLLM_URL`, `VLLM_API_KEY` |
| OpenAI | `ENABLE_OPENAI`, `OPENAI_API_KEY` |
| Vertex AI | `ENABLE_VERTEX_AI`, `VERTEX_AI_CREDENTIALS_PATH`, `VERTEX_AI_PROJECT` |
| Safety | `SAFETY_MODEL`, `SAFETY_URL`, `SAFETY_API_KEY` |
| Jenkins | `JENKINS_URL`, `JENKINS_USERNAME`, `JENKINS_TOKEN` |
| Jira | `JIRA_BASE_URL`, `JIRA_TOKEN` |
| Email | `EMAIL_SENDER`, `EMAIL_USER`, `EMAIL_PASSWORD`, `EMAIL_HOSTNAME`, `EMAIL_PORT` |

## SELinux Notes

On SELinux-enabled systems (Fedora, RHEL), bind mounts need the `:Z` suffix for proper labeling. The compose files already include this where needed. If adding new volume mounts in `compose.override.yaml`, remember to include `:Z`.

## Documentation Map

| Document | Purpose |
|----------|---------|
| `README.md` | Getting started guide |
| `docs/quick-reference.md` | Command cheat sheet |
| `docs/scripts.md` | Script reference and internals |
| `docs/backup.md` | Backup and restore guide |
| `docs/architecture.md` | Copy-sync system design |
| `docs/customization-guide.md` | How to customize RHDH |
| `docs/baseline-configuration.md` | Current plugin and config state |
| `rhdh-local/README.md` | RHDH Local upstream docs |
| `rhdh-local/developer-lightspeed/README.md` | Lightspeed setup guide |
