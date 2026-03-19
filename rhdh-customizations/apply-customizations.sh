#!/bin/bash
# Apply RHDH Local customizations by copying files into rhdh-local
# Run this script from the workspace root (or from rhdh-customizations) to sync customizations.
# Copies (not symlinks) so that container mounts see real files.

set -e

# Get the workspace root (parent of this script's directory)
WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CUSTOMIZATIONS_DIR="$WORKSPACE_ROOT/rhdh-customizations"
RHDH_LOCAL_DIR="$WORKSPACE_ROOT/rhdh-local"

echo "Applying RHDH customizations (copy sync)..."
echo "Workspace root: $WORKSPACE_ROOT"
echo "Customizations: $CUSTOMIZATIONS_DIR"
echo "RHDH Local: $RHDH_LOCAL_DIR"
echo ""

# Copy a file from customizations to rhdh-local; create parent dirs if needed
copy_customization() {
    local source=$1
    local target=$2

    if [ ! -f "$source" ]; then
        echo "Skipping (source missing): $source"
        return 0
    fi
    mkdir -p "$(dirname "$target")"
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Overwriting: $target"
    else
        echo "Copying: $target"
    fi
    cp -f "$source" "$target"
}

echo "Copying customization files..."
echo ""

# Compose override (automatically merged by Podman/Docker Compose)
copy_customization "$CUSTOMIZATIONS_DIR/compose.override.yaml" "$RHDH_LOCAL_DIR/compose.override.yaml"

# Environment variables (read by Compose on host)
copy_customization "$CUSTOMIZATIONS_DIR/.env" "$RHDH_LOCAL_DIR/.env"

# Application config (mounted into container)
copy_customization "$CUSTOMIZATIONS_DIR/configs/app-config/app-config.local.yaml" \
    "$RHDH_LOCAL_DIR/configs/app-config/app-config.local.yaml"

# Dynamic plugins override (mounted into container)
copy_customization "$CUSTOMIZATIONS_DIR/configs/dynamic-plugins/dynamic-plugins.override.yaml" \
    "$RHDH_LOCAL_DIR/configs/dynamic-plugins/dynamic-plugins.override.yaml"

# Lightspeed config (mounted when using Lightspeed compose)
copy_customization "$CUSTOMIZATIONS_DIR/developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml" \
    "$RHDH_LOCAL_DIR/developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml"

# Catalog entity overrides (e.g. custom users for GitHub auth)
if [ -f "$CUSTOMIZATIONS_DIR/configs/catalog-entities/users.override.yaml" ]; then
    copy_customization "$CUSTOMIZATIONS_DIR/configs/catalog-entities/users.override.yaml" \
        "$RHDH_LOCAL_DIR/configs/catalog-entities/users.override.yaml"
fi
# Enterprise OSS and Parasol Insurance catalog files are now managed in GitHub.
# See: https://github.com/benwilcock/backstage-catalogs
# They are loaded by RHDH directly via type:url entries in app-config.local.yaml.

# Translation files (served by the translations-backend plugin for i18n support)
if [ -d "$CUSTOMIZATIONS_DIR/configs/translations" ]; then
    mkdir -p "$RHDH_LOCAL_DIR/configs/translations"
    for f in "$CUSTOMIZATIONS_DIR/configs/translations"/*.json; do
        [ -f "$f" ] && copy_customization "$f" "$RHDH_LOCAL_DIR/configs/translations/$(basename "$f")"
    done
fi

# Extra files (e.g. GitHub App credentials) - copy each file that exists
if [ -f "$CUSTOMIZATIONS_DIR/configs/extra-files/github-app-credentials.yaml" ]; then
    copy_customization "$CUSTOMIZATIONS_DIR/configs/extra-files/github-app-credentials.yaml" \
        "$RHDH_LOCAL_DIR/configs/extra-files/github-app-credentials.yaml"
fi
# Add more extra-files here as needed:
# if [ -f "$CUSTOMIZATIONS_DIR/configs/extra-files/other-credentials.yaml" ]; then
#     copy_customization "$CUSTOMIZATIONS_DIR/configs/extra-files/other-credentials.yaml" \
#         "$RHDH_LOCAL_DIR/configs/extra-files/other-credentials.yaml"
# fi

echo ""
echo "✅ Customizations applied successfully!"
echo ""
echo "Verify copied files:"
for f in "$RHDH_LOCAL_DIR/compose.override.yaml" \
         "$RHDH_LOCAL_DIR/.env" \
         "$RHDH_LOCAL_DIR/configs/app-config/app-config.local.yaml" \
         "$RHDH_LOCAL_DIR/configs/dynamic-plugins/dynamic-plugins.override.yaml" \
         "$RHDH_LOCAL_DIR/developer-lightspeed/configs/app-config/app-config.lightspeed.local.yaml"; do
    if [ -f "$f" ]; then
        ls -la "$f"
    fi
done
if [ -f "$RHDH_LOCAL_DIR/configs/extra-files/github-app-credentials.yaml" ]; then
    ls -la "$RHDH_LOCAL_DIR/configs/extra-files/github-app-credentials.yaml"
fi
echo ""
echo "Setup complete! You can now start RHDH Local:"
echo "  cd $RHDH_LOCAL_DIR"
echo "  podman compose up -d"
echo ""
echo "After editing files in rhdh-customizations/, run this script again to sync."
