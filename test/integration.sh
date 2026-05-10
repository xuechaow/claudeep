#!/usr/bin/env bash
# integration.sh — end-to-end tests: install, setup, doctor, status, uninstall
set -euo pipefail

PASS=0
FAIL=0
TEST_KEY="sk-test000000000000000000000000"
TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
export SHELL="${SHELL:-/bin/bash}"
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/setup.sh"

pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1 — $2"; FAIL=$((FAIL + 1)); }

cleanup() {
    rm -rf "$TEST_HOME"
    # Also clean up any real files this test created
    rm -rf "${HOME}/.deepseek-claude"
}
trap cleanup EXIT

echo ""
echo "=== Integration Tests ==="
echo "HOME: $TEST_HOME"
echo "SHELL: $SHELL"
echo ""

# ── 1. Install via script (setup with API key) ─────────────────────
echo "1. Full install → setup → doctor → status → uninstall"
echo ""

# Run setup with test key, skip real API call (redirect stdin to avoid tty prompts)
"$SCRIPT" setup "$TEST_KEY" --no-test --quiet < /dev/null > /dev/null 2>&1 || true
if [[ -f "${TEST_HOME}/.deepseek-claude/env" ]]; then
    pass "env file created"
else
    fail "env file created" "missing"
fi

# Source the env
source "${TEST_HOME}/.deepseek-claude/env"

# Check env vars
if [[ "$ANTHROPIC_BASE_URL" == "https://api.deepseek.com/anthropic" ]]; then
    pass "ANTHROPIC_BASE_URL set"
else
    fail "ANTHROPIC_BASE_URL set" "got: ${ANTHROPIC_BASE_URL:-unset}"
fi

if [[ "$ANTHROPIC_AUTH_TOKEN" == "$TEST_KEY" ]]; then
    pass "ANTHROPIC_AUTH_TOKEN set"
else
    fail "ANTHROPIC_AUTH_TOKEN set" "mismatch"
fi

# ── 2. Security: file permissions ──────────────────────────────────
echo ""
echo "2. Security checks"
echo ""

ENV_FILE="${TEST_HOME}/.deepseek-claude/env"
if [[ "$(uname)" == "Darwin" ]]; then
    PERMS=$(stat -f "%p" "$ENV_FILE")
    EXPECTED="100600"
else
    PERMS=$(stat -c "%a" "$ENV_FILE")
    EXPECTED="600"
fi
if [[ "$PERMS" == "$EXPECTED" ]]; then
    pass "env file permissions ${EXPECTED}"
else
    fail "env file permissions ${EXPECTED}" "got: ${PERMS}"
fi

# Key not exposed in env file verification (just checking it's there and not world-readable)
if grep -q "$TEST_KEY" "$ENV_FILE"; then
    pass "key stored in env file"
else
    fail "key stored in env file" "not found"
fi

# ── 3. Doctor ─────────────────────────────────────────────────────
echo ""
echo "3. Doctor"
echo ""

DOCTOR_OUT="$("$SCRIPT" doctor --no-test 2>&1 || true)"
if echo "$DOCTOR_OUT" | grep -q "All checks passed\|Health Check\|OK"; then
    pass "doctor runs without crashing"
else
    fail "doctor runs" "unexpected output"
fi

# Doctor should NOT leak the API key
if echo "$DOCTOR_OUT" | grep -q "$TEST_KEY"; then
    fail "doctor leaks API key" "full key found in output"
else
    pass "doctor does not leak API key"
fi

# Doctor should show masked key (e.g. sk-test0...0000)
if echo "$DOCTOR_OUT" | grep -qE "sk-.*\.\.\."; then
    pass "doctor shows masked key"
else
    fail "doctor shows masked key" "no masked key pattern found in output"
fi

# ── 4. Status ─────────────────────────────────────────────────────
echo ""
echo "4. Status"
echo ""

STATUS_OUT="$("$SCRIPT" status 2>&1 || true)"
if echo "$STATUS_OUT" | grep -q "Ready\|Key:"; then
    pass "status runs without crashing"
else
    fail "status runs" "unexpected output"
fi

if echo "$STATUS_OUT" | grep -q "$TEST_KEY"; then
    fail "status leaks API key" "full key found in output"
else
    pass "status does not leak API key"
fi

# ── 5. Shell config ───────────────────────────────────────────────
echo ""
echo "5. Shell integration"
echo ""

# Detect config file
case "$(basename "$SHELL")" in
    zsh)  CONFIG="${TEST_HOME}/.zshrc" ;;
    bash)
        if [[ "$(uname)" == "Darwin" ]]; then
            CONFIG="${TEST_HOME}/.bash_profile"
        else
            CONFIG="${TEST_HOME}/.bashrc"
        fi
        ;;
    *)    CONFIG="${TEST_HOME}/.bashrc" ;;
esac

if grep -q ">>> DeepSeek Claude integration >>>" "$CONFIG" 2>/dev/null; then
    pass "shell integration block present"
else
    fail "shell integration block present" "not found in $CONFIG"
fi

# ── 6. Uninstall ──────────────────────────────────────────────────
echo ""
echo "6. Uninstall"
echo ""

"$SCRIPT" uninstall --quiet < /dev/null > /dev/null 2>&1 || true

if [[ ! -f "$ENV_FILE" ]]; then
    pass "env file removed"
else
    fail "env file removed" "still exists"
fi

if [[ ! -d "${TEST_HOME}/.deepseek-claude" ]]; then
    pass "config directory removed"
else
    fail "config directory removed" "still exists"
fi

if ! grep -q ">>> DeepSeek Claude integration >>>" "$CONFIG" 2>/dev/null; then
    pass "shell integration block removed"
else
    fail "shell integration block removed" "still present"
fi

# ── 7. Error handling ─────────────────────────────────────────────
echo ""
echo "7. Error handling"
echo ""

# Invalid key format
INVALID_OUT="$("$SCRIPT" setup "bad-key" --no-test --quiet < /dev/null 2>&1 || true)"
if echo "$INVALID_OUT" | grep -qi "start with\|invalid\|error"; then
    pass "rejects invalid key format"
else
    fail "rejects invalid key format" "accepted: bad-key"
fi

# Empty key
EMPTY_OUT="$("$SCRIPT" setup "" --no-test --quiet < /dev/null 2>&1 || true)"
if echo "$EMPTY_OUT" | grep -qi "empty\|start with\|error"; then
    pass "rejects empty key"
else
    fail "rejects empty key" "accepted empty"
fi

# ── Summary ────────────────────────────────────────────────────────
echo ""
echo "=============================="
echo "  Passed: $PASS  Failed: $FAIL"
echo "=============================="

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
