#!/usr/bin/env bash

# up.sh - Start RHDH Local with various configurations
# 
# Usage:
#   Interactive mode:  ./up.sh
#   Non-interactive:   ./up.sh [OPTIONS]
#
# Options:
#   --baseline         Start without customizations (pristine RHDH)
#   --customized       Start with customizations applied (default)
#   --lightspeed       Include Developer Lightspeed (BYOM provider)
#   --orchestrator     Include Orchestrator
#   --both             Include both Lightspeed and Orchestrator
#   --ollama           Use Ollama provider for Lightspeed (implies --lightspeed)
#   --safety-guard     Enable safety guard for Lightspeed (implies --lightspeed)
#   --follow-logs, -f  Follow logs after startup
#   --last             Reuse settings from the last successful run (.last-run-settings)
#   --help, -h         Show this help message
#
# Examples:
#   ./up.sh                                    # Interactive mode
#   ./up.sh --customized --lightspeed          # Customized with Lightspeed (BYOM)
#   ./up.sh --customized --ollama              # Customized with Lightspeed using Ollama
#   ./up.sh --customized --ollama --safety-guard  # Ollama with safety guard
#   ./up.sh --baseline                         # Pristine RHDH, no extras
#   ./up.sh --customized --both --follow-logs  # Everything enabled, tail logs
#   ./up.sh --last                             # Same options as last successful start

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
LIGHTSPEED_DIR="${RHDH_LOCAL_DIR}/developer-lightspeed"
ORCHESTRATOR_DIR="${RHDH_LOCAL_DIR}/orchestrator"

# Persisted last-run settings (gitignored); written after a successful compose up
LAST_RUN_SETTINGS_FILE="${SCRIPT_DIR}/.last-run-settings"

# Default values
MODE=""
INCLUDE_LIGHTSPEED=false
INCLUDE_ORCHESTRATOR=false
LIGHTSPEED_PROVIDER="base"
LIGHTSPEED_SAFETY_GUARD=false
FOLLOW_LOGS=false
INTERACTIVE=true
USE_LAST=false

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

# Load validated settings from .last-run-settings (do not source arbitrary shell)
load_last_config() {
    local f="$LAST_RUN_SETTINGS_FILE"
    if [ ! -f "$f" ] || [ ! -r "$f" ]; then
        print_error "No saved last run settings found at $f"
        print_info "Run $0 successfully once (interactive or with explicit flags), then use --last."
        exit 1
    fi

    local line key val
    local have_mode="" have_ls="" have_orc="" have_prov="" have_sg="" have_fl=""

    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line//[[:space:]]/}" ]] && continue
        if [[ ! "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            print_error "Invalid line in $f: $line"
            exit 1
        fi
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        val="${val//$'\r'/}"

        case "$key" in
            VERSION)
                ;;
            MODE)
                case "$val" in
                    customized|baseline)
                        MODE="$val"
                        have_mode=1
                        ;;
                    *)
                        print_error "Invalid MODE in $f: $val (expected customized or baseline)"
                        exit 1
                        ;;
                esac
                ;;
            INCLUDE_LIGHTSPEED)
                case "$val" in
                    true|false)
                        if [ "$val" = true ]; then INCLUDE_LIGHTSPEED=true; else INCLUDE_LIGHTSPEED=false; fi
                        have_ls=1
                        ;;
                    *)
                        print_error "Invalid INCLUDE_LIGHTSPEED in $f: $val"
                        exit 1
                        ;;
                esac
                ;;
            INCLUDE_ORCHESTRATOR)
                case "$val" in
                    true|false)
                        if [ "$val" = true ]; then INCLUDE_ORCHESTRATOR=true; else INCLUDE_ORCHESTRATOR=false; fi
                        have_orc=1
                        ;;
                    *)
                        print_error "Invalid INCLUDE_ORCHESTRATOR in $f: $val"
                        exit 1
                        ;;
                esac
                ;;
            LIGHTSPEED_PROVIDER)
                case "$val" in
                    base|ollama)
                        LIGHTSPEED_PROVIDER="$val"
                        have_prov=1
                        ;;
                    *)
                        print_error "Invalid LIGHTSPEED_PROVIDER in $f: $val"
                        exit 1
                        ;;
                esac
                ;;
            LIGHTSPEED_SAFETY_GUARD)
                case "$val" in
                    true|false)
                        if [ "$val" = true ]; then LIGHTSPEED_SAFETY_GUARD=true; else LIGHTSPEED_SAFETY_GUARD=false; fi
                        have_sg=1
                        ;;
                    *)
                        print_error "Invalid LIGHTSPEED_SAFETY_GUARD in $f: $val"
                        exit 1
                        ;;
                esac
                ;;
            FOLLOW_LOGS)
                case "$val" in
                    true|false)
                        if [ "$val" = true ]; then FOLLOW_LOGS=true; else FOLLOW_LOGS=false; fi
                        have_fl=1
                        ;;
                    *)
                        print_error "Invalid FOLLOW_LOGS in $f: $val"
                        exit 1
                        ;;
                esac
                ;;
            *)
                print_error "Unknown key in $f: $key"
                exit 1
                ;;
        esac
    done < "$f"

    if [ -z "$have_mode" ] || [ -z "$have_ls" ] || [ -z "$have_orc" ] || [ -z "$have_prov" ] || [ -z "$have_sg" ] || [ -z "$have_fl" ]; then
        print_error "Incomplete or invalid settings file: $f"
        print_info "Delete the file and run $0 successfully once to recreate it."
        exit 1
    fi
}

