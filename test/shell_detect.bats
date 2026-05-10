#!/usr/bin/env bats
load test_helper

@test "detects zsh shell and config" {
    export SHELL="/bin/zsh"
    run detect_shell
    [ "$output" = "zsh" ]

    run detect_shell_config "zsh"
    [ "$output" = "${HOME}/.zshrc" ]
}

@test "detects bash shell and config on macOS" {
    export SHELL="/bin/bash"
    run detect_shell
    [ "$output" = "bash" ]

    if [[ "$(uname)" == "Darwin" ]]; then
        run detect_shell_config "bash"
        [ "$output" = "${HOME}/.bash_profile" ]
    fi
}

@test "detects fish shell and config" {
    export SHELL="/usr/bin/fish"
    run detect_shell
    [ "$output" = "fish" ]

    run detect_shell_config "fish"
    [ "$output" = "${HOME}/.config/fish/config.fish" ]
}

@test "rejects unsupported shell" {
    run detect_shell_config "csh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unsupported shell"* ]]
}

@test "ARG_SHELL overrides auto-detection" {
    export SHELL="/bin/zsh"
    ARG_SHELL="fish"
    run detect_shell
    [ "$output" = "fish" ]
}
