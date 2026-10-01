#!/usr/bin/env bash
# Cycles sessions in the order choose-tree shows them (session id, i.e. creation
# order). switch-client -n/-p can't do this: it walks tmux's internal session
# tree, which is keyed by name, so it visits sessions alphabetically instead.
# Usage: session-cycle.sh next|prev [client] [--dry-run]
# The client is passed from the key binding as #{client_name}, since run-shell
# has no implicit current client to switch.
set -eo pipefail

dir=${1:-next}
client=${2:-}
dry=${3:-}

[[ -n $client ]] && c=(-c "$client") || c=()

# Session ids sort lexically as $10 < $2, so strip the $ and sort numerically.
ids=($(tmux list-sessions -F '#{session_id}' | tr -d '$' | sort -n))
n=${#ids[@]}
(( n > 1 )) || exit 0

current=$(tmux display-message "${c[@]}" -p '#{session_id}')
current=${current#\$}

for i in "${!ids[@]}"; do
  [[ ${ids[i]} == "$current" ]] || continue
  if [[ $dir == prev ]]; then
    target=${ids[(i - 1 + n) % n]}
  else
    target=${ids[(i + 1) % n]}
  fi
  if [[ $dry == --dry-run ]]; then
    tmux list-sessions -F '#{session_id} #{session_name}' | grep "^\\\$$target "
  else
    tmux switch-client "${c[@]}" -t "\$$target"
  fi
  exit 0
done
