#!/usr/bin/env bats
load test_helper

@test "install flow creates env file and updates shell config" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"
    export SHELL="/bin/zsh"

    run do_install "sk-test123" "zsh" "${HOME}/.zshrc"

    [ "$status" -eq 0 ]
    assert_file_contains "$ENV_FILE" 'sk-test123'
    assert_file_contains "${HOME}/.zshrc" ">>> DeepSeek Claude integration >>>"
}

@test "install exports variables to current shell" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"

    # Call directly (not via 'run') so exports propagate to test scope
    # '|| true' prevents set -e from killing the test on non-zero return
    do_install "sk-test123" "zsh" "${HOME}/.zshrc" || true

    # After install, vars should be exported
    [ "${ANTHROPIC_BASE_URL:-}" = "https://api.deepseek.com/anthropic" ]
    [ "${ANTHROPIC_AUTH_TOKEN:-}" = "sk-test123" ]
}

@test "dry-run does not create files" {
    create_shell_config "${HOME}/.zshrc"
    ARG_DRY_RUN=true

    run do_install "sk-test123" "zsh" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]

    # No files created
    [ ! -f "$ENV_FILE" ]
}

@test "uninstall removes env directory and shell block" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"
    run do_install "sk-test123" "zsh" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]

    run do_uninstall "zsh" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]
    [ ! -d "$ENV_DIR" ]
    assert_file_not_contains "${HOME}/.zshrc" "DeepSeek Claude integration"
}

@test "uninstall dry-run does nothing" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"
    run do_install "sk-test123" "zsh" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]

    ARG_DRY_RUN=true
    run do_uninstall "zsh" "${HOME}/.zshrc"
    [[ "$output" == *"DRY RUN"* ]]
    [ -d "$ENV_DIR" ]
}

@test "subcommand dispatch: doctor" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"
    export SHELL="/bin/zsh"

    run main doctor
    [[ "$output" == *"Health Check"* ]]
}

@test "subcommand dispatch: uninstall" {
    mock_curl_success
    create_shell_config "${HOME}/.zshrc"
    run do_install "sk-test123" "zsh" "${HOME}/.zshrc"
    [ "$status" -eq 0 ]

    run main uninstall
    [[ "$output" == *"Uninstall complete"* ]]
}

@test "subcommand dispatch: help" {
    run main help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
