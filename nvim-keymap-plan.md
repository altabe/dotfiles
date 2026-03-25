# Nvim Keymap Redesign Plan

Goals:
- Align with VSCode muscle memory (your custom config, not defaults)
- Minimize triple-key shortcuts for frequent actions
- Respect tmux prefix-less bindings (C-a, C-g, C-u, C-], Alt+h/l/j/k)

## Tier 1: Port VSCode Bindings

| Action | VSCode (your config) | Current nvim | New nvim | Keys |
|---|---|---|---|---|
| Find files | `<C-p>` | `<leader>sf` | `<C-p>` | 2 |
| Workspace symbols | `<C-t>` | `<leader>ws` | `<C-t>` | 2 |
| Document symbols (outline) | `<leader>o` | `<leader>ds` | `<leader>o` | 2 |
| Vsplit | `<leader>v` | `<leader>sv` | `<leader>v` | 2 |
| Save | `<leader>w` | (none) | `<leader>w` | 2 |
| Close buffer | `<leader>q` | diagnostic quickfix | `<leader>q` = `:bd` | 2 |
| Duplicate down/up | `<leader>j/k` | `<leader>j/k` | keep (already matching) | 2 |
| Focus left/right | `<leader>h/l` | `<C-h>/<C-l>` | add `<leader>h/l` too (keep both) | 2 |
| Prev/next buffer | `_` / `+` | (none) | `_` / `+` | 1 |
| Definition hover | `gh` | (none) | `gh` (vim.lsp.buf.hover) | 2 |

## Tier 2: Shorten Frequent Actions

| Action | Current nvim | New nvim | Rationale |
|---|---|---|---|
| Live grep | `<leader>sg` | `<leader>g` | 2 keys. Can't use `<C-g>` (tmux new-window) |
| Code action | `<leader>ca` | `<leader>a` | 2 keys |
| Rename | `<leader>rn` | `<F2>` | 1 key. VSCode default |
| Recent files | `<leader>s.` | `<leader>.` | 2 keys |
| Grep word under cursor | `<leader>sw` | `<leader>*` | 2 keys. Like vim `*` but project-wide |
| Toggle diagnostics | `<leader>ud` | `<leader>d` | 2 keys |
| Diagnostic quickfix | `<leader>q` (displaced) | `<leader>e` | 2 keys. Mnemonic: Errors |

## Tier 3: Leave at 3-key (Low Frequency)

- `<leader>sh` — horizontal split (rare, `<leader>v` covers vertical)
- `<leader>sk` — search keymaps (utility)
- `<leader>sn` — search nvim config files
- `<leader>th` — toggle inlay hints
- `<leader>sr` — search resume

## Also Consider Adding

| Action | Suggested | Notes |
|---|---|---|
| Maximize split | `<leader>z` | Matches your VSCode `<leader>z` |
| Toggle comment | `<C-/>` | VSCode standard. Some terminals send `<C-_>`, map both |

## Auto-Save Recommendation

You use `files.autoSave: "afterDelay"` (300ms) in VSCode.
Recommendation: add `vim.opt.autowriteall = true` in nvim options.
This saves on buffer switch/quit (not on every keystroke), avoiding the
mid-type issue. Nvim config files are inert until reloaded anyway.

## Conflicts Resolved

- `<C-g>` NOT used (tmux new-window)
- `<C-u>` NOT used (tmux copy-mode)
- `Alt+h/l/j/k` NOT remapped (tmux window/pane nav)
- `<leader>q` repurposed: close buffer (was diagnostic quickfix, moved to `<leader>e`)
- `<C-p>` in normal mode only (insert-mode completion `<C-p>` unaffected)
- `<C-t>` loses tag-stack-pop, but `<C-o>` (jumplist back) covers navigation
