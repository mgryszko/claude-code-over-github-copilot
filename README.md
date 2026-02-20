# Claude Code over GitHub Copilot-model endpoints - Setup Instructions

## Fork changes

Forked from [kjetiljd/claude-code-over-github-copilot](https://github.com/kjetiljd/claude-code-over-github-copilot) with the following changes:

- Updated models to current Claude versions (`claude-opus-4.6`, `claude-sonnet-4.6`, `claude-haiku-4.5`)
- Migrated task runner from `make` to [`just`](https://github.com/casey/just)
- Removed Claude Code installation step (assumed to be already installed)

## Overview

This project allows you to use Claude Code with GitHub Copilot instead of Anthropic's servers.
We can't send company information to Anthropic, but we already have an agreement with GitHub Copilot for our
VSCode and IDEA agents.

The architecture uses:
- **Translation layer**: LiteLLM proxy to translate between Claude Code and GitHub Copilot APIs
- **Local proxy**: LiteLLM running locally (no external traffic to third parties)
- **GitHub integration**: Direct connection to GitHub Copilot models we're already authorized to use

**References:**
- [Claude Code LLM Gateway Documentation](https://docs.anthropic.com/en/docs/claude-code/llm-gateway)
- [LiteLLM Quick Start](https://docs.litellm.ai/#quick-start-proxy---cli)
- [LiteLLM GitHub Copilot Provider](https://docs.litellm.ai/docs/providers/github_copilot)

## Quick start

### 1. Initial setup

```bash
just setup
```

This command:
- Installs required dependencies via `uv`
- Generates random UUID-based API keys in `.env` file (only if it doesn't exist)

### 2. Configure Claude Code

```bash
just claude-enable
```

This command:
- Backs up your existing Claude Code settings
- Configures Claude Code to use `http://localhost:4444` as the API endpoint
- Sets the primary model and fast model from `copilot-config.yaml` (first and second entries respectively)

### 3. Start the proxy server

> **Important**: The first run will trigger GitHub device authentication - follow the prompts in the terminal.

```bash
just start
```

This will start LiteLLM with the `copilot-config.yaml` configuration.

### 4. Test the connection

```bash
just test
```

### 5. Start Claude Code in your project folder

```bash
claude
```

## Model configuration

Models are defined in `copilot-config.yaml`. The enable script automatically picks:
- **Primary model** (`ANTHROPIC_MODEL`): first entry in `model_list`
- **Fast model** (`ANTHROPIC_SMALL_FAST_MODEL`): second entry in `model_list`

Current configuration:

| Role | Model name | GitHub Copilot model |
|------|------------|----------------------|
| Primary | `claude-opus-4.6` | `github_copilot/claude-opus-4.6` |
| Fast | `claude-sonnet-4.6` | `github_copilot/claude-sonnet-4.6` |
| Additional | `claude-haiku-4.5` | `github_copilot/claude-haiku-4.5` |

## Additional commands

### Check status
```bash
just claude-status
```

### Restore original settings
```bash
just claude-disable
```

### Stop the proxy
```bash
just stop
```

### List available Copilot models
```bash
just list-models
just list-models-enabled
```

## Troubleshooting

- **Authentication issues**: The first `just start` will prompt for GitHub authentication
- **Connection problems**: Use `just test` to verify the proxy is working
- **Configuration issues**: Use `just claude-status` to check your settings
- **Reset everything**: Use `just claude-disable` then `just claude-enable` to reconfigure
