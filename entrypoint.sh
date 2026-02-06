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
        echo "nothing to do"
        exit 1
        ;;

    *)
        echo "nothing to do"
        exit 1
        ;;
esac
