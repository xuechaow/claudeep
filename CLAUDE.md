# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Configures Claude Code to use the DeepSeek API as a backend instead of Anthropic's API, by setting environment variables (`ANTHROPIC_BASE_URL`, model mappings, etc.) and adding a `source` line to the user's shell config.

## Key File

**`setup.sh`** — The single entry point. Handles install, uninstall, and all configuration. Written in bash for maximum portability across macOS and Linux. Supports bash, zsh, and fish shells.

## Architecture

```
User runs setup.sh
  ├── Detects shell (bash / zsh / fish) and its config file
  ├── Validates the DeepSeek API key (must match ^sk-[A-Za-z0-9]+$)
  ├── Creates ~/.deepseek-claude/
  │     ├── env          ← POSIX export syntax (for bash/zsh)
  │     └── env.fish     ← fish set -gx syntax (for fish)
  ├── Appends a source line to shell config between marker comments:
  │     # >>> DeepSeek Claude integration >>>
  │     [ -f ~/.deepseek-claude/env ] && source ~/.deepseek-claude/env
  │     # <<< DeepSeek Claude integration <<<
  ├── Exports variables into the current shell session
  └── Tests API connectivity via curl to /v1/messages
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
# Run the setup interactively
./setup.sh

# Non-interactive with API key
./setup.sh sk-abc123def456

# Dry-run to preview
./setup.sh --dry-run sk-...

# Force a specific shell
./setup.sh --shell fish sk-...

# Skip API test (offline / known-good key)
./setup.sh --no-test sk-...

# Uninstall
./setup.sh --uninstall
```

## Testing / Validation

The script tests connectivity by sending a minimal request to `POST /v1/messages` with `max_tokens: 8`. It checks for HTTP 200 and the presence of `"id":` in the response body. API test can be skipped with `--no-test`.

No other test infrastructure exists — this is a shell script repository.
