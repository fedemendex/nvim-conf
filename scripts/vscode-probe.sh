#!/bin/sh
# Ask the embedded Neovim behind VS Code what state it is in.
#
# Run this from a terminal at the moment VS Code stops responding to typing.
# Neovim answers RPC from inside the input waits that cause the freeze, so a
# reply here is expected even when the editor looks dead; no reply at all is
# itself the finding, and means Neovim is stuck somewhere that does not pump
# the event loop.
#
# With no argument it probes every running instance, which is what you want
# when several VS Code windows are open and only one has wedged.

set -e

directory="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/vscode-sockets"

if [ ! -d "$directory" ]; then
    echo "No sockets directory yet: $directory" >&2
    echo "Restart VS Code so the config can open one." >&2
    exit 1
fi

found=0

for socket in "$directory"/*.sock; do
    [ -S "$socket" ] || continue

    found=1
    pid=$(basename "$socket" .sock)

    echo "=== nvim pid $pid ==="

    if ! nvim --server "$socket" \
        --remote-expr 'v:lua.quiddam_vscode_probe()' 2>&1; then
        echo "  unreachable -- Neovim is not answering RPC"
    fi

    echo
done

if [ "$found" -eq 0 ]; then
    echo "No live sockets in $directory" >&2
    exit 1
fi
