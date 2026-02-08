#!/usr/bin/env bash
source .venv/bin/activate

set -e
case "$1" in
    "shell")
        exec bash
        ;;

    "migrate")
        exec alembic upgrade head
        ;;

    "run")
        exec python app/main.py
        ;;

    "idle")
        exec tail -f /dev/null
        ;;

    "")
        echo "No run parameter passed please use one of: [shell, migrate, run, idle]"
        exit 1
        ;;

    *)
        echo "Unknown command '$1'. Please use one of: [shell, migrate, run, idle]"
        exit 1
        ;;
esac
