# tmux-skeeper

**S**ession **keeper** for tmux: save a session by name, then bring it back
(or delete it) at any time, from any other tmux session.

## What it does

For a live tmux session, skeeper stores each window's **name** and **working
directory** in a small JSON file. Later you can recreate that session from
the saved file, even after the original was killed or tmux restarted.

- **Save** the current session under its name
- **Restore** a saved session by name: it is recreated and you switch to it.
  If a live session with that name already exists, you just switch to it.
- **List** and **delete** saved sessions

It is deliberately simple: no pane layouts, no running programs, no
auto-save. Just the windows you had, where you had them.

## Requirements

`tmux`, `bash`, `jq`

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'luca-c-xcv/tmux-skeeper'
```

Manually: clone the repo and add to `~/.tmux.conf`:

```tmux
run-shell /path/to/tmux-skeeper/tmux-skeeper.tmux
```

## Key bindings (after the tmux prefix)

| Key        | Action                                   |
|------------|------------------------------------------|
| `Ctrl-s`   | Save the current session                 |
| `Ctrl-r`   | Menu of saved sessions: restore one      |
| `Ctrl-d`   | Menu of saved sessions: delete one       |

Change them (before loading the plugin):

```tmux
set -g @skeeper-save    'S'
set -g @skeeper-restore 'R'
set -g @skeeper-delete  'D'
```

## Command line

```sh
scripts/sessions.sh save [name]
scripts/sessions.sh restore <name>
scripts/sessions.sh delete <name>
scripts/sessions.sh list
```

## Storage

`~/.config/tmux/sessions/<name>.json` if `~/.config/tmux` exists, otherwise
`~/.tmux/sessions/<name>.json`. Override with `TMUX_SKEEPER_DIR`.

```json
{
  "name": "work",
  "windows": [
    {"index": 0, "name": "editor", "path": "/home/me/project", "active": false},
    {"index": 1, "name": "server", "path": "/home/me/project/api", "active": true}
  ]
}
```

If a saved path no longer exists, that window opens in `$HOME`.

## Note

Disable tmux-resurrect before using this plugin: it binds the same default
keys (`Ctrl-s` / `Ctrl-r`).
