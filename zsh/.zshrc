source .zsh.alias

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

