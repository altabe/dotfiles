# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a "stow package" that mirrors the home directory structure.

## Stow Commands

```bash
# Symlink a single app's config to ~
stow <app-name> -t ~

# Symlink all configs to ~
stow * -t ~
```

## Repository Structure

Each directory is a stow package — its contents get symlinked relative to `~`:

- **zsh/** — Shell config (`.zshrc`, `.zsh.alias`). Sources oh-my-posh and fzf.
- **nvim/** — Neovim config at `.config/nvim/`. Based on kickstart.nvim, uses lazy.nvim plugin manager. Has a `nvim.backup/` variant for different environments.
- **tmux/** — Tmux config (`.tmux.conf`). Prefix is `C-a`. Vi copy-mode keys.
- **kitty/** — Kitty terminal config at `.config/kitty/`. Custom kitten hint mappings for regex-based text selection.
- **omp/** — Oh My Posh prompt theme at `.config/omp/`. TOML config with Catppuccin palette.

## Neovim Config Architecture

Entry point: `nvim/.config/nvim/init.lua` — sets leader to Space, detects remote environments (SSH/tmux) for performance tuning, then loads:
- `lua/config/options.lua` — Vim options
- `lua/config/keymaps.lua` — Key bindings
- `lua/config/lazy.lua` — lazy.nvim setup; selectively imports from `lua/plugins/` (colorscheme, telescope, treesitter, lsp, nvim-cmp are active; others disabled for remote perf)

Individual plugin configs live in `lua/plugins/<name>.lua`.

## Conventions

- Catppuccin theme is used across kitty, nvim, and omp
- Aliases use short forms: `nv` (nvim), `lg` (lazygit), `ta`/`tn`/`tk`/`tl` (tmux)
- Python aliases default to python3/pip3
