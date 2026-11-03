return {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local dashboard = require("alpha.themes.dashboard")

        local function getCharLen(s, pos)
            local byte = string.byte(s, pos)
            if not byte then return nil end
            return (byte < 0x80 and 1)
                or (byte < 0xE0 and 2)
                or (byte < 0xF0 and 3)
                or (byte < 0xF8 and 4)
                or 1
        end

        local function applyColors(logo, colors, logoColors)
            dashboard.section.header.val = logo

            for key, color in pairs(colors) do
                local name = "Alpha" .. key
                vim.api.nvim_set_hl(0, name, color)
                colors[key] = name
            end

            dashboard.section.header.opts.hl = {}
            for i, line in ipairs(logoColors) do
                local highlights = {}
                local pos = 0
                for j = 1, #line do
                    local opos = pos
                    pos = pos + getCharLen(logo[i], opos + 1)
                    local color_name = colors[line:sub(j, j)]
                    if color_name then
                        table.insert(highlights, { color_name, opos, pos })
                    end
                end
                table.insert(dashboard.section.header.opts.hl, highlights)
            end
            return dashboard.opts
        end

        local function hl_fg(group, fallback)
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = true })
            if ok and hl and hl.fg then
                return string.format("#%06x", hl.fg)
            end
            return fallback
        end

        local function refresh_alpha_palette()
            local colors = {
                ["a"] = { fg = hl_fg("Identifier", "#a6e3a1") },
                ["b"] = { fg = hl_fg("Function", "#89b4fa") },
                ["c"] = { fg = hl_fg("Keyword", "#f38ba8") },
                ["d"] = { fg = hl_fg("Type", "#cba6f7") },
                ["e"] = { fg = hl_fg("String", "#f9e2af") },
            }

            for key, color in pairs(colors) do
                vim.api.nvim_set_hl(0, "Alpha" .. key, color)
            end

            pcall(vim.cmd, "AlphaRedraw")
        end

        local opts = applyColors({
            [[███████╗    ██████╗ ]],
            [[██╔════╝    ██╔═══╝ ]],
            [[█████╗      ██████╗ ]],
            [[██╔══╝      ██╔═══╝ ]],
            [[███████╗    ██║     ]],
            [[╚══════╝    ╚═╝     ]],
            [[N  E  O  V  I  M    ]],
        }, {
            ["a"] = { fg = "#a6e3a1" },
            ["b"] = { fg = "#89b4fa" },
            ["c"] = { fg = "#f38ba8" },
            ["d"] = { fg = "#cba6f7" },
            ["e"] = { fg = "#f9e2af" },
        }, {
            [[bbbbbbba    cccccca ]],
            [[bbaaaaaa    ccaaaaa ]],
            [[bbbbba      cccccca ]],
            [[bbaaaa      ccaaaaa ]],
            [[bbbbbbba    cca     ]],
            [[aaaaaaaa    aaa     ]],
            [[d  d  d  e  e  e    ]],
        })

        dashboard.section.buttons.val = {
            dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
            dashboard.button("f", "󰱼  > Find file", ":lua require('telescope.builtin').find_files({ hidden = true, no_ignore = true })<CR>"),
            dashboard.button("F", "󰥨  > Find folder", ":lua _G.search_and_scope_into_directory()<CR>"),
            dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
            dashboard.button("c", "  > Config", ":cd ~/.config/nvim | Telescope find_files<CR>"),
            dashboard.button("l", "󰒲 > Lazy", ":Lazy<CR>"),
            dashboard.button("q", "  > Quit", ":qa<CR>"),
        }

        if vim.fn.isdirectory(vim.fn.expand("~/.config/hypr")) == 1 then
            table.insert(dashboard.section.buttons.val, #dashboard.section.buttons.val,
                dashboard.button("h", "  > Settings", ":cd ~/.config/hypr | Telescope find_files<CR>"))
        end

        dashboard.section.footer.val = { "", "Welcome!" }

        require("alpha").setup(opts)
        refresh_alpha_palette()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("alpha-theme-palette", { clear = true }),
            callback = function()
                refresh_alpha_palette()
            end,
        })
    end,
}
