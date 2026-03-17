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

# Oh my posh
# eval "$(oh-my-posh init zsh --config ~/.config/omp/catpuccin.omp.json)"
eval "$(oh-my-posh init zsh --config ~/.config/omp/config.toml)"
# eval "$(oh-my-posh init zsh --config ~/.config/omp/orig_config.toml)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json)"
# eval "$(oh-my-posh init zsh)"
source <(fzf --zsh)

export PATH="$HOME/.local/bin:$PATH"

# Kubectl aliases
[[ -f ~/.kubectl_aliases ]] && source ~/.kubectl_aliases

# The next line updates PATH for Nebius CLI.
if [ -f '/Users/tomerbenaltabe/.nebius/path.zsh.inc' ]; then source '/Users/tomerbenaltabe/.nebius/path.zsh.inc'; fi
