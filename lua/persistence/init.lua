local Config = require("persistence.config")

local M = {}

local e = vim.fn.fnameescape

function M.get_current()
  local pattern = "/"
  if vim.fn.has("win32") == 1 then
    pattern = "[\\:]"
  end
  local name = vim.fn.getcwd():gsub(pattern, "%%")
  return Config.options.dir .. name .. ".vim"
end

function M.get_last()
  local sessions = M.list()
  table.sort(sessions, function(a, b)
    return vim.loop.fs_stat(a).mtime.sec > vim.loop.fs_stat(b).mtime.sec
  end)
  return sessions[1]
end

function M.setup(opts)
  Config.setup(opts)
  M.start()
end

function M.start()
  vim.cmd([[
    augroup Persistence
      autocmd!
      autocmd VimLeavePre * lua require("persistence").save()
    augroup end
  ]])
end

function M.stop()
  vim.cmd([[
  autocmd! Persistence
  augroup! Persistence
  ]])
end

function M.save()
  -- 返回當前緩沖區個數
  --   https://stackoverflow.com/questions/17931507/vimscript-number-of-listed-buffers
  --   :echo len(getbufinfo({'buflisted':1}))
  --   :lua print(vim.fn.len(vim.fn.getbufinfo({buflisted = 1})))
  -- 獲取當前buf的文件名
  --   vim.api.nvim_buf_get_name(0)
  -- 獲取當前buf的行數
  --   nvim_buf_line_count(0)

  -- 判斷當前bur list個數,如果為0或者為1並名字和行數為空的時候不保存session
  -- 在nvchad打開Startify的時候,馬上關閉(目前buf list數量為0), 跳過保存session
  local buf_list_len = vim.fn.len(vim.fn.getbufinfo { buflisted = 1 })
  if (buf_list_len == 0)
    or (buf_list_len == 1
      and (vim.api.nvim_buf_get_name(0) == "" or vim.api.nvim_buf_line_count(0) == 1))
  then return end

  local tmp = vim.o.sessionoptions
  vim.o.sessionoptions = table.concat(Config.options.options, ",")
  vim.cmd("mks! " .. e(M.get_current()))
  vim.o.sessionoptions = tmp
end

function M.load(opt)
  opt = opt or {}
  local sfile = opt.last and M.get_last() or M.get_current()
  if sfile and vim.fn.filereadable(sfile) ~= 0 then
    vim.cmd("silent! source " .. e(sfile))
  end
end

function M.list()
  return vim.fn.glob(Config.options.dir .. "*.vim", true, true)
end

return M
