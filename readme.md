[![Typing SVG](https://readme-typing-svg.demolab.com?font=Fira+Code&size=30&letterSpacing=tiny&duration=2000&pause=3000&color=F7F7F7&center=true&vCenter=true&width=435&lines=Eli's+Dotfiles)](https://git.io/typing-svg)

<img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice7.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice1.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice4.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice5.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice6.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/rice3.png" width = "50%">


> [!TIP]
> Check out [MyFetch](https://github.com/elifouts/MyFetch) now!

This contains My **Arch** Linux Dotfiles for a clean-looking lightweight **Hyprland** setup.

***ENJOY!!***

-Eli F.


> [!WARNING] 
>  
> All Configurations were meant to be used with `Pywal`
>

If you do not want this, **you can remove it in the given applications `style.css` and add valid color values.** Although I highly recommend `Pywal` It's Pretty cool!

# Install

> [!CAUTION]
> 
> This script is experimental and might not work properly. Please make sure you know what you are doing ***Please Please Please***
<details>
  <summary>Arch Install Script</summary>
  
- With this script you should be able to install everything together, or the applications and their configs individually.
- Dont worry it only really installs what is needed unless you select the everything script.

  ```
  cd && git clone https://github.com/elifouts/Dotfiles.git
  cd ~/Dotfiles/InstallScripts
  chmod +x install.sh
  ./install.sh
  ```  
</details>


## My Applications




<details>
  
  <summary>🚥 Waybar</summary>
  
![waybar1](https://github.com/elifouts/Dotfiles/blob/main/images/waybar1.png)
![waybar2](https://github.com/elifouts/Dotfiles/blob/main/images/waybar6.png)
![waybar3](https://github.com/elifouts/Dotfiles/blob/main/images/waybar4.png)
![waybar4](https://github.com/elifouts/Dotfiles/blob/main/images/waybar3.png)
![waybar5](https://github.com/elifouts/Dotfiles/blob/main/images/waybar2.png)

  
  ## Overview
  This is my minimal Waybar setup for Hyprland, designed to be clean and efficient. It includes all the essential features I wanted in Waybar. For additional needs like volume control, I use `swaync`, which can be triggered from Waybar. 

  ## Workspaces
  I’ve configured the workspaces so that if there is content on a workspace, the dot appears darker. This helps you keep track of your open content! Inspiration from [Gbar](https://github.com/scorpion-26/gBar).

  ![2025-01-04-030026_hyprshot](https://github.com/user-attachments/assets/31668572-b35d-4acb-8525-8cb0e5669101)
  
  ## Expanding Waybar
  In the screenshot below, you’ll see a method to hide and reveal certain widgets you don’t need all the time. You can easily add or remove widgets in `~/.config/waybar/config` under the `group/expand` section.
  
  - **Network Widget**: I’ve configured it to not display your IP by default (it did that for some reason). Clicking the network widget opens `nmtui` in `kitty`.
  
  - **Hyprpicker Widget**: This custom widget lets you use `hyprpicker`, display values when hovered, and copy the hex value to your clipboard.
    
    ![image](https://github.com/user-attachments/assets/f8c723c0-a9c9-4fa6-a3c8-bda06e81f81d)

  ## Configuration
  
  ### *How To Install*
1. **Install [Waybar](https://github.com/Alexays/Waybar)**
2. Copy the `Dotfiles/.config/waybar` folder into `~/.config`

***NOTE*** *Make sure you have a Pywal theme set or else waybar will not load*

  ### Dependencies
  ```
  waybar
  hyprpicker
  pywal
  blueman
  bluez
  networkmanager
  swaync
  yay
  ```

  ### How to Add Blur

  Add this to the end of your `hyprland.conf`:
  
  ```
  layerrule = blur, waybar
  layerrule = ignorezero, waybar
  layerrule = ignorealpha 0.5, waybar
  ```

</details>


<details>
  <summary>🔍 Wofi</summary>
    <img src="https://github.com/elifouts/Dotfiles/blob/main/images/wofi1.png" width = "35%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wofi2.png" width = "35%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wofi3.png" width = "35%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wofi4.png" width = "35%">


  ## Configuration

  ### *How To Install*
  
1. **Install `Wofi`:**

   ```
    sudo pacman -S wofi
   ```
   
2. Copy the `Dotfiles/.config/wofi` folder into `~/.config`
3. **Launching Wofi**
    - I launch wofi like this:
   
      ```config
      wofi --show drun -n
      ```

### How to Add Blur to Wofi

Add this to the end of your `hyprland.conf`:

```
layerrule = blur, wofi
layerrule = ignorezero, wofi
layerrule = ignorealpha 0.5, wofi
```

### `Pywal` with Wofi

**If you want Pywal colors**
- In `~/.config/wofi/style.css`, update the hostname in the file path to your `pywal` colors.
**If you don't want Pywal colors**
- You can remove the top line of your style.css and replace the colors at the top with your desired choice.
</details>

<details>
  <summary>🔔 Swaync</summary>
  <img src="https://github.com/elifouts/Dotfiles/blob/main/images/swaync1.png" width = "20%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/swaync2.png" width = "20%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/swaync3.png" width = "20%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/swaync4.png" width = "20%">


  ## Configuration
  
  ### *How To Install*
  
1. **Install [Swaync](https://github.com/ErikReider/SwayNotificationCenter)**
2. Copy the `Dotfiles/.config/swaync` folder into `~/.config`

  ### Dependencies for `Swaync`
  ```
  swaync
  pywal
  gvfs
  libnotify
  ```
  
  ### How to Add Blur to Swaync
  
  Add this to the end of your `hyprland.conf`:
  
  ```
  layerrule = blur, swaync-control-center
  layerrule = blur, swaync-notification-window
  layerrule = ignorezero, swaync-control-center
  layerrule = ignorezero, swaync-notification-window
  layerrule = ignorealpha 0.5, swaync-control-center
  layerrule = ignorealpha 0.5, swaync-notification-window
  ```

</details>

<details>
  <summary>🔒 Hyprlock</summary>
  <img src="https://github.com/elifouts/Dotfiles/blob/main/images/lock1.PNG" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/lock2.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/lock3.png" width = "50%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/lock4.png" width = "50%">
  
  ## Overview
    
  - Hyprlock uses the current wallpaper from Pywal to generate a background, displays a greeting with your username, and applies Pywal colors.
  - You can bind Hyprlock to a key, use it with `hypridle`, or configure it however you prefer.
  - If you want to configure `hypridle` as well, I’ve included a `hypridle.conf` file in the same directory as Hyprlock.

  ## Configuration
  
  ### *How To Install*
1. **Install [Hyprlock](https://github.com/hyprwm/hyprlock/)**
2. Copy `Dotfiles/.config/hypr/hyprlock.conf` to `~/.config/hypr`

</details>

<details>
  <summary>📝 Nvim</summary>
<img src="https://github.com/elifouts/Dotfiles/blob/main/images/nvim1.png" width = "30%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/nvim2.png" width = "30%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/nvim3.png" width = "30%">
  
## Overview

- This Neovim "rice" is a simplified version of Lazyvim, created with custom Lua files. It’s lightweight and includes only what you need. I just installed lazy and configured only the pluggins I wanted.
- It features:
  - Alpha-nvim
  - Pywal theme
  - Autocompletion
  - Lualine
  - Tabline
  - Glow
  - Noice
  - Mini-icons
  - Snacks
    - bigfile
    - indent
    - input
    - quickfile
    - scroll
    - statuscolumn
    - words
  - Neo-tree
  - Telescope
  - Treesitter
  - Gitsigns
  - Colorizer

### *How To Install*
1. **Install `Neovim`:**
    ```bash
    yay -S neovim
    ```
2. Copy `Dotfiles/.config/nvim` into `~/.config/`

3. Start `nvim` and watch it install all necessary components.

</details>

<details>
  <summary>🚪 Wlogout</summary>
  <img src="https://github.com/elifouts/Dotfiles/blob/main/images/wlogout1.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wlogout2.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wlogout3.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/wlogout4.png" width = "40%">
  
### *How To Install*
1. **Install `wlogout`:**
   
    ```bash
    yay -S wlogout
    ```
2. Copy `Dotfiles/.config/wlogout` into `~/.config/`
3. If not already set make sure you set a key bind in hyprland.conf to launch wlogout.
</details>


<details>
  <summary>🖼️ Wallpaper Solution/Pywal</summary>
  
  ![image](https://github.com/user-attachments/assets/7cbe58e3-7226-4537-8e69-bb316cdfaebc)





## General Overview

- The `wallpaper.sh` script in `Dotfiles/.config/hypr/` applies a wallpaper using `swww` and sets the `Pywal` theme. It also updates Kitty's color scheme, Cava, nvim (if configured), and any other application using `pywal`.
- The script uses Wofi to select wallpapers. I have not been able to optimize the wallpaper loading so it might load slowly but it should work.

### Dependencies

- `swww`
- `pywal`
- `wofi`
- `fd`

### *How To Install*
- Install dependencies:

     ```bash
     yay -S swww pywal wofi fd
     ```
     
1. **Copy Configuration Files:**
   - Copy `Dotfiles/.config/wal` to `~/.config/` to provide `pywal` with the necessary template for Hyprland.
   - Copy `Dotfiles/.config/hypr/wallpaper.sh` to `~/.config/hypr/`.
   - Copy `Dotfiles/.config/wofi` to `~/.config/`. ( Check the Wofi tab for how to configure blur )

2. Bind the script to a key combination of your choice to easily change your wallpaper.

3. Make sure to add the following line to your `hyprland.conf`:

     ```bash
     exec-once = swww-daemon
     ```

  
</details>

<details>
  <summary>🦊 Pywalfox</summary>
  <img src="https://github.com/elifouts/Dotfiles/blob/main/images/fox1.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/fox2.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/fox3.png" width = "40%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/fox4.png" width = "40%">

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
4. Run `pywalfox update` in your terminal or add it to a script to update the `Firefox` theme after generating `Pywal` colors.


</details>

<details>
  <summary>🚀 Starship</summary>
    <img src="https://github.com/elifouts/Dotfiles/blob/main/images/starship.png" width = "30%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/starship1.png" width = "30%"><img src="https://github.com/elifouts/Dotfiles/blob/main/images/starship2.png" width = "30%">

## Overview

  - This is a custom Starship config that is minimal but yet has everything you need/want from a terminal prompt.

 ### *How To Install*
1. **Install [Starship](https://github.com/starship/starship?tab=readme-ov-file#-installation)**
2. Copy the `Dotfiles/.config/starship.toml` folder into `~/.config`
3. Add this to your `.bashrc` file:

   ```bash
    eval "$(starship init bash)"
   ```
   - Or go [here](https://github.com/starship/starship?tab=readme-ov-file#step-2-set-up-your-shell-to-use-starship) to find what you need for your shell.
</details>

<details>
  <summary>🎨 GTK Themes</summary>
  
  ### I use these GTK themes
  
  - Widget Theme: Materia-dark
  - Icon Theme: Qogir-dark
</details>

## Keybinds

`Mod+Q` - Open Terminal

`Mod+R` - Open App Launcher (Wofi)

`Mod+M` - Quit Hyprland
 
`Mod+B` - Close

`Mod+F` - Fullscreen

`Mod+V` - Popout

`Mod+Space` - Terminal Scratch Pad

`Mod-E` - Opens Thunar

`Alt+B` - Waybar Style Selector (Wofi)

`Alt+A` - Toggle Waybar

`Alt+R` - Reload Swaync

`Alt+W` - Wallpaper Selector (Wofi)

`Alt+Tab` - wlogout

> [!NOTE]
> This isnt every Keybind. Just some highlighted ones.
> 
> More can be found and changed in `~/.confing/hypr/hyprland.conf`

## Help

<details>
  <summary>Apps Fuzzy or Blurry?</summary>
  
  #### This may be because they need to be run with Wayland or are Electron applications
  
  - The solution I found is to add the following to `/usr/share/applications/{app}.desktop` after `exec=/app/executable/app`
  - Works on `Spotify` `Discord`
  
  ```
  --enable-features=UseOzonePlatform --ozone-platform=wayland --uri=%U
  ```

  - ***NOTE*** This gets removed if the app is redownloaded! I'm not sure how to make this a global thing. I have tried and failed. Help?

</details>

<details>
  <summary>Cant Find a file that is in .cache?</summary>

### You may be looking for a file that looks something like this:

`@import url('/home/eli/.cache/wal/colors-waybar.css');`

That file is one of many that is created by `Pywal`. Try replacing eli with your $USER and see if that works. Alternatively, you can do one of the following:

- create your own file which would look something like this:
```
@define-color background <Replace>;
@define-color color0 <Replace>;
@define-color color9 <Repace>;
```
Instead of those colors, you can use whichever color is needed by the style.css file.

- create the colors manually in the style.css files you took those paths from. 
```
@define-color <ColorName> <Color>;
```

- Find the sections of that file that are calling the missing file, such as `$color2` or `@color2` and replace it with a valid value.

</details>



## Notes
- If you want Cava to work with `Pywal`, it is already in the wallpaper.sh, but find the section needed and copy the config file I have into your `~/.config` directory.
- Am about to start working on an eww dashboard so look out for that
<details>
  <summary>📥 Download Suggestions</summary>
  
  - This is everything I think is essential to have. At least for me. I would suggest doing your own research before blindly downloading everything here. This is here just so if I break my computer which we all know I will, I can remember what I need/want!
    
```txt
git
wlogout
nvim
zip unzip
pipewire
hyprpicker
hypridle
hyprlock
hyprshot
code
bpytop
nerdfetch
yay
wl-clipboard
wl-copy
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
swaync
pywal
waybar
swww
blueman
bluez
networkmanager
gvfs
libnotify
pavucontrol
pipewire-pulse
nwg-look
wofi
s-tui
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
  bottom
  ```
</details>

