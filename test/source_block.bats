#!/usr/bin/env bats
load test_helper

@test "adds integration block to existing zsh config" {
    create_shell_config "${HOME}/.zshrc"

    add_source_line "${HOME}/.zshrc" "zsh"

    assert_file_contains "${HOME}/.zshrc" "# >>> DeepSeek Claude integration >>>"
    assert_file_contains "${HOME}/.zshrc" "source ${ENV_FILE}"
    assert_file_contains "${HOME}/.zshrc" "# <<< DeepSeek Claude integration <<<"
    # Original content preserved
    assert_file_contains "${HOME}/.zshrc" "existing config"
}

@test "removes integration block from config" {
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"

    remove_source_block "${HOME}/.zshrc"

    assert_file_not_contains "${HOME}/.zshrc" "DeepSeek Claude integration"
    assert_file_not_contains "${HOME}/.zshrc" "deepseek-claude/env"
    # Original content preserved
    assert_file_contains "${HOME}/.zshrc" "existing config"
}

@test "replaces duplicate blocks when adding" {
    create_shell_config "${HOME}/.zshrc"
    add_source_line "${HOME}/.zshrc" "zsh"
    add_source_line "${HOME}/.zshrc" "zsh"

    # Should have exactly one block
    local count
    count=$(grep -c ">>> DeepSeek Claude integration >>>" "${HOME}/.zshrc" || true)
    [[ "$count" -eq 1 ]]
}

@test "adds fish source line with env.fish path" {
    create_shell_config "${HOME}/.config/fish/config.fish"

    add_source_line "${HOME}/.config/fish/config.fish" "fish"

    assert_file_contains "${HOME}/.config/fish/config.fish" "source ${ENV_FILE_FISH}"
}

@test "handles empty config file gracefully" {
    # No pre-existing config file
    add_source_line "${HOME}/.zshrc" "zsh"

    assert_file_contains "${HOME}/.zshrc" ">>> DeepSeek Claude integration >>>"
}

@test "idempotent: removing from already-clean config does nothing" {
    create_shell_config "${HOME}/.zshrc"
    run remove_source_block "${HOME}/.zshrc"
    [ "$status" -eq 0 ]
    assert_file_contains "${HOME}/.zshrc" "existing config"
}
