source ~/.zsh.alias

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY

bindkey '\e[H' beginning-of-line
bindkey '\e[F' end-of-line
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

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
