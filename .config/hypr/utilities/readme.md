# Hyprland scripts

The scripts behind my Hyprland setup: profiles, the settings panel, theming, bars and a pypr fix.

## How it's laid out

A style is just a folder. Drop in a new one and it works.

```
hypr/<style>/base/          shared .lua config
hypr/<style>/<variant>/     per-machine overrides (desktop, laptop...), incl. machine.lua
hypr/<style>/utilities/     quickshell config (shell.qml, lock.qml, boot.qml and one folder per utility)
hypr/<style>/waybar/<name>/ waybar styles (config, style.css, preview.png)
hypr/<style>/quickshellbar/<name>/  quickshell bar styles (config.json, preview.svg)
hypr/tweaks/                tweaks and saved profiles from the settings panel
hypr/state/                 what's live right now, gitignored: profile, bar, bar-style, saved.json,
                            color-theme, color-roles*.json, settings.lua, todos.json
hypr/utilities/             scripts that work for any style, paths.sh is where they find the active one
```

A variant file with the same name as a base file replaces it.

`hyprland.lua` reads `state/profile` and loads the files straight out of that profile's folders, variant first then base, so editing `Modern/base/style.lua` is editing the live config. The style's `base/hyprland.lua` loads `machine`, `startup`, `style`, `shortcuts` and then `overrides.lua` last. `overrides.lua` applies `settings.lua` (only the keys you changed) on top of the profile:

- animations use one curve for every leaf, base speeds divided by the speed multiplier
- mouse sensitivity is also set per device since per-device beats the global value

## Profiles

```
hypr-profile.sh apply <style> <variant> [--offline]
hypr-profile.sh list
```

Applying just writes `state/profile` and reloads. Nothing gets copied anymore, so there's nothing to save back.

## Settings panel

`hypr-settings.py` is the backend. Tweaks live in `hypr/tweaks/<Style>-<variant>.json` and the active one is mirrored to `hypr/state/settings.lua`. Profile files are never touched.

```
hypr-settings.py state KEY...       # current values as JSON
hypr-settings.py set KEY=JSON ...   # save + apply live (dotted keys, null removes)
hypr-settings.py reset              # back to Default, variant file is kept
hypr-settings.py sync               # write settings.lua for the active profile
hypr-settings.py saved save NAME    # snapshot what's live
hypr-settings.py saved apply|delete ID
hypr-settings.py saved wipe         # delete all saved profiles and tweaks files
```

The live entry is one of:

- `default`: no overrides, but it still remembers its own wallpaper, colors and bar in `tweaks/default-look.json`
- `variant:NAME`: `tweaks/<Style>-NAME.json`
- `saved:NAME`: `tweaks/saved/<Style>-<variant>/NAME.json`

Editing a Hyprland setting while on Default writes to the active variant's file and makes that live. The current entry is tracked in `hypr/state/saved.json`.

An entry can also carry a color theme, bar, bar style and wallpaper. Changing those from the picker or the scripts records them on the live entry. `sync` also writes which bar runs (`hypr/state/bar`), so a fresh install starts the bar the entry names.

The panel itself (`Modern/utilities/settings`) is a sheet from the left (`ALT+S`). `Store.qml` holds the state and batches writes to `hypr-settings.py`. Every page and option is in `Schema.js`, keyed by dotted paths into the tweaks file:

- `config.*`: `hl.config()` options, live values from `hyprctl getoption`
- `animation.*`, `border.*`, `cursor.*`, `boot.*`: read by `overrides.lua` / `startup.lua`

Adding an option is one line in `Schema.js`. 5+ choices turn into a dropdown. `when` hides a control unless another option has a value and `cap` hides it unless the hardware has it. Right-click resets a setting to the profile value.

## Theming

```
color-apply.sh [theme] [wallpaper]   # "pywal" (default) or a scheme from ~/.config/wal/colorschemes/
wallpaper-apply.sh                   # set wallpaper + regenerate theme
wallpaper-index.py                   # build the picker thumbnails/palettes
waybar-style.sh apply <name> | list
```

## Bars, utilities, OSD

```
bar.sh start | apply waybar|quickshell | style <name> | toggle | current
shells.sh start|stop|restart
shells.sh <utility> [call]           # home, launcher, music, wallpaper, settings
osd.sh vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down|caps|play|next|prev
```

All quickshell utilities run in one process (`shell.qml`), stay hidden and open over IPC. `boot` is the exception, `startup.lua` runs it alone. `ALT+a` toggles the bar.

Windows stay mapped with an empty input region while closed so they open instantly. Most of them take input over the whole screen while open so clicking outside closes them.

`common/` is shared by everything:

