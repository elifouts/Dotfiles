# hypr

The technical docs for my setup. The [main readme](../../readme.md) covers installing and what everything looks like. This one covers how it works.

There are no comments in the code on purpose, I dont like writing comments. I had claude put together documentation for me

**Jump to:** [Big picture](#big-picture) · [Startup](#what-happens-at-login) · [How it works](#how-it-works) · [Where do I change...](#where-do-i-change) · [Confusing stuff](#confusing-stuff) · [Quirks](#quirks) · [Every file](#every-file)

## Big picture

Everything is three layers stacked on each other:

| Layer | What it is | Where it lives | Example |
|---|---|---|---|
| **Style** | the whole look, its own shell | `<Style>/` | `Modern`, `Space` |
| **Variant** | what changes per machine | `<Style>/<variant>/machine.lua` | `desktop`, `laptop` |
| **Tweaks** | settings panel changes on top | `<Style>/tweaks/` | `saved/desktop/Zen.json` |

And the folders split by who owns what:

```text
hyprland.lua, overrides.lua       the same no matter the style
session.lua, wal.lua
utilities/                        scripts any style can use
shared/                           qml and scripts both styles link in
Modern/  Space/                   the styles
state/                            what's live right now, gitignored
```

`~/.config/hypr` is a symlink to this folder. Nothing gets copied, so editing a file here is editing the live config.

## What happens at login

```text
hyprland.lua                 reads state/profile, sets package.path: variant, base, state, then loads
   ├─ machine.lua            monitors and defaults
   ├─ startup.lua            pulls in session.lua, Modern also starts the boot animation
   ├─ style.lua              look, curves, rules
   ├─ shortcuts.lua          style binds, pulls in binds.lua for the shared ones
   └─ overrides.lua          state/settings.lua wins over everything above

session.lua, on hyprland.start
└─ utilities/session/session.sh start
   ├─ session/shells.sh start   the one quickshell process
   └─ <Style>/base/session.sh
                             Modern: awww, bar.sh boot, pypr
                             Space:  pypr
```

## How it works

<details>
<summary><b>Config loading</b></summary>

The lua path goes variant, then base, then state. So a file in `desktop/` with the same name as one in `base/` replaces it.

`hyprctl reload` reruns everything from scratch, which is why switching styles leaves no old binds or rules behind.

The block at the top of `hyprland.lua` moves state out of the old `.active-*` files. It only runs if `.active-profile` still exists.

</details>

<details>
<summary><b>Switching styles and variants</b></summary>

`settings/hypr-profile.sh apply <style> <variant>` runs this:

1. `transition.sh begin` freezes the screen behind a blurred frame and a loading bar
2. `session.sh stop` kills the old shell, waybar and awww, in the background
3. writes `state/profile`
4. `hypr-settings.py sync` writes `state/settings.lua` and `state/bar`
5. `hyprctl reload`
6. `session.sh start` and `hypr-settings.py colors` run together, then the wallpaper
7. `transition.sh reveal` fades into the new style

A style counts if it has `base/style.lua`, `<variant>/machine.lua` and `utilities/`. It gets the transition for free, nothing in it knows about styles.

`transition.qml` runs as its own process because the shell it covers gets killed. It keeps the old bar's space with empty layers on the background level, which get arranged last so they don't push the new bar down. The old gaps stay through `$XDG_RUNTIME_DIR/style-transition.lua`, which `overrides.lua` reads. Both get released right as the fade starts, so windows resize during it.

Windows only resize during the fade when the new bar reserves less than the old one. A bigger bar pushes them as soon as it maps, there's no way to hold that back, so they move behind the frame.

Layer close animations stay off until the reveal. Hyprland draws a dead shell's closing panels above the overlay otherwise, sharp on top of the blur.

The bar runs on a timer, it doesn't track real steps. It waits at 90% until the reveal.

</details>

<details>
<summary><b>Settings and tweaks</b></summary>

```text
Settings panel → Store.qml → hypr-settings.py → <Style>/tweaks/*.json
                                              → state/settings.lua → overrides.lua
```

`Store.qml` shows changes right away and batches the writes. Profile files are never touched.

The live entry is tracked per Style/variant in `state/saved.json`:

| Entry | File | Means |
|---|---|---|
| `default` | `tweaks/default-look.json` | no overrides, only remembers wallpaper, colors, bar |
| `variant:NAME` | `tweaks/NAME.json` | the machine's own tweaks |
| `saved:NAME` | `tweaks/saved/<variant>/NAME.json` | a saved profile |

Changing a Hyprland setting while on Default moves you onto the variant entry.

Pages and options all live in `Schema.js`, keyed by dotted paths. `config.*` goes to `hl.config()`, and `animation.*`, `border.*`, `cursor.*`, `boot.*` are read by the lua.

Option fields: `when` hides it unless another option has a value, `cap` hides it unless the hardware has it.

</details>

<details>
<summary><b>Colors</b></summary>

```text
wallpaper-apply.sh → awww + color-apply.sh → wal → ~/.cache/wal/*
                                                 ├ hyprland   wal.lua
                                                 ├ quickshell ThemeBase.qml watches it
                                                 ├ waybar     colors-waybar.css
                                                 ├ kitty      current-theme.conf
                                                 ├ cava       rewrites ~/.config/cava/config
                                                 └ firefox    pywalfox update
```

In Space each profile keeps its color in `space.world`, with the finished palette so the switch doesn't need the shell to make it. `sync_world` writes it to `dark/space.json` and `~/.config/space/world.json`. A profile without one uses Default, which is gruvbox. Picking a color on Default moves you onto the variant entry. Hopping worlds or landing on a star doesn't touch the profile, so switching back brings its color back. Each star also keeps its own hue and landing on it applies that, so `sync_world` sets `restored` in `world.json` and `World.qml` repaints the current workspace's star to match.

`state/color-theme` is `pywal` or a scheme from `~/.config/wal/colorschemes/`. Role picks like the accent slot are saved per scheme, and per wallpaper on pywal.

Default slots: `color9` is the accent, `color7` is text.

</details>

<details>
<summary><b>The Modern shell</b></summary>

One quickshell process. `utilities/shell.qml` finds every `*/shell.qml` and loads it, so adding a folder adds a utility. `boot` and `lock` run alone, their main files are `BootShell.qml` and `LockShell.qml` so the search skips them.

Utilities stay loaded and hidden, then open over ipc. Windows stay mapped with an empty input region, which is why they open instantly.

```bash
shells.sh <utility> [call] [args]   # default call is toggle, starts the shell if it's down
```

| Utility | Key | Notes |
|---|---|---|
| launcher | tap `Super` | dial, apps, commands, keybinds |
| home-screen | `Alt+Tab` | Music, System stats, Notifications, Calendar |
| settings | `Alt+S` | sheet from the left |
| music | `Alt+Enter` | follows Spotify, else whatever's playing |
| wallpaper-picker | `Alt+W` | previews on every monitor |
| profiles | `Super+P` | list comes from `hypr-settings.py saved preview` |
| overview | `Super+Tab` | shares its tiles with the bar's workspace page |
| osd | media keys | `osd.sh` does the action, then shows it |
| welcome | first run | the tour |

</details>

<details>
<summary><b>The two bars</b></summary>

`state/bar` says which one runs, `bar.sh` handles it, `Alt+A` toggles it.

**Waybar:** a style is `<Style>/waybar/<name>/` with `config`, `style.css` and `preview.png`. `waybar-style.sh` copies it into `~/.config/waybar/`.

**Quickshell bar:** `Modern/utilities/bar`. Modules sit in up to three pills, hovering grows a pill into a card. A style is `quickshellbar/<name>/config.json`:

| Key | Does |
|---|---|
| `left` `center` `right` | module lists, only `center` gives one big pill |
| `strip` | full width strip the cards grow out of |
| `background` | draws the pill background |
| `attached` | pills hang from the top edge |
| `height` `gap` | sizes |
| `shape` | `round`, `capsule`, `square` |

Modules: `user` `workspaces` `media` `date` `constdate` `timer` `clock` `tray` `updates` `notifications` `network` `audio` `battery` `power`, and `|` for a divider.

`InstallScripts/quickshellbarinstall.sh` and `waybarinstall.sh` install either bar alone. The standalone quickshell bar reads `style.json` next to its `shell.qml`.

</details>

<details>
<summary><b>Lock</b></summary>

`lock.sh` runs `lock.qml` as its own process, so it still comes up if the shell is dead. It quits after unlocking and ships its own pam file.

Modern grabs a frame of each monitor with grim and fades from that into the blurred wallpaper. Handoff layers mapped under the lock take over on unlock.

`lock.sh --preview` shows it in windows without locking.

> [!WARNING]
> If it crashes, the session stays locked. Go to a tty and run `lock.sh` again.

</details>

<details>
<summary><b>Space</b></summary>

Same scripts, settings and color themes as Modern, none of the visuals. One process, `Space/utilities/shell.qml`. Each monitor gets the land and the bar, everything else is a `LazyLoader` thrown away when it closes.

| Part | Key | What it is |
|---|---|---|
| land | | the wallpaper is a shader, workspaces pan across it |
| world | `Alt+W` | new color and land from `World.qml`, not saved to the profile. `before` in `Land.qml` is a second terrain holding the old seed and colors. `hopProg` in `World.qml` drives every monitor: both pan together while a soft edge wipes the old one away and the moon comes back overhead. a press mid way only runs it to the end fast. the reload waits for it all to stop with `Ui.holdTheme` |
| star map | `Super+Tab` | workspaces and special workspaces with windows are stars, windows are planets, pypr scratchpads are moons |
| scan | `Alt+Tab` | visor with system info |
| launcher | tap `Super` | little terminal under the bar, `Tab` cycles apps, commands and a bare kitty prompt, `Shift+Enter` runs in the background instead of kitty |
| desk | `Alt+D` | widgets, layouts in `~/.config/space/layouts/` |
| settings | `Alt+S` | hud sheet that sizes to each tab, most pages come from the shared `Schema.js`, `LAYOUT` in Space's `Schema.js` sets their columns, right click resets an option |
| welcome | first run | the tour. the galaxy map opens, closes itself after takeoff and moves on once it has landed. goes to one empty workspace and back so it can't jump monitors |
| lock | `Super+L` | land dimmed behind a small hud |

Panels move on Hyprland's curves like Modern, through `Settle`, `Theme.leave` and `Theme.ms`. The star map's flights and the world hop keep their own timing, they're tied to the capture and terrain steps below. `hyprctl animations` reports `windowsIn` as `spring:easy` and a spring isn't a bezier, so `ThemeBase` falls back to `global`.

`Hud` text scrambles when it first shows and when it changes. Anything that ticks sets `decode: false`, like the timer, volume, sliders and seek times.

Star map cards show the color you'd land on in the corner: the preset's name, or the hex if it's random, in its accent. Planets get their own accent from the system's preset unless that preset has a pinned accent.

Star map keys: mouse aims, `wasd`, arrows or `hjkl` fly, `q` `e` turn, `shift` is fast, `tab` cycles your systems.

The windows falling away on launch are captures drawn in the star map, the real ones never move. They use `active_opacity` and `inactive_opacity` from `style.lua` as fixed numbers in `StarMap.qml`, so change both together. `fall` in `StarMap.qml` sets how fast they drop. Their blur is done in the star map too, `blurMax` on `frosted` is the strength.

On landing the captures come from the workspace you picked, not the one you left. Picking a pypr scratchpad moon runs `pypr toggle` and keeps that window on top.

Launch and landing stay smooth because the heavy work happens while nothing is moving:
- first frames and captures are prepared before the clock starts, that's `gate` in `StarMap.qml`
- a world's colors start when you pick it, `color-apply.sh` runs as its own process so apps recolor while they're hidden
- `Theme.frozen` holds the qml colors and `World.heldReload` holds the Hyprland reload until the camera has stopped and the terrain still covers everything, then the reveal waits a moment so no old colors show
- the bar and desk fade in as the terrain lifts, that's the last `veil` animation in `descend`
- stars get reused when the camera crosses cells instead of being rebuilt
- the camera updates once per finished frame, so it works at any refresh rate

**How the shaders work**

The land's colors go through `dither()` in `land.frag`, or the faint moon and sky band into shapes in 8-bit. `h3` is a `mod 289` hash because the old float one could give a cell's shared corner different values, which drew hard blocks on the moon. Don't use `uint` in these shaders, Qt loads a GLSL version here that doesn't have it.

The scenery has no images and there's no 3D engine. QML keeps the state and hands numbers and colors to the shaders, and a QML property reaches the shader when it has the same name as a uniform. Colors get mixed from the theme in `Terrain.qml`, so a new theme doesn't need a recompile. Editing a `.frag` does, see "I edited a shader and nothing happened".

- `land.frag` draws the sky, moon, planets, hills and trees in one pass. Switching workspaces only animates `pan`.
- Drawing all of that every frame is expensive, so `Land.qml` draws it once, stars included, and keeps the result. It only redraws when something like `pan` actually changes.
- `craters()` skips cells further than 0.83 away because a crater can't reach past that. That's the biggest radius times the 1.8 fade, so if you change either one change the number too.
- Only `Hypr.moonScreen` gets the moon, the other monitors are `moonless`.
- `starmap.frag` is only the backdrop, nebula and far stars worked out from where the camera is looking. Everything you can fly to is a normal QML item, and `project()` in `StarMap.qml` does the 3D math by hand to get its screen position and size.
- `common/orb.frag` is the small orb used by `Orb.qml`.

</details>

<details>
<summary><b>pypr</b></summary>

Upstream pypr dies when Hyprland drops its socket during a reload.

- `pypr.py` is installed as `~/.local/bin/pypr` and patches the bug at runtime, so `/usr/lib` stays untouched
- `pypr.sh` restarts it if it dies anyway, and stops when Hyprland does
- `pypr.sh` unsets `CLAUDE*`, if a Claude session starts it every scratchpad terminal inherits the session marker and Claude stops saving transcripts

> [!WARNING]
> Stopping pypr closes every scratchpad it opened, including a terminal and whatever is running in it. Switching to a style that doesn't use pypr does this too. Don't restart it from the dropterm.

</details>

<details>
<summary><b>Commands</b></summary>

All paths are from `~/.config/hypr/utilities/`.

```bash
settings/hypr-profile.sh apply <style> <variant> [--offline] | list

settings/hypr-settings.py state KEY...         # current values as json
settings/hypr-settings.py set KEY=JSON ...     # save and apply, null removes
settings/hypr-settings.py reset | sync | cursor | colors | appearance
settings/hypr-settings.py saved save NAME | apply ID | delete ID | preview | wipe

session/shells.sh start | stop | restart | <utility> [call]
session/osd.sh vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down|caps|play|next|prev
session/lock.sh [--preview]

bars/bar.sh start | boot | apply waybar|quickshell | style <name> | toggle | current
bars/waybar-style.sh apply <name> | list

colors/color-apply.sh [theme] [wallpaper]
wallpaper/wallpaper-apply.sh <image> [outputs]
wallpaper/wallpapers.sh install | pull | dev-pull | push
```

</details>

## Where do I change...

| I want to change | Go to |
|---|---|
| keybinds | `binds.lua` for both styles, `<Style>/base/shortcuts.lua` for one |
| monitors | `shared/machine/machine-<variant>.lua` |
| gaps, blur, curves, window rules | `<Style>/base/style.lua` |
| what runs at login | `session.lua`, `<Style>/base/session.sh` |
| idle timeouts | `hypridle.conf` |
| add a setting | one line in `shared/core/Schema.js`, both styles draw it. Space picks its pages in `Space/utilities/common/Schema.js` |
| add a Modern utility | new folder with a `shell.qml` and an `IpcHandler`, then a bind. if it has its own components, add `import "folder"` to `utilities/shell.qml` |
| add a bar module | `Modern/utilities/bar/Module.qml` |
| add a bar style | new folder in `quickshellbar/` or `waybar/` |
| add a color scheme | new json in `.config/wal/colorschemes/` |
| add a machine | new `machine-*.lua`, then link it as `<Style>/<variant>/machine.lua` |
| add a style | new folder with `base/`, `<variant>/`, `utilities/`, link what you need from `shared/` |

## Confusing stuff

<details>
<summary><b>"Profile" means two things</b></summary>

`state/profile` and `hypr-profile.sh` mean Style/variant. The settings panel and the profile wheel mean a saved tweak entry. Glass and Zen are the second kind.

</details>

<details>
<summary><b>Same name, different file</b></summary>

| Name | Which is which |
|---|---|
| `session` | `session.lua` is login, `utilities/session/session.sh` starts and stops a style, `base/session.sh` is that style's extras, `menus/Session.qml` is the power menu |
| `Theme` | `shared/core/ThemeBase.qml` is the real one, each `common/Theme.qml` extends it |
| `shell.qml` | one per utility, plus `utilities/shell.qml` which loads them |
| `Toggle`, `Card`, `Reveal` | each exists more than once, they're local to their folder |
| `stats.sh` | one file, linked as `home-stats.sh` and `scan/stats.sh` |

</details>

<details>
<summary><b>Why so many symlinks?</b></summary>

Quickshell won't import files outside the folder it started in. So shared qml lives in `shared/` and each style's `common/` links to it. Imports inside a linked file resolve from where the link is, so `Theme` in a shared file means that style's `Theme`.

It's also why `lock.qml` and `boot.qml` are tiny wrappers at the top of `utilities/`. They need to start from there to reach `common/`.

Edit the real file in `shared/`, not the link. It changes both styles.

The bar's wifi, bluetooth, sound, updates and notifications menus work like this too. What they do is in `shared/menus/`. What they look like is `Entry`, `Group`, `Header`, `Round`, `Chips`, `Slider`, `Switch` and `Tile`, each style has its own. Space's panels are links with a `Panel` name, `Wing.qml` tells them when they're open.

One folder link per style doesn't work, I tried. The shared singletons would have to import a folder that lists them, and Qt fails with `Audio is instantiated recursively`.

</details>

<details>
<summary><b>Why does Modern's shell.qml import folders it doesn't use?</b></summary>

Quickshell only registers a folder's components if it reaches that folder through an `import`, starting from the root file. Modern loads its utilities with `createComponent`, which it can't follow, so the imports at the top of `utilities/shell.qml` are how it finds them. Same for Space's `bar/panels`, those load through a `Loader`.

There are no `qmldir` files anymore, Quickshell makes them from these. A singleton just needs `pragma Singleton`.

</details>

<details>
<summary><b>Don't edit these, they get overwritten</b></summary>

| File | Written by | Edit instead |
|---|---|---|
| `~/.config/waybar/config`, `style.css` | `waybar-style.sh` | `<Style>/waybar/<name>/` |
| `state/settings.lua` | `hypr-settings.py` | tweaks json or the panel |
| `~/.config/kitty/current-theme.conf` | `color-apply.sh` | a color scheme |
| `~/.config/cava/config` | `color-apply.sh` | the heredoc in `color-apply.sh` |
| `wal/colorschemes/dark/space.json` | `World.qml` | the themes in `World.qml` |
| `Modern/utilities/overview/workspaces.json` | the overview | save from the overview |

</details>

<details>
<summary><b>I edited a shader and nothing happened</b></summary>

Qt runs the `.qsb`, not the `.frag`. Recompile it:

```bash
/usr/lib/qt6/bin/qsb --qt6 -o land.frag.qsb land.frag
```

</details>

<details>
<summary><b>Keybind descriptions</b></summary>

The launcher doesn't ask Hyprland. `Binds.js` reads `binds.lua` and Modern's `shortcuts.lua` as text, one line at a time, and `describe()` works out the label from the dispatcher.

So a bind has to fit on one line to show up, and that's why `binds.lua` spells out each one instead of looping. The order of the two files sets the order on the page. To name something new, add it in `describe()` or `SCRIPTS` in `Binds.js`.

</details>

<details>
<summary><b>Things that aren't where you'd think</b></summary>

- `notifications` is the notification host, so it's always running. Home isn't, so a notification can't depend on it
- Popups are bottom left and hide while the home screen is open
- Wallpapers live in `~/wallpapers/library`, only favorites are in this repo. The pre-commit hook copies them in from `favorites.txt`
- Spotify always opens through `spotify.sh`
- Lock keeps its gear menu settings in `~/.local/state`
- `hypr-settings.py` gets the boot and cursor defaults by asking the running Hyprland for `require("machine").defaults`, so changing what `machine.lua` returns can break it even though no lua file complains

</details>

## Quirks

Things that took me a while. Worth reading before "fixing" any of them.

<details>
<summary><b>Quickshell and Qt</b></summary>

- `Space` binds go through `shells.sh`, not `GlobalShortcut`. That crashed the shell on exit and it kept respawning on style switches
- `shells.sh stop` loops because a crash on exit gets respawned
- Never hide the launcher window. The icon textures drop and it stutters
- `Backdrop` and blur opacity never reach 0, Qt skips the first blur render otherwise.
- `Entry.qml` hardcodes its loop time. `Theme.ms` can hit 0 and a 0ms infinite loop maxes the cpu
- The bar surface is one fixed size, tall enough for the biggest card. Resizing it glitches and redraws the blur
- Lock surfaces are transparent, opaque ones get a low precision format and the blur bands
- Qt's js engine has no `Object.fromEntries`
- Qt drags can't leave their surface, so past the edge the monitor under the pointer takes over
- Bar visualizers use even pixel heights or they flicker
- Avoid looping `Behavior`s on hidden things. One never settled and redrew the 240hz screen nonstop at about 55W

</details>

<details>
<summary><b>Hyprland</b></summary>

- `Caps_Lock` is bound twice. Caps counts as a modifier once it's on, so the plain bind never fires
- Hyprland warps the cursor on every window move, so `keepCursor` puts it back
- Can't close the visible workspace, so the overview switches off it first
- Stop a window capture before closing the window or it errors
- `cm_auto_hdr = 0` stops fullscreen apps flipping the screen into hdr
- `spotify-launcher` forks so it never floats right without its window rule
- Blur `ignore_alpha` on the bar is half the pill opacity or the blur halos
- Mouse sensitivity is also set per device, per device beats global
- `focusedMonitor` can be stale at startup, so `Hypr.qml` asks for the cursor position

</details>

<details>
<summary><b>Performance</b></summary>

- The land is drawn once and kept, the stars are part of that one layer and don't twinkle. Looping the whole shader repainted every pixel at full refresh, and even redrawing only the stars made Hyprland redraw everything on top of them. Now the GPU goes back to idle when nothing is moving
- Vsync stays on unless the monitors have different refresh rates, that's `qs_sync` in `paths.sh`. With it off the shell drew around 280 fps on a 165hz screen and none of it lined up with the display. My desktop is 240 and 75, so it still runs without vsync
- `Pace.qml` watches frame times while the land, a hop, a launch or a landing is moving. Under about 40 fps it draws the terrain at lower resolution, down to half, and goes back up when frames are fast again. It only applies while moving, the land goes back to full resolution when it stops. A fast GPU never drops
- If everything is suddenly laggy on the laptop check the battery first. At 6% the GPU was capped to 30W instead of 125W and stuck around 500MHz, by 14% the cap was gone. `nvidia-smi -q -d POWER` shows the current limit
- One `Cava` for every visualizer, each monitor's bar used to spawn its own
- `Panel` frees textures after it's been closed a while
- Wifi scanning stops while typing and only runs while the menu is open
- Workspace data only polls Hyprland while something is showing

</details>

<details>
<summary><b>Everything else</b></summary>

- `WifiEditor` never reads the password back, and only touches the ip method if you changed it, or link-local gets wiped
- New wifi goes through nmcli because it says when the password is wrong
- Hyprland's capture includes the cursor even when asked not to, so the transition's frame has a copy baked in. The blur is what hides it
- `eap` in `net.sh` uses peap and mschapv2 because UC_Secure wants it
- `procs.sh` only counts a shell on a tty as a terminal, pywalfox spawns one without
- `tabs.py` decodes mozlz4 itself so I don't need `python-lz4`
- `pypr.sh` closes fd 9 for pypr, a slow dying one used to block the next supervisor
- `color-roles.sh` rewrites `style.css` onto itself because waybar only reloads when that file changes
- `MediaCtl` and `NowPlaying` handle Spotify's music videos, which play through its own chromium as `title • artist`
- `capture.sh` recordings are capped at 60fps because wf-recorder's default spreads the bits over 200+ frames a second on the 240Hz monitor. The bt709 tags are set by hand or colors shift in players
- `capture.sh` falls back to x264 when NVENC won't start. NVENC rejects tiny regions and doesn't exist without an NVIDIA card

</details>

## Every file

All 372 of them. `→` means it's a symlink, the real file is in that `shared/` folder.

<details>
<summary><b>hypr/ (root)</b></summary>

```text

├─ binds.lua      keybinds both styles share. the launcher parses this file too
├─ hypridle.conf  warn at 800s, lock at 1000s, screen off at 2400s
├─ hyprland.lua   entry point. reads state/profile, sets the lua path, loads machine, startup, style, shortcuts, overrides
├─ overrides.lua  applies state/settings.lua on top of the style, runs last
├─ readme.md      this file
├─ session.lua    login: env vars, cursor, portals, polkit, shell, hypridle
├─ wal.lua        pywal palette for lua: wal.hex, wal.accent, wal.color()
└─ xdph.conf      points the screen share portal at my picker (share.sh)
```

</details>

<details>
<summary><b>state/ (gitignored)</b></summary>

```text
state/
├─ bar                     waybar or quickshell
├─ bar-style               active quickshell bar style
├─ color-roles-saved.json  role picks remembered per theme and wallpaper
├─ color-roles.json        role picks (accent slot) for the current theme
├─ color-theme             pywal or a scheme name like dark/space
├─ profile                 active Style/variant, like Space/desktop
├─ saved.json              which tweak entry is live, per Style/variant
├─ settings.lua            generated. the live tweaks as a lua table
└─ todos.json              calendar todos, only exists once there are some
```

</details>

<details>
<summary><b>utilities/</b></summary>

```text
utilities/
├─ bars/
│  ├─ bar.sh                  picks and toggles waybar or the quickshell bar
│  └─ waybar-style.sh         copies a waybar style into ~/.config/waybar
├─ colors/
│  ├─ color-apply.sh          runs pywal, updates kitty, firefox, cava and borders
│  └─ color-roles.sh          remembers role picks, pokes waybar so it reloads css
├─ packages/
│  ├─ package-tui.py          the package manager tui
│  └─ package-tui.sh          launcher for the tui
├─ pypr/
│  ├─ pypr.py                 ~/.local/bin/pypr. patches pypr's socket bug at runtime
│  └─ pypr.sh                 restarts pypr if it dies, stops when hyprland does
├─ session/
│  ├─ lock.sh                 grabs monitor frames, runs lock.qml as its own process
│  ├─ osd.sh                  brightness and volume keys, then shows the osd
│  ├─ session.sh              start or stop a style's shell and daemons
│  ├─ shells.sh               start, stop or call the quickshell process over ipc
│  ├─ transition.qml          blurred frame and loading bar that hide a style switch
│  └─ transition.sh           starts it, holds the old layout, then reveals
├─ settings/
│  ├─ hypr-profile.sh         switch or list Style/variant
│  └─ hypr-settings.py        settings backend: tweaks, saved entries, settings.lua
├─ wallpaper/
│  ├─ wallpaper-apply.sh      sets the wallpaper, then recolors everything
│  ├─ wallpaper-fav.sh        toggles a wallpaper in favorites.txt
│  ├─ wallpaper-fix-names.py  renames files to <prefix>-NN.<ext>, has --dry-run
│  ├─ wallpaper-index.py      builds thumbs, screen copies and palettes for the picker
│  └─ wallpapers.sh           git wrapper for the wallpaper library repo
├─ launcher.py                desktop entries, commands and usage counts, both launchers use it
└─ paths.sh                   sourced by scripts. sets $HYPR $UTIL $STYLE $QS from state/profile, qs_sync picks vsync
```

</details>

<details>
<summary><b>shared/</b></summary>

```text
shared/
├─ capture/
│  ├─ capture.sh              screenshots and recordings by region, window or screen
│  ├─ cast.py                 casts to tvs: chromecast, dlna, miracast
│  └─ share.sh                xdph's custom picker, hands off to the capture menu
├─ core/
│  ├─ Hypr.qml                paths, which screen has focus or the cursor, dispatch
│  ├─ Motion.js               animation presets and curves for both settings pages
│  ├─ Schema.js               every settings page and option, one line per setting
│  ├─ Store.qml               settings state, batches writes to hypr-settings.py
│  ├─ ThemeBase.qml           palette, rounding, gaps, timing. each Theme.qml extends this
│  └─ Watched.qml             FileView that rereads when the file changes
├─ machine/
│  ├─ machine-desktop.lua     desktop monitors, boot and cursor defaults
│  └─ machine-laptop.lua      laptop monitors, boot and cursor defaults
├─ menus/
│  ├─ BluetoothList.qml       bluetooth devices and their rows, pair and connect
│  ├─ Card.qml                Tile with padding for menu content
│  ├─ Network.qml             wifi and bluetooth side by side
│  ├─ Notifications.qml       notification history, dnd and clear
│  ├─ Oops.qml                inline error text
│  ├─ Sound.qml               speakers, mics, volume rows and device picking
│  ├─ Toggle.qml              label and switch row
│  ├─ UpdateMenu.qml          pending updates, update now or check again
│  ├─ Wifi.qml                wifi list and connect
│  └─ WifiEditor.qml          edit a saved connection: ip, dns, security, with its fields
├─ media/
│  ├─ Audio.qml               default speaker and mic, volume and mute
│  ├─ cava.conf               base cava config, CavaFeed swaps in bars and framerate
│  ├─ Cava.qml                one cava feed for every visualizer
│  ├─ CavaFeed.qml            runs cava with its own bar count
│  ├─ Cover.qml               album art that slides the way you skipped
│  ├─ Media.qml               picks the player, skip and play controls
│  ├─ MiniWave.qml            small bar visualizer
│  ├─ NowPlaying.qml          track info, covers spotify's blank music videos
│  ├─ PlayButton.qml          accent circle with the play/pause morph
│  ├─ PlayPause.qml           shape that morphs between play and pause
│  ├─ Seek.qml                smooth progress bar
│  ├─ SkipButton.qml          prev/next that kicks when it skips
│  └─ spotify.sh              opens spotify's scratchpad, or a normal window without pypr
├─ system/
│  ├─ pam/
│  │  └─ password.conf        the lock's pam file, so it doesn't need hyprlock's
│  ├─ Brightness.qml          screen brightness state
│  ├─ NotificationCard.qml    one notification card
│  ├─ NotificationPopups.qml  popups, bottom left
│  ├─ Notifs.qml              the notification daemon, keeps history and dnd
│  ├─ Osd.qml                 osd pill and media card
│  ├─ OsdState.qml            what the osd does, caps lock tracking
│  ├─ net.sh                  nmcli calls for the wifi menus
│  ├─ Power.qml               session actions and battery
│  ├─ stats.sh                system info from /proc and /sys, read by home and scan
│  └─ Updates.qml             pending pacman and aur count, every 30 min
├─ ui/
│  ├─ CurvePlot.qml           draggable bezier graph
│  ├─ Fade.qml                one island tab, fades and rises in when on
│  ├─ Hover.qml               MouseArea with hover and the hand cursor
│  ├─ IconButton.qml          clickable icon that lights up on hover
│  ├─ Label.qml               Text in the theme font and color
│  ├─ Morph.qml               the grow out of a dot open and close
│  ├─ SettingBezier.qml       full curve editor with preview and randomize
│  ├─ Settle.qml              NumberAnimation on hyprland's window curve
│  ├─ SwapText.qml            text that slides out and types back in
│  └─ Tour.qml                first run tour, each style gives it steps and spots
└─ widgets/
   ├─ Calendar.qml            calendar and todo list
   ├─ CaptureTab.qml          screenshot, record, cast and share tab
   ├─ ColorTab.qml            color picker tab, shares waybar's history
   ├─ Countdown.qml           focus timer logic, lives in the shell
   ├─ Forecast.qml            wttr.in weather data, refreshes every 30 min
   ├─ TimerTab.qml            drag ring timer ui
   ├─ Todos.qml               todo storage in state/todos.json
   └─ WeatherTab.qml          weather tab with graph
```

</details>

<details>
<summary><b>Modern/ config</b></summary>

```text
Modern/
├─ base/
│  ├─ session.sh          awww, the bar and pypr. runs after the shell starts
│  ├─ shortcuts.lua       Modern's keybinds. the launcher parses this file too
│  ├─ startup.lua         runs the boot animation
│  └─ style.lua           hyprland look: gaps, blur, curves, window and layer rules
├─ desktop/
│  └─ machine.lua         → machine: desktop monitors, boot and cursor defaults
├─ laptop/
│  └─ machine.lua         → machine: laptop monitors, boot and cursor defaults
├─ quickshellbar/
│  ├─ attached/
│  │  ├─ config.json      pills hang from the top edge
│  │  └─ preview.svg      preview for the settings page
│  ├─ default/
│  │  ├─ config.json      three floating pills
│  │  └─ preview.svg      preview for the settings page
│  ├─ experimental/
│  │  ├─ config.json      one big attached center pill
│  │  └─ preview.svg      preview for the settings page
│  ├─ full/
│  │  ├─ config.json      full width strip, no background, 24px tall
│  │  └─ preview.svg      preview for the settings page
│  └─ zen/
│     ├─ config.json      one small pill: workspaces, date, clock
│     └─ preview.svg      preview for the settings page
├─ tweaks/
│  ├─ saved/
│  │  ├─ desktop/
│  │  │  ├─ Gruvbox.json  saved profile, desktop
│  │  │  └─ Zen.json      saved profile, desktop
│  │  └─ laptop/
│  │     ├─ Gruvbox.json  saved profile, laptop
│  │     ├─ Snappy.json   saved profile, laptop
│  │     └─ Zen.json      saved profile, laptop
│  └─ default-look.json   wallpaper, colors and bar that Default remembers
└─ waybar/
   ├─ default/
   │  ├─ config           modules for the default pill bar
   │  ├─ preview.png      preview for the settings page
   │  └─ style.css        css for default
   ├─ experimental/
   │  ├─ config           modules for the experimental pill bar, hover effects
   │  ├─ preview.png      preview for the settings page
   │  └─ style.css        css for experimental
   ├─ line/
   │  ├─ config           modules for the line line bar
   │  ├─ preview.png      preview for the settings page
   │  └─ style.css        css for line
   └─ zen/
      ├─ config           modules for the zen minimal bar
      ├─ preview.png      preview for the settings page
      └─ style.css        css for zen
```

</details>

<details>
<summary><b>Modern/utilities/bar/</b></summary>

```text
Modern/utilities/bar/
├─ island/
│  ├─ Countdown.qml      → widgets: focus timer logic, lives in the shell
│  ├─ Forecast.qml       → widgets: wttr.in weather data, refreshes every 30 min
│  └─ MediaTab.qml       island's media tab, with its button and empty state
├─ menus/
│  ├─ BluetoothList.qml  → menus: bluetooth devices and their rows, pair and connect
│  ├─ Card.qml           → menus: Tile with padding for menu content
│  ├─ Chips.qml          row of pickable chips
│  ├─ Entry.qml          menu row base, wiggles while connecting
│  ├─ Group.qml          titled group, clips rows to its corners
│  ├─ Header.qml         card header with title and icon
│  ├─ Network.qml        → menus: wifi and bluetooth side by side
│  ├─ Notifications.qml  → menus: notification history, dnd and clear
│  ├─ Oops.qml           → menus: inline error text
│  ├─ Round.qml          small round icon button
│  ├─ Session.qml        power menu, the scary ones need a second press
│  ├─ Sound.qml          → menus: speakers, mics, volume rows and device picking
│  ├─ Toggle.qml         → menus: label and switch row
│  ├─ Tray.qml           system tray with its menus
│  ├─ UpdateMenu.qml     → menus: pending updates, update now or check again
│  ├─ Wifi.qml           → menus: wifi list and connect
│  └─ WifiEditor.qml     → menus: edit a saved connection: ip, dns, security, with its fields
├─ alarm.ogg             the alarm sound
├─ Alarm.qml             rings out of the bar when the focus timer ends
├─ Island.qml            the media and clock card with its tabs
├─ Module.qml            every bar module in one file
├─ net.sh                → system: nmcli calls for the wifi menus
├─ Pill.qml              one pill. grows into a card on hover
├─ procs.sh              per pid: cmdline, cwd and running program, for saving workspaces
├─ shell.qml             bar windows per monitor, `bar` ipc, picks the style
├─ tabs.py               reads firefox's session store for tab urls
└─ Workspaces.qml        dots, workspace page, tile and saved workspace data
```

</details>

<details>
<summary><b>Modern/utilities/common/</b></summary>

```text
Modern/utilities/common/
├─ Audio.qml               → media: default speaker and mic, volume and mute
├─ Backdrop.qml            blurred dark wallpaper behind home, overview and lock
├─ Brightness.qml          → system: screen brightness state
├─ Button.qml              text button
├─ Calendar.qml            → widgets: calendar and todo list
├─ CaptureTab.qml          → widgets: screenshot, record, cast and share tab
├─ cava.conf               → media: base cava config, CavaFeed swaps in bars and framerate
├─ Cava.qml                → media: one cava feed for every visualizer
├─ CavaFeed.qml            → media: runs cava with its own bar count
├─ ColorTab.qml            → widgets: color picker tab, shares waybar's history
├─ Cover.qml               → media: album art that slides the way you skipped
├─ Fade.qml                → ui: one island tab, fades and rises in when on
├─ Field.qml               text input
├─ Hover.qml               → ui: MouseArea with hover and the hand cursor
├─ Hypr.qml                → core: paths, which screen has focus or the cursor, dispatch
├─ IconButton.qml          → ui: clickable icon that lights up on hover
├─ Label.qml               → ui: Text in the theme font and color
├─ Media.qml               → media: picks the player, skip and play controls
├─ MediaView.qml           tells the osd a media screen is up
├─ MiniWave.qml            → media: small bar visualizer
├─ Morph.qml               → ui: the grow out of a dot open and close
├─ NotificationCard.qml    → system: one notification card
├─ NotificationPopups.qml  → system: popups, bottom left
├─ Notifs.qml              → system: the notification daemon, keeps history and dnd
├─ NowPlaying.qml          → media: track info, covers spotify's blank music videos
├─ Osd.qml                 → system: osd pill and media card
├─ OsdState.qml            → system: what the osd does, caps lock tracking
├─ Panel.qml               Morph plus screen hop and keep warm
├─ PlayButton.qml          → media: accent circle with the play/pause morph
├─ PlayPause.qml           → media: shape that morphs between play and pause
├─ Pop.qml                 quick bounce on a rename
├─ Say.qml                 the tour's text, plain in Modern
├─ Power.qml               → system: session actions and battery
├─ Rise.qml                staggered fade and pop in
├─ Seek.qml                → media: smooth progress bar
├─ Settle.qml              → ui: NumberAnimation on hyprland's window curve
├─ SkipButton.qml          → media: prev/next that kicks when it skips
├─ Slider.qml              slider
├─ spotify.sh              → media: opens spotify's scratchpad, or a normal window without pypr
├─ SwapText.qml            → ui: text that slides out and types back in
├─ Switch.qml              toggle that stretches when it flips
├─ Tabs.qml                icon tabs with a sliding accent pill
├─ Theme.qml               Modern's theme, just ThemeBase
├─ ThemeBase.qml           → core: palette, rounding, gaps, timing. each Theme.qml extends this
├─ Tile.qml                the faint panel behind menu rows
├─ Tour.qml                → ui: first run tour, each style gives it steps and spots
├─ TimerTab.qml            → widgets: drag ring timer ui
├─ Todos.qml               → widgets: todo storage in state/todos.json
├─ Updates.qml             → system: pending pacman and aur count, every 30 min
├─ Watched.qml             → core: FileView that rereads when the file changes
└─ WeatherTab.qml          → widgets: weather tab with graph
```

</details>

<details>
<summary><b>Modern/utilities/ everything else</b></summary>

```text
Modern/utilities/
├─ boot/
│  └─ BootShell.qml          boot animation, runs alone
├─ home-screen/
│  ├─ Home.qml               home screen. clock, music, stats, notifications
│  ├─ home-stats.sh          → system: system info from /proc and /sys, read by home and scan
│  ├─ home-wall.sh           prints a screen sized wallpaper copy per monitor
│  └─ shell.qml              loads Home when it opens, drops it when it closes
├─ launcher/
│  ├─ AppGrid.qml            app grid
│  ├─ Binds.js               parses binds.lua and shortcuts.lua into keybind rows
│  ├─ HomePage.qml           the home dial
│  ├─ KeybindsPage.qml       keybind list
│  ├─ Radial.qml             the dial wheel
│  ├─ SearchPill.qml         search box
│  ├─ shell.qml              launcher window, tabs, search and ranking
│  ├─ ShellPage.qml          command runner
│  └─ VWheel.qml             vertical wheel for commands
├─ lock/
│  ├─ Face.qml               what you see on one monitor, with its digits, buttons and wave
│  ├─ Lock.qml               lock state, pam, gear menu settings
│  ├─ LockShell.qml          lock session and monitor surfaces
│  └─ Toggle.qml             gear menu switch
├─ music/
│  ├─ shell.qml              music card. move, resize, tuck away
│  └─ Visualizer.qml         cava bars for the card
├─ notifications/
│  └─ shell.qml              the always on part: daemon, popups, dnd and clear calls
├─ osd/
│  └─ shell.qml              `osd` ipc, the real osd is shared/system/Osd.qml
├─ overview/
│  ├─ shell.qml              big workspace overview, tiles come from bar/Workspaces.qml
│  └─ workspaces.json        my saved workspaces. tracked so git syncs them
├─ profiles/
│  └─ shell.qml              profile wheel on the right edge
├─ settings/
│  ├─ CurvePlot.qml          → ui: draggable bezier graph
│  ├─ Dropdown.qml           dropdown control
│  ├─ Motion.js              → core: animation presets and curves for both settings pages
│  ├─ Schema.js              → core: every settings page and option, one line per setting
│  ├─ Segmented.qml          segmented control
│  ├─ SettingAnimpreset.qml  animation preset picker
│  ├─ SettingBar.qml         waybar or quickshell picker
│  ├─ SettingBezier.qml      → ui: full curve editor with preview and randomize
│  ├─ SettingChoice.qml      choice control tied to a key, pills under 5 options, dropdown otherwise
│  ├─ SettingColor.qml       color control with swatches and alpha
│  ├─ SettingCursors.qml     cursor theme picker
│  ├─ SettingProfile.qml     style and variant picker
│  ├─ SettingSaved.qml       save, apply, delete and wipe profiles
│  ├─ SettingSlider.qml      slider control tied to a key
│  ├─ SettingToggle.qml      switch control tied to a key
│  ├─ SettingWaybar.qml      bar style picker with preview
│  ├─ shell.qml              settings sheet window
│  ├─ Store.qml              → core: settings state, batches writes to hypr-settings.py
│  └─ Themes.qml             colors page, the fake terminal
├─ wallpaper-picker/
│  ├─ blur.frag              blur shader source
│  ├─ blur.frag.qsb          compiled blur shader, this is what runs
│  └─ shell.qml              full screen wallpaper picker
├─ welcome/
│  └─ shell.qml              Modern's tour steps
├─ boot.qml                  wrapper so boot can reach common/
├─ lock.qml                  wrapper so lock can reach common/
└─ shell.qml                 the shell. loads every */shell.qml
```

</details>

<details>
<summary><b>Space/ config</b></summary>

```text
Space/
├─ base/
│  ├─ session.sh         just pypr, the shell does the rest
│  ├─ shortcuts.lua      Space's keybinds, most go through `shells.sh space toggle`
│  ├─ startup.lua        only pulls in session.lua
│  └─ style.lua          hyprland look for the hud
├─ desktop/
│  └─ machine.lua        → machine: desktop monitors, boot and cursor defaults
├─ laptop/
│  └─ machine.lua        → machine: laptop monitors, boot and cursor defaults
└─ tweaks/
   ├─ saved/
   │  └─ desktop/
   │     └─ Space.json   saved profile, desktop
   ├─ default-look.json  what Default remembers
   └─ desktop.json       live tweaks for the desktop variant
```

</details>

<details>
<summary><b>Space/utilities/common/</b></summary>

```text
Space/utilities/common/
├─ Audio.qml               → media: default speaker and mic, volume and mute
├─ Brightness.qml          → system: screen brightness state
├─ Button.qml              Modern's Button api, drawn the space way
├─ Calendar.qml            → widgets: calendar and todo list
├─ CaptureTab.qml          → widgets: screenshot, record, cast and share tab
├─ cava.conf               → media: base cava config, CavaFeed swaps in bars and framerate
├─ Cava.qml                → media: one cava feed for every visualizer
├─ CavaFeed.qml            → media: runs cava with its own bar count
├─ ColorTab.qml            → widgets: color picker tab, shares waybar's history
├─ Countdown.qml           → widgets: focus timer logic, lives in the shell
├─ Cover.qml               → media: album art that slides the way you skipped
├─ decode.js               the text scramble effect
├─ Fade.qml                → ui: one island tab, fades and rises in when on
├─ Field.qml               Modern's Field api, space look
├─ Forecast.qml            → widgets: wttr.in weather data, refreshes every 30 min
├─ Hover.qml               → ui: MouseArea with hover and the hand cursor
├─ Hud.qml                 the one text style, decodes on change
├─ Hypr.qml                → core: paths, which screen has focus or the cursor, dispatch
├─ IconButton.qml          → ui: clickable icon that lights up on hover
├─ Kit.qml                 small hud controls every panel uses
├─ Label.qml               → ui: Text in the theme font and color
├─ Live.qml                one timer and forecast for every monitor
├─ Media.qml               → media: picks the player, skip and play controls
├─ MediaCtl.qml            now playing for the bar panel, scan and the desk
├─ MiniWave.qml            → media: small bar visualizer
├─ Morph.qml               → ui: the grow out of a dot open and close
├─ Motion.js               → core: animation presets and curves for both settings pages
├─ NotificationCard.qml    → system: one notification card
├─ NotificationPopups.qml  → system: popups, bottom left
├─ Notifs.qml              → system: the notification daemon, keeps history and dnd
├─ NowPlaying.qml          → media: track info, covers spotify's blank music videos
├─ orb.frag                ball of light shader
├─ orb.frag.qsb            compiled, this is what runs
├─ Orb.qml                 glowing ball, bar dots and stars
├─ Osd.qml                 → system: osd pill and media card
├─ OsdState.qml            → system: what the osd does, caps lock tracking
├─ Pace.qml                lowers the terrain's resolution while moving if frames get slow
├─ PlayButton.qml          → media: accent circle with the play/pause morph
├─ PlayPause.qml           → media: shape that morphs between play and pause
├─ Power.qml               → system: session actions and battery
├─ Say.qml                 the tour's text, scrambles in Space
├─ Schema.js               which shared pages Space shows, plus its own keys
├─ SchemaBase.js           → core: every settings page and option, one line per setting
├─ Seek.qml                → media: smooth progress bar
├─ Settle.qml              → ui: NumberAnimation on hyprland's window curve
├─ SkipButton.qml          → media: prev/next that kicks when it skips
├─ Slider.qml              segmented slider, Kit.Slide uses it too
├─ spotify.sh              → media: opens spotify's scratchpad, or a normal window without pypr
├─ Store.qml               → core: settings state, batches writes to hypr-settings.py
├─ SwapText.qml            → ui: text that slides out and types back in
├─ Switch.qml              Kit toggle for the shared menus
├─ Sys.qml                 cpu, ram and link from /proc, no processes
├─ Theme.qml               ThemeBase, square, Space's font, accent outlines
├─ ThemeBase.qml           → core: palette, rounding, gaps, timing. each Theme.qml extends this
├─ Tile.qml                outlined panel behind menu rows
├─ TimerTab.qml            → widgets: drag ring timer ui
├─ Todos.qml               → widgets: todo storage in state/todos.json
├─ Tour.qml                → ui: first run tour, each style gives it steps and spots
├─ Ui.qml                  what's open, so windows can react to each other
├─ Updates.qml             → system: pending pacman and aur count, every 30 min
├─ Watched.qml             → core: FileView that rereads when the file changes
├─ WeatherTab.qml          → widgets: weather tab with graph
└─ World.qml               planet hue, seeds, star positions, writes space.json
```

</details>

<details>
<summary><b>Space/utilities/ everything else</b></summary>

```text
Space/utilities/
├─ bar/
│  ├─ Bar.qml            bar window, two wings and input regions
│  ├─ panels/
│  │  ├─ BluetoothList.qml → menus: bluetooth devices and their rows, pair and connect
│  │  ├─ Card.qml          → menus: Tile with padding for menu content
│  │  ├─ Chips.qml         row of pickable chips, made of Buttons
│  │  ├─ Entry.qml         menu row, a Kit line with a gear
│  │  ├─ Group.qml         titled group of rows that scrolls
│  │  ├─ Header.qml        Kit title for the shared menus
│  │  ├─ Oops.qml          → menus: inline error text
│  │  ├─ PanelAudio.qml    → menus: Sound.qml
│  │  ├─ PanelMedia.qml    shared island tabs under the media chip
│  │  ├─ PanelNet.qml      → menus: Network.qml
│  │  ├─ PanelNotifs.qml   → menus: Notifications.qml
│  │  ├─ PanelPower.qml    battery, brightness and session
│  │  ├─ PanelTime.qml     big clock, calendar and todos
│  │  ├─ PanelTray.qml     tray apps as lines
│  │  ├─ PanelUpdates.qml  → menus: UpdateMenu.qml
│  │  ├─ Round.qml         small Button with a glyph
│  │  ├─ Toggle.qml        → menus: label and switch row
│  │  ├─ Wifi.qml          → menus: wifi list and connect
│  │  └─ WifiEditor.qml    → menus: edit a saved connection: ip, dns, security, with its fields
│  ├─ Chip.qml           readout that opens a panel
│  ├─ net.sh             → system: nmcli calls for the wifi menus
│  ├─ Stars.qml          workspace dots as orbs
│  └─ Wing.qml           glass wing with corner brackets, loads Panel<kind>.qml
├─ desk/
│  ├─ Desk.qml           desktop widgets with snapping
│  ├─ DeskEdit.qml       edit mode overlay
│  ├─ DeskModel.qml      one monitor's widgets, saved per monitor shape
│  ├─ Editor.qml         strip for adding and tweaking widgets
│  └─ Widget.qml         one widget
├─ land/
│  ├─ land.frag          sky, moon, hills and pines. no image files
│  ├─ land.frag.qsb      compiled, this is what runs
│  ├─ Land.qml           one monitor's wallpaper window, pans with workspaces
│  └─ Terrain.qml        the land shader with theme colors
├─ launcher/
│  └─ Launcher.qml       little terminal under the bar
├─ scan/
│  ├─ Scan.qml           alt tab visor with system readouts
│  └─ stats.sh           → system: system info from /proc and /sys, read by home and scan
├─ settings/
│  ├─ CurvePlot.qml      → ui: draggable bezier graph
│  ├─ Motion.js          → core: animation presets and curves for both settings pages
│  ├─ SettingBezier.qml  → ui: full curve editor with preview and randomize
│  └─ Settings.qml       hud settings sheet from the bottom
├─ starmap/
│  ├─ glow.png           star glow sprite
│  ├─ starmap.frag       far sky shader
│  ├─ starmap.frag.qsb   compiled, this is what runs
│  └─ StarMap.qml        3d star map. workspaces are stars, windows are planets
├─ welcome/
│  └─ Welcome.qml        Space's tour steps
├─ lock.qml              lock and its screen, own process with the land behind it
└─ shell.qml             the whole shell. overlays load lazily and drop on close
```

</details>

## Outside hypr/

| Path | What it is |
|---|---|
| `InstallScripts/` | `install.sh` is the menu, `apply.sh` relinks after a pull, `common.sh` is shared helpers, plus each install and uninstall path |
| `.githooks/pre-commit` | syncs favorite wallpapers into `wallpapers/library`. The installer sets `core.hooksPath` |
| `.config/waybar/` | the live waybar config, see overwritten files above. `scripts/` is the color picker and toggle |
| `.config/wal/` | color schemes and pywal templates |
| `.config/pypr/config.toml` | scratchpads, the bar reads classes from here too |
| `.config/kitty/` `nvim/` `starship.toml` `clock-rs/` | app configs |
| `.bashrc` | aliases and functions, the launcher lists these too |
| `wallpapers/library/` | favorite wallpapers and `favorites.txt` |
| `archive/` | retired configs, nothing here runs |
