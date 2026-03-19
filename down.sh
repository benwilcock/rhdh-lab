#!/usr/bin/env bash

# down.sh - Stop RHDH Local and clean customizations
# 
# Usage:
#   Interactive mode:  ./down.sh
#   Non-interactive:   ./down.sh [OPTIONS]
#
# Options:
#   --volumes, -v          Remove volumes (clears plugin cache and database)
#   --keep-volumes         Keep volumes intact (default)
#   --help, -h             Show this help message
#
# Examples:
#   ./down.sh                              # Interactive mode (prompts for volumes)
#   ./down.sh --volumes                    # Stop and remove volumes
#
# Note: Stops containers FIRST (including Jenkins and custom services from compose.override.yaml),
#       THEN removes customizations from rhdh-local/ (restores pristine state).
#       Your source customizations in rhdh-customizations/ are never touched.

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (workspace root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RHDH_LOCAL_DIR="${SCRIPT_DIR}/rhdh-local"
CUSTOMIZATIONS_DIR="${SCRIPT_DIR}/rhdh-customizations"

# Default values
REMOVE_VOLUMES=false
INTERACTIVE=true

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
}

# Function to show help
show_help() {
    cat << EOF
RHDH Local Shutdown Script

Usage: $0 [OPTIONS]

Options:
  --volumes, -v              Remove volumes (clears plugin cache and database)
  --keep-volumes             Keep volumes intact (default)
  --help, -h                 Show this help message

Examples:
  $0                                # Interactive mode - prompts for volume removal
  $0 --volumes                      # Stop and remove volumes (clean slate)

Notes:
  - Stops ALL containers: RHDH, Jenkins, Lightspeed, Orchestrator (sonataflow), and dependencies
  - Containers stopped FIRST, then customizations removed (ensures all services shut down properly)
  - Automatically includes all compose files (safe - ignores non-existent services)
  - Removing volumes clears plugin cache and database (useful for troubleshooting)
  - ALWAYS removes customizations from rhdh-local/ after shutdown (restores pristine git state)
  - Your source customizations in rhdh-customizations/ are NEVER removed
  - Only copied files in rhdh-local/ are removed (*.local.yaml, .env, compose.override.yaml, etc.)
  - To reapply customizations after restart: cd rhdh-customizations && ./apply-customizations.sh

EOF
}

# Parse command-line arguments
parse_args() {
    if [ $# -eq 0 ]; then
        INTERACTIVE=true
        return
    fi
    
    INTERACTIVE=false
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --volumes|-v)
                REMOVE_VOLUMES=true
                shift
                ;;
            --keep-volumes)
                REMOVE_VOLUMES=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Detect container runtime (podman or docker)
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        print_error "Neither podman nor docker found. Please install one."
        exit 1
    fi
}

# Interactive prompt for volume removal
prompt_volumes() {
    echo ""
    print_warning "Do you want to remove volumes?"
    echo ""
    echo "Removing volumes will:"
    echo "  • Clear the plugin download cache"
    echo "  • Remove the PostgreSQL database"
    echo "  • Provide a completely fresh start"
    echo ""
    echo "This is useful for:"
    echo "  • Troubleshooting plugin issues"
    echo "  • Testing clean installations"
    echo "  • Clearing corrupted data"
    echo ""
    read -p "Remove volumes? [y/N]: " remove_choice
    remove_choice=${remove_choice:-N}
    
    if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
        REMOVE_VOLUMES=true
        print_warning "Volumes will be removed"
    else
        REMOVE_VOLUMES=false
        print_info "Volumes will be kept"
    fi
}

# Check if containers are running
check_running_containers() {
    local runtime=$1
    cd "$RHDH_LOCAL_DIR"
    
    # Get list of running containers
    local running=$($runtime compose ps --quiet 2>/dev/null || true)
    
    if [ -z "$running" ]; then
        print_warning "No RHDH Local containers are currently running"
        echo ""
        read -p "Continue anyway? [y/N]: " continue_choice
        continue_choice=${continue_choice:-N}
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            print_info "Cancelled by user"
            exit 0
        fi
    else
        # Count containers
        local count=$(echo "$running" | wc -l | tr -d ' ')
        print_info "Found $count running container(s)"
    fi
}

# Explain which compose files will be included and why
explain_compose_files() {
    echo ""
    echo "Compose files to be included:"
    echo ""
    echo "  • compose.yaml (base RHDH configuration)"
    
    if [ -f "compose.override.yaml" ]; then
        echo "  • compose.override.yaml (customizations: Jenkins, extra services, networks, etc.)"
    fi
    
    # Lightspeed detection (include all available compose files for thorough shutdown)
    if [ -f "developer-lightspeed/compose-with-ollama.yaml" ]; then
        echo "  • developer-lightspeed/compose-with-ollama.yaml (Lightspeed with Ollama)"
    fi
    if [ -f "developer-lightspeed/compose-with-safety-guard-ollama.yaml" ]; then
        echo "  • developer-lightspeed/compose-with-safety-guard-ollama.yaml (Ollama safety guard)"
    fi
    if [ -f "developer-lightspeed/compose-with-safety-guard.yaml" ]; then
        echo "  • developer-lightspeed/compose-with-safety-guard.yaml (BYOM safety guard)"
    fi
    if [ -f "developer-lightspeed/compose.yaml" ]; then
        echo "  • developer-lightspeed/compose.yaml (Lightspeed base / BYOM)"
    fi
    
    # Orchestrator detection
    if [ -f "orchestrator/compose.yaml" ]; then
        echo "  • orchestrator/compose.yaml (Orchestrator with Sonataflow, PostgreSQL)"
    fi
    
    echo ""
    print_info "Note: compose down safely ignores any non-existent services"
}

