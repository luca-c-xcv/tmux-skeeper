#!/usr/bin/env bash
# Save / restore / list / delete tmux sessions (window names + paths).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  m="tmux-skeeper: 'jq' is required but not installed"
  tmux display-message "$m" 2>/dev/null || echo "$m" >&2
  exit 1
fi

# Sessions live in the tmux config folder: ~/.config/tmux if present, else ~/.tmux
if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" ]; then
  CONF="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
else
  CONF="$HOME/.tmux"
fi
DIR="${TMUX_SKEEPER_DIR:-$CONF/sessions}"
mkdir -p "$DIR"

msg() { tmux display-message "$*" 2>/dev/null || echo "$*"; }
file_for() { echo "$DIR/${1//\//_}.json"; }

cmd_save() {
  local name="${1:-$(tmux display-message -p '#S')}"
  local target="${2:-$name}"
  tmux has-session -t "=$target" 2>/dev/null || { msg "No such live session: $target"; exit 1; }
  tmux list-windows -t "=$target" -F '#{window_index}'$'\t''#{window_name}'$'\t''#{pane_current_path}'$'\t''#{window_active}' \
    | jq -R -s --arg name "$name" '{name: $name, windows: [split("\n")[] | select(length>0) | split("\t")
        | {index: (.[0]|tonumber), name: .[1], path: .[2], active: (.[3]=="1")}]}' \
    > "$(file_for "$name")"
  msg "Saved session '$name'"
}

cmd_restore() {
  local name="${1:?session name required}"
  local f; f="$(file_for "$name")"
  [ -f "$f" ] || { msg "No saved session: $name"; exit 1; }

  if ! tmux has-session -t "=$name" 2>/dev/null; then
    local first=1 active=""
    while IFS=$'\t' read -r wname path act; do
      [ -d "$path" ] || path="$HOME"
      if [ $first -eq 1 ]; then
        tmux new-session -d -s "$name" -n "$wname" -c "$path"
        first=0
      else
        tmux new-window -d -t "=$name:" -n "$wname" -c "$path"
      fi
      [ "$act" = "true" ] && active="$wname"
    done < <(jq -r '.windows[] | [.name, .path, .active] | @tsv' "$f")
    [ -n "$active" ] && tmux select-window -t "=$name:$active" 2>/dev/null || true
  fi

  if [ -n "${TMUX:-}" ]; then tmux switch-client -t "=$name"; else tmux attach -t "=$name"; fi
}

cmd_delete() {
  local f; f="$(file_for "${1:?session name required}")"
  [ -f "$f" ] || { msg "No saved session: $1"; exit 1; }
  rm -- "$f"; msg "Deleted saved session '$1'"
}

cmd_list() {
  local f
  for f in "$DIR"/*.json; do
    [ -e "$f" ] || continue
    printf '%s (%s windows)\n' "$(basename "$f" .json)" "$(jq '.windows|length' "$f")"
  done
}

# Interactive menu (prefix + key): pick a saved session and run an action.
cmd_menu() {
  local action="$1" args=() f n
  for f in "$DIR"/*.json; do
    [ -e "$f" ] || continue
    n="$(basename "$f" .json)"
    args+=("$n" "" "run-shell \"$0 $action '$n'\"")
  done
  [ ${#args[@]} -gt 0 ] || { msg "No saved sessions"; exit 0; }
  tmux display-menu -T "#[align=centre]$action session" "${args[@]}"
}

case "${1:-}" in
  save)    shift; cmd_save "$@" ;;
  restore) shift; cmd_restore "$@" ;;
  delete)  shift; cmd_delete "$@" ;;
  list)    cmd_list ;;
  menu)    shift; cmd_menu "$@" ;;
  *) echo "usage: $0 {save [name]|restore <name>|delete <name>|list}" >&2; exit 2 ;;
esac
