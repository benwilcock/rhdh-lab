#!/bin/bash
# Backup script for RHDH Local Setup
# Creates a complete, portable backup that can be restored on any system
# 
# This backup includes everything needed to recreate your exact RHDH Local setup:
# - All customizations (configs, environment, compose overrides)
# - AI assistant rules
# - Documentation
# - Helper scripts
#
# The backup does NOT include rhdh-local/ (users clone it fresh from GitHub)

set -e

# Get the current date and time in YYYY-MM-DD_HH-MM-SS format
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the archive file name
archive_name="rhdh-local-setup-backup_$timestamp.tar.gz"

# Create backup directory if it doesn't exist
backup_dir=~/rhdh-local-backups
mkdir -p "$backup_dir"

# Get the script's directory (workspace root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         RHDH Local Setup - Complete Backup                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Creating portable backup of your RHDH Local setup..."
echo "Workspace: $SCRIPT_DIR"
echo ""

# Create a temporary directory for building the backup
temp_dir=$(mktemp -d)
backup_root="$temp_dir/rhdh-local-setup"
mkdir -p "$backup_root"

# Copy customizations directory
echo "📦 Backing up customizations..."
cp -R "$SCRIPT_DIR/rhdh-customizations" "$backup_root/"

# Copy workspace root files
echo "📦 Backing up workspace files..."
cp -R "$SCRIPT_DIR/.cursor" "$backup_root/"
cp "$SCRIPT_DIR/backup.sh" "$backup_root/"
cp "$SCRIPT_DIR/SETUP-COMPLETE.md" "$backup_root/"

# Create a restore guide
echo "📦 Creating RESTORE.md guide..."
cat > "$backup_root/RESTORE.md" << 'RESTORE_EOF'
# RHDH Local Setup - Restore Guide

This backup contains a complete, portable RHDH Local setup that can be restored on any system.

## What's Included

