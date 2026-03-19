#!/bin/bash
# Remove RHDH Local customizations from rhdh-local to restore pristine state
# Deletes the copied customization files so RHDH runs with defaults only.
# Your customization files in rhdh-customizations/ are NOT deleted.

set -e

# Get the workspace root (parent of this script's directory)
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RHDH_LOCAL_DIR="$WORKSPACE_ROOT/rhdh-local"

echo "Removing RHDH customizations from rhdh-local..."
echo "Workspace root: $WORKSPACE_ROOT"
echo "RHDH Local: $RHDH_LOCAL_DIR"
echo ""
echo "⚠️  This will remove all customization files from rhdh-local."
echo "    RHDH Local will run with default settings only."
echo "    Your customization files in rhdh-customizations/ are safe and NOT deleted."
echo ""

# Remove a customization file from rhdh-local if it exists
remove_customization() {
    local target=$1
    local description=$2

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "✓ Removing: $target ($description)"
        rm -f "$target"
    else
        echo "ℹ️  Not found: $target (already removed or never applied)"
    fi
}

echo "Removing customization files..."
echo ""

# Compose override
remove_customization "$RHDH_LOCAL_DIR/compose.override.yaml" "Compose override"

# Environment variables
remove_customization "$RHDH_LOCAL_DIR/.env" "Environment variables"

# Application config
remove_customization "$RHDH_LOCAL_DIR/configs/app-config/app-config.local.yaml" "Application config"

# Dynamic plugins override
remove_customization "$RHDH_LOCAL_DIR/configs/dynamic-plugins/dynamic-plugins.override.yaml" "Dynamic plugins"

# Lightspeed config
remove_customization "$RHDH_LOCAL_DIR/developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml" "Lightspeed config"

# Catalog entity overrides
remove_customization "$RHDH_LOCAL_DIR/configs/catalog-entities/users.override.yaml" "User overrides"
remove_customization "$RHDH_LOCAL_DIR/configs/catalog-entities/components.override.yaml" "Component overrides"

# Enterprise catalog files
for f in "$RHDH_LOCAL_DIR/configs/catalog-entities"/enterprise-catalog-*.override.yaml; do
    [ -f "$f" ] && remove_customization "$f" "Enterprise catalog ($(basename "$f"))"
done

# Translation files
if [ -d "$RHDH_LOCAL_DIR/configs/translations" ]; then
    echo "✓ Removing: $RHDH_LOCAL_DIR/configs/translations/ (Translation files)"
    rm -rf "$RHDH_LOCAL_DIR/configs/translations"
fi

# Extra files
remove_customization "$RHDH_LOCAL_DIR/configs/extra-files/github-app-credentials.yaml" "GitHub App credentials"
# Add more extra-files removals here as needed

echo ""
echo "✅ All customizations have been removed from rhdh-local!"
echo ""
echo "RHDH Local is now in pristine state with NO customizations."
echo ""
echo "📋 What happens now:"
echo "   • RHDH will use only default configurations"
echo "   • No custom plugins beyond defaults"
echo "   • Default authentication (Guest user)"
echo "   • Default branding and theme"
echo "   • In-memory database (no PostgreSQL)"
echo ""
echo "🧪 To test pristine RHDH Local:"
echo "   cd $RHDH_LOCAL_DIR"
echo "   podman compose down --volumes"
echo "   podman compose up -d"
echo ""
echo "🔄 To restore your customizations:"
echo "   cd $WORKSPACE_ROOT/rhdh-customizations"
echo "   ./apply-customizations.sh"
echo ""
echo "📁 Your customization files remain safe in:"
echo "   $WORKSPACE_ROOT/rhdh-customizations/"
