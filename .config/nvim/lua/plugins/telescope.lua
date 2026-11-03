return {
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            -- Telescope 0.1.x expects this parser API.
            local ok_parsers, ts_parsers = pcall(require, "nvim-treesitter.parsers")
            if ok_parsers and ts_parsers and ts_parsers.ft_to_lang == nil then
                ts_parsers.ft_to_lang = function(ft)
                    if vim.treesitter and vim.treesitter.language then
                        if vim.treesitter.language.ft_to_lang then
                            return vim.treesitter.language.ft_to_lang(ft)
                        end
                        if vim.treesitter.language.get_lang then
                            return vim.treesitter.language.get_lang(ft)
                        end
                    end
                    return ft
                end
            end

            local ts_ok, ts_utils = pcall(require, "telescope.previewers.utils")
            if ts_ok and ts_utils then
                local original_ts_highlighter = ts_utils.ts_highlighter
                ts_utils.ts_highlighter = function(...)
                    local ok, _ = pcall(original_ts_highlighter, ...)
                    if not ok then
                        return
                    end
                end
            end

            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    preview = {
                        treesitter = true,
                    },
                },
                extensions = {
                    ["ui-select"] = require("telescope.themes").get_dropdown({}),
                },
            })
            telescope.load_extension("ui-select")

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Telescope: Find files" })
            vim.keymap.set("n", "<A-f>", builtin.live_grep, { desc = "Telescope: Live grep" })

            _G.search_and_scope_into_directory = function()
                builtin.find_files({
                    prompt_title = "Search Directories",
                    find_command = { "fd", "--type", "d", "--hidden", "--follow" },
                    attach_mappings = function(prompt_bufnr, map)
                        local actions = require("telescope.actions")
                        actions.select_default:replace(function()
                            local selection = require("telescope.actions.state").get_selected_entry()
                            vim.cmd("cd " .. selection.path)
                            actions.close(prompt_bufnr)
                        end)
                        return true
                    end,
                })
            end
            vim.keymap.set("n", "<A-d>", _G.search_and_scope_into_directory, { desc = "Telescope: Pick dir and cd" })

            vim.keymap.set("n", "<leader>/", function()
                local ok = pcall(builtin.current_buffer_fuzzy_find, require("telescope.themes").get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
                if not ok then
                    builtin.live_grep({ grep_open_files = true, prompt_title = "Grep Open Files" })
                end
            end, { desc = "Telescope: Fuzzy search in current buffer" })
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
    },
}
