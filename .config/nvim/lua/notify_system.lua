local M = {}
M.history = {}

local L = vim.log.levels
local urgency = {
  [L.TRACE] = "low", [L.DEBUG] = "low",
  [L.INFO] = "normal", [L.WARN] = "normal",
  [L.ERROR] = "critical",
}

local LOG = "/tmp/nvim-notify.log"

local function dbg(line)
  local f = io.open(LOG, "a")
  if f then
    f:write(os.date("%H:%M:%S ") .. line .. "\n")
    f:close()
  end
end

local function esc(s)
  s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
  return s
end

function M.setup()
  if vim.fn.executable("notify-send") == 0 then
    dbg("notify-send not found, override NOT installed")
    return
  end

  local original = vim.notify
  dbg("override installed")

  vim.notify = function(msg, level, opts)
    level = level or L.INFO
    opts = opts or {}
    msg = tostring(msg)

    dbg(string.format("level=%s msg=%s", level,
      (msg:sub(1, 90):gsub("\n", " "))))

    table.insert(M.history, msg)

    local function fallback()
      vim.schedule(function() original(msg, level, opts) end)
    end

    local ok, err = pcall(vim.system, {
      "notify-send",
      "-a", "Neovim",
      "-u", urgency[level] or "normal",
      "-A", "copy=Copy",
      "-w",
      opts.title or "Neovim",
      esc(msg),
    }, { text = true }, function(res)
      dbg("notify-send exit=" .. tostring(res.code) .. " stderr=" .. tostring(res.stderr))
      if res.code ~= 0 then
        fallback()
        return
      end
      if vim.trim(res.stdout or "") == "copy" then
        vim.schedule(function() vim.fn.setreg("+", msg) end)
      end
    end)

    if not ok then
      dbg("vim.system failed: " .. tostring(err))
      fallback()
    end
  end
end

vim.api.nvim_create_user_command("NotifyCopy", function()
  local last = M.history[#M.history]
  if last then
    vim.fn.setreg("+", last)
  end
end, { desc = "Copy last notification" })

return M
