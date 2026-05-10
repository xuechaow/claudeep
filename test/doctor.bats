#!/usr/bin/env bats
load test_helper

@test "detects missing env file" {
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"

    run do_doctor "zsh" "${HOME}/.zshrc"
    [[ "$output" == *"File missing"* ]]
}

@test "detects key mismatch between env and session" {
    mkdir -p "$ENV_DIR"
    write_posix_env "sk-envfile-key"
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"

    export ANTHROPIC_AUTH_TOKEN="sk-session-key"

    run do_doctor "zsh" "${HOME}/.zshrc"
    [[ "$output" == *"Key MISMATCH"* ]]
    [[ "$output" == *"sk-envfil"* ]]
    [[ "$output" == *"sk-sessio"* ]]
}

@test "detects no issues when all clean" {
    export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
    export ANTHROPIC_AUTH_TOKEN="sk-test000"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_EFFORT_LEVEL="max"
    mkdir -p "$ENV_DIR"
    write_posix_env "sk-test000"
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"
    mock_curl_success

    run do_doctor "zsh" "${HOME}/.zshrc"
    [[ "$output" == *"All checks passed"* ]]
}

@test "detects stale direct exports in shell config" {
    export ANTHROPIC_AUTH_TOKEN="sk-test000"
    mkdir -p "$ENV_DIR"
    write_posix_env "sk-test000"
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"
    echo 'export ANTHROPIC_AUTH_TOKEN="sk-stale-key"' >> "${HOME}/.zshrc"

    run do_doctor "zsh" "${HOME}/.zshrc"
    [[ "$output" == *"direct export"* ]]
}

@test "doctor --fix removes stale exports" {
    export ANTHROPIC_AUTH_TOKEN="sk-test000"
    mkdir -p "$ENV_DIR"
    write_posix_env "sk-test000"
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"
    echo 'export ANTHROPIC_AUTH_TOKEN="sk-stale-key"' >> "${HOME}/.zshrc"

    ARG_DOCTOR_FIX=true
    run do_doctor "zsh" "${HOME}/.zshrc"

    assert_file_not_contains "${HOME}/.zshrc" "sk-stale-key"
}

@test "doctor --fix sources env file on key mismatch" {
    export ANTHROPIC_AUTH_TOKEN="sk-wrong-key"
    mkdir -p "$ENV_DIR"
    write_posix_env "sk-correct-key"
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"

    ARG_DOCTOR_FIX=true
    run do_doctor "zsh" "${HOME}/.zshrc"

    [[ "$output" == *"sourced"* ]]
}
