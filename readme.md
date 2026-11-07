[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=30&letterSpacing=tiny&duration=2000&pause=3000&color=F7F7F7&center=true&vCenter=true&width=435&lines=Eli's+Dotfiles)](https://git.io/typing-svg)

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/rice-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/rice-zen.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/SpaceRice1.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/ModernRice1.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/rice1.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/SpaceRice4.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/rice5.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/rice6.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/SpaceRice5.png" width="32%">
</p>

> [!TIP]
> Check out [MyFetch](https://github.com/elifouts/MyFetch)!!!!
> 
> A dynamic lightweight fetching tool forked from [NerdFetch](https://github.com/ThatOneCalculator/NerdFetch)

This contains My **Arch** Linux Dotfiles for a clean-looking lightweight **Hyprland** setup, built around **Quickshell**.

Built by me, with help from my own thoughts and ideas AKA Claude for some of the scripting and docs. The design, look, and result are all my own.

***ENJOY!!***

-Eli F.

<details>
  <summary>AI Policy</summary>

## My AI Policy

- No code in this repository was AI generated without intense review. I use Claude to create a lot of the Quickshell skeletons that you see. After creating a skeleton and some pseudocode, I go in and make changes to the configs until I like what I see. My text editor of choice is Nvim with some Lua plugins. This is where I do most of my work. If you want my config, you can install it [here](https://github.com/elifouts/MyNvim).
---
- I write and maintain a lot of the code and scripts in this repository myself. Working as an Applications Engineer has given me a better understanding of how applications are built and how to optimize systems. Combined with my Computer Science studies and experience with Quickshell and Linux, this helps me avoid bloated AI-generated code and build a more optimized, lightweight config.
</details> 

> [!WARNING]
> All Configurations were meant to be used with `Pywal`
>
> <details>
>   <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/color-schemes-more-info-v2.svg" alt="Color Schemes (more info)" align="absmiddle"></picture></summary>
>
>   If you do not want this, **you can pick a fixed color scheme in the settings panel (`Alt+S` > Colors)** or remove it in the given applications `style.css` and add valid color values. Although I highly recommend `Pywal` It's Pretty cool!
>
> </details>

## Styles

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/how-it-all-fits-together-v2.svg" alt="How It All Fits Together" align="absmiddle"></picture></summary>

  - **Style**: the whole look. Right now I only have `Modern` and `Space`.
  - **Variant**: `desktop` or `laptop`. Just the stuff that changes per machine like monitors and mouse. Hyprland loads both straight out of `.config/hypr/Modern/`, so that is the config you edit.
  - **Profile**: your tweaks on top, picked in the settings panel. **Glass** and **Zen** are mine. Saving a profile also saves your colors, bar and wallpaper.

  Detailed Documentation is in [`.config/hypr/readme.md`](.config/hypr/readme.md).

  <p align="center">
    <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/profiles.gif" width="70%">
  </p>

</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/modern-v2.svg" alt="Modern" align="absmiddle"></picture></summary>

  <details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/launcher-modern-v3.svg" alt="Launcher" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-zen.png" width = "33%">

![launcher](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher.gif)

- **Tap `Super`** to open it.
- Has a dial for power and session stuff, an app search, a command runner, and a list of all my keybinds.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/home-screen-modern-v3.svg" alt="Home Screen" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-zen.png" width = "33%">

- **`Alt+Tab`** to open it.
- Clock, music, calendar, system stats, volume and your notifications all in one place.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/settings-panel-modern-v3.svg" alt="Settings Panel" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-zen.png" width = "33%">

![settings](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings.gif)

- **`Alt+S`** to open it.
- This is where you change pretty much everything. Profiles, bar, colors, gaps, blur, animations, cursor, and more. It all updates live.
- Save your own profile in **Profile > Saved profiles**. Right-click any setting to reset it.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/music-player-modern-v3.svg" alt="Music Player" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-default.jpg" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-glass.jpg" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-zen.jpg" width = "33%">

![music](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music.gif)

- **`Alt+Enter`** to open it.
- Works with Spotify or whatever else is playing, and has a `cava` visualizer.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/wallpaper-picker-modern-v3.svg" alt="Wallpaper Picker" align="absmiddle"></picture></summary>

![wallpaper-picker](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper-picker.gif)

- **`Alt+W`** to open it.
- Scroll through your wallpapers in `~/wallpapers/library`. Picking one updates the `Pywal` colors for everything.
- Only my favorites ship with the dotfiles. The full library is in [elifouts/wallpapers](https://github.com/elifouts/wallpapers) ([browse and download](https://www.elifouts.net/wallpapers/)). The installer asks if you want it, or run `wallpapers.sh install` later.
- `wallpapers.sh pull` / `push` keeps the library synced, `dev-pull` grabs everything including the archive.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/osd-modern-v3.svg" alt="OSD" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-zen.png" width = "33%">

![osd](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd.gif)

- Pops up at the bottom when you change volume, brightness, caps lock or use the media keys.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/notifications-modern-v3.svg" alt="Notifications" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-zen.png" width = "33%">

![notify](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify.gif)

- Notifications show up in the bottom left. You can see the old ones on the home screen.
</details>

<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/boot-animation-modern-v3.svg" alt="Boot Animation" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-zen.png" width = "33%">

![boot](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot.gif)

- Plays when Hyprland starts. You can turn it off in **Settings > System**.
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/waybar-modern-v3.svg" alt="Waybar" align="absmiddle"></picture></summary>

  ![waybar-default](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-default.png)
  ![waybar-glass](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-glass.png)
  ![waybar-zen](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-zen.png)

  ## Overview
  This is my minimal Waybar setup for Hyprland, designed to be clean and efficient. There are 4 styles (`default`, `experimental`, `line`, `zen`). Pick one in **Settings > Profile**, and `Alt+A` turns it on and off.

  ## Workspaces
  I’ve configured the workspaces so that if there is content on a workspace, the dot appears darker. This helps you keep track of your open content! Inspiration from [Gbar](https://github.com/scorpion-26/gBar).

  ## Expanding Waybar
  You can hide and reveal widgets you don’t need all the time. You can easily add or remove widgets in the style's `config` under the `group/expand` section.

  - **Network Widget**: Clicking the network widget opens `nmtui` in `kitty`.
  - **Hyprpicker Widget**: This custom widget lets you use `hyprpicker`, display values when hovered, and copy the hex value to your clipboard.

  ### *How To Install*
  Run the install script and pick `2. Waybar`. You don't need the rest of my dotfiles for it.

  ### Dependencies
  ```
  waybar
  hyprpicker
  pywal
  blueman
  bluez
  networkmanager
  ```
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/quickshell-bar-modern-v3.svg" alt="Quickshell Bar" align="absmiddle"></picture></summary>

  ![quickshellbar-default](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-default.png)
  ![quickshellbar-attached](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-attached.png)
  ![quickshellbar-experimental](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-experimental.png)
  ![quickshellbar-full](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-full.png)
  ![quickshellbar-zen](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-zen.png)

  ![quickshellbar-attached](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-attached.gif)

  ## Overview
  My Quickshell version of Waybar. There are 5 styles (`default`, `attached`, `experimental`, `full`, `zen`). Pick one in **Settings > Profile**, and `Alt+A` turns it on and off.

  When you hover the pills they grow into cards for your workspaces, music, wifi, sound and power. Inspiration from [NabyScape](https://github.com/BillyNabil/nabyscape).

  ### *How To Install*
  Run the install script and pick `3. Quickshell bar`, then start it with `qs -c dotfiles-bar`. You don't need the rest of my dotfiles for it.
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/lock-screen-modern-v3.svg" alt="Lock Screen" align="absmiddle"></picture></summary>

  ## Overview
  - `Mod+L` to lock, or it locks on its own when you're idle with `hypridle`.
  - It blurs your current wallpaper, greets you with your username, and uses your Pywal colors. If music is playing it shows that too.

  ### *How To Install*
  1. **Install [Quickshell](https://quickshell.org/)** and `hypridle`
  2. Copy `Dotfiles/.config/hypr/Modern/utilities` to `~/.config/hypr/Modern/utilities` (lock needs `common` and `lock.qml` next to it), plus `utilities/session/lock.sh`, `utilities/paths.sh` and `hypridle.conf`
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/old-stuff-no-longer-used-v2.svg" alt="Old Stuff (no longer used)" align="absmiddle"></picture></summary>

  I replaced all of these with my Quickshell stuff. The configs are still on the [`archive` branch](https://github.com/elifouts/Dotfiles/tree/archive) if you want them.

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/wofi-replaced-by-the-launcher-and-wallpaper-picker-v2.svg" alt="Wofi (replaced by the Launcher and Wallpaper Picker)" align="absmiddle"></picture></summary>
    <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi1.png" width = "35%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi2.png" width = "35%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi3.png" width = "35%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi4.png" width = "35%">

  - I launched wofi like this:
    ```config
    wofi --show drun -n
    ```

  ### How to Add Blur to Wofi

  ```
  layerrule = blur, wofi
  layerrule = ignorezero, wofi
  layerrule = ignorealpha 0.5, wofi
  ```
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/swaync-replaced-by-notifications-and-the-home-screen-v2.svg" alt="Swaync (replaced by Notifications and the Home Screen)" align="absmiddle"></picture></summary>
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync1.png" width = "20%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync2.png" width = "20%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync3.png" width = "20%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync4.png" width = "20%">

  - Config is on the [`archive` branch](https://github.com/elifouts/Dotfiles/tree/archive/swaync).
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/swayosd-replaced-by-the-osd-v2.svg" alt="SwayOSD (replaced by the OSD)" align="absmiddle"></picture></summary>

  - Config is on the [`archive` branch](https://github.com/elifouts/Dotfiles/tree/archive/swayosd).
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/wlogout-replaced-by-the-launcher-s-home-dial-v2.svg" alt="Wlogout (replaced by the Launcher's Home dial)" align="absmiddle"></picture></summary>
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout1.png" width = "40%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout2.png" width = "40%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout3.png" width = "40%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout4.png" width = "40%">

  - Config is on the [`archive` branch](https://github.com/elifouts/Dotfiles/tree/archive/wlogout).
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/hyprlock-v2.svg" alt="Hyprlock" align="absmiddle"></picture></summary>
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-zen.png" width = "33%">

  ![lock](https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock.gif)

  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock1.PNG" width = "50%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock2.png" width = "50%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock3.png" width = "50%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock4.png" width = "50%">

  - Hyprlock uses the current wallpaper from Pywal to generate a background, displays a greeting with your username, and applies Pywal colors.
  - Config is on the [`archive` branch](https://github.com/elifouts/Dotfiles/tree/archive/hyprlock).
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/old-wallpaper-solution-wofi-swww-v2.svg" alt="Old Wallpaper Solution (wofi + swww)" align="absmiddle"></picture></summary>

  ![image](https://github.com/user-attachments/assets/7cbe58e3-7226-4537-8e69-bb316cdfaebc)

  - A script that applied a wallpaper using `swww` and set the `Pywal` theme.
  - The script uses Wofi to select wallpapers. I have not been able to optimize the wallpaper loading so it might load slowly but it should work.
</details>

</details>

</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/space-v2.svg" alt="Space" align="absmiddle"></picture></summary>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/launcher-space-v3.svg" alt="Launcher" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/launcher.png" width = "50%">

![launcher](https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/launcher.gif)

- **Tap `Super`** to open it.
- Little terminal under the bar. `Tab` cycles apps, commands and a bare prompt.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/home-screen-space-v3.svg" alt="Home Screen" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/home.png" width = "50%">

- **`Alt+Tab`** to open it.
- A visor with system stats, network and whatever is playing.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/settings-panel-space-v3.svg" alt="Settings Panel" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings-colors.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings-motion.png" width = "33%">

- **`Alt+S`** to open it.
- Colors, fonts, motion and profiles all in one sheet. It all updates live.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/osd-space-v3.svg" alt="OSD" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/osd.png">

- Pops up at the bottom when you change volume, brightness, caps lock or use the media keys.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/notifications-space-v3.svg" alt="Notifications" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/notify.png">

- Notifications show up in the bottom left. The bell in the bar has the old ones.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/wallpaper-space-v3.svg" alt="Wallpaper" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/wallpaper-1.png" width = "50%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/wallpaper-2.png" width = "50%">

- **`Alt+W`** to change colors.
- It's a shader, not an image, so it moves when you switch workspaces.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/lock-screen-space-v3.svg" alt="Lock Screen" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/lock.png" width = "50%">

- `Mod+L` to lock. Just the land dimmed behind a small hud.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/quickshell-bar-space-v3.svg" alt="Quickshell Bar" align="absmiddle"></picture></summary>

![bar](https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/bar.png)

![bar-stars](https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/bar-stars.png)

![bar-media](https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/bar-media.png)

- **`Alt+A`** turns it on and off.
- Hover an icon to open its menu. Music also has tabs for a timer, color picker, screenshots and weather.
- The stars are your workspaces. A workspace with windows gets a bigger star, and extra windows orbit it as moons.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/space-map-space-v3.svg" alt="Space Map" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/map.png" width = "50%">

- **`Mod+Tab`** to open it.
- Workspaces are stars, windows are planets and scratchpads are moons.
- `wasd` to fly, `Tab` for the next system, `Enter` to land there, `Esc` to go back.
  </details>

  <details>
    <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/desktop-widgets-space-v3.svg" alt="Desktop Widgets" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/widgets.png" width = "50%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/widgets-edit.png" width = "50%">

- **`Alt+D`** to edit them. Drag them around, add more or change their style.
- Layouts save per monitor shape.
  </details>

</details>

## Other Configurations

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/nvim-v2.svg" alt="Nvim" align="absmiddle"></picture></summary>
<img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-zen.png" width = "33%">

## Overview

- This Neovim "rice" is a simplified version of Lazyvim, created with custom Lua files. It’s lightweight and includes only what you need. I just installed lazy and configured only the pluggins I wanted.
- It uses the Pywal theme, so relaunch nvim after you change your wallpaper to get the new colors.
- It features:
  - Alpha-nvim
  - Pywal theme
  - Autocompletion
  - Lualine
  - Tabline
  - Markview
  - Noice
  - Mini-icons
  - Snacks
  - Neo-tree
  - Telescope
  - Treesitter
  - Gitsigns
  - Colorizer
  - Which-key
  - LSP (Mason)
  - Copilot

### *How To Install*
1. **Install `Neovim`:**
    ```bash
    yay -S neovim
    ```
2. Copy `Dotfiles/.config/nvim` into `~/.config/`

3. Start `nvim` and watch it install all necessary components.
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/starship-v2.svg" alt="Starship" align="absmiddle"></picture></summary>
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-zen.png" width = "33%">

## Overview

  - This is a custom Starship config that is minimal but yet has everything you need/want from a terminal prompt.

 ### *How To Install*
1. **Install [Starship](https://github.com/starship/starship?tab=readme-ov-file#-installation)**
2. Copy the `Dotfiles/.config/starship.toml` file into `~/.config`
3. Add this to your `.bashrc` file:

   ```bash
    eval "$(starship init bash)"
   ```
   - Or go [here](https://github.com/starship/starship?tab=readme-ov-file#step-2-set-up-your-shell-to-use-starship) to find what you need for your shell.
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/pywalfox-v2.svg" alt="Pywalfox" align="absmiddle"></picture></summary>
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-default.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-glass.png" width = "33%"><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-zen.png" width = "33%">

  ## Overview

  - This is a way to configure `Firefox` so that it uses `Pywal` colors. After proper configuration, `Firefox` will change automatically when `Pywal` updates its color scheme.

  ### Dependencies
  ```
  Firefox
  Python
  Pywal
  ```

 ### *How To Install*
1. **Install [Pywalfox](https://github.com/Frewacom/pywalfox)**
2. Run `pywalfox install`
3. Install Firefox add-on for PywalFox
4. Run `pywalfox update` in your terminal or add it to a script to update the `Firefox` theme after generating `Pywal` colors. My `color-apply.sh` already does this.
</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/gtk-themes-v2.svg" alt="GTK Themes" align="absmiddle"></picture></summary>

  ### I use these GTK themes

  - Widget Theme: Materia-dark
  - Icon Theme: Qogir-dark
  - Cursor: Bibata-Modern-Ice
</details>

# Install / Updating

Install

  - With this script you should be able to install everything together, or just one of my bars on its own.
  - Dont worry it doesn't delete anything. It asks to back up your `~/.config` first and moves anything it replaces to `~/.dotfiles_replaced_<date>`.

  ```
  cd && git clone --depth 1 https://github.com/elifouts/Dotfiles.git
  cd ~/Dotfiles/InstallScripts
  chmod +x install.sh
  ./install.sh
  ```

  - `1. Full install` - everything
  - `2. Waybar` - just my waybar
  - `3. Quickshell bar` - just my quickshell bar
  - `p. Package manager TUI` - see below

Update:

```
git -C ~/Dotfiles pull && ~/Dotfiles/InstallScripts/apply.sh
```

Or if you have the bash alias `dotpull` that works too

Uninstall:

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/package-manager-tui-v2.svg" alt="Package Manager TUI" align="absmiddle"></picture></summary>

  A little tool I made to see what's installed, where it came from, and how big it is.

  ```bash
  ~/Dotfiles/.config/hypr/utilities/packages/package-tui.sh
  ```

  `j`/`k` to scroll, `d` to uninstall, `r` to reinstall, `q` to quit.
</details>

```
~/Dotfiles/InstallScripts/uninstall.sh
```



## My Applications


<details>
<summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/gallery-v2.svg" alt="Gallery" align="absmiddle"></picture></summary>

### Desktop Profiles

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/rice-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/rice-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/rice-zen.png" width="32%">
</p>

### Quickshell

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/home-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-default.jpg" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-glass.jpg" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music-zen.jpg" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot-zen.png" width="32%">
</p>

### Waybar

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-default.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-glass.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/waybar-zen.png" width="100%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/waybar1.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/waybar6.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/waybar4.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/waybar3.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/waybar2.png" width="100%">
  <img src="https://github.com/user-attachments/assets/31668572-b35d-4acb-8525-8cb0e5669101" width="100%">
  <img src="https://github.com/user-attachments/assets/f8c723c0-a9c9-4fa6-a3c8-bda06e81f81d" width="100%">
</p>

### Quickshell Bar

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-default.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-attached.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-experimental.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-full.png" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-zen.png" width="100%">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar-attached.gif" width="100%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/quickshellbar.gif" width="100%">
</p>

### Space

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/launcher.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/home.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/map.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/wallpaper-1.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/wallpaper-2.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/lock.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings-colors.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/settings-motion.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/widgets.png" width="48%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/widgets-edit.png" width="48%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/bar.png" width="100%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/osd.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/notify.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/space/launcher.gif" width="75%">
</p>

### Other Applications

**Neovim**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/nvim-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/nvim1.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/nvim2.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/nvim3.png" width="32%">
</p>

**Starship**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/starship-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/starship.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/starship1.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/starship2.png" width="32%">
</p>

**Pywalfox**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/fox-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/fox1.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/fox2.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/fox3.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/fox4.png" width="20%">
</p>

**Wofi**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi1.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi2.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi3.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wofi4.png" width="20%">
</p>

**Swaync**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync1.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync2.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync3.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/swaync4.png" width="20%">
</p>

**Wlogout**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout1.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout2.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout3.png" width="20%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/wlogout4.png" width="20%">
</p>

**Hyprlock**

<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-default.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-glass.png" width="32%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock-zen.png" width="32%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/lock.gif" width="75%">
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock1.PNG" width="48%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock2.png" width="48%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock3.png" width="48%">
  <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/lock4.png" width="48%">
</p>

### GIFs

<table>
  <tr>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/launcher.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/settings.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/music.gif" width="100%">
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/osd.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/notify.gif" width="100%">
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/boot.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/profiles.gif" width="100%">
    </td>
    <td align="center" width="33%">
      <img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/v2/wallpaper-picker.gif" width="100%">
    </td>
  </tr>
</table>

</details>

## Keybinds

`Mod+Q` - Open Terminal

`Super` (tap) - App Launcher

`Mod+M` - Quit Hyprland

`Mod+B` - Close

`Mod+F` - Fullscreen

`Mod+V` - Popout

`Mod+L` - Lock

`Mod+Space` - Terminal Scratch Pad

`Mod+E` - Opens Thunar

`Alt+Tab` - Home Screen

`Alt+S` - Settings Panel

`Alt+W` - Wallpaper Picker

`Alt+Enter` - Music Player

`Mod+P` - Profile Switcher

`Alt+A` - Toggle Bar

`Mod+Tab` - Workspace Overview/Galaxy Map

> [!NOTE]
> This isnt every Keybind. Just some highlighted ones.
>
> Tap `Super` > **Keybinds** to see all of them, or change them in `~/.config/hypr/Modern/base/shortcuts.lua`

## Help

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/apps-fuzzy-or-blurry-v2.svg" alt="Apps Fuzzy or Blurry?" align="absmiddle"></picture></summary>

  #### This may be because they need to be run with Wayland or are Electron applications

  - The solution I found is to add the following to `/usr/share/applications/{app}.desktop` after `exec=/app/executable/app`
  - Works on `Spotify` `Discord`

  ```
  --enable-features=UseOzonePlatform --ozone-platform=wayland --uri=%U
  ```

  - ***NOTE*** This gets removed if the app is redownloaded! I'm not sure how to make this a global thing. I have tried and failed. Help?

</details>

<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/cant-find-a-file-that-is-in-cache-v2.svg" alt="Cant Find a file that is in .cache?" align="absmiddle"></picture></summary>

### You may be looking for a file that looks something like this:

`@import url('../../.cache/wal/colors-waybar.css');`

That file is one of many that is created by `Pywal`. Make sure `Pywal` has run at least once (picking a wallpaper does this) and see if that works. Alternatively, you can do one of the following:

- create your own file which would look something like this:
```
@define-color background <Replace>;
@define-color color0 <Replace>;
@define-color color9 <Replace>;
```
Instead of those colors, you can use whichever color is needed by the style.css file.

- create the colors manually in the style.css files you took those paths from.
```
@define-color <ColorName> <Color>;
```

- Find the sections of that file that are calling the missing file, such as `$color2` or `@color2` and replace it with a valid value.

</details>

## Notes
- Cava uses `Pywal` too. My `color-apply.sh` rewrites `~/.config/cava/config` every time the colors change.
<details>
  <summary><picture><img src="https://raw.githubusercontent.com/elifouts/Dotfiles/images/badges/download-suggestions-v2.svg" alt="Download Suggestions" align="absmiddle"></picture></summary>

  - This is everything I think is essential to have. At least for me. I would suggest doing your own research before blindly downloading everything here. This is here just so if I break my computer which we all know I will, I can remember what I need/want!

```txt
git
quickshell
nvim
zip unzip
pipewire
hyprpicker
hypridle
hyprshot
pyprland
code
bottom
myfetch
yay
wl-clipboard
nerd-fonts
starship
thunar
grim
slurp
gnome-network-displays
discord
Firefox
spotify ncspot
pacman-contrib
python-pywal16
waybar
awww
blueman
bluez
networkmanager
gvfs
libnotify
pavucontrol
pipewire-pulse
nwg-look
cava
python-pywalfox
auto-cpufreq
powertop
qogir-icon-theme
fd
noto-fonts
libreoffice-fresh
materia-dark-gtk
```

  Fun to have

  ```
  asciiquarium
  pipes-rs
  clock-rs
  libcaca
  cowsay
  snake
  2048
  terminal-mines mines-tui
  genact
  no-more-secrets
  lolcat
  ```
  Cool things you don't need
  ```
  waypaper
  ranger
  howdoi
  ```
</details>

## Star History

<a href="https://www.star-history.com/?repos=elifouts%2Fdotfiles&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=elifouts/dotfiles&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=elifouts/dotfiles&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=elifouts/dotfiles&type=date&legend=bottom-right" />
 </picture>
</a>