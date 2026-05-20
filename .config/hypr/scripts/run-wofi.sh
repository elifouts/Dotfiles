#!/bin/bash

if pgrep -x wofi > /dev/null; then
    return
else
    wofi -n
fi
