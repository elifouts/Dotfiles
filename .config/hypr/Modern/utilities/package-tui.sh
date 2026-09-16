#!/bin/bash

exec python3 "$(dirname "${BASH_SOURCE[0]}")/package-tui.py" "$@"
