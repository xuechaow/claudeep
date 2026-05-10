#!/usr/bin/env bats
load test_helper

@test "creates POSIX env file with correct content" {
    write_posix_env "sk-testkey123"
    assert_file_contains "$ENV_FILE" 'export ANTHROPIC_BASE_URL'
    assert_file_contains "$ENV_FILE" 'export ANTHROPIC_AUTH_TOKEN="sk-testkey123"'
    assert_file_contains "$ENV_FILE" 'export ANTHROPIC_DEFAULT_SONNET_MODEL'
    assert_file_contains "$ENV_FILE" 'export CLAUDE_CODE_SUBAGENT_MODEL'
    assert_file_contains "$ENV_FILE" 'export CLAUDE_CODE_EFFORT_LEVEL'
}

@test "env file has restricted permissions (600)" {
    write_posix_env "sk-testkey123"
    local perms
    perms=$(stat -f "%p" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE")
    # macOS stat returns full mode like 100600, Linux returns 600
    [[ "$perms" =~ 600$ ]]
}

@test "creates fish env file with set -gx syntax" {
    write_fish_env "sk-fishkey999"
    assert_file_contains "$ENV_FILE_FISH" 'set -gx ANTHROPIC_BASE_URL'
    assert_file_contains "$ENV_FILE_FISH" 'set -gx ANTHROPIC_AUTH_TOKEN "sk-fishkey999"'
    assert_file_contains "$ENV_FILE_FISH" 'set -gx CLAUDE_CODE_SUBAGENT_MODEL'
}

@test "overwrites existing env file" {
    mkdir -p "$ENV_DIR"
    echo "# old config" > "$ENV_FILE"
    write_posix_env "sk-newkey456"
    assert_file_contains "$ENV_FILE" 'sk-newkey456'
    assert_file_not_contains "$ENV_FILE" 'old config'
}

@test "respects custom BASE_URL override" {
    BASE_URL="https://custom.api.example.com/llm"
    write_posix_env "sk-testkey123"
    assert_file_contains "$ENV_FILE" 'https://custom.api.example.com/llm'
}

@test "respects custom model overrides" {
    SONNET_MODEL="custom-sonnet"
    OPUS_MODEL="custom-opus"
    write_posix_env "sk-testkey123"
    assert_file_contains "$ENV_FILE" 'export ANTHROPIC_DEFAULT_SONNET_MODEL="custom-sonnet"'
    assert_file_contains "$ENV_FILE" 'export ANTHROPIC_DEFAULT_OPUS_MODEL="custom-opus"'
}
