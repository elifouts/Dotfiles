return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        -- Missing parsers install only when the CLI and a compiler are available.
        local can_install = vim.fn.executable("tree-sitter") == 1
            and (vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1)
        local available

        local function start(buf, lang)
            if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
                return
            end
            if vim.treesitter.query.get(lang, "indents") then
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
            callback = function(ev)
                local lang = vim.treesitter.language.get_lang(ev.match)
                if not lang then
                    return
                end
                if can_install and not vim.list_contains(ts.get_installed(), lang) then
                    available = available or ts.get_available()
                    if vim.list_contains(available, lang) then
                        ts.install(lang):await(vim.schedule_wrap(function()
                            start(ev.buf, lang)
                        end))
                        return
                    end
                end
                start(ev.buf, lang)
            end,
        })
    end,
}
