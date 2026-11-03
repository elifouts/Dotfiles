return {
  {
    "hrsh7th/cmp-nvim-lsp",
  },
  {
    "hrsh7th/cmp-buffer",
  },
  {
    "hrsh7th/cmp-path",
  },
  {
    "hrsh7th/cmp-cmdline",
  },
  {
    "saadparwaiz1/cmp_luasnip",
  },
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local state = require("settings_state")

      local function set_cmp_mode(mode)
        local normalized = (mode == "off" or mode == "inline" or mode == "menu") and mode or "inline"

        if normalized == "menu" then
          vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
        else
          -- cmp's custom view avoids E785 from native completion callbacks.
          vim.opt.completeopt = { "noselect", "noinsert" }
        end

        cmp.setup({
          enabled = function()
            return vim.g.cmp_mode ~= "off"
          end,
          completion = {
            autocomplete = normalized == "off" and false or { cmp.TriggerEvent.TextChanged },
          },
          experimental = {
            ghost_text = normalized ~= "off",
          },
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
        })

        vim.g.cmp_mode = normalized
        vim.g.cmp_menu_enabled = normalized == "menu"
        state.set("completion_mode", normalized)
      end

      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        preselect = cmp.PreselectMode.Item,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() or cmp.get_active_entry() then
              cmp.confirm({ select = true })
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              local mode = vim.api.nvim_get_mode().mode
              if vim.g.cmp_mode ~= "off" and (mode == "i" or mode == "ic" or mode == "ix" or mode == "s") then
                cmp.complete()
              else
                fallback()
              end
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
        experimental = {
          ghost_text = true,
        },
      })

      local mode_labels = {
        off = "off",
        inline = "inline-only",
        menu = "menu + inline",
      }

      local function notify_mode()
        vim.notify("Completion UI: " .. (mode_labels[vim.g.cmp_mode] or vim.g.cmp_mode), vim.log.levels.INFO)
      end

      _G.set_cmp_mode = function(mode)
        set_cmp_mode(mode)
        notify_mode()
      end

      _G.toggle_cmp_mode = function()
        local next_mode = "inline"
        if vim.g.cmp_mode == "inline" then
          next_mode = "menu"
        elseif vim.g.cmp_mode == "menu" then
          next_mode = "off"
        end

        set_cmp_mode(next_mode)
        notify_mode()
      end

      _G.toggle_cmp_menu = function()
        if vim.g.cmp_mode == "menu" then
          _G.set_cmp_mode("inline")
        else
          _G.set_cmp_mode("menu")
        end
      end

      vim.api.nvim_create_user_command("CmpToggleMenu", function()
        _G.toggle_cmp_menu()
      end, { desc = "Toggle cmp dropdown menu" })

      vim.api.nvim_create_user_command("CmpToggleMode", function()
        _G.toggle_cmp_mode()
      end, { desc = "Cycle cmp mode (inline -> menu -> off)" })

      vim.api.nvim_create_user_command("CmpModeInline", function()
        _G.set_cmp_mode("inline")
      end, { desc = "Set cmp mode to inline-only" })

      vim.api.nvim_create_user_command("CmpModeMenu", function()
        _G.set_cmp_mode("menu")
      end, { desc = "Set cmp mode to menu + inline" })

      vim.api.nvim_create_user_command("CmpModeOff", function()
        _G.set_cmp_mode("off")
      end, { desc = "Turn completion fully off" })

      set_cmp_mode(state.get("completion_mode", "inline"))

      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      local ok_cmp_autopairs, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
      if ok_cmp_autopairs then
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },
}
