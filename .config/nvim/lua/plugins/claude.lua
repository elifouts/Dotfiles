return {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSend", "ClaudeCodeSendText", "ClaudeCodeOpen", "ClaudeCodeAdd", "ClaudeCodeSelectModel" },
    opts = {
        terminal = {
            split_side = "right",
            split_width_percentage = 0.35,
        },
    },
    keys = {
        { "<leader>ap", "<cmd>ClaudeCode<cr>", desc = "Claude: Toggle Right Panel" },
        { "<leader>ao", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: Focus Panel" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: Resume Session" },
        { "<leader>ac", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: Continue Last Chat" },
        {
            "<leader>an",
            function()
                local term = require("claudecode.terminal")
                local running = term.get_active_terminal_bufnr and term.get_active_terminal_bufnr()
                vim.cmd("ClaudeCodeOpen")
                if running then
                    vim.cmd("ClaudeCodeSendText /clear")
                end
            end,
            desc = "Claude: New Session",
        },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Claude: Pick Model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: Add This File" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: Send Selection" },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: Accept Diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: Deny Diff" },
    },
}
