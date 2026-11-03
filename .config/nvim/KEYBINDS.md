# Neovim Keybinds

Leader key: `<Space>`

## Completion (nvim-cmp)

- Mode: insert/select
- Inline preview: enabled (ghost text)
- Modes: `inline-only` (default), `menu + inline`, `off`
- `<C-Space>`: Trigger completion menu
- `<C-e>`: Abort completion
- `<C-b>`: Scroll docs up
- `<C-f>`: Scroll docs down
- `<C-y>`: Confirm selected completion item (or first item)
- `<CR>`: Confirm explicitly selected completion item only
- `<Tab>`: Accept current completion item, or snippet jump/expand
- `<S-Tab>`: Previous completion item, or snippet jump backward
- `:CmpToggleMenu`: Toggle dropdown menu on/off
- `:CmpToggleMode`: Cycle completion mode (`inline -> menu -> off`)
- `:CmpModeInline`: Set inline-only mode
- `:CmpModeMenu`: Set menu + inline mode
- `:CmpModeOff`: Fully disable completion

## File Navigation

- Mode: normal
- `<C-n>`: Reveal current file in Neo-tree (left)
- `<C-p>`: Telescope find files
- `<A-f>`: Telescope live grep
- `<A-d>`: Telescope directory picker and `cd` into selected folder
- `<leader>/`: Telescope fuzzy find in current buffer

## Telescope (Find)

- Mode: normal
- `<leader>ff`: Find files
- `<leader>fg`: Live grep
- `<leader>fb`: Find buffers
- `<leader>fh`: Help tags
- `<leader>fo`: Recent files
- `<leader>fr`: Resume last picker
- `<leader>fk`: Find keymaps
- `<leader>fc`: Find commands
- `<leader>fd`: Find diagnostics
- `<leader>fD`: Find directory and `cd`

## AI (Claude)

- Mode: normal
- `<leader>ap`: Toggle Claude panel
- `<leader>ao`: Focus Claude panel
- `<leader>ar`: Resume a session
- `<leader>ac`: Continue last session
- `<leader>an`: Start a new session
- `<leader>am`: Pick model
- `<leader>ab`: Add current file
- `<leader>aa`: Accept Claude diff
- `<leader>ad`: Reject Claude diff
- Visual `<leader>as`: Send selection to Claude

## LSP (buffer-local, active when an LSP attaches)

- Mode: normal
- `gd`: Go to definition
- `gr`: Find references
- `gI`: Go to implementation
- `K`: Hover documentation
- `<leader>rn`: Rename symbol
- `<leader>ca`: Code action
- `<leader>lf`: Format buffer
- `<leader>ld`: Line diagnostics popup
- `[d`: Previous diagnostic
- `]d`: Next diagnostic

## Snacks

- Mode: normal
- `<leader>z`: Toggle Zen mode
- `<leader>s`: Toggle scratch buffer
- `<leader>S`: Select scratch buffer
- `<C-/>`: Toggle floating terminal
- `<leader>gb`: Git blame line
- `<leader>gf`: Lazygit current file history
- `<leader>gg`: Open Lazygit
- `<leader>gl`: Lazygit log (cwd)
- `<leader>N`: Open Neovim news window

## Snacks (normal + visual)

- `<leader>gB`: Git browse

## Snacks Toggles (created on VeryLazy)

- Mode: normal
- `<leader>us`: Toggle spelling
- `<leader>uw`: Toggle line wrap

## Keybind Discovery

- Mode: normal
- `<leader>?`: Show buffer-local keymaps with which-key

## UI Theme Controls

- Mode: normal
- `<leader>utp`: Full pywal theme (UI + file colors)
- `<leader>utt`: Full TokyoNight theme
- `<leader>utg`: Full Gruvbox theme
- `<leader>utk`: Full Kanagawa theme
- `<leader>utc`: Full Catppuccin Macchiato theme
- `<leader>utr`: Full Rose Pine theme
- `<leader>utn`: Full Nord theme
- `<leader>ute`: Full Everforest theme
- `<leader>uto`: Full OneDark theme
- `<leader>utf`: Full Carbonfox theme
- `<leader>uth`: Full GitHub Dark Dimmed theme
- `<leader>utv`: Full VSCode theme
- `<leader>utm`: Full Gruvbox Material theme

## Completion UI Controls

- Mode: normal
- `<leader>ucc`: Cycle completion mode (inline-only -> menu + inline -> off)
- `<leader>uci`: Set completion to inline-only
- `<leader>ucm`: Set completion to menu + inline
- `<leader>uco`: Turn completion fully off

## Markdown Visualization

- Mode: normal
- `<leader>umt`: Toggle markview preview (persistent)
- `<leader>umh`: Toggle markview hybrid mode (persistent)
- `<leader>umr`: Re-render markview

## Persistent Settings

- Theme choice is restored on startup.
- Completion mode is restored on startup.
- Markview preview/hybrid toggles are restored on startup.
- `wrap` (`<leader>uw`) and `spell` (`<leader>us`) are restored on startup.

## Editor Shortcuts

- Mode: normal
- `<leader>ws`: Write buffer
- `<leader>qq`: Quit all
- `<leader>qQ`: Force quit all
- `<leader>xl`: Open Lazy
- `<leader>xm`: Open Mason

## Dashboard Shortcuts (Alpha start screen)

These are active on the Alpha dashboard page, not global normal-mode mappings.

- `e`: New file
- `f`: Find file
- `F`: Find folder
- `r`: Recent files
- `c`: Open Neovim config search
- `l`: Open Lazy
- `h`: Open Hypr config search
- `q`: Quit Neovim

## Commands (not keybinds)

- `:Mason`
- `:Typr`
- `:TyprStats`
- `:ClaudeCode`
- `:ClaudeCodeFocus`
- `:ThemePywal`
- `:ThemeFileTokyo`
- `:ThemeFileGruvbox`
- `:ThemeFileKanagawa`
- `:ThemeFileCatppuccin`
- `:ThemeFileRosePine`
- `:ThemeFileNord`
- `:ThemeFileEverforest`
- `:ThemeFileOneDark`
- `:ThemeFileCarbonfox`
- `:ThemeFileGithub`
- `:ThemeFileVSCode`
- `:ThemeFileGruvboxMaterial`
