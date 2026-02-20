#!/usr/bin/env python3
import json
import sys
from pathlib import Path

import yaml


def load_model_names(config_path: Path) -> tuple[str, str]:
    with open(config_path, "r") as f:
        config = yaml.safe_load(f)
    model_list = config["model_list"]
    return model_list[0]["model_name"], model_list[1]["model_name"]


def main():
    if len(sys.argv) != 2:
        print("Usage: claude_enable.py <master_key>")
        sys.exit(1)

    master_key = sys.argv[1]
    claude_dir = Path.home() / ".claude"
    settings_file = claude_dir / "settings.json"

    script_dir = Path(__file__).parent
    copilot_config = script_dir.parent / "copilot-config.yaml"
    model, fast_model = load_model_names(copilot_config)

    claude_dir.mkdir(exist_ok=True)

    settings = {}
    if settings_file.exists():
        try:
            with open(settings_file, "r") as f:
                settings = json.load(f)
        except (json.JSONDecodeError, IOError):
            settings = {}

    settings["env"] = {
        "ANTHROPIC_AUTH_TOKEN": master_key,
        "ANTHROPIC_BASE_URL": "http://localhost:4444",
        "ANTHROPIC_MODEL": model,
        "ANTHROPIC_SMALL_FAST_MODEL": fast_model,
    }

    settings["model"] = model

    if "$schema" not in settings:
        settings["$schema"] = "https://json.schemastore.org/claude-code-settings.json"

    with open(settings_file, "w") as f:
        json.dump(settings, f, indent=2)

    print("✅ Updated settings while preserving existing configuration")


if __name__ == "__main__":
    main()
