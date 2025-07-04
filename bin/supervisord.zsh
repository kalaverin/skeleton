#!/usr/bin/env zsh

function is_started {
    if [ ! -x "$1" ]; then
        echo " == fail ($0): directory not found: '$1'"
        return 1

    elif [ -f "$1/supervisord.pid" ]; then
        pid="$(pgrep -F "$1/supervisord.pid")"
        if [ -n "$pid" ] && [ "$pid" -gt 0 ] && [ -S "$1/supervisord.sock" ]; then
            # echo " ++ warn ($0): supervisord($pid) started (from $1/supervisord.pid)" >&2
            return 0
        fi
        return 2
    fi
    return 3
}

builtin cd "$(dirname "$0")/../" || return "$?"

# check if supervisord is already running

local RUN="$PWD/run"
if [ ! -x "$RUN" ]; then
    echo " == fail ($0): directory not found: '$RUN'"
    return 1

elif [ ! -x "$commands[uvx]" ]; then
    echo " == fail ($0): uvx not found"
    return 1
fi
is_started "$RUN" && return 0

# evaluate local .env when exists before supervisord

if [ -f "$PWD/.env" ] && [ -x "$commands[mise]" ]; then
    eval "$(mise activate)"
elif [ -f "$PWD/.envrc" ] && [ -x "$commands[direnv]" ]; then
    eval "$(direnv export zsh)"
fi

# start supervisord and check if it is started successfully

uvx \
    --color always \
    --no-progress \
    --quiet \
    --from supervisor \
    supervisord \
        --silent \
        --configuration "$PWD/etc/supervisord.conf" && \
echo " -- info ($0): supervisord starting up, wait.." && \
sleep 0.5 && \
is_started "$RUN" && return 0

echo " == fail ($0): supervisord start failed" >&2
return 1