- **rhdh-customizations/** - All your configuration files, environment variables, and overrides
- **.cursor/rules/** - Modular AI assistant rules for maintaining the project structure
- **backup.sh** - Backup script (for creating future backups)
- **SETUP-COMPLETE.md** - Complete setup documentation
- **RESTORE.md** - This file

## Prerequisites

Before restoring, ensure you have:

1. **Container Runtime**: Podman 5.4.1+ or Docker 28.1.0+ with Compose support
   - Install Podman: https://podman.io/docs/installation
   - Or Docker: https://docs.docker.com/engine/

2. **Git**: For cloning the RHDH Local repository
   ```bash
   git --version
   ```

3. **System Requirements**:
   - macOS, Linux, or WSL2 (Windows)
   - 8GB RAM minimum (16GB recommended)
   - 20GB free disk space

## Restore Steps

### 1. Create Workspace Directory

Choose a location for your RHDH Local setup:

```bash
# Example: in your home directory
mkdir -p ~/Code
cd ~/Code
```

### 2. Clone RHDH Local Repository

Clone the official RHDH Local repository:

```bash
git clone https://github.com/redhat-developer/rhdh-local.git
cd ..
```

You should now have:
```
~/Code/
└── rhdh-local/
```

### 3. Extract Backup

Extract this backup archive in the parent directory of rhdh-local:

```bash
# If backup is in Downloads
cd ~/Code
tar -xzf ~/Downloads/rhdh-local-setup-backup_*.tar.gz

# Move contents to current directory
mv rhdh-local-setup/.cursor .
mv rhdh-local-setup/* .
rmdir rhdh-local-setup
```

You should now have:
```
~/Code/
├── .cursor/rules/          (AI assistant rules)
├── backup.sh
├── SETUP-COMPLETE.md
├── RESTORE.md (this file)
├── rhdh-customizations/
│   ├── .env
│   ├── configs/
│   └── ...
└── rhdh-local/
```

### 4. Review and Update Environment Variables

Edit the environment variables to match your new system:

```bash
cd ~/Code
code rhdh-customizations/.env  # or use your preferred editor
```

**Important variables to review:**

- `BASE_URL` - Update if your hostname/domain changed
- `GITHUB_ORG` - GitHub organization name
- `AUTH_GITHUB_CLIENT_ID` - GitHub OAuth app ID
- `AUTH_GITHUB_CLIENT_SECRET` - GitHub OAuth secret
- `EMAIL_*` - Email/SMTP settings
- `JENKINS_*` - Jenkins connection details (if using)

**GitHub App credentials:**

If you use GitHub App authentication, also update:
```bash
code rhdh-customizations/configs/extra-files/github-app-credentials.yaml
```

### 5. Apply Customizations

Copy your customizations into RHDH Local so containers can read them:

```bash
cd ~/Code/rhdh-customizations
./apply-customizations.sh
```

This copies your configuration files into `rhdh-local/` where containers expect them.

### 6. Verify Setup

Check that customization copies exist:

```bash
ls -la ~/Code/rhdh-local/.env
ls -la ~/Code/rhdh-local/configs/app-config/app-config.local.yaml
ls -la ~/Code/rhdh-local/configs/dynamic-plugins/dynamic-plugins.override.yaml
```

### 7. Start RHDH Local

Start RHDH Local with your customizations using the provided scripts:

```bash
cd ~/Code
./up.sh --customized
# Or with optional components:
# ./up.sh --customized --both --ollama
```

### 8. Verify RHDH is Running

Check container status:

```bash
cd rhdh-local
podman compose ps
```

View logs:

```bash
podman compose logs -f rhdh
```

### 9. Access RHDH Local

Open your browser to:
- **URL**: http://localhost:7007 (or your BASE_URL)
- **Auth**: According to your configuration (GitHub OAuth or Guest)

## Troubleshooting

### Customizations Not Applied

If customization files are missing from rhdh-local:
```bash
cd ~/Code/rhdh-customizations
./apply-customizations.sh
```

### GitHub Authentication Issues

1. Verify credentials in `rhdh-customizations/.env`
2. Check GitHub OAuth app settings
3. Ensure callback URL matches your BASE_URL

### Container Won't Start

Check logs for errors:
```bash
cd ~/Code/rhdh-local
podman compose logs
```

### Port 7007 Already in Use

Check what's using the port:
```bash
lsof -i :7007
```

Kill the process or change RHDH port in compose.override.yaml

### Need Help?

- Review: `SETUP-COMPLETE.md` for complete documentation
- Check: `rhdh-customizations/README.md` for customization details
- Visit: https://github.com/redhat-developer/rhdh-local

## Testing the Setup

### Test with Default Configuration

To verify RHDH Local works without customizations:

```bash
cd ~/Code
./down.sh
./up.sh --baseline
```

Access http://localhost:7007 (Guest login, default config)

### Restore Customizations

```bash
cd ~/Code/rhdh-customizations
./apply-customizations.sh
cd ~/Code
./down.sh && ./up.sh --customized
```

## Next Steps

1. **Create Regular Backups**
   ```bash
   cd ~/Code
   ./backup.sh
   ```

2. **Version Control Your Customizations** (Optional)
   ```bash
   cd ~/Code/rhdh-customizations
   git init
   git add .
   git commit -m "Initial RHDH customizations"
   ```

3. **Update RHDH Local**
   ```bash
   cd ~/Code
   ./down.sh
   cd rhdh-local && git pull && cd ..
   cd rhdh-customizations && ./apply-customizations.sh && cd ..
   ./up.sh --customized
   ```

## Success!

Your RHDH Local setup should now be fully restored and running with all your customizations!

**Key Files:**
- Customizations: `~/Code/rhdh-customizations/`
- Configuration docs: `~/Code/rhdh-customizations/BASELINE-CONFIGURATION.md`
- Testing guide: `~/Code/rhdh-customizations/TESTING-GUIDE.md`

Enjoy your restored RHDH Local setup! 🚀
RESTORE_EOF

# Create the archive
echo "📦 Creating archive..."
cd "$temp_dir"
tar -czf "$archive_name" rhdh-local-setup/

# Move to backup directory
mv "$archive_name" "$backup_dir/"

# Cleanup temp directory
rm -rf "$temp_dir"

# Calculate archive size
archive_path="$backup_dir/$archive_name"
archive_size=$(du -h "$archive_path" | cut -f1)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  Backup Complete! ✅                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Archive Details:"
echo "   Name: $archive_name"
echo "   Size: $archive_size"
echo "   Location: $backup_dir/"
echo ""
echo "📋 Backup Contents:"
echo "   ✓ rhdh-customizations/ (all configs, env, overrides)"
echo "   ✓ .cursor/rules/ (modular AI assistant rules)"
echo "   ✓ backup.sh (this script)"
echo "   ✓ SETUP-COMPLETE.md (setup documentation)"
echo "   ✓ RESTORE.md (restore instructions)"
echo ""
echo "🚀 To Restore on Another System:"
echo "   1. Clone: git clone https://github.com/redhat-developer/rhdh-local.git"
echo "   2. Extract: tar -xzf $archive_name"
echo "   3. Read: cat RESTORE.md"
echo "   4. Setup: cd rhdh-customizations && ./apply-customizations.sh"
echo "   5. Start: cd rhdh-local && podman compose up -d"
echo ""
echo "📁 Full backup path:"
echo "   $archive_path"
echo ""
echo "💡 Tip: Share this archive with team members for identical setups!"