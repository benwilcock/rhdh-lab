# Testing Guide

How to test RHDH Local in different configurations using the customization scripts.

## Two Testing Modes

### Customized Mode

Your full configuration is active -- plugins, authentication, branding, integrations.

```bash
./up.sh --customized
```

### Baseline (Pristine) Mode

RHDH defaults only -- guest authentication, default plugins, no integrations.

```bash
./up.sh --baseline
```

## Comparison Matrix

| Feature | Customized Mode | Baseline Mode |
|---------|----------------|---------------|
| Configuration | Your custom settings | RHDH defaults only |
| Authentication | GitHub OAuth | Guest user only |
| Plugins | All configured plugins | Default plugins only |
| Branding | Custom title and theme | Default RHDH branding |
| Catalog | Custom entities and catalogs | Example entities only |
| RBAC | Enabled with admin user | Disabled |
| GitHub Integration | Full integration | None |
| Email/Notifications | Configured SMTP | Not configured |
| Jenkins | Configured connection | Not configured |

## When to Use Each Mode

**Use Customized Mode for:**
- Normal daily development
- Production-like testing
- Demonstrating features
- Working with your catalogs and templates

**Use Baseline Mode for:**
- Isolating configuration issues
- Testing RHDH updates and upgrades
- Reproducing bug reports against upstream
- Comparing default vs. custom behavior
- Creating minimal reproduction cases

## Testing Workflows

### Troubleshooting Configuration Issues

If something is not working in your customized setup:

```bash
# 1. Test with pristine defaults
./up.sh --baseline
# Open http://localhost:7007 -- does the problem occur?

# 2a. If it works in baseline: the issue is in your customizations
# 2b. If it fails in baseline: the issue is in RHDH Local itself

# 3. Return to customized mode
./down.sh
./up.sh --customized
```

### Testing RHDH Updates

When a new RHDH version is released:

```bash
# 1. Update the submodule
cd rhdh-local && git pull && cd ..

# 2. Test baseline first
./up.sh --baseline
# Verify at http://localhost:7007 -- check version, test basic functionality

# 3. Test with your customizations
./down.sh
./up.sh --customized
# Check for deprecation warnings in logs
# Test all your custom plugins
```

### Creating Bug Reports

To determine if an issue is upstream or in your configuration:

```bash
# Reproduce in pristine mode
./down.sh --volumes
./up.sh --baseline
# If bug exists in pristine: report to RHDH Local project
# If bug only in customized: issue is in your configuration
```

## Verification Commands

### Check Current Mode

```bash
# If these files exist, customizations are applied
ls rhdh-local/.env
ls rhdh-local/configs/app-config/app-config.local.yaml
```

### Compare Logs Between Modes

```bash
# Capture pristine logs
./up.sh --baseline
cd rhdh-local && podman compose logs rhdh > ~/pristine-logs.txt && cd ..

# Capture customized logs
./down.sh
./up.sh --customized
cd rhdh-local && podman compose logs rhdh > ~/customized-logs.txt && cd ..

# Compare
diff ~/pristine-logs.txt ~/customized-logs.txt
```

## Important Notes

- Using `--volumes` when switching modes ensures a completely clean state (database, plugin cache)
- Your customization source files in `rhdh-customizations/` are never deleted by any script
- `down.sh` always removes customization copies from `rhdh-local/`, so `up.sh` re-applies them on the next start
- Some configuration changes may require clearing browser cache -- try incognito mode for clean tests
