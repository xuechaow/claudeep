# test_helper.bash — shared setup, mocks, and utilities

# Find the project root relative to this helper file
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$TEST_DIR/.." && pwd)"

# Source setup.sh to get all functions (won't run main due to guard)
source "${PROJECT_DIR}/setup.sh"

# ── Per-test setup ────────────────────────────────────────────────────
setup() {
    TEST_ROOT="$(mktemp -d)"
    export HOME="$TEST_ROOT"
    export SHELL="/bin/zsh"
    export ZDOTDIR="$HOME"
    unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL
    unset CLAUDE_CODE_SUBAGENT_MODEL CLAUDE_CODE_EFFORT_LEVEL

    # Recompute env paths under fake HOME
    ENV_DIR="${HOME}/.deepseek-claude"
    ENV_FILE="${ENV_DIR}/env"
    ENV_FILE_FISH="${ENV_DIR}/env.fish"

    # Reset global state flags
    ARG_SHELL=""
    ARG_UNINSTALL=false
    ARG_STATUS=false
    ARG_DOCTOR=false
    ARG_DOCTOR_FIX=false
    ARG_INSTALL_CLI=false
    ARG_CLI_NAME=""
    ARG_CLI_BIN=""
    ARG_NO_TEST=false
    ARG_DRY_RUN=false
    ARG_QUIET=false
}

teardown() {
    rm -rf "$TEST_ROOT"
}

# ── Mock helpers ──────────────────────────────────────────────────────
mock_curl_success() {
    function curl() {
        # Simulate: body + newline + HTTP 200 (matching test_api's parsing)
        printf '{"id":"mock-123","type":"message","role":"assistant"}\n200'
        return 0
    }
    export -f curl
}

mock_curl_failure() {
    function curl() {
        printf '{"error":{"message":"Invalid API key"}}\n401'
        return 0
    }
    export -f curl
}

# ── Shell config helpers ──────────────────────────────────────────────
create_shell_config() {
    mkdir -p "$(dirname "$1")"
    echo "# existing config" > "$1"
}

# Assert a file contains a pattern (fails if not)
assert_file_contains() {
    local file="$1" pattern="$2"
    if ! grep -qF "$pattern" "$file" 2>/dev/null; then
        echo "Expected file $file to contain: $pattern" >&2
        echo "File contents:" >&2
        cat "$file" >&2
        return 1
    fi
}

# Assert a file does NOT contain a pattern
assert_file_not_contains() {
    local file="$1" pattern="$2"
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        echo "Expected file $file NOT to contain: $pattern" >&2
        return 1
    fi
}
