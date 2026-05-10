#!/usr/bin/env bash
# setup.sh — Configure Claude Code to use DeepSeek API as backend
# Repository: https://github.com/xuechaow/claudeep
#
# Usage:
#   ./setup.sh                        # Interactive, prompts for API key
#   ./setup.sh sk-your-api-key        # Non-interactive
#   ./setup.sh --uninstall            # Remove all configuration
#   ./setup.sh --shell fish           # Override shell auto-detection
#   ./setup.sh --no-test              # Skip API connectivity test
#   ./setup.sh --dry-run              # Show what would be done
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/xuechaow/claudeep/main/setup.sh | bash -s -- YOUR_API_KEY

set -euo pipefail

# ── Configuration defaults (override via env vars before running) ─────
BASE_URL="${CLD_DEEP_BASE_URL:-https://api.deepseek.com/anthropic}"
SONNET_MODEL="${CLD_DEEP_SONNET_MODEL:-deepseek-v4-pro}"
OPUS_MODEL="${CLD_DEEP_OPUS_MODEL:-deepseek-v4-pro}"
HAIKU_MODEL="${CLD_DEEP_HAIKU_MODEL:-deepseek-v4-flash}"
SUBAGENT_MODEL="${CLD_DEEP_SUBAGENT_MODEL:-deepseek-v4-flash}"
EFFORT_LEVEL="${CLD_DEEP_EFFORT_LEVEL:-max}"

ENV_DIR="${HOME}/.deepseek-claude"
ENV_FILE="${ENV_DIR}/env"
ENV_FILE_FISH="${ENV_DIR}/env.fish"

# ── Terminal colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

error()   { echo -e "${RED}Error:${NC} $*" >&2; }
success() { echo -e "${GREEN}✓${NC} $*"; }
info()    { echo -e "${YELLOW}→${NC} $*"; }
step()    { echo -e "${BLUE}→${NC} $*"; }

# ── Usage ─────────────────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}DeepSeek + Claude Code Integration Setup${NC}

Configure Claude Code to use the DeepSeek API as its model backend.

${BOLD}Usage:${NC}
  claudeep COMMAND [OPTIONS]

${BOLD}Commands:${NC}
  setup [API_KEY]     Configure DeepSeek integration
  status              Quick health check (default when run with no args)
  doctor [--fix]      Full diagnostic — run when something is wrong
  uninstall           Remove all configuration files and shell integration
  install             Install claudeep as a global CLI command
  help                Show this message

${BOLD}Doctor options:${NC}
  --fix               Auto-repair common issues (key mismatch, stale exports)

${BOLD}Install options:${NC}
  --cli-name NAME     CLI command name (default: claudeep)
  --cli-bin DIR       Install directory (default: /usr/local/bin)

${BOLD}Setup options:${NC}
  -s, --shell NAME    Specify shell (bash, zsh, fish). Auto-detected by default.
  -n, --no-test       Skip the API connectivity test during setup
  -d, --dry-run       Print what would be done without making changes
  -q, --quiet         Suppress informational output (errors still shown)

${BOLD}Examples:${NC}
  claudeep                                # Quick status check
  claudeep status                         # Same as above
  claudeep doctor                         # Full diagnostic
  claudeep doctor --fix                   # Diagnostic + auto-repair
  claudeep setup sk-abc123def456          # Configure with API key
  claudeep uninstall                      # Remove everything
  claudeep install                        # Install as global command

${BOLD}Environment variable overrides:${NC}
  CLD_DEEP_BASE_URL          Default: ${BASE_URL}
  CLD_DEEP_SONNET_MODEL      Default: ${SONNET_MODEL}
  CLD_DEEP_OPUS_MODEL        Default: ${OPUS_MODEL}
  CLD_DEEP_HAIKU_MODEL       Default: ${HAIKU_MODEL}
  CLD_DEEP_SUBAGENT_MODEL    Default: ${SUBAGENT_MODEL}
  CLD_DEEP_EFFORT_LEVEL      Default: ${EFFORT_LEVEL}

${BOLD}Supported shells:${NC} bash, zsh, fish
EOF
    exit 0
}

# ── Shell detection ───────────────────────────────────────────────────
detect_shell() {
    # Respect explicit override
    if [[ -n "${ARG_SHELL:-}" ]]; then
        echo "$ARG_SHELL"
        return
    fi
    local name
    name=$(basename "${SHELL:-/bin/bash}")
    echo "$name"
}

