# DeepSeek + Claude Code Integration

<p align="center">
  <b>Configure <a href="https://claude.ai/code">Claude Code</a> to use the <a href="https://deepseek.com">DeepSeek</a> API as its model backend.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/shell-bash%20%7C%20zsh%20%7C%20fish-blue" alt="Shells: bash, zsh, fish">
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey" alt="Platform: macOS, Linux">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
</p>

---

## Quick Start

```bash
# Interactive mode (prompts for your API key)
./setup.sh

# Non-interactive (pass API key directly)
./setup.sh sk-your-deepseek-api-key

# Or curl directly from GitHub
curl -fsSL https://raw.githubusercontent.com/xuechaow/cld_deep/main/setup.sh | bash -s -- sk-your-api-key
```

Then run Claude Code as usual:

```bash
claude --bare
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
setup.sh [OPTIONS] [API_KEY]

Options:
  -h, --help        Show help message
  -u, --uninstall   Remove all configuration
  -s, --shell NAME  Specify shell (bash, zsh, fish) — auto-detected by default
  -n, --no-test     Skip the API connectivity test
  -d, --dry-run     Preview changes without applying them
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

## Uninstall

```bash
./setup.sh --uninstall
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
cld_deep/
├── setup.sh          # Main setup/uninstall script
├── README.md         # This file
├── LICENSE           # MIT license
└── CLAUDE.md         # Guidance for Claude Code instances
```

## License

MIT © [xuechaow](https://github.com/xuechaow)