# Persist effective configuration after a successful compose up (atomic write)
save_last_config() {
    local f="$LAST_RUN_SETTINGS_FILE"
    local tmp
    tmp="$(mktemp "${f}.XXXXXX")"
    {
        echo "# Last successful up.sh configuration (auto-generated; do not commit)"
        echo "VERSION=1"
        echo "MODE=$MODE"
        echo "INCLUDE_LIGHTSPEED=$INCLUDE_LIGHTSPEED"
        echo "INCLUDE_ORCHESTRATOR=$INCLUDE_ORCHESTRATOR"
        echo "LIGHTSPEED_PROVIDER=$LIGHTSPEED_PROVIDER"
        echo "LIGHTSPEED_SAFETY_GUARD=$LIGHTSPEED_SAFETY_GUARD"
        echo "FOLLOW_LOGS=$FOLLOW_LOGS"
    } > "$tmp"
    mv "$tmp" "$f"
}

# Function to show help
show_help() {
    cat << EOF
RHDH Local Startup Script

Usage: $0 [OPTIONS]

Modes:
  --baseline         Start without customizations (pristine RHDH)
  --customized       Start with customizations applied (default)

Components:
  --lightspeed       Include Developer Lightspeed
  --orchestrator     Include Orchestrator
  --both             Include both Lightspeed and Orchestrator

Lightspeed Options:
  --ollama           Use Ollama provider (implies --lightspeed)
  --safety-guard     Enable safety guard (implies --lightspeed, combines with provider)

Other:
  --follow-logs, -f  Follow logs after startup (tail all container logs)
  --last             Reuse settings from the last successful run ($LAST_RUN_SETTINGS_FILE)
  --help, -h         Show this help message

Examples:
  $0                                    # Interactive mode
  $0 --customized --lightspeed          # Customized with Lightspeed (BYOM)
  $0 --customized --ollama              # With Lightspeed using Ollama
  $0 --customized --ollama --safety-guard # Ollama with safety guard
  $0 --baseline                         # Pristine RHDH, no extras
  $0 --customized --both                # Everything enabled
  $0 --customized --ollama --follow-logs # With Lightspeed using Ollama, tail logs
  $0 --last                             # Repeat last successful startup options

EOF
}

# Parse command-line arguments
parse_args() {
    USE_LAST=false
    local extra_config_count=0

    if [ $# -eq 0 ]; then
        INTERACTIVE=true
        return
    fi

    INTERACTIVE=false

    while [ $# -gt 0 ]; do
        case "$1" in
            --last)
                USE_LAST=true
                shift
                ;;
            --baseline)
                MODE="baseline"
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --customized)
                MODE="customized"
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --lightspeed)
                INCLUDE_LIGHTSPEED=true
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --orchestrator)
                INCLUDE_ORCHESTRATOR=true
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --both)
                INCLUDE_LIGHTSPEED=true
                INCLUDE_ORCHESTRATOR=true
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --ollama)
                INCLUDE_LIGHTSPEED=true
                LIGHTSPEED_PROVIDER="ollama"
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --safety-guard)
                INCLUDE_LIGHTSPEED=true
                LIGHTSPEED_SAFETY_GUARD=true
                extra_config_count=$((extra_config_count + 1))
                shift
                ;;
            --follow-logs|-f)
                FOLLOW_LOGS=true
                extra_config_count=$((extra_config_count + 1))
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

    if [ "$USE_LAST" = true ] && [ "$extra_config_count" -gt 0 ]; then
        print_error "--last cannot be combined with other configuration options"
        exit 1
    fi

    if [ "$USE_LAST" = true ]; then
        load_last_config
        return
    fi

    # Default to customized if not specified
    if [ -z "$MODE" ]; then
        MODE="customized"
    fi
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

