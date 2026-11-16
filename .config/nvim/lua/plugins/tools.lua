return {
    "williamboman/mason.nvim",
    lazy = false,
    priority = 900,
    config = function(_, opts)
        require("mason").setup(opts)

        local bin = vim.fn.stdpath("data") .. "/bin"
        vim.env.PATH = bin .. ":" .. vim.env.PATH

        local reg = require("mason-registry")
        reg.refresh(function()
            local ok, pkg = pcall(reg.get_package, "tree-sitter-cli")
            if ok and not pkg:is_installed() then
                pkg:install()
            end
        end)

        if vim.fn.executable("rg") == 1 then
            return
        end
        local arch = vim.uv.os_uname().machine
        local target = arch == "aarch64" and "aarch64-unknown-linux-gnu" or "x86_64-unknown-linux-musl"
        local ver = "14.1.1"
        local name = "ripgrep-" .. ver .. "-" .. target
        local url = "https://github.com/BurntSushi/ripgrep/releases/download/" .. ver .. "/" .. name .. ".tar.gz"
        vim.fn.mkdir(bin, "p")
        vim.notify("installing ripgrep")
        vim.system({
            "sh", "-c",
            'curl -fsSL "$1" | tar -xz -C "$2" --strip-components=1 "$3/rg"',
            "sh", url, bin, name,
        }, {}, function(res)
            vim.schedule(function()
                if res.code == 0 then
                    vim.notify("ripgrep installed")
                else
                    vim.notify("ripgrep install failed: " .. (res.stderr or ""), vim.log.levels.ERROR)
                end
            end)
        end)
    end,
}
