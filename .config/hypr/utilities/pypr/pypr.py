#!/usr/bin/python

import asyncio
import re
import sys
from contextlib import asynccontextmanager

import pyprland.ipc as ipc
from pyprland.adapters import hyprland as hypr_adapter
from pyprland.adapters import notifier
from pyprland.models import PyprError
from pyprland.plugins.scratchpads.schema import SCRATCHPAD_SCHEMA

_open_connection = ipc.hyprctl_connection


@asynccontextmanager
async def hyprctl_connection(logger):
    try:
        async with _open_connection(logger) as streams:
            yield streams
    except (PyprError, FileNotFoundError):
        raise
    except ConnectionResetError:
        raise
    except OSError as e:
        raise ConnectionResetError(str(e)) from e


ipc.hyprctl_connection = hyprctl_connection
hypr_adapter.hyprctl_connection = hyprctl_connection

ipc.IPC_MAX_RETRIES = 8


def _never_fail(method):
    async def wrapper(self, *args, log, **kwargs):
        try:
            return await method(self, *args, log=log, **kwargs)
        except Exception as e:
            log.warning("notification dropped: %s", e)
            return None

    return wrapper


for _name in ("notify", "notify_info", "notify_error"):
    setattr(notifier.HyprlandNotifier, _name, _never_fail(getattr(notifier.HyprlandNotifier, _name)))


def _check_each(valid):
    def check(values):
        return [f"Invalid value {v!r}, valid options: {', '.join(valid)}" for v in values if v not in valid]

    return check


for _field in SCRATCHPAD_SCHEMA:
    if _field.field_type is list and _field.choices and not _field.validator:
        _field.validator = _check_each(_field.choice_values)

from pyprland.command import main

if __name__ == "__main__":
    sys.argv[0] = re.sub(r"(-script\.pyw|\.exe)?$", "", sys.argv[0])
    sys.exit(main())
