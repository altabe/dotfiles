---
name: create_interactive
description: Create or edit interactive Python scripts using notebook-style cells (# %%) that work both interactively in IDEs like VS Code and as standalone CLI scripts. Use when the user asks to create a Python notebook, interactive script, or .py file with cell separators.
argument-hint: [description or file path]
---

# Interactive Python Script Skill

You are creating or editing a Python script that uses **notebook-style cells** (compatible with VS Code Interactive Python, Jupyter, Spyder, PyCharm, etc.) while also being fully executable as a standalone CLI script.

## Cell Format Rules

- Cells are separated by the comment `# %%`
- The **first line of code or comment** after `# %%` MUST be a descriptive comment explaining what the cell does. This is critical because IDEs like VS Code only show the first line of a collapsed cell — if it's a decorator line (e.g. `# ═══════`) the user can't tell what the cell does without expanding it.
- Only add `# %%` and description comments to cells **you create**. Do NOT add comments to existing cells unless the user explicitly asks
- Example:
  ```python
  # %%
  # Load and preprocess the dataset
  import pandas as pd
  df = pd.read_csv("data.csv")
  df = df.dropna()
  ```
- **Bad** — first line is a visual separator, not a description:
  ```python
  # %%
  # ═══════════════════════════════════════
  # Load and preprocess the dataset
  ```

## Dual-Mode Compatibility (Critical)

Every script MUST work in **both** modes:
1. **Interactive mode** — run cell-by-cell in an IDE (VS Code, Jupyter, etc.)
2. **CLI mode** — run end-to-end via `python script.py` from the terminal with no user interaction

To achieve this:
- Do NOT use `input()` or any interactive prompts. If configuration is needed, define it as variables at the top of the script.
- Avoid `%magic` commands or IPython-specific syntax — use pure Python only.
- If the script needs to display output, use `print()` for CLI and let the IDE handle rich display for interactive mode.
- For plots, use `plt.show()` which works in both modes.

## Self-Contained & Fully Functional

The script must be **self-contained** and work on its own without external setup steps:

- **Credentials & authentication**: If credentials, API keys, tokens, or auth configs are available (from environment, config files, or known to you), embed them directly in the script so it authenticates without user interaction. Use environment variables as fallback: `os.environ.get("KEY", "hardcoded_default")`.
- **Dependencies**: Add a cell at the top that installs required packages if they're not already available:
  ```python
  # %%
  # Install dependencies
  import subprocess, sys
  for pkg in ["pandas", "requests"]:
      try:
          __import__(pkg)
      except ImportError:
          subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])
  ```
- **Data & Caching**: Scripts are often run multiple times. If the script fetches/downloads data, always cache it locally to avoid redundant downloads. Check if a cached file exists before downloading, and only fetch if it's missing. Example:
  ```python
  # %%
  # Fetch data (cached locally)
  import os, requests
  CACHE_FILE = "data_cache.json"
  if not os.path.exists(CACHE_FILE):
      print("Downloading data...")
      resp = requests.get(DATA_URL)
      resp.raise_for_status()
      with open(CACHE_FILE, "w") as f:
          f.write(resp.text)
      print(f"Saved to {CACHE_FILE}")
  else:
      print(f"Using cached {CACHE_FILE}")
  with open(CACHE_FILE) as f:
      data = json.load(f)
  ```
  Use a sensible cache file name/path relative to the script. For multiple data sources, use separate cache files. If the data has a natural expiry, optionally check file age — but default to simple exists-or-download logic.
- **Configuration**: All configurable values (URLs, paths, parameters) should be defined as variables in an early cell so they're easy to find and modify.

## Structure Guidelines

1. **First cell**: Install dependencies (if any non-stdlib packages are needed)
2. **Second cell**: Imports and configuration (credentials, paths, parameters)
3. **Middle cells**: Core logic, broken into logical steps
4. **Final cell(s)**: Output, visualization, or summary

Keep cells focused — each cell should do one logical thing. Avoid very long cells; break them up.

## Naming Convention

When creating a **new** script, the filename MUST start with `nb_` (e.g., `nb_analysis.py`, `nb_fetch_data.py`). This prefix identifies it as a notebook-style interactive script. If the user provides a name without the prefix, prepend it automatically. This rule applies only to new files — do not rename existing files.

## When Editing Existing Scripts

- Preserve existing cell boundaries and comments
- Only add `# %%` markers to new code you write
- Do not restructure or reformat existing cells unless asked
- Maintain the script's existing style and conventions

## Task

$ARGUMENTS
