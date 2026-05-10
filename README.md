# Claudeep — Claude Code with DeepSeek API

<p align="center">
  <b>Run <a href="https://claude.ai/code">Claude Code CLI</a> with <a href="https://deepseek.com">DeepSeek</a> models (deepseek-v4-pro, deepseek-v4-flash) instead of Anthropic's API.</b><br>
  <b>One command to set up, <code>claudeep doctor</code> to stay healthy, <code>claudeep doctor --fix</code> to auto-repair.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/shell-bash%20%7C%20zsh%20%7C%20fish-blue" alt="Shells: bash, zsh, fish">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey" alt="Platform: macOS, Linux">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
  <img src="https://img.shields.io/github/stars/xuechaow/claudeep?style=social" alt="GitHub stars">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/xuechaow/claudeep/main/banner.svg" alt="claudeep — Claude Code + DeepSeek" width="800">
</p>

---

## Quick Start

```bash
# Interactive mode (prompts for your API key)
./setup.sh

# Non-interactive (pass API key directly)
./setup.sh sk-your-deepseek-api-key

# Or curl directly from GitHub
curl -fsSL https://raw.githubusercontent.com/xuechaow/claudeep/main/setup.sh | bash -s -- sk-your-api-key
```

Then run Claude Code as usual:

```bash
claude --bare
```

### Install as a CLI Command

```bash
./setup.sh install                        # Install as 'claudeep'
./setup.sh install --cli-name myname      # Custom name
```

After installation, run from anywhere:

```bash
claudeep doctor              # Health check
claudeep doctor --fix        # Auto-repair issues
claudeep uninstall           # Remove config
claudeep sk-...              # Reconfigure
```

## What It Does

The script sets the environment variables that Claude Code reads to discover an Anthropic-compatible API. DeepSeek provides an Anthropic Messages API endpoint at `https://api.deepseek.com/anthropic`.

| Variable | Value |
|---|---|
| `ANTHROPIC_BASE_URL` | `https://api.deepseek.com/anthropic` |
| `ANTHROPIC_AUTH_TOKEN` | Your DeepSeek API key |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` |
| `CLAUDE_CODE_EFFORT_LEVEL` | `max` |

The configuration is stored in `~/.deepseek-claude/env` and automatically sourced by your shell on startup.

## Usage

```
claudeep COMMAND [OPTIONS]

Commands:
  setup [API_KEY]   Configure DeepSeek integration (default)
  doctor [--fix]    Diagnose environment, config, and API
  uninstall         Remove all configuration
  install           Install claudeep as a global CLI command
  help              Show help

Options:
  --fix             (with doctor) Auto-repair common issues
  --cli-name NAME   (with install) Custom CLI name (default: claudeep)
  --cli-bin DIR     (with install) Target directory (default: /usr/local/bin)
  -s, --shell NAME  Specify shell (bash, zsh, fish) — auto-detected
  -n, --no-test     Skip API connectivity test
  -d, --dry-run     Preview without applying changes
  -q, --quiet       Suppress informational output
```

### Custom Models or Endpoints

Override defaults by setting environment variables before running the script:

```bash
CLD_DEEP_SONNET_MODEL="your-custom-model" ./setup.sh sk-...
```

| Override Variable | Controls |
|---|---|
| `CLD_DEEP_BASE_URL` | API base URL |
| `CLD_DEEP_SONNET_MODEL` | Sonnet-equivalent model |
| `CLD_DEEP_OPUS_MODEL` | Opus-equivalent model |
| `CLD_DEEP_HAIKU_MODEL` | Haiku-equivalent model |
| `CLD_DEEP_SUBAGENT_MODEL` | Sub-agent model |
| `CLD_DEEP_EFFORT_LEVEL` | Reasoning effort level |

## Shell Support

| Shell | Config File | Method |
|---|---|---|
| **zsh** | `~/.zshrc` | Sourced on shell init |
| **bash** (macOS) | `~/.bash_profile` | Sourced on login shell init |
| **bash** (Linux) | `~/.bashrc` | Sourced on interactive shell init |
| **fish** | `~/.config/fish/config.fish` | Sourced on shell init (uses `set -gx` syntax) |

> **Note for fish users:** The script cannot export variables into your current fish session from bash. After setup, run `source ~/.deepseek-claude/env.fish` or open a new terminal.

## Doctor — Health Check

Diagnose your setup to catch stale keys, config conflicts, and API issues:

```bash
claudeep doctor
# or: ./setup.sh doctor
```

The doctor checks:
1. **Environment variables** — are `ANTHROPIC_*` vars set and consistent?
2. **Config file** — does `~/.deepseek-claude/env` exist with correct permissions? Does its key match the current session?
3. **Shell integration** — is the source block present? Are there stale direct exports from an old setup that could load wrong keys?
4. **API connectivity** — can the current key reach DeepSeek?
5. **CLI installation** — is `claudeep` in your PATH? Is Claude Code available?

Each check shows a ✓, ✗, or ⚠ with specific fix instructions.

### Auto-repair

```bash
claudeep doctor --fix
```

Automatically fixes the most common issues: sources the correct env file if there's a key mismatch, removes stale direct exports from your shell config, consolidates duplicate integration blocks, and fixes file permissions.

## Uninstall

```bash
claudeep uninstall
# or: ./setup.sh uninstall
```

This removes the integration block from your shell config and deletes `~/.deepseek-claude/`. Environment variables already set in the current session are unaffected — they disappear when you open a new terminal.

## How It Works

1. Writes environment variables to `~/.deepseek-claude/env` (permissions `600`)
2. Adds a `source` line to your shell's startup file, wrapped in clear marker comments
3. Exports the variables into the current terminal session
4. Optionally tests the API connection with a minimal request

The marker comments (`# >>> DeepSeek Claude integration >>>` / `# <<<`) make uninstall clean and safe — only the integration block is removed, leaving the rest of your shell config untouched.

## Prerequisites

- **Claude Code** installed (`npm install -g @anthropic-ai/claude-code` or similar)
- **DeepSeek API key** (get one at [platform.deepseek.com](https://platform.deepseek.com))
- **curl**, **bash** (both pre-installed on macOS and most Linux distributions)

## Files

```
claudeep/
├── setup.sh          # Setup, doctor, uninstall, CLI install — all in one
├── README.md         # This file
├── LICENSE           # MIT license
├── CLAUDE.md         # Guidance for Claude Code instances
└── .gitignore
```

## License

MIT © [xuechaow](https://github.com/xuechaow)
