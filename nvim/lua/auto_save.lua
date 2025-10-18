-- 디바운스 autosave (실시간 느낌, 300ms 모아서 저장)

-- lua/autosave.lua (새 파일로 두고 require 하거나, 기존 au.lua에 교체)
vim.g.autosave_enabled = true
vim.g.autosave_delay = 1000 -- ms

local group = vim.api.nvim_create_augroup("AutosaveDebounced", { clear = true })

-- 타이머 보관소 (버퍼번호 -> uv_timer)
local timers = {}

local function should_save(buf)
  if not vim.g.autosave_enabled then return false end
  local bo = vim.bo[buf]
  if bo.modifiable == false or bo.readonly == true then return false end
  if bo.buftype ~= "" then return false end           -- help/quickfix 등 제외
  if vim.api.nvim_buf_get_name(buf) == "" then return false end -- 이름 없는 버퍼 제외
  if vim.fn.getcmdwintype() ~= "" then return false end          -- cmdwin 열림
  return true
end

local function schedule_save(buf)
  -- 기존 타이머 정리
  local t = timers[buf]
  if t then t:stop(); t:close(); timers[buf] = nil end

  -- 새 타이머 시작
  t = vim.loop.new_timer()
  timers[buf] = t
  t:start(vim.g.autosave_delay, 0, function()
    -- Neovim API는 메인 스레드에서
    vim.schedule(function()
      if vim.api.nvim_buf_is_loaded(buf)
         and should_save(buf)
         and vim.bo[buf].modified then
        pcall(vim.cmd, "silent keepalt keepjumps noautocmd write")
      end
      -- 1회용이므로 닫고 제거
      if timers[buf] then
        timers[buf]:stop()
        timers[buf]:close()
        timers[buf] = nil
      end
    end)
  end)
end

-- 내용 변경 시 디바운스 저장
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
  group = group,
  callback = function(args)
    schedule_save(args.buf)
  end,
})

-- 포커스 잃거나 버퍼 떠날 때도 마지막으로 한 번 더 저장
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  group = group,
  callback = function(args)
    if should_save(args.buf) and vim.bo[args.buf].modified then
      pcall(vim.cmd, "silent keepalt keepjumps noautocmd write")
    end
  end,
})

