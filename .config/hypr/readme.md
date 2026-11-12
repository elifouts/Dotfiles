# hypr

The technical docs for my setup. The [main readme](../../readme.md) covers installing and what everything looks like. This one covers how it works.

There are no comments in the code on purpose, I dont like writing comments. I had claude put together documentation for me

**Jump to:** [Big picture](#big-picture) · [Startup](#what-happens-at-login) · [How it works](#how-it-works) · [Where do I change...](#where-do-i-change) · [Confusing stuff](#confusing-stuff) · [Quirks](#quirks) · [Every file](#every-file)

## Big picture

Everything is three layers stacked on each other:

| Layer | What it is | Where it lives | Example |
|---|---|---|---|
| **Style** | the whole look, its own shell | `<Style>/` | `Modern`, `Space` |
| **Variant** | what changes per machine | `machine/<variant>.lua` | `desktop`, `laptop` |
| **Tweaks** | settings panel changes on top | `<Style>/tweaks/` | `saved/desktop/Zen.json` |

And the folders split by who owns what:

```text
hyprland.lua, overrides.lua       the same no matter the style
session.lua, wal.lua
machine/                          monitors and defaults per machine
utilities/                        scripts any style can use
quickshell/                       the shell, one folder per style plus shared/
Modern/  Space/                   each style's hyprland config, bars and tweaks
state/                            what's live right now, gitignored
```

`~/.config/hypr` is a symlink to this folder. Nothing gets copied, so editing a file here is editing the live config.

## What happens at login

```text
hyprland.lua                 reads state/profile, points quickshell/style at the style, sets package.path: base, state, then loads
   ├─ machine/<variant>.lua  monitors and defaults
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

The lua path goes base, then state. The variant is loaded by name from `machine/` and kept as `require("machine")`.

`hyprctl reload` reruns everything from scratch, which is why switching styles leaves no old binds or rules behind.

The block at the top of `hyprland.lua` moves state out of the old `.active-*` files. It only runs if `.active-profile` still exists.

</details>

<details>
<summary><b>Switching styles and variants</b></summary>

`settings/hypr-profile.sh apply <style> <variant>` runs this:

1. `transition.sh begin` freezes the screen behind a blurred frame and a loading bar
2. `session.sh stop` kills the old shell, waybar and awww, in the background
3. writes `state/profile` and points `quickshell/style` at the new style
4. `hypr-settings.py sync` writes `state/settings.lua` and `state/bar`
5. waits for the old shell to die, then `hyprctl reload`. Both styles run from the same path, so a new shell started early would see the old one and quit
6. `session.sh start` and `hypr-settings.py colors` run together, then the wallpaper
7. `transition.sh reveal` fades into the new style

A style counts if it has `<Style>/base/style.lua` and `quickshell/<Style>/`. Variants are whatever is in `machine/`. It gets the transition for free, nothing in it knows about styles.

`TransitionShared.qml` runs as its own process because the shell it covers gets killed. It keeps the old bar's space with empty layers on the background level, which get arranged last so they don't push the new bar down. The old gaps stay through `$XDG_RUNTIME_DIR/style-transition.lua`, which `overrides.lua` reads. Both get released right as the fade starts, so windows resize during it.

Windows only resize during the fade when the new bar reserves less than the old one. A bigger bar pushes them as soon as it maps, there's no way to hold that back, so they move behind the frame.

Layer close animations stay off until the reveal. Hyprland draws a dead shell's closing panels above the overlay otherwise, sharp on top of the blur.

The bar runs on a timer, it doesn't track real steps. It waits at 90% until the reveal.

</details>

<details>
<summary><b>Settings and tweaks</b></summary>

```text
Settings panel → StoreShared.qml → hypr-settings.py → <Style>/tweaks/*.json
                                              → state/settings.lua → overrides.lua
```

`StoreShared.qml` shows changes right away and batches the writes. Profile files are never touched.

The live entry is tracked per Style/variant in `state/saved.json`:

| Entry | File | Means |
|---|---|---|
| `default` | `tweaks/default-look.json` | no overrides, only remembers wallpaper, colors, bar |
| `variant:NAME` | `tweaks/NAME.json` | the machine's own tweaks |
| `saved:NAME` | `tweaks/saved/<variant>/NAME.json` | a saved profile |

Changing a Hyprland setting while on Default moves you onto the variant entry.

Pages and options all live in `SchemaShared.js`, keyed by dotted paths. `config.*` goes to `hl.config()`, and `animation.*`, `border.*`, `cursor.*`, `boot.*` are read by the lua.

Option fields: `when` hides it unless another option has a value, `cap` hides it unless the hardware has it.

</details>

<details>
<summary><b>Colors</b></summary>

```text
wallpaper-apply.sh → awww + color-apply.sh → wal → ~/.cache/wal/*
                                                 ├ hyprland   wal.lua
                                                 ├ quickshell ThemeBaseShared.qml watches it
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

One quickshell process. `quickshell/Modern/Shell.qml` finds every `*/shell.qml` and loads it, so adding a folder adds a utility. `boot` and `lock` run alone, their main files are `BootShell.qml` and `LockShell.qml` so the search skips them.

Utilities stay loaded and hidden, then open over ipc. Windows stay mapped with an empty input region, which is why they open instantly.

```bash
shells.sh <utility> [call] [args]   # default call is toggle, starts the shell if it's down
```

| Utility | Key | Notes |
|---|---|---|
| launcher | tap `Super` | dial, apps, commands, keybinds |
| home | `Alt+Tab` | Music, System stats, Notifications, Calendar |
| settings | `Alt+S` | sheet from the left |
| music | `Alt+Enter` | follows Spotify, else whatever's playing |
| wallpaper-picker | `Alt+W` | previews on every monitor |
| profiles | `Super+P` | list comes from `hypr-settings.py saved preview` |
| overview | `Super+Tab` | shares its tiles with the bar's workspace page |
| osd | media keys | `osd.sh` does the action, then shows it |
| widgets | `Alt+D` | same widgets as Space with its own layouts, on the bottom layer. `state/layouts/modern/` |
| welcome | first run | the tour |

</details>

<details>
<summary><b>The two bars</b></summary>

`state/bar` says which one runs, `bar.sh` handles it, `Alt+A` toggles it. A style with no `waybar/` folder (Space) always gets the quickshell bar, even if a profile says waybar.

**Waybar:** a style is `<Style>/waybar/<name>/` with `style.css`, `preview.png` and a `config`, or it uses `default/config`. `waybar-style.sh` copies it into `~/.config/waybar/`.

**Quickshell bar:** `quickshell/Modern/bar`. Modules sit in up to three pills, hovering grows a pill into a card. A style is `quickshellbar/<name>/config.json`:

| Key | Does |
|---|---|
| `left` `center` `right` | module lists, only `center` gives one big pill |
| `strip` | full width strip the cards grow out of |
| `background` | draws the pill background |
| `attached` | pills hang from the top edge |
| `height` `gap` | sizes |
| `shape` | `round`, `capsule`, `square` |

Modules: `user` `workspaces` `media` `date` `constdate` `timer` `clock` `tray` `updates` `notifications` `network` `audio` `battery` `power`, and `|` for a divider.

Every `config.json`, Modern's and Space's, starts with a `"//"` list of its options. JSON has no comments and both bars ignore that key.

`InstallScripts/bars/quickshellbarinstall.sh` and `waybarinstall.sh` install either bar alone. The standalone quickshell bar reads `style.json` next to its `shell.qml`. The installer copies `shared/` and the parts of Modern it needs into `style/`, so the imports work the same.

</details>

<details>
<summary><b>Lock</b></summary>

`lock.sh` runs `quickshell/lock.qml` as its own process, so it still comes up if the shell is dead. It quits after unlocking and ships its own pam file.

Both styles run the same lock from `quickshell/shared/`, so multiple monitors, music, battery, power buttons and the gear menu work the same in each. It grabs a frame of each monitor with grim and fades from that into the style's `Backdrop`: the blurred wallpaper in Modern, the land in Space. Handoff layers mapped under the lock take over on unlock.

The clock and password field only go on the monitor you locked from. The others just show the album art big in the middle with the song name, or nothing if no music is playing.

Square corners, fonts and colors come from `Theme`, `LockShared.ink` is the text color. Text also follows `Theme.caps` and `Theme.tracking` and art gets a `Theme.lines` edge, so Space's lock is uppercase, spaced out and outlined like the rest of Space.

`lock.sh --preview` shows it in windows without locking.

> [!WARNING]
> If it crashes, the session stays locked. Go to a tty and run `lock.sh` again.

</details>

<details>
<summary><b>Space</b></summary>

Same scripts, settings and color themes as Modern, none of the visuals. One process, `quickshell/Space/Shell.qml`. Each monitor gets the land and the bar, everything else is a `LazyLoader` thrown away when it closes.

| Part | Key | What it is |
|---|---|---|
| land | | the wallpaper is a shader, workspaces pan across it |
| world | `Alt+W` | new color and land from `World.qml`, not saved to the profile. `before` in `Wallpaper.qml` is a second terrain holding the old seed and colors. `hopProg` in `World.qml` drives every monitor: both pan together while a soft edge wipes the old one away and the moon comes back overhead. a press mid way only runs it to the end fast. the reload waits for it all to stop with `Ui.holdTheme` |
| overview | `Super+Tab` | workspaces and special workspaces with windows are stars, windows are planets, pypr scratchpads are moons |
| home | `Alt+Tab` | visor with system info |
| launcher | tap `Super` | little terminal under the bar, `Tab` switches between apps and commands, `Shift+Enter` runs in the background instead of kitty |
| widgets | `Alt+D` | same widgets as Modern with its own layouts, `state/layouts/space/` |
| bar | `Alt+A` | styles are `Space/quickshellbar/<name>/config.json`, same `left` `center` `right` `attached` and module names as Modern, so a new folder shows up in the bar picker on the core tab. unknown modules are skipped |
| settings | `Alt+S` | hud sheet that sizes to each tab, most pages come from `SchemaShared.js`, `LAYOUT` in Space's `Schema.js` sets their columns, right click resets an option |
| land tab | `Alt+S` | `LAND` in Space's `Schema.js`, saved as `space.land.*` in the profile. `Terrain.qml` binds each one straight to a shader uniform so it changes live. per world change rolls them a bit per seed, planets too. atlas swaps the home moon only, shooting stars is a count up to 6, each one gets its own spot left or right of the moon and its own size. reset puts every land option back |
| welcome | first run | the tour. the overview opens, closes itself after takeoff and moves on once it has landed. goes to one empty workspace and back so it can't jump monitors |
| lock | `Super+L` | the shared lock with the land behind it |

Panels move on Hyprland's curves like Modern, through `Settle`, `Theme.leave` and `Theme.ms`. The star map's flights and the world hop keep their own timing, they're tied to the capture and terrain steps below. `hyprctl animations` reports `windowsIn` as `spring:easy` and a spring isn't a bezier, so `ThemeBase` falls back to `global`.

`DecodeText` scrambles when it first shows and when it changes. Anything that ticks sets `decode: false`, like the timer, volume, sliders and seek times.

Overview cards show the color you'd land on in the corner: the preset's name, or the hex if it's random, in its accent. Planets get their own accent from the system's preset unless that preset has a pinned accent.

Overview keys: mouse aims, `wasd`, arrows or `hjkl` fly, `q` `e` turn, `shift` is fast, `tab` cycles your systems.

The windows falling away on launch are captures drawn in the overview, the real ones never move. They use `active_opacity` and `inactive_opacity` from `style.lua` as fixed numbers in `Overview.qml`, so change both together. `fall` in `Overview.qml` sets how fast they drop. Their blur is done in the overview too, `blurMax` on `frosted` is the strength.

On landing the captures come from the workspace you picked, not the one you left. Picking a pypr scratchpad moon runs `pypr toggle` and keeps that window on top.

Launch and landing stay smooth because the heavy work happens while nothing is moving:
- first frames and captures are prepared before the clock starts, that's `gate` in `Overview.qml`
- a world's colors start when you pick it, `color-apply.sh` runs as its own process so apps recolor while they're hidden
- `Theme.frozen` holds the qml colors and `World.heldReload` holds the Hyprland reload until the camera has stopped and the terrain still covers everything, then the reveal waits a moment so no old colors show
- the bar and widgets fade in as the terrain lifts, that's the last `veil` animation in `descend`
- stars get reused when the camera crosses cells instead of being rebuilt
- launch, landing and the world hop run on `PaceShared`. It steps once per frame of the fastest monitor (`HyprShared.fastScreen`), right after that frame's handoff, so the next frame gets worked out while the current one draws. Every frame moves the same amount and a late one slows it down for a moment instead of jumping
- the bar and wallpaper stop drawing (`updatesEnabled`) while the overview covers them, that's `Ui.covered`. Qt steps every animation once per window that draws, so the hidden visualizer and widgets were making the shell redo the camera about 1000 times a second and starving the 240hz screen
- nothing looks for what you're aiming at during a launch or landing, and the sky shader is off while the land fully covers it
- the falling windows grab one frame when you pick and another on touchdown, not a live capture every frame. Live capture was the biggest cost in the landing

**How the shaders work**

The land's colors go through `dither()` in `terrain.frag`, or the faint moon and sky band into shapes in 8-bit. `h3` is a `mod 289` hash because the old float one could give a cell's shared corner different values, which drew hard blocks on the moon. Don't use `uint` in these shaders, Qt loads a GLSL version here that doesn't have it.

The scenery has no images and there's no 3D engine. QML keeps the state and hands numbers and colors to the shaders, and a QML property reaches the shader when it has the same name as a uniform. Colors get mixed from the theme in `Terrain.qml`, so a new theme doesn't need a recompile. Editing a `.frag` does, see "I edited a shader and nothing happened".

- `terrain.frag` draws the sky, moon, planets, hills and trees in one pass. Switching workspaces only animates `pan`. Trees come in scenes on the thirds of the main hill (forest or group, then a lone tree or nothing), trees, bushes and rocks take the flat shade of the hill they stand on, ridge trees skip the low dips so they don't look planted on the main hill, bases come small, medium or large with random parts, landed ships and bases can have a little camp around them (bases sometimes with a ship parked), small rocks sit around scenes, ships, bases and the close astronaut, the rocks setting scatters more along the hills, a tiny astronaut stands on the tallest far mountain in view, and some worlds add a close one scanning a bush or sitting on a crate by the landed ship.
- On a launch or landing the land's stars morph into the overview's. The overview's land gets the sky camera (`view`, `viewSize`) and draws the same stars `overview.frag` does, moving with the wallpaper sky while the wallpaper stars shrink and fade, then stopping once they've taken over, so nothing pops when the sky takes over. They're cut out by the land and where the moon actually is, and only show low in the sky once it's dark
- Drawing all of that every frame is expensive, so `Wallpaper.qml` draws it once, stars included, and keeps the result. It only redraws when something like `pan` actually changes.
- `craters()` skips cells further than 0.83 away because a crater can't reach past that. That's the biggest radius times the 1.8 fade, so if you change either one change the number too.
- Only `Hypr.moonScreen` gets the moon, the other monitors are `moonless`.
- `overview.frag` is only the backdrop, nebula and far stars worked out from where the camera is looking. Everything you can fly to is a normal QML item, and `project()` in `Overview.qml` does the 3D math by hand to get its screen position and size.
- `common/orb.frag` is the small orb used by `Orb.qml`.

</details>

<details>
<summary><b>pypr</b></summary>

Upstream pypr dies when Hyprland drops its socket during a reload.

- `pypr.py` is installed as `~/.local/bin/pypr` and patches the bug at runtime, so `/usr/lib` stays untouched
- `pypr.sh` restarts it if it dies anyway, and stops it when Hyprland exits. It checks the PID in `hyprland.lock` because the daemon doesn't exit on its own when Hyprland goes away, and without this one was left behind every session
- `pypr.sh` unsets `CLAUDE*`, if a Claude session starts it every scratchpad terminal inherits the session marker and Claude stops saving transcripts
- every scratchpad has `skip_windowrules = ["group"]`, pypr's group deny rule makes Hyprland draw `col.nogroup_border` instead of the theme border, and that defaults to pink
- `pypr.py` also fixes the config check for list options, upstream compares the whole list against the valid names so `["group"]` shows a "config error(s)" notification even though the option works. It checks each item now, so a real typo still gets flagged

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
| monitors | `machine/<variant>.lua` |
| gaps, blur, curves, window rules | `<Style>/base/style.lua` |
| what runs at login | `session.lua`, `<Style>/base/session.sh` |
| idle timeouts | `hypridle.conf` |
| add a setting | one line in `quickshell/shared/SchemaShared.js`, both styles draw it. Each style picks its pages in `common/Schema.js` |
| add a Modern utility | new folder with a `shell.qml` and an `IpcHandler`, then a bind. if it has its own components, add `import "folder"` to `quickshell/Modern/Shell.qml` |
| add a bar module | `quickshell/Modern/bar/Module.qml` |
| add a widget | a `case` in `quickshell/shared/WidgetShared.qml` and its name in `WidgetEditorShared.qml` |
| panel opacity, 24 hour clock | Windows > Opacity and System > Clock. `Theme.back()` and `Theme.clock()` use them, so use those for new panels and times |
| add a bar style | new folder in `quickshellbar/` or `waybar/` |
| add a color scheme | new json in `.config/wal/colorschemes/` |
| add a machine | new `machine/<name>.lua` |
| add a style | new `<Style>/base/` and `quickshell/<Style>/` with a `Shell.qml`, `common/Theme.qml`, `common/Schema.js`, `common/Backdrop.qml`, `common/MediaCard.qml` and the `bar/menus` parts shared menus use |
| add something both styles use | new file in `quickshell/shared/`, add `import "../style/common"` if it needs `Theme` |

## Confusing stuff

<details>
<summary><b>"Profile" means two things</b></summary>

`state/profile` and `hypr-profile.sh` mean Style/variant. The settings panel and the profile wheel mean a saved tweak entry. Glass and Zen are the second kind.

</details>

<details>
<summary><b id="file-names">File names</b></summary>

QML in `quickshell/shared/` ends in `Shared`, `AudioShared.qml`, and the code uses that name, `AudioShared {}`. Files in `Modern/` and `Space/` have plain names.

</details>

<details>
<summary><b>Same name, different file</b></summary>

| Name | Which is which |
|---|---|
| `session` | `session.lua` is login, `utilities/session/session.sh` starts and stops a style, `base/session.sh` is that style's extras, `menus/Session.qml` is the power menu |
| `Theme` | `quickshell/shared/ThemeBaseShared.qml` is the real one, each style's `common/Theme.qml` extends it |
| `shell.qml` | one per Modern utility. `quickshell/shell.qml` starts the style's `Shell.qml`, which loads them |
| `Toggle`, `Card`, `Reveal` | each exists more than once, they're local to their folder |

</details>

<details>
<summary><b>What's the style link?</b></summary>

Quickshell won't import files outside the folder it started in, so it starts from `quickshell/` and everything sits inside it. `quickshell/style` is the only link, it points at `Modern` or `Space`. It's gitignored, `hyprland.lua` and `hypr-profile.sh` keep it right.

```text
quickshell/
├─ shell.qml    import "style", Shell {}
├─ lock.qml     import "shared", LockShellShared {}
├─ boot.qml     import "style/boot", BootShell {}
├─ style        → Modern or Space
├─ Modern/
├─ Space/
└─ shared/
```

Shared files import `../style/common`, so `Theme` in a shared file means the running style's `Theme`. Style files import `../shared` from however deep they are. Always go through `style/` from a shared file, never `../Modern/`, or a singleton ends up loaded twice.

The bar's wifi, bluetooth, sound, updates and notifications menus work like this too. What they do is in `quickshell/shared/`. What they look like is `Entry`, `Group`, `Header`, `Round` and `Chips` in each style's `bar/menus`, and `Slider`, `Switch` and `Tile` in its `common`.

`shared/` is flat because a shared file sees everything next to it without an import.

</details>

<details>
<summary><b>Why does Modern's Shell.qml import folders it doesn't use?</b></summary>

Quickshell only registers a folder's components if it reaches that folder through an `import`, starting from the root file. Modern loads its utilities with `createComponent`, which it can't follow, so the imports at the top of `quickshell/Modern/Shell.qml` are how it finds them. Same for Space's `bar/menus`, those load through a `Loader`.

There are no `qmldir` files, Quickshell makes them from these. A singleton just needs `pragma Singleton`.

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
| `quickshell/Modern/overview/workspaces.json` | the overview | save from the overview |

</details>

<details>
<summary><b>I edited a shader and nothing happened</b></summary>

Qt runs the `.qsb`, not the `.frag`. This rebuilds every shader and restarts the shell:

```bash
utilities/session/shells.sh shaders
```

`terrain.frag` is only the setup, the parts live in `wallpaper/terrain/` and get pulled in with `#include`. `sky`, `land` and `space` are pasted inside `main()`, so they share its variables like `col`, `y` and `cover`.

Each section is labeled with a one or two word comment like `// trees` so you can find things. Those labels are the only comments in the repo.

</details>

<details>
<summary><b>Keybind descriptions</b></summary>

The launcher doesn't ask Hyprland. `Binds.js` reads `binds.lua` and Modern's `shortcuts.lua` as text, one line at a time, and `describe()` works out the label from the dispatcher.

So a bind has to fit on one line to show up, and that's why `binds.lua` spells out each one instead of looping. The order of the two files sets the order on the page. To name something new, add it in `describe()` or `SCRIPTS` in `Binds.js`.

</details>

<details>
<summary><b>Things that aren't where you'd think</b></summary>

- `notifications` is the notification host, so it's always running. Home isn't, so a notification can't depend on it
- The shell is the notification server, so switching styles kills it. `NotifsShared.qml` keeps history and dnd in `$XDG_RUNTIME_DIR/notifications.json` and loads them back on start. Notifications that come back from the file have lost their action buttons, the app on the other end is gone from the server's point of view. They last until you log out
- The dotfiles' own notifications (profile switch, focus timer, capture, cast) are sent transient with `notify-send -e`. They still pop up but never land in the history or the bar count
- Popups are bottom left and hide while the home screen is open
- Wallpapers live in `~/wallpapers/library`, only favorites are in this repo. The pre-commit hook copies them in from `favorites.txt`
- Spotify always opens through `spotify.sh`
- Lock keeps its gear menu settings in `~/.local/state`
- `hypr-settings.py` gets the boot and cursor defaults by asking the running Hyprland for `require("machine").defaults`, so changing what `machine/<variant>.lua` returns can break it even though no lua file complains

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
- `h` in `Qt.formatTime` is still 24 hour unless the format has `AP` too. Use `Theme.clock()`
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
- `focusedMonitor` can be stale at startup, so `HyprShared.qml` asks for the cursor position

</details>

<details>
<summary><b>Performance</b></summary>

- The land is drawn once and kept, the stars are part of that one layer and don't twinkle. Looping the whole shader repainted every pixel at full refresh, and even redrawing only the stars made Hyprland redraw everything on top of them. Now the GPU goes back to idle when nothing is moving
- Vsync is always on. Without it Qt drew frames in bursts that didn't line up with the screen and about a third of the 240hz frames were repeats. It used to stutter with vsync on because of the 75hz screen holding up the 240hz one, the overview pausing hidden windows and `PaceShared` fixed that
- `RenderScale.qml` watches frame times while the land, a hop, a launch or a landing is moving. Under about 40 fps it draws the terrain at lower resolution, down to half, and goes back up when frames are fast again. It only applies while moving, the land goes back to full resolution when it stops. It decides during the motion but only switches once things stop, switching mid animation was a visible pop. A fast GPU never drops
- During a hop `before` covers the land, so `terrain.frag` skips the land's pixels under it (`beneath`) and `before`'s pixels the wipe already cleared. Only one full land gets drawn per frame instead of two
- Land options that are off cost nothing, `terrain.frag` skips them on the uniform. The galaxy only runs on sky pixels. Nothing animates while idle, so the land only redraws when something changes
- `terrain.frag` skips the planet until it actually shows. It used to work out the whole planet surface for every pixel while you were still on the ground, and all the time on the second monitor
- The frosted copy behind the falling windows is drawn at quarter size, it's blurred so much you can't tell
- The first launch or hop after the PC sits idle starts on a sleeping GPU. Mine sits at 210MHz for about half a second before it goes up to full speed, that's the few dropped frames left at the very start
- If everything is suddenly laggy on the laptop check the battery first. At 6% the GPU was capped to 30W instead of 125W and stuck around 500MHz, by 14% the cap was gone. `nvidia-smi -q -d POWER` shows the current limit
- With `QSG_USE_SIMPLE_ANIMATION_DRIVER` any running animation, `FrameAnimation` included, redraws every shell window every frame. `SeekShared` used one to poll the song position, so while music played all 9 windows drew at full refresh and the shell gained about 1GB an hour from Wayland events the NVIDIA driver never hands back. It polls with a `Timer` now, which only redraws its own window. Keep anything that runs while idle on a `Timer`
- One `Cava` for every visualizer, each monitor's bar used to spawn its own
- `Panel` frees textures after it's been closed a while
- The launcher, music, settings and overview windows only exist while they're open.
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
- Both `MediaCard`s, Modern's `MediaTab` and `NowPlaying` handle Spotify's music videos, which play through its own chromium as `title • artist`
- `capture.sh` recordings are capped at 60fps because wf-recorder's default spreads the bits over 200+ frames a second on the 240Hz monitor. The bt709 tags are set by hand or colors shift in players
- `cast.py` mirrors to Miracast tvs over Wi-Fi Direct through NetworkManager, the LG CX shows up this way. A tv on DLNA only opens the stream as a video in its media player, and the LG won't even start one with no end to it, so Wi-Fi Direct wins when a tv has both. It runs next to the normal Wi-Fi so the internet stays up. The link is UDP with no resends, so the stream keeps a keyframe every half second, paces its packets and marks them as video priority to keep a lost packet from showing for long.
- `capture.sh` falls back to x264 when NVENC won't start. NVENC rejects tiny regions and doesn't exist without an NVIDIA card

</details>

## Every file

All 261 of them.

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
│  ├─ shells.sh               start, stop or call the quickshell process over ipc, `shaders` rebuilds them
│  ├─ TransitionShared.qml    blurred frame and loading bar that hide a style switch
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
└─ paths.sh                   sourced by scripts. sets $HYPR $UTIL $STYLE $QS from state/profile
```

</details>

<details>
<summary><b>quickshell/ and shared/</b></summary>

```text
quickshell/
├─ shared/
│  ├─ capture/
│  │  ├─ capture.sh                    screenshots and recordings by region, window or screen
│  │  ├─ cast.py                       casts to tvs: wifi direct, miracast, chromecast, dlna
│  │  └─ share.sh                      xdph's custom picker, hands off to the capture menu
│  ├─ pam/
│  │  └─ password.conf                 the lock's pam file, so it doesn't need hyprlock's
│  ├─ AudioShared.qml                  default speaker and mic, volume and mute
│  ├─ BluetoothListShared.qml          bluetooth devices and their rows, pair and connect
│  ├─ BrightnessShared.qml             screen brightness state
│  ├─ CalendarShared.qml               calendar and todo list
│  ├─ CaptureTabShared.qml             screenshot, record, cast and share tab
│  ├─ CardShared.qml                   Tile with padding for menu content
│  ├─ cava.conf                        base cava config, CavaFeed swaps in bars and framerate
│  ├─ CavaFeedShared.qml               runs cava with its own bar count
│  ├─ CavaShared.qml                   one cava feed for every visualizer
│  ├─ ColorTabShared.qml               color picker tab, shares waybar's history
│  ├─ CountdownShared.qml              focus timer logic, lives in the shell
│  ├─ CoverShared.qml                  album art that slides the way you skipped
│  ├─ CurvePlotShared.qml              draggable bezier graph
│  ├─ FadeShared.qml                   one island tab, fades and rises in when on
│  ├─ ForecastShared.qml               wttr.in weather data, refreshes every 30 min
│  ├─ HoverShared.qml                  MouseArea with hover and the hand cursor
│  ├─ HyprShared.qml                   paths, which screen has focus or the cursor, the fastest screen, dispatch
│  ├─ IconButtonShared.qml             clickable icon that lights up on hover
│  ├─ LabelShared.qml                  Text in the theme font and color
│  ├─ LockFaceShared.qml               what you see on one monitor, with its digits, buttons and wave
│  ├─ LockShared.qml                   lock state, pam, gear menu settings
│  ├─ LockShellShared.qml              lock session and monitor surfaces
│  ├─ LockToggleShared.qml             gear menu switch
│  ├─ MediaShared.qml                  picks the player, skip and play controls
│  ├─ MediaViewShared.qml              tells the osd a media screen is up
│  ├─ MiniWaveShared.qml               small bar visualizer
│  ├─ MorphShared.qml                  the grow out of a dot open and close
│  ├─ MotionShared.js                  animation presets and curves for both settings pages
│  ├─ net.sh                           nmcli calls for the wifi menus
│  ├─ NetworkShared.qml                wifi and bluetooth side by side
│  ├─ NotificationCardShared.qml       one notification card
│  ├─ NotificationPopupsShared.qml     popups, bottom left
│  ├─ NotificationsShared.qml          notification history, dnd and clear
│  ├─ NotifsShared.qml                 the notification daemon, keeps history and dnd
│  ├─ NowPlayingShared.qml             track info, covers spotify's blank music videos
│  ├─ OopsShared.qml                   inline error text
│  ├─ OsdShared.qml                    osd pill and media card
│  ├─ OsdStateShared.qml               what the osd does, caps lock tracking
│  ├─ PaceShared.qml                   animation clock locked to the fastest monitor's frames
│  ├─ PlayButtonShared.qml             accent circle with the play/pause morph
│  ├─ PlayPauseShared.qml              shape that morphs between play and pause
│  ├─ PowerShared.qml                  session actions and battery
│  ├─ SchemaShared.js                  every settings page and option, one line per setting
│  ├─ SeekShared.qml                   smooth progress bar
│  ├─ SettingBezierShared.qml          full curve editor with preview and randomize
│  ├─ SettleShared.qml                 NumberAnimation on hyprland's window curve
│  ├─ SkipButtonShared.qml             prev/next that kicks when it skips
│  ├─ SoundShared.qml                  speakers, mics, volume rows and device picking
│  ├─ spotify.sh                       opens spotify's scratchpad, or a normal window without pypr
│  ├─ stats.sh                         system info from /proc and /sys, read by both home screens
│  ├─ StoreShared.qml                  settings state, batches writes to hypr-settings.py
│  ├─ SwapTextShared.qml               text that slides out and types back in
│  ├─ SystemStatsShared.qml            cpu, ram and link from /proc, no processes
│  ├─ ThemeBaseShared.qml              palette, rounding, gaps, timing. each Theme.qml extends this
│  ├─ TimerTabShared.qml               drag ring timer ui
│  ├─ TodosShared.qml                  todo storage in state/todos.json
│  ├─ ToggleShared.qml                 label and switch row
│  ├─ TourShared.qml                   first run tour, each style gives it steps and spots
│  ├─ UpdateMenuShared.qml             pending updates, update now or check again
│  ├─ UpdatesShared.qml                pending pacman and aur count, every 30 min
│  ├─ WatchedShared.qml                FileView that rereads when the file changes
│  ├─ WeatherTabShared.qml             weather tab with graph
│  ├─ WidgetBoardShared.qml            desktop widgets with snapping
│  ├─ WidgetEditorShared.qml           strip for adding and tweaking widgets
│  ├─ WidgetModelShared.qml            one monitor's widgets, saved per monitor shape
│  ├─ WidgetsEditShared.qml            edit mode overlay
│  ├─ WidgetShared.qml                 one widget
│  ├─ WidgetStateShared.qml            which monitor is editing or typing
│  ├─ WifiEditorShared.qml             edit a saved connection: ip, dns, security, with its fields
│  └─ WifiShared.qml                   wifi list and connect
├─ boot.qml                            starts boot from the running style
├─ lock.qml                            starts the shared lock
├─ shell.qml                           starts the running style's Shell.qml
└─ style                               link to Modern or Space, gitignored
```

</details>

<details>
<summary><b>machine/</b></summary>

```text
machine/
├─ desktop.lua  desktop monitors, boot and cursor defaults
└─ laptop.lua   laptop monitors, boot and cursor defaults
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
│  │  │  ├─ Aurora.json   northern lights, soft round corners
│  │  │  ├─ Dusk.json     catppuccin sunset, attached bar, big gaps
│  │  │  ├─ Gruvbox.json  saved profile, desktop
│  │  │  ├─ Neon.json     gas station at night, square, gradient border
│  │  │  ├─ Sun.json      saved profile, desktop
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
<summary><b>quickshell/Modern/bar/</b></summary>

```text
quickshell/Modern/bar/
├─ island/
│  └─ MediaTab.qml              island's media tab, with its button and empty state
├─ menus/
│  ├─ Chips.qml                 row of pickable chips
│  ├─ Entry.qml                 menu row base, wiggles while connecting
│  ├─ Group.qml                 titled group, clips rows to its corners
│  ├─ Header.qml                card header with title and icon
│  ├─ Round.qml                 small round icon button
│  ├─ Session.qml               power menu, the scary ones need a second press
│  └─ Tray.qml                  system tray with its menus
├─ alarm.ogg                    the alarm sound
├─ Alarm.qml                    rings out of the bar when the focus timer ends
├─ Island.qml                   the media and clock card with its tabs
├─ Module.qml                   every bar module in one file
├─ Pill.qml                     one pill. grows into a card on hover
├─ procs.sh                     per pid: cmdline, cwd and running program, for saving workspaces
├─ shell.qml                    bar windows per monitor, `bar` ipc, picks the style
├─ tabs.py                      reads firefox's session store for tab urls
└─ Workspaces.qml               dots, workspace page, tile and saved workspace data
```

</details>

<details>
<summary><b>quickshell/Modern/common/</b></summary>

```text
quickshell/Modern/common/
├─ Backdrop.qml                   blurred dark wallpaper behind home, overview and lock
├─ Button.qml                     text button
├─ Field.qml                      text input
├─ MediaCard.qml                  now playing for widgets, built like the lock's card
├─ Panel.qml                      Morph plus screen hop and keep warm
├─ Pop.qml                        quick bounce on a rename
├─ Say.qml                        the tour's text, plain in Modern
├─ Schema.js                      Modern's settings pages, all of them
├─ Rise.qml                       staggered fade and pop in
├─ Slider.qml                     slider
├─ Switch.qml                     toggle that stretches when it flips
├─ Tabs.qml                       icon tabs with a sliding accent pill
├─ Theme.qml                      Modern's theme, just ThemeBase
└─ Tile.qml                       the faint panel behind menu rows
```

</details>

<details>
<summary><b>quickshell/Modern/ everything else</b></summary>

```text
quickshell/Modern/
├─ boot/
│  └─ BootShell.qml                      boot animation, runs alone
├─ home/
│  ├─ Home.qml                           home screen. clock, music, stats, notifications
│  ├─ home-wall.sh                       prints a screen sized wallpaper copy per monitor
│  └─ shell.qml                          loads Home when it opens, drops it when it closes
├─ launcher/
│  ├─ AppGrid.qml                        app grid
│  ├─ Binds.js                           parses binds.lua and shortcuts.lua into keybind rows
│  ├─ HomePage.qml                       the home dial
│  ├─ KeybindsPage.qml                   keybind list
│  ├─ Radial.qml                         the dial wheel
│  ├─ SearchPill.qml                     search box
│  ├─ shell.qml                          launcher window, tabs, search and ranking
│  ├─ ShellPage.qml                      command runner
│  └─ VWheel.qml                         vertical wheel for commands
├─ music/
│  ├─ shell.qml                          music card. move, resize, tuck away
│  └─ Visualizer.qml                     cava bars for the card
├─ notifications/
│  └─ shell.qml                          the always on part: daemon, popups, dnd and clear calls
├─ osd/
│  └─ shell.qml                          `osd` ipc, the real osd is quickshell/shared/OsdShared.qml
├─ overview/
│  ├─ shell.qml                          big workspace overview, tiles come from bar/Workspaces.qml
│  └─ workspaces.json                    my saved workspaces. tracked so git syncs them
├─ profiles/
│  └─ shell.qml                          profile wheel on the right edge
├─ settings/
│  ├─ Dropdown.qml                       dropdown control
│  ├─ ResetArea.qml                      right click that resets an option
│  ├─ Segmented.qml                      segmented control
│  ├─ SettingAnimpreset.qml              animation preset picker
│  ├─ SettingBar.qml                     waybar or quickshell picker
│  ├─ SettingChoice.qml                  choice control tied to a key, pills under 5 options, dropdown otherwise
│  ├─ SettingColor.qml                   color control with swatches and alpha
│  ├─ SettingCursors.qml                 cursor theme picker
│  ├─ SettingProfile.qml                 style and variant picker
│  ├─ SettingSaved.qml                   save, apply, delete and wipe profiles
│  ├─ SettingSlider.qml                  slider control tied to a key
│  ├─ SettingToggle.qml                  switch control tied to a key
│  ├─ SettingWaybar.qml                  bar style picker with preview
│  ├─ shell.qml                          settings sheet window
│  └─ Themes.qml                         colors page, the fake terminal
├─ wallpaper-picker/
│  ├─ blur.frag                          blur shader source
│  ├─ blur.frag.qsb                      compiled blur shader, this is what runs
│  └─ shell.qml                          full screen wallpaper picker
├─ widgets/
│  └─ shell.qml                          hosts the shared widgets on every monitor
├─ welcome/
│  └─ shell.qml                          Modern's tour steps
└─ Shell.qml                             the shell. loads every */shell.qml
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
├─ quickshellbar/
│  ├─ attached/config.json  pills hang from the top edge
│  ├─ default/config.json   user and workspaces left, everything else right
│  ├─ split/config.json     media and clock in a center pill
│  └─ zen/config.json       workspaces, sound, notifications, clock
└─ tweaks/
   ├─ saved/
   │  └─ desktop/
   │     ├─ Atlas.json   atlas instead of a planet
   │     ├─ Bloom.json   rose pine, flat and full of trees
   │     ├─ Frost.json   nord, snowy mountains, big galaxy
   │     └─ Mars.json    gruvbox red, dry rocky sunset
   ├─ default-look.json  what Default remembers
   └─ desktop.json       live tweaks for the desktop variant
```

</details>

<details>
<summary><b>quickshell/Space/common/</b></summary>

```text
quickshell/Space/common/
├─ Backdrop.qml                   the land behind the lock
├─ Button.qml                     Modern's Button api, drawn the space way
├─ Controls.qml                   small hud controls every menu uses
├─ decode.js                      the text scramble effect
├─ DecodeText.qml                 the one text style, decodes on change
├─ Field.qml                      Modern's Field api, space look
├─ MediaCard.qml                  now playing for the island, home screen and widgets
├─ orb.frag                       ball of light shader
├─ orb.frag.qsb                   compiled, this is what runs
├─ Orb.qml                        glowing ball, bar dots and stars
├─ RenderScale.qml                lowers the terrain's resolution while moving if frames get slow
├─ Say.qml                        the tour's text, scrambles in Space
├─ Schema.js                      which shared pages Space shows, plus its own keys
├─ Slider.qml                     segmented slider, Controls.Slide uses it too
├─ Switch.qml                     Controls toggle for the shared menus
├─ Theme.qml                      ThemeBase, square, Space's font, accent outlines
├─ Tile.qml                       outlined panel behind menu rows
├─ TimerForecast.qml              one timer and forecast for every monitor
├─ Ui.qml                         what's open, so windows can react to each other
└─ World.qml                      planet hue, seeds, star positions, writes space.json
```

</details>

<details>
<summary><b>quickshell/Space/ everything else</b></summary>

```text
quickshell/Space/
├─ bar/
│  ├─ Bar.qml                      bar window, two pills and input regions
│  ├─ menus/
│  │  ├─ Calendar.qml              big clock, calendar and todos
│  │  ├─ Chips.qml                 row of pickable chips, made of Buttons
│  │  ├─ Entry.qml                 menu row, a Controls line with a gear
│  │  ├─ Group.qml                 titled group of rows that scrolls
│  │  ├─ Header.qml                Controls title for the shared menus
│  │  ├─ Island.qml                shared island tabs under the media module
│  │  ├─ Round.qml                 small Button with a glyph
│  │  ├─ Session.qml               battery, brightness and session
│  │  └─ Tray.qml                  tray apps as lines
│  ├─ Module.qml                   readout that opens a menu
│  ├─ Pill.qml                     glass pill with corner brackets, loads the open menu
│  └─ Workspaces.qml               workspace dots as orbs
├─ home/
│  └─ Home.qml                     alt tab visor with system readouts
├─ launcher/
│  └─ Launcher.qml                 little terminal under the bar
├─ overview/
│  ├─ glow.png                     star glow sprite
│  ├─ overview.frag                far sky shader
│  ├─ overview.frag.qsb            compiled, this is what runs
│  └─ Overview.qml                 3d star map. workspaces are stars, windows are planets
├─ settings/
│  └─ Settings.qml                 hud settings sheet from the bottom
├─ wallpaper/
│  ├─ terrain.frag                 setup and main, includes the parts below. no image files
│  ├─ terrain/
│  │  ├─ uniforms.glsl             every value Terrain.qml hands in
│  │  ├─ noise.glsl                hashes, noise, dither
│  │  ├─ orbit.glsl                planet and moon surfaces, space stars
│  │  ├─ atlas.glsl                the atlas
│  │  ├─ shapes.glsl               hills, rocks, trees, grass, bases, ships
│  │  ├─ sky.glsl                  sky, moon, galaxy, stars, flying ships
│  │  ├─ land.glsl                 mountains, ridges, hill, landed ship, foreground
│  │  └─ space.glsl                launch and landing, planet in orbit
│  ├─ terrain.frag.qsb             compiled, this is what runs
│  ├─ Terrain.qml                  the terrain shader with theme colors
│  └─ Wallpaper.qml                one monitor's wallpaper window, pans with workspaces
├─ welcome/
│  └─ Welcome.qml                  Space's tour steps
└─ Shell.qml                       the whole shell. overlays load lazily and drop on close
```

</details>
## Outside hypr/

| Path | What it is |
|---|---|
| `InstallScripts/` | `install.sh` is the menu, `apply.sh` relinks after a pull, `common.sh` is shared helpers. `full/` is the full install and uninstall, `bars/` is the standalone bars, `NoMansSky-Background-and-Map/` is the standalone Space wallpaper and star map |
| `.githooks/pre-commit` | syncs favorite wallpapers into `wallpapers/library`. The installer sets `core.hooksPath` |
| `.config/waybar/` | the live waybar config, see overwritten files above. `scripts/` is the color picker |
| `.config/wal/` | color schemes and pywal templates |
| `.config/pypr/config.toml` | scratchpads, the bar reads classes from here too |
| `.config/kitty/` `nvim/` `starship.toml` `clock-rs/` | app configs |
| `.bashrc` | aliases and functions, the launcher lists these too |
| `wallpapers/library/` | favorite wallpapers and `favorites.txt` |
| `archive` branch | retired configs, nothing there runs |
