vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false

-- 스왑파일 안생기게 (복구 안됌)
vim.opt.swapfile = false

vim.opt.linespace = 50
-- init.lua 등
vim.opt.expandtab = true -- 탭 대신 스페이스 입력
vim.opt.shiftwidth = 2 -- 자동 들여쓰기 폭
vim.opt.tabstop = 2 -- 탭 표시 폭
vim.opt.softtabstop = 2

-- 더 신뢰도 높게: 외부 변경 자동 반영
vim.opt.autoread = true
vim.opt.updatetime = 1000 -- CursorHold/InsertHold가 1초에 한 번씩 트리거되도록

local function safe_checktime()
	-- 현재 버퍼가 수정 중이면 자동 덮어쓰기 금지
	local buf = vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_get_option(buf, "modified") then
		return
	end
	-- 터미널/quickfix 등 특수 버퍼는 패스
	if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then
		return
	end
	pcall(vim.cmd, "checktime")
end

-- 포커스/버퍼/윈도 진입 + 커서 머묾 + 터미널 닫힘 등 광범위 훅
vim.api.nvim_create_autocmd(
	{ "FocusGained", "BufEnter", "BufWinEnter", "WinEnter", "CursorHold", "CursorHoldI", "TermClose", "TermEnter" },
	{ callback = safe_checktime }
)

-- 디스크에서 실제로 다시 읽은 뒤 알림
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	callback = function(ev)
		vim.notify("Reloaded from disk: " .. ev.file, vim.log.levels.INFO)
	end,
})

-- 디스크와 버퍼가 둘 다 바뀐 충돌 상황 안내 (강제 :e! 또는 :w 유도)
vim.api.nvim_create_autocmd("FileChangedShell", {
	callback = function()
		vim.notify("File changed on disk. Use :e! to reload, or :w to overwrite disk.", vim.log.levels.WARN)
	end,
})
