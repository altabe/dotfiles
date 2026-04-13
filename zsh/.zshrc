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

# Alternating background between commands
# \e[J pre-paints visible screen with tinted bg; command output overwrites text cells
# but empty end-of-line cells keep the pre-painted bg
__cmd_bg_toggle=0
_cmd_bg_start() {
  (( __cmd_bg_toggle = 1 - __cmd_bg_toggle ))
  (( __cmd_bg_toggle )) && printf '\e[48;2;80;82;108m\e[J'
}
_cmd_bg_reset() { printf '\e[49m\e[J' }
precmd_functions=(${precmd_functions:#_cmd_bg_reset} _cmd_bg_reset)
preexec_functions=(${preexec_functions:#_cmd_bg_start} _cmd_bg_start)
# eval "$(oh-my-posh init zsh --config ~/.config/omp/orig_config.toml)"
# eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json)"
# eval "$(oh-my-posh init zsh)"
source <(fzf --zsh)

export PATH="$HOME/.local/bin:$PATH"

# Kubectl aliases
[[ -f ~/.kubectl_aliases ]] && source ~/.kubectl_aliases

# Claude sound toggle
alias son='jq ".hooks.Stop = [{matcher:\"\",hooks:[{type:\"command\",command:\"afplay /System/Library/Sounds/Glass.aiff\"}]}] | .hooks.Notification = [{matcher:\"\",hooks:[{type:\"command\",command:\"afplay /System/Library/Sounds/Glass.aiff\"}]}]" ~/.claude/settings.json > /tmp/cs.json && mv /tmp/cs.json ~/.claude/settings.json'
alias soff='jq "del(.hooks.Stop) | del(.hooks.Notification)" ~/.claude/settings.json > /tmp/cs.json && mv /tmp/cs.json ~/.claude/settings.json'

# The next line updates PATH for Nebius CLI.
if [ -f '/Users/tomerbenaltabe/.nebius/path.zsh.inc' ]; then source '/Users/tomerbenaltabe/.nebius/path.zsh.inc'; fi
