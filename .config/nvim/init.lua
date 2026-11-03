local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
vim.opt.termguicolors = true
vim.cmd("set number")
require("vim-options")
require("ui_settings").init()
require("notify_system").setup()
require("lazy").setup("plugins")
