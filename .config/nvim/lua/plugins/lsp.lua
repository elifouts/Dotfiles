return {
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
        },
        opts = {
            ensure_installed = {
                "lua_ls",
                "bashls",
                "jsonls",
                "marksman",
            },
            automatic_enable = true,
        },
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local servers = {
                lua_ls = {
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                            workspace = {
                                checkThirdParty = false,
                            },
                        },
                    },
                },
                bashls = {
                    capabilities = capabilities,
                },
                jsonls = {
                    capabilities = capabilities,
                },
                marksman = {
                    capabilities = capabilities,
                },
            }

            for server, opts in pairs(servers) do
                vim.lsp.config(server, opts)
            end
            vim.lsp.enable(vim.tbl_keys(servers))

            vim.diagnostic.config({
                virtual_text = true,
                signs = true,
                underline = true,
                update_in_insert = false,
                severity_sort = true,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
                callback = function(event)
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, { buffer = event.buf, desc = desc })
                    end

                    map("gd", vim.lsp.buf.definition, "LSP: Go to Definition")
                    map("gr", vim.lsp.buf.references, "LSP: References")
                    map("gI", vim.lsp.buf.implementation, "LSP: Go to Implementation")
                    map("K", vim.lsp.buf.hover, "LSP: Hover")
                    map("<leader>rn", vim.lsp.buf.rename, "LSP: Rename Symbol")
                    map("<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
                    map("<leader>lf", function()
                        vim.lsp.buf.format({ async = true })
                    end, "LSP: Format Buffer")
                    map("[d", vim.diagnostic.goto_prev, "Diagnostics: Previous")
                    map("]d", vim.diagnostic.goto_next, "Diagnostics: Next")
                    map("<leader>ld", vim.diagnostic.open_float, "Diagnostics: Line Details")
                end,
            })
        end,
    },
}
