set dotenv-load

default:
    @just --list

setup:
    @echo "Setting up environment..."
    @uv sync
    @if [ ! -f .env ]; then \
        echo "Generating .env file..."; \
        uv run python generate_env.py; \
    else \
        echo "✓ .env file already exists, skipping generation"; \
    fi
    @echo "✓ Setup complete"

start:
    @echo "Starting LiteLLM proxy..."
    uv run litellm --config copilot-config.yaml --port 4444

stop:
    @echo "Stopping processes..."
    @pkill -f litellm 2>/dev/null || true
    @echo "✓ Processes stopped"

test:
    @echo "Testing proxy connection..."
    curl -X POST http://localhost:4444/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2 | tr -d '\"')" \
        -d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hello"}]}'
    @echo ""
    @echo "✅ Test completed successfully!"

claude-enable:
    @echo "Configuring Claude Code to use local proxy..."
    @if [ ! -f .env ]; then echo "❌ .env file not found. Run 'just setup' first."; exit 1; fi
    @MASTER_KEY=$(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2 | tr -d '"'); \
    if [ -z "$MASTER_KEY" ]; then echo "❌ LITELLM_MASTER_KEY not found in .env"; exit 1; fi; \
    if [ -f ~/.claude/settings.json ]; then \
        cp ~/.claude/settings.json ~/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S); \
        echo "📁 Backed up existing settings to ~/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"; \
    fi; \
    uv run python scripts/claude_enable.py "$MASTER_KEY"
    @echo "✅ Claude Code configured to use local proxy"
    @echo "💡 Make sure to run 'just start' to start the LiteLLM proxy server"

claude-disable:
    @echo "Restoring Claude Code to default settings..."
    @if [ -f ~/.claude/settings.json ]; then \
        cp ~/.claude/settings.json ~/.claude/settings.json.proxy_backup.$(date +%Y%m%d_%H%M%S); \
        echo "📁 Backed up proxy settings to ~/.claude/settings.json.proxy_backup.$(date +%Y%m%d_%H%M%S)"; \
    fi
    @if ls ~/.claude/settings.json.backup.* >/dev/null 2>&1; then \
        LATEST_BACKUP=$(ls -t ~/.claude/settings.json.backup.* | head -1); \
        cp "$LATEST_BACKUP" ~/.claude/settings.json; \
        echo "✅ Restored settings from $LATEST_BACKUP"; \
    else \
        uv run python scripts/claude_disable.py; \
    fi

claude-status:
    @echo "Current Claude Code configuration:"
    @echo "=================================="
    @if [ -f ~/.claude/settings.json ]; then \
        echo "📄 Settings file: ~/.claude/settings.json"; \
        echo ""; \
        cat ~/.claude/settings.json | uv run python -m json.tool 2>/dev/null || cat ~/.claude/settings.json; \
        echo ""; \
        if grep -q "localhost:4444" ~/.claude/settings.json 2>/dev/null; then \
            echo "🔗 Status: Using local proxy"; \
            if curl -s http://localhost:4444/health >/dev/null 2>&1; then \
                echo "✅ Proxy server: Running"; \
            else \
                echo "❌ Proxy server: Not running (run 'just start')"; \
            fi; \
        else \
            echo "🌐 Status: Using default Anthropic servers"; \
        fi; \
    else \
        echo "📄 No settings file found - using Claude Code defaults"; \
        echo "🌐 Status: Using default Anthropic servers"; \
    fi

list-models:
    @echo "Listing available GitHub Copilot models..."
    ./list-copilot-models.sh

list-models-enabled:
    @echo "Listing enabled GitHub Copilot models..."
    ./list-copilot-models.sh --enabled-only