- `Theme`: pywal palette (`color9` accent, `color7` text), Hyprland's rounding and gaps, and its animation curve and speed so the utilities move like windows. The "default quickshell animations" setting gives them their own curve instead.
- `Hypr`: paths (`Hypr.util`, `Hypr.state`), which screen the cursor or focus is on, and dispatch.
- `Media`, `Audio`, `Brightness`, `Power`: player picking/skipping, default speaker and mic, screen brightness, session actions and battery.
- `Morph` is the grow-out-of-a-dot open/close, `Panel` adds the screen hop and keep-warm the launcher, music and settings share.
- `CavaFeed` runs cava on `common/cava.conf` with its own bar count (`Cava` for the bar and music, the lock's `Wave` runs its own).

- **launcher** (tap `Super`): Home dial (Home/Settings/Wallpaper pinned, the rest by use, logout/reboot/poweroff need a second press), app grid ranked by use, every bash command on a wheel (`.bashrc` aliases and functions too), and keybinds parsed from `shortcuts.lua`. A trailing `-- text` on a bind in `shortcuts.lua` is used as its description. `launcher.py` gives it the desktop entry info quickshell doesn't expose and keeps the usage counts.
- **home-screen** (`ALT+Tab`): also the notification daemon, so it's always running. Popups go bottom left and hide while the home screen is open. Other monitors get a dimmed wallpaper and a clock.
- **music** (`ALT+Enter`): card under the bar. Follows Spotify, else whatever is playing. Opening moves the mouse onto it, and it has the keyboard while the mouse is over it. Drag the bottom edge to resize, drag anywhere else to move, double-click to put it back. It publishes where it is so the launcher and bar can work around it.
- **wallpaper-picker** (`ALT+W`): previews the wallpaper full screen on every monitor and recolors both bars live. Waybar only watches `style.css`, so that gets rewritten in place. Thumbnails, screen-sized copies and palettes come from `wallpaper-index.py`, which reruns when the library changes.
- **profiles** (`Mod+P`): a small wheel on the right edge, one card per profile entry showing its wallpaper and a window with its blur, rounding, opacity, border and open animation, plus which bar it uses. Tab / Shift+Tab or scroll to pick, Enter or click to apply, Esc or clicking outside closes. The list comes from `hypr-settings.py saved preview` every time it opens.
- **overview** (`Super+Tab`): every workspace as a big tile with live windows, plus the special workspace and open scratchpads below. Drag windows between tiles (onto New to start a workspace, onto Special to stash it), × closes a window. The save icon keeps a workspace as a custom one (each window's launch command from `/proc`, and for terminals the folder and program the shell was running, via `bar/procs.sh`, plus position and size) in `~/.local/state/overview/workspaces.json` (saving the same apps again replaces the entry), and the trash icon closes everything on it. Saved workspaces are listed at the bottom: click one to reopen it on a new workspace (or drag it onto New or Special), floating windows land where they were and tiled ones open one at a time left to right so the layout splits the same way. Reuses `bar/Workspaces.qml`, and the bar's Overview button opens it over IPC.
- **osd**: `osd.sh` does the action and then shows it.
- Spotify always opens through `common/spotify.sh`: its pypr scratchpad if pypr is running, a normal window otherwise.

### Quickshell bar

`Modern/utilities/bar` is the other bar next to waybar. `bar.sh` picks which one runs. Modules go into up to three pills like waybar's left/center/right. Hovering a module grows its pill into a card with that module's page, and moving to another module on the same pill swaps the page without closing it.

- `Module.qml`: `user`, `workspaces`, `media`, `date`, `constdate`, `timer`, `clock`, `tray`, `updates`, `network`, `audio`, `battery`, `power`, and `|` for a divider. `media` and `updates` hide when empty.
- `Island.qml`: the media/clock page, tabs in `island/` for media, a focus timer, the color picker, capture and weather (wttr.in). The timer (`Countdown`) and weather (`Forecast`) live in the shell so every monitor shares them.
- `menus/`: network (`Wifi`, `WifiEditor`, `BluetoothList`), `Sound`, `Session` and `Tray`, plus the rows and fields they're built from. The nmcli work is in `net.sh`.
- `Workspaces.qml`: the dots, the workspace page, and the workspace data, tiles, drag proxy and saved workspaces the overview reuses. The page works like a small overview: drag windows between tiles, × closes a window, the save and trash icons by each name save or clear that workspace, and saved workspaces are listed below (click or drag onto New to open, trash to delete). Hyprland is only polled while something is showing. pypr scratchpads (by class from `pypr/config.toml`) are left off the tiles.

A style is `quickshellbar/<name>/config.json` (`hypr/state/bar-style` names the active one): `left`/`center`/`right` modules (only `center` gives one big pill), `strip` (a full-width strip the cards grow out of), `background`, `attached` (pills hang from the top edge), `height`, `gap` and `shape` (`round`, `capsule`, `square`).

The surface is one fixed size, tall enough for the biggest card, so it never resizes and redraws its blur. If a card would cover the music player, the player tucks away until it closes.

`InstallScripts/quickshellbarinstall.sh` and `waybarinstall.sh` install either bar on its own. The standalone quickshell bar reads `style.json` next to its `shell.qml` instead.

### Lock

`lock.sh` runs the style's `lock.qml` in its own process, not the shared one, so it still comes up if that one is down. It quits after unlocking. `lock.sh --preview` shows it in windows without locking.

It takes a frame of each monitor with grim first and fades from that into the blurred wallpaper. On unlock, handoff layers that were mapped under the lock the whole time take over the backdrop and fade into the desktop. Quickshell only loads files under the folder it started in, so `Lock.qml` has its own copy of the theme. Gear menu settings are saved in `~/.local/state`. It ships its own pam file so it doesn't need hyprlock's.

If it crashes the session stays locked. Switch to a tty and run `lock.sh` again.

## pypr

Upstream pypr dies when Hyprland drops its IPC socket during a reload. Two files deal with it:

- `pypr.py`: installed as `~/.local/bin/pypr`, patches the bug at runtime so `/usr/lib` stays untouched.
- `pypr.sh`: restarts the daemon if it dies anyway. It stops when Hyprland does.