# Interactive prompts
prompt_mode() {
    echo ""
    echo "Select startup mode:"
    echo "  1) Customized (with your configurations)"
    echo "  2) Baseline (pristine RHDH, no customizations)"
    echo ""
    read -p "Enter choice [1]: " mode_choice
    mode_choice=${mode_choice:-1}
    
    case "$mode_choice" in
        1)
            MODE="customized"
            ;;
        2)
            MODE="baseline"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

prompt_components() {
    echo ""
    echo "Include optional components?"
    echo "  1) None (RHDH only)"
    echo "  2) Developer Lightspeed"
    echo "  3) Orchestrator"
    echo "  4) Both Lightspeed and Orchestrator"
    echo ""
    read -p "Enter choice [1]: " component_choice
    component_choice=${component_choice:-1}
    
    case "$component_choice" in
        1)
            INCLUDE_LIGHTSPEED=false
            INCLUDE_ORCHESTRATOR=false
            ;;
        2)
            INCLUDE_LIGHTSPEED=true
            INCLUDE_ORCHESTRATOR=false
            ;;
        3)
            INCLUDE_LIGHTSPEED=false
            INCLUDE_ORCHESTRATOR=true
            ;;
        4)
            INCLUDE_LIGHTSPEED=true
            INCLUDE_ORCHESTRATOR=true
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

prompt_lightspeed_provider() {
    if [ "$INCLUDE_LIGHTSPEED" = true ]; then
        echo ""
        echo "Select Lightspeed LLM provider:"
        echo "  1) Bring Your Own Model (BYOM)"
        echo "  2) Ollama (local LLM)"
        echo ""
        read -p "Enter choice [1]: " provider_choice
        provider_choice=${provider_choice:-1}
        
        case "$provider_choice" in
            1)
                LIGHTSPEED_PROVIDER="base"
                ;;
            2)
                LIGHTSPEED_PROVIDER="ollama"
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

prompt_lightspeed_safety_guard() {
    if [ "$INCLUDE_LIGHTSPEED" = true ]; then
        echo ""
        echo "Enable safety guard (Llama Guard content filtering)?"
        echo "  1) No safety guard"
        echo "  2) With safety guard"
        echo ""
        read -p "Enter choice [1]: " safety_choice
        safety_choice=${safety_choice:-1}
        
        case "$safety_choice" in
            1)
                LIGHTSPEED_SAFETY_GUARD=false
                ;;
            2)
                LIGHTSPEED_SAFETY_GUARD=true
                ;;
            *)
                print_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

prompt_follow_logs() {
    echo ""
    echo "Would you like to follow logs after startup?"
    echo "  This will automatically tail all container logs once they're running."
    echo "  (You can exit log view anytime with Ctrl+C)"
    echo ""
    read -p "Follow logs? [y/N]: " follow_choice
    follow_choice=${follow_choice:-N}
    
    if [[ "$follow_choice" =~ ^[Yy]$ ]]; then
        FOLLOW_LOGS=true
        print_info "Will follow logs after startup"
    else
        FOLLOW_LOGS=false
        print_info "Will not follow logs (manual: cd rhdh-local && podman compose logs -f)"
    fi
}

# Apply or remove customizations
manage_customizations() {
    if [ "$MODE" = "customized" ]; then
        print_info "Applying customizations..."
        cd "$CUSTOMIZATIONS_DIR"
        if [ -f "apply-customizations.sh" ]; then
            bash apply-customizations.sh
            print_success "Customizations applied"
        else
            print_error "apply-customizations.sh not found"
            exit 1
        fi
    else
        print_info "Removing customizations for baseline mode..."
        cd "$CUSTOMIZATIONS_DIR"
        if [ -f "remove-customizations.sh" ]; then
            bash remove-customizations.sh
            print_success "Customizations removed (baseline mode)"
        else
            print_error "remove-customizations.sh not found"
            exit 1
        fi
    fi
}

