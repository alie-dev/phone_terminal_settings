vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false
-- 자동 들여쓰기
vim.opt.autoindent = true
vim.opt.smartindent = true

-- 스왑파일 안생기게 (복구 안됌)
vim.opt.swapfile = false

vim.opt.linespace = 50
-- init.lua 등
vim.opt.expandtab = true -- 탭 대신 스페이스 입력
vim.opt.shiftwidth = 2 -- 자동 들여쓰기 폭
vim.opt.tabstop = 2 -- 탭 표시 폭
vim.opt.softtabstop = 2



-- italic 제거하기
-- Kill ALL italics (keep colors/styles as much as possible)
local function strip_italics()
  -- 모든 하이라이트 그룹 이름 가져오기
  local groups = vim.fn.getcompletion("", "highlight")

  for _, name in ipairs(groups) do
    -- link면 원본을 못 건드리니 link=false로 실제 값 가져오기
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and type(hl) == "table" and hl.italic then
      hl.italic = false
      -- 혹시 모를 legacy 키들 정리(환경 따라 남아있을 수 있음)
      hl.cterm = nil
      hl.gui = nil
      pcall(vim.api.nvim_set_hl, 0, name, hl)
    end
  end
end

-- colorscheme가 italic 다시 넣는 걸 매번 즉시 제거
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "UIEnter" }, {
  callback = function()
    strip_italics()
  end,
})



-- 🔄 외부 파일 변경 자동 반영 (libuv 파일 감시)
vim.opt.autoread = true

-- 각 버퍼의 파일 감시 핸들 저장
local watchers = {}

-- 버퍼 열릴 때 파일 감시 시작
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	callback = function(args)
		local bufnr = args.buf
		local filepath = vim.api.nvim_buf_get_name(bufnr)

		-- 빈 파일명이거나 특수 버퍼는 건너뛰기
		if filepath == "" or vim.bo[bufnr].buftype ~= "" then
			return
		end

		-- 이미 감시 중이면 건너뛰기
		if watchers[filepath] then
			return
		end

		-- libuv fs_event로 파일 감시
		local handle = vim.loop.new_fs_event()
		if not handle then
			return
		end

		watchers[filepath] = handle

		handle:start(filepath, {}, function(err, filename, events)
			if err then
				return
			end

			-- 파일 변경 감지되면 Neovim 메인 스레드에서 checktime 실행
			vim.schedule(function()
				-- 버퍼가 수정되지 않았을 때만 리로드
				if vim.api.nvim_buf_is_valid(bufnr) and not vim.bo[bufnr].modified then
					vim.cmd("checktime " .. bufnr)
				end
			end)
		end)
	end,
})

-- 버퍼 닫힐 때 감시 중단
vim.api.nvim_create_autocmd("BufDelete", {
	callback = function(args)
		local filepath = vim.api.nvim_buf_get_name(args.buf)
		if watchers[filepath] then
			watchers[filepath]:stop()
			watchers[filepath] = nil
		end
	end,
})

-- 포커스 얻을 때도 체크 (추가 안전장치) 및 영어 입력으로 전환
vim.api.nvim_create_autocmd("FocusGained", {
	callback = function()
		vim.cmd("checktime")
		-- 포커스를 얻을 때 영어 입력으로 전환
		vim.fn.system("im-select com.apple.keylayout.ABC")
	end,
})

-- 🔄 주기적 체크 (다른 터미널/에디터에서 변경된 경우 대응)
-- 1초마다 변경사항 확인 (매우 가벼운 작업이라 괜찮음)
local timer = vim.loop.new_timer()
timer:start(
	1000, -- 1초 후 시작
	1000, -- 1초마다 반복
	vim.schedule_wrap(function()
		-- 현재 버퍼가 수정되지 않았고, 일반 파일이면 체크
		local bufnr = vim.api.nvim_get_current_buf()
		if vim.bo[bufnr].buftype == "" and not vim.bo[bufnr].modified then
			vim.cmd("checktime")
		end
	end)
)

-- 파일 리로드 완료 시 알림
vim.api.nvim_create_autocmd("FileChangedShellPost", {
	callback = function(ev)
		vim.notify("Reloaded: " .. vim.fn.fnamemodify(ev.file, ":t"), vim.log.levels.INFO)
	end,
})

-- ⌨️  Insert 모드를 빠져나올 때 영어 입력으로 자동 전환
-- macOS에서 im-select 도구를 사용하여 입력 소스를 영어로 자동 전환합니다.
-- 한글이나 다른 언어로 타이핑 후 Normal 모드로 돌아갈 때 자동으로 영어로 전환되어
-- Vim 명령어를 바로 사용할 수 있습니다.
local default_input_source = "com.apple.keylayout.ABC" -- 영어 입력 소스 ID

vim.api.nvim_create_autocmd("InsertLeave", {
	callback = function()
		-- im-select를 사용하여 입력 소스를 영어로 전환
		vim.fn.system("im-select " .. default_input_source)
	end,
})
