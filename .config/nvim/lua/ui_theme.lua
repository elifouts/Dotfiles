local M = {}
local state = require("settings_state")

local wal_file = vim.fn.expand("~/.cache/wal/colors-wal.vim")
local fallback = "tokyonight"

function M.has_pywal()
    return vim.fn.filereadable(wal_file) == 1
end

local function refresh_bars()
    vim.cmd("redrawstatus")
    local ok_lualine, lualine = pcall(require, "lualine")
    if ok_lualine and lualine.refresh then
        lualine.refresh({
            place = { "statusline", "tabline", "winbar" },
            trigger = "colorscheme",
        })
    end
end

local function sync_lualine_theme(theme_name)
    local ok_lualine, lualine = pcall(require, "lualine")
    if not ok_lualine or not lualine.get_config or not lualine.setup then
        return
    end

    local cfg = lualine.get_config()
    if not cfg or type(cfg) ~= "table" then
        return
    end

    cfg.options = cfg.options or {}
    cfg.options.theme = theme_name
    lualine.setup(cfg)
end

local function apply_pywal_plugin_overrides()
    local color_bg = vim.g.background or "#000000"
    local color_fg = vim.g.foreground or "#ffffff"
    local color1 = vim.g.color1 or color_fg
    local color5 = vim.g.color5 or color_fg
    local color9 = vim.g.color9 or color_fg

    vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { fg = color9 })
    vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { fg = color5 })
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = color_fg, bg = color_bg })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = color_fg, bg = color_bg })
    vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = color1, bg = color_bg })
end

local function set_colorscheme(theme)
    local ok, err = pcall(vim.cmd, "colorscheme " .. theme)
    if not ok then
        vim.notify("Theme not available: " .. theme .. " (" .. tostring(err) .. ")", vim.log.levels.ERROR)
        return false
    end
    return true
end

-- Fallback themes should not replace the saved choice.
function M.apply_theme(theme, persist)
    if not set_colorscheme(theme) then
        return
    end

    vim.g.current_theme = theme
    if persist ~= false then
        state.set("theme", theme)
    end
    sync_lualine_theme("auto")
    refresh_bars()
end

function M.use_pywal()
    if not M.has_pywal() then
        vim.notify("pywal colors not found (run wal first), using " .. fallback, vim.log.levels.WARN)
        M.apply_theme(fallback, false)
        return
    end
    vim.cmd.source(wal_file)

    if not set_colorscheme("pywal") then
        local ok, pywal = pcall(require, "pywal")
        if ok and pywal.setup then
            pywal.setup()
            vim.g.colors_name = "pywal"
            vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "pywal" })
        else
            return
        end
    end

    vim.g.current_theme = "pywal"
    state.set("theme", "pywal")

    vim.schedule(function()
        apply_pywal_plugin_overrides()
        sync_lualine_theme("pywal-nvim")
        refresh_bars()
    end)
end

function M.init()
    vim.g.current_theme = state.get("theme", "pywal")

    vim.api.nvim_create_user_command("ThemePywal", function()
        M.use_pywal()
    end, { desc = "Use pywal for all highlights" })

    vim.api.nvim_create_user_command("ThemeFileTokyo", function()
        M.apply_theme("tokyonight")
    end, { desc = "Switch full theme to tokyonight" })

    vim.api.nvim_create_user_command("ThemeFileGruvbox", function()
        M.apply_theme("gruvbox")
    end, { desc = "Switch full theme to gruvbox" })

    vim.api.nvim_create_user_command("ThemeFileKanagawa", function()
        M.apply_theme("kanagawa")
    end, { desc = "Switch full theme to kanagawa" })

    vim.api.nvim_create_user_command("ThemeFileCatppuccin", function()
        M.apply_theme("catppuccin-macchiato")
    end, { desc = "Switch full theme to catppuccin macchiato" })

    vim.api.nvim_create_user_command("ThemeFileRosePine", function()
        M.apply_theme("rose-pine")
    end, { desc = "Switch full theme to rose-pine" })

    vim.api.nvim_create_user_command("ThemeFileNord", function()
        M.apply_theme("nord")
    end, { desc = "Switch full theme to nord" })

    vim.api.nvim_create_user_command("ThemeFileEverforest", function()
        M.apply_theme("everforest")
    end, { desc = "Switch full theme to everforest" })

    vim.api.nvim_create_user_command("ThemeFileOneDark", function()
        M.apply_theme("onedark")
    end, { desc = "Switch full theme to onedark" })

    vim.api.nvim_create_user_command("ThemeFileCarbonfox", function()
        M.apply_theme("carbonfox")
    end, { desc = "Switch full theme to carbonfox" })

    vim.api.nvim_create_user_command("ThemeFileGithub", function()
        M.apply_theme("github_dark_dimmed")
    end, { desc = "Switch full theme to github dark dimmed" })

    vim.api.nvim_create_user_command("ThemeFileVSCode", function()
        M.apply_theme("vscode")
    end, { desc = "Switch full theme to vscode" })

    vim.api.nvim_create_user_command("ThemeFileGruvboxMaterial", function()
        M.apply_theme("gruvbox-material")
    end, { desc = "Switch full theme to gruvbox material" })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("ui-theme-refresh-bars", { clear = true }),
        callback = function()
            refresh_bars()
        end,
    })

    vim.schedule(function()
        local startup_theme = state.get("theme", "pywal")
        if startup_theme == "pywal" and not M.has_pywal() then
            M.apply_theme(fallback, false)
        elseif startup_theme == "pywal" then
            M.use_pywal()
        else
            M.apply_theme(startup_theme)
        end
    end)
end

return M
