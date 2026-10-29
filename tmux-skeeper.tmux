#!/usr/bin/env bash
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$CURRENT_DIR/scripts/sessions.sh"

if ! command -v jq >/dev/null 2>&1; then
  tmux display-message "tmux-skeeper: 'jq' is required but not installed (e.g. sudo apt install jq)"
  exit 0
fi

get() { local v; v="$(tmux show-option -gqv "$1")"; echo "${v:-$2}"; }

tmux bind-key "$(get @skeeper-save C-s)"    run-shell "$S save '#S'"
tmux bind-key "$(get @skeeper-restore C-r)" run-shell "$S menu restore"
tmux bind-key "$(get @skeeper-delete C-d)"  run-shell "$S menu delete"
