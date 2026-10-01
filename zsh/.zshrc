source ~/.zsh.alias

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY

bindkey '\e[H' beginning-of-line
bindkey '\e[F' end-of-line
bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

# Alt+arrows and Alt+backspace (word navigation with slash as separator)
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word
bindkey '\eb' backward-word
bindkey '\ef' forward-word
bindkey '\e^?' backward-kill-word

# Completion
autoload -Uz compinit
zmodload zsh/complist
# Full fpath rescan at most once a day; otherwise trust the cached dump (-C)
if [[ -n $HOME/.zcompdump(#qN.mh-24) ]]; then
  compinit -C
else
  compinit
fi
zstyle ':completion:*' menu select                                # arrow-key menu on Tab
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'  # case-insensitive + partial-word
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.cache/zsh/compcache
bindkey -M menuselect '^[[Z' reverse-menu-complete                # Shift-Tab goes backward

# Before the tools below: on Linux, oh-my-posh and claude install to ~/.local/bin
# Before the tools below: on Linux, oh-my-posh and claude install to ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Oh my posh
# eval "$(oh-my-posh init zsh --config ~/.config/omp/catpuccin.omp.json)"
eval "$(oh-my-posh init zsh --config ~/.config/omp/config.toml)"

# eval "$(oh-my-posh init zsh --config ~/.config/omp/orig_config.toml)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json)"
# eval "$(oh-my-posh init zsh)"
source <(fzf --zsh)

# zoxide: frecency-ranked cd. `cd gitop` jumps to the best-ranked dir whose
# path contains "gitop". When zoxide's substring matcher finds nothing (e.g.
# `cd cfel` for corma-fellowship), fall back to fzf fuzzy-matching over the
# whole zoxide db. Every cd (builtin included) feeds the db via zoxide's
# chpwd hook.
eval "$(zoxide init zsh)"
cd() {
  if [[ $# -eq 0 || -d $1 || $1 == -* ]]; then
    builtin cd "$@"
    return
  fi
  __zoxide_z "$@" 2>/dev/null && return
  # --list is frecency-ordered and --no-sort preserves that order, so this
  # picks the most-frecent dir among the fuzzy matches.
  local dir
  dir=$(zoxide query --list | fzf --filter "$*" --no-sort | head -1)
  if [[ -n $dir ]]; then
    builtin cd "$dir"
  else
    builtin cd "$@"  # surface the normal "no such file or directory" error
  fi
}

# Ghost-text suggestions from history as you type; accept with → (or Alt-f per word)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Kubectl aliases
[[ -f ~/.kubectl_aliases ]] && source ~/.kubectl_aliases

# Claude sound toggle
alias son='jq ".hooks.Stop = [{matcher:\"\",hooks:[{type:\"command\",command:\"afplay /System/Library/Sounds/Glass.aiff\"}]}] | .hooks.Notification = [{matcher:\"\",hooks:[{type:\"command\",command:\"afplay /System/Library/Sounds/Glass.aiff\"}]}]" ~/.claude/settings.json > /tmp/cs.json && mv /tmp/cs.json ~/.claude/settings.json'
alias soff='jq "del(.hooks.Stop) | del(.hooks.Notification)" ~/.claude/settings.json > /tmp/cs.json && mv /tmp/cs.json ~/.claude/settings.json'

# The next line updates PATH for Nebius CLI.
if [ -f '/Users/tomerbenaltabe/.nebius/path.zsh.inc' ]; then source '/Users/tomerbenaltabe/.nebius/path.zsh.inc'; fi

# Auto-reconnecting SSH to secure-workstation.
# The AWS EC2 Instance Connect tunnel hard-caps every session at 1 hour, so this
# re-dials on drop and re-attaches a persistent tmux session ("main") — your work
# survives the reconnect. Detach with Ctrl-b d (or exit the shell) to stop cleanly.
sws() {
  while true; do
    ssh -t secure-workstation 'tmux attach -t main || tmux new -s main'
    local code=$?
    [ $code -eq 0 ] && break   # clean detach/logout -> stop
    echo "sws: tunnel dropped (exit $code) — reconnecting in 5s (Ctrl-C to stop)…"
    sleep 5
  done
}