detect_shell_config() {
    local shell_name="$1"
    case "$shell_name" in
        zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
        bash)
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS Terminal.app opens login shells → .bash_profile
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)
            error "Unsupported shell: ${shell_name}. Use --shell to specify bash, zsh, or fish."
            exit 1
            ;;
    esac
}

# ── API key validation ────────────────────────────────────────────────
validate_api_key() {
    local key="$1"
    if [[ -z "$key" ]]; then
        error "API key cannot be empty."
        return 1
    fi
    if [[ ! "$key" =~ ^sk-[A-Za-z0-9]+$ ]]; then
        error "API key should start with 'sk-' and contain only alphanumeric characters."
        return 1
    fi
    return 0
}

# ── Write env file (POSIX export syntax for bash/zsh) ─────────────────
write_posix_env() {
    local key="$1"
    mkdir -p "$(dirname "$ENV_FILE")"
    cat > "$ENV_FILE" <<ENVEOF
# DeepSeek + Claude Code integration
# Generated by setup.sh on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Repository: https://github.com/xuechaow/claudeep

export ANTHROPIC_BASE_URL="${BASE_URL}"
export ANTHROPIC_AUTH_TOKEN="${key}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${SONNET_MODEL}"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${OPUS_MODEL}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${HAIKU_MODEL}"
export CLAUDE_CODE_SUBAGENT_MODEL="${SUBAGENT_MODEL}"
export CLAUDE_CODE_EFFORT_LEVEL="${EFFORT_LEVEL}"
ENVEOF
    chmod 600 "$ENV_FILE"
}

# ── Write env file (fish set -gx syntax) ──────────────────────────────
write_fish_env() {
    local key="$1"
    mkdir -p "$(dirname "$ENV_FILE_FISH")"
    cat > "$ENV_FILE_FISH" <<ENVEOF
# DeepSeek + Claude Code integration
# Generated by setup.sh on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Repository: https://github.com/xuechaow/claudeep

set -gx ANTHROPIC_BASE_URL "${BASE_URL}"
set -gx ANTHROPIC_AUTH_TOKEN "${key}"
set -gx ANTHROPIC_DEFAULT_SONNET_MODEL "${SONNET_MODEL}"
set -gx ANTHROPIC_DEFAULT_OPUS_MODEL "${OPUS_MODEL}"
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL "${HAIKU_MODEL}"
set -gx CLAUDE_CODE_SUBAGENT_MODEL "${SUBAGENT_MODEL}"
set -gx CLAUDE_CODE_EFFORT_LEVEL "${EFFORT_LEVEL}"
ENVEOF
    chmod 600 "$ENV_FILE_FISH"
}

# ── Add source line to shell config ───────────────────────────────────
add_source_line() {
    local config_file="$1"
    local shell_name="$2"
    local source_line
    local marker_start="# >>> DeepSeek Claude integration >>>"
    local marker_end="# <<< DeepSeek Claude integration <<<"

    # Determine source line based on shell
    case "$shell_name" in
        fish)
            source_line="source ${ENV_FILE_FISH}"
            ;;
        *)
            source_line="[ -f ${ENV_FILE} ] && source ${ENV_FILE}"
            ;;
    esac

    # Remove any existing integration block
    remove_source_block "$config_file"

    # Ensure file exists
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"

    # Add trailing newline if needed
    if [[ -s "$config_file" ]] && [[ "$(tail -c 1 "$config_file")" != $'\n' ]]; then
        echo "" >> "$config_file"
    fi

    {
        echo ""
        echo "$marker_start"
        echo "$source_line"
        echo "$marker_end"
    } >> "$config_file"
}

# ── Remove integration block from shell config ────────────────────────
remove_source_block() {
    local config_file="$1"
    local marker_start="# >>> DeepSeek Claude integration >>>"
    local marker_end="# <<< DeepSeek Claude integration <<<"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # macOS sed vs GNU sed compat
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "/^${marker_start//\//\\/}/,/^${marker_end//\//\\/}/d" "$config_file" 2>/dev/null || true
    else
        sed -i "/^${marker_start//\//\\/}/,/^${marker_end//\//\\/}/d" "$config_file" 2>/dev/null || true
    fi
}

