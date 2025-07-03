#!/usr/bin/env zsh

builtin cd "$(dirname "$0")/../"

if [ "$?" -eq 0 ]; then

    # check if supervisord is already running

    if [ -f "$PWD/run/supervisord.pid" ]; then
        pid="$(pgrep -F "$PWD/run/supervisord.pid" 2>/dev/null)"
        if [ -n "$pid" ] && [ "$pid" -gt 0 ] && [ -S "$PWD/run/supervisord.sock" ]; then
            return 0
        fi
    fi

    # evaluate local .env when exists before supervisord

    if [ -f "$PWD/.envrc" ] && [ -x "$commands[direnv]" ]; then
        eval "$(direnv export zsh)"
    fi

    if [ ! -x "$commands[uvx]" ]; then
        echo " == fail ($0): uvx not found"
        return 1
    fi

    # start supervisord and check if it is started successfully
    uvx \
        --color always \
        --frozen \
        --no-progress \
        --no-sync \
        --quiet \
        --from supervisor \
        supervisord \
            --silent \
            --configuration "$PWD/supervisord.conf" \
    && sleep 0.5

    if [ "$?" -eq 0 ] && [ -f "run/supervisord.pid" ]; then
        pid="$(pgrep -F "run/supervisord.pid")"
        if [ -n "$pid" ] && [ "$pid" -gt 0 ] && [ -S "run/supervisord.sock" ]; then
            echo " -- info ($0): supervisord($pid) started (from $PWD/run/supervisord.pid)" >&2
            return 0
        fi
    fi

    echo " == fail ($0): supervisord start failed" >&2
    return 1
fi