# Build compose command
build_compose_command() {
    local runtime=$1
    local compose_files="-f compose.yaml"
    
    # CRITICAL: When using -f flags, compose.override.yaml is NOT automatically loaded
    # We must explicitly include it if it exists (it's created by apply-customizations.sh)
    if [ -f "compose.override.yaml" ]; then
        compose_files="$compose_files -f compose.override.yaml"
    fi
    
    # Add Lightspeed compose files (provider + optional safety guard)
    if [ "$INCLUDE_LIGHTSPEED" = true ]; then
        if [ "$LIGHTSPEED_PROVIDER" = "ollama" ]; then
            compose_files="$compose_files -f developer-lightspeed/compose-with-ollama.yaml"
            if [ "$LIGHTSPEED_SAFETY_GUARD" = true ]; then
                compose_files="$compose_files -f developer-lightspeed/compose-with-safety-guard-ollama.yaml"
            fi
        else
            compose_files="$compose_files -f developer-lightspeed/compose.yaml"
            if [ "$LIGHTSPEED_SAFETY_GUARD" = true ]; then
                compose_files="$compose_files -f developer-lightspeed/compose-with-safety-guard.yaml"
            fi
        fi
    fi
    
    # Add Orchestrator compose file
    if [ "$INCLUDE_ORCHESTRATOR" = true ]; then
        compose_files="$compose_files -f orchestrator/compose.yaml"
    fi
    
    echo "$runtime compose $compose_files up -d"
}

# Main execution
main() {
    print_header "RHDH Local Startup"
    
    # Parse arguments
    parse_args "$@"
    
    # Detect runtime
    RUNTIME=$(detect_runtime)
    print_info "Using container runtime: $RUNTIME"
    
    # Interactive prompts if needed
    if [ "$INTERACTIVE" = true ]; then
        prompt_mode
        prompt_components
        prompt_lightspeed_provider
        prompt_lightspeed_safety_guard
        prompt_follow_logs
    fi
    
    # Display configuration
    echo ""
    print_header "Configuration Summary"
    echo "Mode:          $MODE"
    echo "Lightspeed:    $INCLUDE_LIGHTSPEED"
    if [ "$INCLUDE_LIGHTSPEED" = true ]; then
        echo "  Provider:    $LIGHTSPEED_PROVIDER"
        echo "  Safety guard: $LIGHTSPEED_SAFETY_GUARD"
    fi
    echo "Orchestrator:  $INCLUDE_ORCHESTRATOR"
    echo "Follow logs:   $FOLLOW_LOGS"
    echo "Runtime:       $RUNTIME"
    echo ""
    
    if [ "$INTERACTIVE" = true ]; then
        read -p "Proceed with this configuration? [Y/n]: " confirm
        confirm=${confirm:-Y}
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warning "Cancelled by user"
            exit 0
        fi
    fi
    
    # Manage customizations
    print_header "Managing Customizations"
    manage_customizations
    
    # Change to rhdh-local directory
    cd "$RHDH_LOCAL_DIR"
    
    # Build and execute compose command
    print_header "Starting RHDH Local"
    COMPOSE_CMD=$(build_compose_command "$RUNTIME")
    print_info "Executing: $COMPOSE_CMD"
    eval "$COMPOSE_CMD"

    save_last_config
    print_info "Saved last run settings to $LAST_RUN_SETTINGS_FILE"
    
    # Success message
    echo ""
    print_header "Startup Complete"
    print_success "RHDH Local is starting up"
    print_info "Access at: http://localhost:7007"
    
    if [ "$MODE" = "baseline" ]; then
        print_warning "Running in BASELINE mode (no customizations)"
        print_info "To restore customizations: cd rhdh-customizations && ./apply-customizations.sh"
    fi
    
    # Follow logs if requested
    if [ "$FOLLOW_LOGS" = true ]; then
        echo ""
        print_info "Following logs for all containers (Ctrl+C to exit)..."
        echo ""
        sleep 1  # Brief pause for user to read the message
        exec $RUNTIME compose logs -f
    else
        print_info "View logs: cd rhdh-local && $RUNTIME compose logs -f rhdh"
        echo ""
    fi
}

# Run main
main "$@"