# Build compose down command with ALL possible compose files
# This is safe and non-destructive - compose down ignores services that don't exist
build_down_command() {
    local runtime=$1
    local compose_files="-f compose.yaml"
    
    # CRITICAL: When using -f flags, compose.override.yaml is NOT automatically loaded
    # We must explicitly include it if it exists (it's created by apply-customizations.sh)
    if [ -f "compose.override.yaml" ]; then
        compose_files="$compose_files -f compose.override.yaml"
    fi
    
    # Include ALL possible compose files (safe - compose down ignores non-existent services)
    # This ensures we catch all containers regardless of naming (e.g., sonataflow, orchestrator, etc.)
    
    # Lightspeed: include all available compose files to ensure all services are stopped.
    # Compose down safely ignores services that aren't running.
    if [ -f "developer-lightspeed/compose-with-ollama.yaml" ]; then
        compose_files="$compose_files -f developer-lightspeed/compose-with-ollama.yaml"
    fi
    if [ -f "developer-lightspeed/compose-with-safety-guard-ollama.yaml" ]; then
        compose_files="$compose_files -f developer-lightspeed/compose-with-safety-guard-ollama.yaml"
    fi
    if [ -f "developer-lightspeed/compose-with-safety-guard.yaml" ]; then
        compose_files="$compose_files -f developer-lightspeed/compose-with-safety-guard.yaml"
    fi
    if [ -f "developer-lightspeed/compose.yaml" ]; then
        compose_files="$compose_files -f developer-lightspeed/compose.yaml"
    fi
    
    # Always include Orchestrator if the compose file exists (contains sonataflow, postgres-orchestrator, etc.)
    if [ -f "orchestrator/compose.yaml" ]; then
        compose_files="$compose_files -f orchestrator/compose.yaml"
    fi
    
    # Build the command
    local cmd="$runtime compose $compose_files down"
    
    if [ "$REMOVE_VOLUMES" = true ]; then
        cmd="$cmd --volumes"
    fi
    
    echo "$cmd"
}

# Main execution
main() {
    print_header "RHDH Local Shutdown"
    
    # Parse arguments
    parse_args "$@"
    
    # Detect runtime
    RUNTIME=$(detect_runtime)
    print_info "Using container runtime: $RUNTIME"
    
    # Check running containers
    check_running_containers "$RUNTIME"
    
    # Interactive prompts if needed
    if [ "$INTERACTIVE" = true ]; then
        prompt_volumes
    fi
    
    # Display configuration
    echo ""
    print_header "Shutdown Configuration"
    echo "Remove volumes:         $REMOVE_VOLUMES"
    echo "Remove customizations:  YES (always)"
    echo "Runtime:                $RUNTIME"
    echo ""
    
    if [ "$REMOVE_VOLUMES" = true ]; then
        print_warning "This will remove all volumes (plugin cache, database, etc.)"
    else
        print_info "Volumes will be preserved for faster restart"
    fi
    
    print_warning "Customizations will be removed from rhdh-local/ (pristine state)"
    print_info "Your source files in rhdh-customizations/ are safe"
    
    if [ "$INTERACTIVE" = true ]; then
        echo ""
        read -p "Proceed with shutdown? [Y/n]: " confirm
        confirm=${confirm:-Y}
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warning "Cancelled by user"
            exit 0
        fi
    fi
    
    # Change to rhdh-local directory
    cd "$RHDH_LOCAL_DIR"
    
    # Execute shutdown FIRST (before removing customizations)
    # This ensures compose.override.yaml is present so Jenkins and other custom services are stopped
    echo ""
    print_header "Stopping RHDH Local"
    
    # Explain which compose files will be used
    explain_compose_files
    
    # Build and execute the down command
    DOWN_CMD=$(build_down_command "$RUNTIME")
    echo ""
    print_info "Executing: $DOWN_CMD"
    echo ""
    eval "$DOWN_CMD"
    
    # Remove customizations AFTER stopping containers
    echo ""
    print_header "Removing Customizations"
    
    if [ -f "${CUSTOMIZATIONS_DIR}/remove-customizations.sh" ]; then
        print_info "Running remove-customizations.sh..."
        cd "${CUSTOMIZATIONS_DIR}"
        bash remove-customizations.sh
        cd "${SCRIPT_DIR}"
        print_success "Customizations removed from rhdh-local/"
    else
        print_error "remove-customizations.sh not found in ${CUSTOMIZATIONS_DIR}"
        print_warning "Customizations were NOT removed"
    fi
    
    # Success message
    echo ""
    print_header "Shutdown Complete"
    print_success "RHDH Local has been stopped"
    
    if [ "$REMOVE_VOLUMES" = true ]; then
        print_success "Volumes have been removed (clean slate)"
        print_info "Next startup will download fresh plugins"
    else
        print_info "Volumes preserved for faster restart"
    fi
    
    print_success "Customizations removed from rhdh-local/ (pristine state)"
    print_info "Ready for: cd rhdh-local && git pull"
    print_info "To restart with customizations: ./up.sh --customized --ollama"
    
    echo ""
    print_info "To start in pristine mode: ./up.sh --baseline"
    echo ""
}

# Run main
main "$@"