# ── Spinner animation ────────────────────────────────────────────────
_spinner_pid=""
_spin() {
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "${_spinner_pid}" 2>/dev/null; do
        printf "\r  ${BLUE}%s${NC} Testing connection..." "${chars:$i:1}"
        i=$(( (i + 1) % ${#chars} ))
        sleep 0.1
    done
    printf "\r\033[K"
}

# ── Test API connectivity ─────────────────────────────────────────────
test_api() {
    local key="$1"
    local url="${BASE_URL}/v1/messages"

    local tmpfile
    tmpfile="$(mktemp)"

    # Run curl in background, spinner on top
    (
        curl -s -w "\n%{http_code}" -m 20 -X POST "$url" \
            -H "Content-Type: application/json" \
            -H "x-api-key: ${key}" \
            -H "anthropic-version: 2023-06-01" \
            -d "{\"model\":\"${SONNET_MODEL}\",\"max_tokens\":8,\"messages\":[{\"role\":\"user\",\"content\":\"say OK\"}]}" 2>&1
    ) > "$tmpfile" &
    _spinner_pid=$!
    _spin
    wait "${_spinner_pid}" || true

    local response
    response="$(cat "$tmpfile")"
    rm -f "$tmpfile"

    if [[ -z "$response" ]]; then
        error "Could not reach the API. Check your network and the BASE_URL."
        return 1
    fi

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]] && echo "$body" | grep -q '"id":'; then
        success "API connection verified (HTTP ${http_code})."
        return 0
    else
        error "API test returned HTTP ${http_code}."
        echo "Response: $(echo "$body" | head -c 500)" >&2
        return 1
    fi
}

# ── Export to current shell session ───────────────────────────────────
export_to_current_shell() {
    local key="$1"
    local shell_name="$2"

    step "Exporting variables to current shell..."

    if [[ "$shell_name" == "fish" ]]; then
        # We can't export directly from bash into a fish parent process.
        # Instead we print commands the user can evaluate.
        cat <<FISHCMD

  Your shell is ${BOLD}fish${NC}. Environment variables cannot be set in the
  current session from a bash script. Run this command manually:

    ${GREEN}source ${ENV_FILE_FISH}${NC}

  Or open a new terminal — the variables load automatically.
FISHCMD
        return 0
    fi

    export ANTHROPIC_BASE_URL="${BASE_URL}"
    export ANTHROPIC_AUTH_TOKEN="${key}"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="${SONNET_MODEL}"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="${OPUS_MODEL}"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="${HAIKU_MODEL}"
    export CLAUDE_CODE_SUBAGENT_MODEL="${SUBAGENT_MODEL}"
    export CLAUDE_CODE_EFFORT_LEVEL="${EFFORT_LEVEL}"
    success "Variables exported to current ${shell_name} session."
}

# ── Install ───────────────────────────────────────────────────────────
do_install() {
    local key="$1"
    local shell_name="$2"
    local config_file="$3"

    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║  DeepSeek + Claude Code Integration Setup    ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    validate_api_key "$key" || exit 1

    info "Shell:       ${shell_name}"
    info "Config file: ${config_file}"
    info "Env dir:     ${ENV_DIR}"
    echo ""

    if [[ "${ARG_DRY_RUN:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would create ${ENV_FILE} with API key and model config."
        if [[ "$shell_name" == "fish" ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would also create ${ENV_FILE_FISH} with fish syntax."
        fi
        echo -e "${YELLOW}[DRY RUN]${NC} Would add source line to ${config_file}."
        echo -e "${YELLOW}[DRY RUN]${NC} Would test API connectivity."
        return 0
    fi

    # Create env directory
    mkdir -p "$ENV_DIR"
    chmod 700 "$ENV_DIR"

    # Write env file(s)
    if [[ "$shell_name" == "fish" ]]; then
        write_fish_env "$key"
        success "Created ${ENV_FILE_FISH}"
    fi
    write_posix_env "$key"
    success "Created ${ENV_FILE}"

    # Add source line to shell config
    add_source_line "$config_file" "$shell_name"
    success "Updated ${config_file}"

    # Export to current session
    export_to_current_shell "$key" "$shell_name"

    # Test API
    echo ""
    if [[ "${ARG_NO_TEST:-false}" != "true" ]]; then
        if test_api "$key"; then
            echo ""
            echo -e "${GREEN}${BOLD}🎉 Setup complete!${NC}"
            echo ""
            echo -e "  Run:  ${BOLD}claude --bare${NC}"
            echo ""
            echo "  For new terminals, the config loads automatically."
            echo "  To verify:  echo \$ANTHROPIC_BASE_URL"
        else
            echo ""
            echo -e "${YELLOW}Configuration written, but the API test failed.${NC}"
            echo "  Check your API key and network, then try again:"
            echo "  ${BOLD}source ${ENV_FILE}${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}${BOLD}✓ Setup complete (API test skipped).${NC}"
        echo ""
        echo -e "  Run:  ${BOLD}claude --bare${NC}"
    fi

    # Offer to install CLI if script is a real file and terminal is interactive
    if [[ -f "${BASH_SOURCE[0]:-$0}" ]] && [[ -t 0 ]] && [[ "${ARG_QUIET:-false}" != "true" ]]; then
        local cli_name="${ARG_CLI_NAME:-claudeep}"
        if ! command -v "$cli_name" &>/dev/null; then
            echo ""
            echo -n "Install '${cli_name}' CLI command to /usr/local/bin? [Y/n] "
            read -r reply || true
            if [[ -z "$reply" ]] || [[ "$reply" =~ ^[Yy] ]]; then
                do_install_cli
            fi
        fi
    fi
}

# ── Uninstall ─────────────────────────────────────────────────────────
do_uninstall() {
    local shell_name="$1"
    local config_file="$2"

    echo ""
    echo -e "${BOLD}${YELLOW}DeepSeek + Claude Code — Uninstall${NC}"
    echo ""

    if [[ "${ARG_DRY_RUN:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would remove integration block from ${config_file}."
        echo -e "${YELLOW}[DRY RUN]${NC} Would delete ${ENV_DIR}/"
        return 0
    fi

    # Remove source block from shell config
    if [[ -f "$config_file" ]]; then
        remove_source_block "$config_file"
        success "Removed integration from ${config_file}"
    fi

    # Remove env files
    if [[ -d "$ENV_DIR" ]]; then
        rm -rf "$ENV_DIR"
        success "Removed ${ENV_DIR}/"
    fi

    echo ""
    echo -e "${GREEN}Uninstall complete.${NC}"
    echo ""
    echo "  The following variables are ${BOLD}still set${NC} in this terminal session:"
    echo "    ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, model vars"
    echo "  They will be gone when you open a new terminal."
    echo ""
    echo "  To clear them now:"
    echo "    unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_DEFAULT_SONNET_MODEL"
    echo "    unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL"
    echo "    unset CLAUDE_CODE_SUBAGENT_MODEL CLAUDE_CODE_EFFORT_LEVEL"
    echo ""
}

# ── Status (quick check, no args default) ─────────────────────────────
do_status() {
    local shell_name="$1"
    local config_file="$2"
    local ok=true

    echo ""

    # Env check
    if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        echo -e "  ${GREEN}●${NC} Key: ${ANTHROPIC_AUTH_TOKEN:0:10}...${ANTHROPIC_AUTH_TOKEN: -4}"
    else
        echo -e "  ${RED}○${NC} Key: not set — run ${BOLD}claudeep setup sk-YOUR-KEY${NC}"
        ok=false
    fi

    if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
        echo -e "  ${GREEN}●${NC} URL: ${ANTHROPIC_BASE_URL}"
    fi

    # Config file
    if [[ -f "$ENV_FILE" ]]; then
        local env_key
        env_key=$(grep 'ANTHROPIC_AUTH_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'"' -f2)
        if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]] && [[ "$env_key" == "${ANTHROPIC_AUTH_TOKEN}" ]]; then
            echo -e "  ${GREEN}●${NC} Config: matches session"
        elif [[ -n "$env_key" ]]; then
            echo -e "  ${YELLOW}●${NC} Config: key mismatch — run ${BOLD}claudeep doctor --fix${NC}"
            ok=false
        fi
    fi

    # Shell integration
    if [[ -f "$config_file" ]]; then
        if grep -q ">>> DeepSeek Claude integration >>>" "$config_file" 2>/dev/null; then
            echo -e "  ${GREEN}●${NC} Shell: integrated"
        else
            echo -e "  ${YELLOW}●${NC} Shell: not integrated — run ${BOLD}claudeep setup${NC}"
            ok=false
        fi
    fi

    echo ""
    if [[ "$ok" == "true" ]]; then
        echo -e "  ${GREEN}${BOLD}Ready.${NC} Run: ${BOLD}claude --bare${NC}"
    else
        echo -e "  ${YELLOW}Run ${BOLD}claudeep doctor${NC} for details."
    fi
    echo ""
}

# ── Doctor ────────────────────────────────────────────────────────────
# ARG_DOCTOR_FIX=true when --fix is passed
do_doctor() {
    local shell_name="$1"
    local config_file="$2"
    local issues=0
    local warnings=0

    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║  DeepSeek + Claude Code — Health Check       ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    # ── 1. Current environment ──────────────────────────────────────
    echo -e "${BOLD}1. Environment variables${NC}"
    if [[ -n "${ANTHROPIC_BASE_URL:-}" ]]; then
        echo -e "   ${GREEN}✓${NC} ANTHROPIC_BASE_URL = ${ANTHROPIC_BASE_URL}"
    else
        echo -e "   ${RED}✗${NC} ANTHROPIC_BASE_URL not set"
        ((issues++))
    fi

    if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        local cur_key="${ANTHROPIC_AUTH_TOKEN}"
        echo -e "   ${GREEN}✓${NC} ANTHROPIC_AUTH_TOKEN = ${cur_key:0:10}...${cur_key: -4}"
    else
        echo -e "   ${RED}✗${NC} ANTHROPIC_AUTH_TOKEN not set"
        ((issues++))
    fi

    local models=(SONNET_MODEL OPUS_MODEL HAIKU_MODEL)
    for m in "${models[@]}"; do
        local varname="ANTHROPIC_DEFAULT_${m}"
        if [[ -n "${!varname:-}" ]]; then
            echo -e "   ${GREEN}✓${NC} ${varname} = ${!varname}"
        else
            echo -e "   ${YELLOW}⚠${NC} ${varname} not set (will use Claude Code default)"
            ((warnings++))
        fi
    done

    if [[ -n "${CLAUDE_CODE_SUBAGENT_MODEL:-}" ]]; then
        echo -e "   ${GREEN}✓${NC} CLAUDE_CODE_SUBAGENT_MODEL = ${CLAUDE_CODE_SUBAGENT_MODEL}"
    fi
    if [[ -n "${CLAUDE_CODE_EFFORT_LEVEL:-}" ]]; then
        echo -e "   ${GREEN}✓${NC} CLAUDE_CODE_EFFORT_LEVEL = ${CLAUDE_CODE_EFFORT_LEVEL}"
    fi

    # ── 2. Env file ─────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}2. Config file${NC} (${ENV_FILE})"
    if [[ -f "$ENV_FILE" ]]; then
        local perms
        perms=$(stat -f "%p" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null)
        if [[ "$perms" == "100600" || "$perms" == "600" ]]; then
            echo -e "   ${GREEN}✓${NC} File exists (permissions: 600)"
        else
            echo -e "   ${YELLOW}⚠${NC} File exists but permissions are ${perms} (should be 600)"
            if [[ "${ARG_DOCTOR_FIX:-false}" == "true" ]]; then
                chmod 600 "$ENV_FILE"
                echo -e "     ${GREEN}Fixed${NC}: permissions set to 600"
            fi
            ((warnings++))
        fi

        # Compare env file key with current env key
        local env_key
        env_key=$(grep 'ANTHROPIC_AUTH_TOKEN=' "$ENV_FILE" 2>/dev/null | cut -d'"' -f2)
        if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]] && [[ -n "$env_key" ]]; then
            if [[ "$env_key" == "${ANTHROPIC_AUTH_TOKEN}" ]]; then
                echo -e "   ${GREEN}✓${NC} Key matches current environment"
            else
                echo -e "   ${RED}✗${NC} Key MISMATCH — env file differs from current session!"
                echo -e "     ${YELLOW}Env file:${NC} ${env_key:0:10}...${env_key: -4}"
                echo -e "     ${YELLOW}Current:${NC}  ${ANTHROPIC_AUTH_TOKEN:0:10}...${ANTHROPIC_AUTH_TOKEN: -4}"
                if [[ "${ARG_DOCTOR_FIX:-false}" == "true" ]]; then
                    source "$ENV_FILE"
                    echo -e "     ${GREEN}Fixed${NC}: sourced ${ENV_FILE}"
                    echo -e "     ${YELLOW}→${NC} Current key is now: ${ANTHROPIC_AUTH_TOKEN:0:10}...${ANTHROPIC_AUTH_TOKEN: -4}"
                else
                    echo -e "     ${GREEN}Fix:${NC} source ${ENV_FILE}"
                fi
                ((issues++))
            fi
        fi

        # Check for stale env.fish
        if [[ -f "$ENV_FILE_FISH" ]]; then
            local fish_key
            fish_key=$(grep 'ANTHROPIC_AUTH_TOKEN' "$ENV_FILE_FISH" 2>/dev/null | cut -d'"' -f2)
            if [[ -n "$env_key" ]] && [[ "$fish_key" != "$env_key" ]]; then
                echo -e "   ${YELLOW}⚠${NC} env.fish has a different key (fish users may have issues)"
                ((warnings++))
            fi
        fi
    else
        echo -e "   ${RED}✗${NC} File missing"
        echo -e "     ${GREEN}Fix:${NC} claudeep setup YOUR_API_KEY"
        ((issues++))
    fi

    # ── 3. Shell config ─────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}3. Shell integration${NC} (${config_file})"
    if [[ -f "$config_file" ]]; then
        # Check for integration marker block
        local marker_count
        marker_count=$(grep -c ">>> DeepSeek Claude integration >>>" "$config_file" 2>/dev/null || true)
        if [[ "$marker_count" -eq 1 ]]; then
            echo -e "   ${GREEN}✓${NC} Integration block present"
        elif [[ "$marker_count" -gt 1 ]]; then
            echo -e "   ${RED}✗${NC} ${marker_count} duplicate integration blocks!"
            if [[ "${ARG_DOCTOR_FIX:-false}" == "true" ]]; then
                # Remove all blocks, then re-add one clean one
                while grep -q ">>> DeepSeek Claude integration >>>" "$config_file" 2>/dev/null; do
                    remove_source_block "$config_file"
                done
                add_source_line "$config_file" "$shell_name"
                echo -e "     ${GREEN}Fixed${NC}: consolidated into a single clean integration block"
            else
                echo -e "     ${GREEN}Fix:${NC} claudeep uninstall && claudeep setup YOUR_KEY"
            fi
            ((issues++))
        else
            echo -e "   ${RED}✗${NC} No integration block found"
            if [[ "${ARG_DOCTOR_FIX:-false}" == "true" ]]; then
                add_source_line "$config_file" "$shell_name"
                echo -e "     ${GREEN}Fixed${NC}: added integration block to ${config_file}"
            else
                echo -e "     ${GREEN}Fix:${NC} claudeep setup YOUR_KEY"
            fi
            ((issues++))
        fi

        # Check for stale direct exports (outside the marker block)
        local direct_count
        direct_count=$(grep -c "^export ANTHROPIC_" "$config_file" 2>/dev/null || true)
        if [[ "$direct_count" -gt 0 ]]; then
            echo -e "   ${RED}✗${NC} Found ${direct_count} direct export(s) OUTSIDE the integration block"
            echo -e "     These override ~/.deepseek-claude/env and may load stale keys."

            # Show the problematic lines
            local stale_lines
            stale_lines=$(grep -n "^export ANTHROPIC_" "$config_file" 2>/dev/null || true)
            if [[ -n "$stale_lines" ]]; then
                while IFS= read -r line; do
                    echo -e "       ${YELLOW}Line ${line}${NC}"
                done <<< "$stale_lines"
            fi

            if [[ "${ARG_DOCTOR_FIX:-false}" == "true" ]]; then
                echo -e "     ${BLUE}→${NC} Removing stale direct exports..."
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' '/^export ANTHROPIC_/d' "$config_file"
                    sed -i '' '/^export CLAUDE_CODE_/d' "$config_file"
                    # Also remove old comment lines left orphaned
                    sed -i '' '/^# DeepSeek + Claude Code configuration (added/d' "$config_file"
                else
                    sed -i '/^export ANTHROPIC_/d' "$config_file"
                    sed -i '/^export CLAUDE_CODE_/d' "$config_file"
                    sed -i '/^# DeepSeek + Claude Code configuration (added/d' "$config_file"
                fi
                echo -e "     ${GREEN}Fixed${NC}: removed ${direct_count} stale export(s)"
                # If we removed stale exports and there's an integration block, also source to reload
                if [[ "$marker_count" -ge 1 ]] && [[ -f "$ENV_FILE" ]]; then
                    source "$ENV_FILE"
                    echo -e "     ${GREEN}Fixed${NC}: reloaded correct key from ${ENV_FILE}"
                fi
            else
                echo -e "     ${GREEN}Fix:${NC} claudeep doctor --fix (auto-removes stale lines)"
            fi
            ((issues++))
        else
            echo -e "   ${GREEN}✓${NC} No stale direct exports"
        fi
    else
        echo -e "   ${YELLOW}⚠${NC} Config file does not exist yet (will be created during setup)"
        ((warnings++))
    fi

    # ── 4. API connectivity ─────────────────────────────────────────
    echo ""
    echo -e "${BOLD}4. API connectivity${NC}"
    if [[ "${ARG_NO_TEST:-false}" == "true" ]]; then
        echo -e "   ${YELLOW}⊘${NC} Skipped (--no-test)"
    elif [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
        if test_api "${ANTHROPIC_AUTH_TOKEN}"; then
            : # test_api already prints success
        else
            ((issues++))
        fi
    else
        echo -e "   ${YELLOW}⊘${NC} Skipped — no API key in environment"
        ((warnings++))
    fi

    # ── 5. CLI check ────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}5. CLI installation${NC}"
    local found_cli=false
    local cli_name="${ARG_CLI_NAME:-claudeep}"
    if command -v "$cli_name" &>/dev/null; then
        local cli_path
        cli_path=$(command -v "$cli_name")
        echo -e "   ${GREEN}✓${NC} Command '${cli_name}' found at ${cli_path}"
        found_cli=true
    fi
    if command -v claude &>/dev/null; then
        local claude_path
        claude_path=$(command -v claude)
        echo -e "   ${GREEN}✓${NC} Claude Code found at ${claude_path}"
    else
        echo -e "   ${YELLOW}⚠${NC} Claude Code CLI not found in PATH"
        ((warnings++))
    fi
    if [[ "$found_cli" == "false" ]]; then
        echo -e "   ${YELLOW}⊘${NC} Setup CLI not installed. Run: ${BOLD}./setup.sh install${NC}"
    fi

    # ── Summary ─────────────────────────────────────────────────────
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════${NC}"
    if [[ "$issues" -eq 0 ]] && [[ "$warnings" -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ All checks passed.${NC} You're ready: ${BOLD}claude --bare${NC}"
    elif [[ "$issues" -eq 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}✓ OK with ${warnings} minor warning(s).${NC}"
        echo -e "  Review above. Run: ${BOLD}claude --bare${NC}"
    else
        echo -e "  ${RED}${BOLD}✗ Found ${issues} issue(s), ${warnings} warning(s).${NC}"
        if [[ "${ARG_DOCTOR_FIX:-false}" != "true" ]]; then
            echo -e "  Run: ${BOLD}claudeep doctor --fix${NC} to auto-repair"
        else
            echo -e "  Re-run: ${BOLD}claudeep doctor${NC} to verify repairs"
        fi
    fi
    echo ""
}

# ── CLI installation ────────────────────────────────────────────────
do_install_cli() {
    local bin_dir="${ARG_CLI_BIN:-/usr/local/bin}"
    local cli_name="${ARG_CLI_NAME:-claudeep}"
    local target="${bin_dir}/${cli_name}"
    local script_path

    # Determine script location; if piped (no real file), download from GitHub
    if [[ -f "${BASH_SOURCE[0]:-$0}" ]]; then
        script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/$(basename "${BASH_SOURCE[0]:-$0}")"
    else
        script_path="${ENV_DIR}/setup.sh"
        info "Downloading setup.sh from GitHub..."
        curl -fsSL https://raw.githubusercontent.com/xuechaow/claudeep/main/setup.sh -o "$script_path"
        chmod +x "$script_path"
    fi

    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║  Install CLI Command                         ║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    info "Script:  ${script_path}"
    info "Target:  ${target}"

    if [[ "${ARG_DRY_RUN:-false}" == "true" ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would symlink ${script_path} → ${target}"
        return 0
    fi

    # Check write permission; suggest sudo if needed
    if [[ ! -w "$bin_dir" ]]; then
        echo ""
        echo -e "  ${YELLOW}${bin_dir} is not writable.${NC}"
        echo -e "  Rerun with sudo:"
        echo ""
        echo -e "    ${BOLD}sudo ./setup.sh --install-cli${NC}"
        echo ""
        return 1
    fi

    # Remove existing symlink or file at target
    if [[ -L "$target" ]] || [[ -f "$target" ]]; then
        info "Removing existing ${target}"
        rm -f "$target"
    fi

    # Create symlink
    ln -s "$script_path" "$target"
    chmod +x "$target" 2>/dev/null || true

    success "Installed: ${BOLD}${cli_name}${NC} → ${script_path}"
    echo ""
    echo -e "  Now you can run from anywhere:"
    echo ""
    echo -e "    ${BOLD}${cli_name} doctor${NC}              # Health check"
    echo -e "    ${BOLD}${cli_name} doctor --fix${NC}        # Auto-repair issues"
    echo -e "    ${BOLD}${cli_name} uninstall${NC}           # Remove config"
    echo -e "    ${BOLD}${cli_name} install${NC}             # Re-install CLI"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
    local ARG_SHELL=""
    local ARG_UNINSTALL=false
    local ARG_STATUS=false
    local ARG_DOCTOR=false
    local ARG_DOCTOR_FIX=false
    local ARG_INSTALL_CLI=false
    local ARG_CLI_NAME=""
    local ARG_CLI_BIN=""
    local ARG_NO_TEST=false
    local ARG_DRY_RUN=false
    local ARG_QUIET=false
    local API_KEY=""

    # ── Subcommand-style parsing: first positional arg is the command ──
    if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]] && [[ ! "$1" =~ ^sk- ]]; then
        case "$1" in
            help)      usage ;;
            status)    ARG_STATUS=true; shift ;;
            doctor)    ARG_DOCTOR=true; shift ;;
            uninstall) ARG_UNINSTALL=true; shift ;;
            install)   ARG_INSTALL_CLI=true; shift ;;
            setup)     shift ;;  # "setup" is a no-op, fall through to install flow
            *)
                if [[ "$1" =~ ^sk- ]]; then
                    API_KEY="$1"; shift
                else
                    error "Unknown command: $1"; usage; exit 1
                fi
                ;;
        esac
    fi

    # ── Flag parsing (handles both --flags and subcommand args) ──────
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)       usage ;;
            -u|--uninstall)   ARG_UNINSTALL=true; shift ;;
            -D|--doctor)      ARG_DOCTOR=true; shift ;;
            --fix)            ARG_DOCTOR_FIX=true; shift ;;
            -I|--install-cli) ARG_INSTALL_CLI=true; shift ;;
            --cli-name)       ARG_CLI_NAME="$2"; shift 2 ;;
            --cli-bin)        ARG_CLI_BIN="$2"; shift 2 ;;
            -s|--shell)       ARG_SHELL="$2"; shift 2 ;;
            -n|--no-test)     ARG_NO_TEST=true; shift ;;
            -d|--dry-run)     ARG_DRY_RUN=true; shift ;;
            -q|--quiet)       ARG_QUIET=true; shift ;;
            --)               shift; break ;;
            -*)               error "Unknown option: $1"; usage; exit 1 ;;
            *)                API_KEY="$1"; shift; break ;;
        esac
    done

    # Remaining positional args as API key
    if [[ -z "$API_KEY" ]] && [[ $# -gt 0 ]]; then
        API_KEY="$1"
    fi

    # Detect shell and config
    local shell_name config_file
    shell_name=$(detect_shell)
    config_file=$(detect_shell_config "$shell_name")

    if [[ "$ARG_QUIET" == "true" ]]; then
        success() { :; }
        info()    { :; }
        step()    { :; }
    fi

    # ── Dispatch ────────────────────────────────────────────────────
    if [[ "$ARG_DOCTOR" == "true" ]]; then
        do_doctor "$shell_name" "$config_file"
        return 0
    fi

    if [[ "$ARG_STATUS" == "true" ]]; then
        do_status "$shell_name" "$config_file"
        return 0
    fi

    if [[ "$ARG_INSTALL_CLI" == "true" ]]; then
        do_install_cli
        return 0
    fi

    if [[ "$ARG_UNINSTALL" == "true" ]]; then
        do_uninstall "$shell_name" "$config_file"
        return 0
    fi

    # If API key given, do setup
    if [[ -n "$API_KEY" ]]; then
        do_install "$API_KEY" "$shell_name" "$config_file"
        return 0
    fi

    # Default: if config exists → status, else → interactive setup
    if [[ -f "$ENV_FILE" ]]; then
        do_status "$shell_name" "$config_file"
    else
        echo ""
        echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${BLUE}║  claudeep — Claude Code + DeepSeek           ║${NC}"
        echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        echo -n "Enter your DeepSeek API key (starts with sk-): "
        read -r API_KEY
        echo ""
        do_install "$API_KEY" "$shell_name" "$config_file"
    fi
}

# Only run main if executed directly (not sourced, e.g. by tests)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
