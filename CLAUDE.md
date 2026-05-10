# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Configures Claude Code to use the DeepSeek API as a backend instead of Anthropic's API, by setting environment variables (`ANTHROPIC_BASE_URL`, model mappings, etc.) and adding a `source` line to the user's shell config.

## Key File

**`setup.sh`** — Single entry point supporting subcommand-style CLI (`claudeep doctor`, `claudeep uninstall`, `claudeep install`). Written in bash for portability across macOS and Linux. Supports bash, zsh, and fish shells.

## Architecture

```
User runs claudeep [command] → setup.sh
  ├── Subcommand parsing: doctor | uninstall | install | setup | help
  ├── Detects shell (bash / zsh / fish) and its config file
  ├── [doctor]   Checks env vars, env file, shell config, API, CLI status
  │     └── --fix: auto-sources correct env, removes stale exports, consolidates blocks
  ├── [install]  Creates ~/.deepseek-claude/
  │     ├── env          ← POSIX export syntax (for bash/zsh, chmod 600)
  │     └── env.fish     ← fish set -gx syntax (for fish, chmod 600)
  │     ├── Appends source line to shell config between markers:
  │     │     # >>> DeepSeek Claude integration >>>
  │     │     [ -f ~/.deepseek-claude/env ] && source ~/.deepseek-claude/env
  │     │     # <<< DeepSeek Claude integration <<<
  │     ├── Exports variables to current shell session
  │     └── Tests API via curl to /v1/messages
  ├── [uninstall] Removes marker block from shell config, deletes ~/.deepseek-claude/
  └── [setup]    Interactive API key prompt → install
```

## Configuration Storage

- **Directory:** `~/.deepseek-claude/` (permissions: 700)
- **Env file:** `~/.deepseek-claude/env` (permissions: 600)
- **Shell integration:** A marker-delimited block in the user's shell config file (e.g., `~/.zshrc`, `~/.bashrc`)

## Key Design Decisions

- **Markers for clean uninstall:** Integration lines are wrapped in `# >>>` / `# <<<` markers so `sed` can precisely remove only those lines during uninstall without touching the rest of the user's shell config.
- **Separate env file:** Writing to `~/.deepseek-claude/env` (rather than directly into the shell config) keeps the API key in a dedicated file with restricted permissions (600) and makes uninstall a simple directory removal.
- **No backup of shell config on install:** The integration is a single source line between markers; the risk of damage is minimal. If needed, users can `--dry-run` first.
- **fish gets its own syntax file:** `env.fish` uses `set -gx` instead of `export`. The bash script cannot export into a parent fish process, so fish users are instructed to source manually.

## Environment Variables Set

| Variable | Default Value |
|---|---|
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` |
| `ANTHROPIC_AUTH_TOKEN` | User-provided DeepSeek API key |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash[1m]` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash[1m]` |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` |

The `[1m]` suffix enables 1M-token context window (DeepSeek requirement). Defaults can be overridden via `CLD_DEEP_*` env vars.

## Distribution

- **One-liner:** `curl -fsSL https://raw.githubusercontent.com/xuechaow/claudeep/main/install.sh | bash`
- **npm:** `npm install -g claudeep@latest`
- **Homebrew:** `brew tap xuechaow/claudeep && brew install claudeep`

## Common Commands

```bash
claudeep                   # Default: status if configured, else interactive setup
claudeep status            # Quick health check
claudeep doctor            # Full diagnostic
claudeep doctor --fix      # Diagnostic + auto-repair (key mismatch, stale exports, etc.)
claudeep setup sk-...      # Configure with API key
claudeep uninstall         # Remove all config
claudeep install           # Install CLI symlink to /usr/local/bin
```

## Testing

```
test/
├── test_helper.bash           # Temp HOME, mocks, shared setup
├── api_key.bats         (5)   # Key validation & format checks
├── shell_detect.bats    (5)   # bash/zsh/fish detection
├── env_file.bats        (6)   # POSIX/fish env generation, permissions
├── source_block.bats    (6)   # Shell config marker block add/remove
├── doctor.bats          (6)   # Health checks, --fix auto-repair
├── cli.bats            (11)   # Subcommand dispatch, install/uninstall/dry-run
└── integration.sh      (16)   # E2E: install → doctor → security → uninstall
```

**55 checks total** (39 unit + 16 integration). Run with:
```bash
brew install bats-core       # one-time
bats test/                    # unit tests
bash test/integration.sh      # integration tests
```

Tests use temp `$HOME` directories — real config files are never touched. API calls are skipped (`ARG_NO_TEST=true`) or mocked. CI runs both macOS and Linux via GitHub Actions.

## CI

`.github/workflows/test.yml` — 4 jobs (unit + integration × macOS + Linux), `fail-fast: false`. Bats installed from source tarball. Integration tests cover install, security (permissions, key masking), doctor, status, and uninstall flows.

## Platform Compatibility

| Difference | Handling |
|---|---|
| `stat` (BSD vs GNU) | Branch on `uname` |
| Shell config path | `detect_shell_config()` maps macOS bash → `.bash_profile`, Linux → `.bashrc` |
| `sed -i` | BSD needs `sed -i ''`, GNU needs `sed -i` — branched |

## Current Status

- Published on npm: `claudeep@1.0.0`
- Homebrew tap: `xuechaow/homebrew-claudeep`
- Pending: PR to [deepseek-ai/awesome-deepseek-agent](https://github.com/deepseek-ai/awesome-deepseek-agent) to add claudeep as quick-setup option in the Claude Code guide (issue #92)
