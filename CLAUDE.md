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
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` |

All defaults can be overridden by setting `CLD_DEEP_*` environment variables before running `setup.sh`.

## Common Commands

```bash
# Interactive setup
./setup.sh

# Subcommand-style (preferred, works via 'claudeep' symlink too)
./setup.sh doctor            # Health check
./setup.sh doctor --fix      # Health check + auto-repair
./setup.sh uninstall         # Remove all config
./setup.sh install           # Install as global 'claudeep' command

# Non-interactive with API key
./setup.sh sk-abc123def456

# Dry-run to preview
./setup.sh setup --dry-run sk-...

# Force a specific shell
./setup.sh --shell fish sk-...
```

## Testing / Validation

The script tests connectivity by sending a minimal request to `POST /v1/messages` with `max_tokens: 8`. It checks for HTTP 200 and the presence of `"id":` in the response body. API test can be skipped with `--no-test`.

No other test infrastructure exists — this is a shell script repository.
