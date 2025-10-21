-- keymaps.lua (cleaned)
-- =========================================================
-- Aliases / Requires
-- =========================================================
local map = vim.keymap.set
local motions = require("motions") -- 사용자 모듈 (smart_w/b, lsp_supports, project_root 등)

-- 안전한 require (미설치/지연 로드 대비)
local function safe_require(mod)
	local ok, m = pcall(require, mod)
	return ok and m or nil
end

-- 공통: 진단 팝업 옵션
local diag_float_opts = { border = "rounded", focus = false, source = "if_many" }

-- =========================================================
-- 기본 편의 키
-- =========================================================

-- 버퍼 이동 (WezTerm: Cmd+Shift+[ / ] → Alt+{ / Alt+})
map("n", "<M-{>", "<cmd>bprevious<CR>", { silent = true, desc = "Prev buffer" })
map("n", "<M-}>", "<cmd>bnext<CR>", { silent = true, desc = "Next buffer" })

-- 파일 트리 (WezTerm: Cmd+1 → Alt+1)
map("n", "<M-1>", "<cmd>Neotree toggle left reveal_force_cwd<CR>", { silent = true, desc = "Toggle file tree" })

-- 버퍼 닫기 / 기타 버퍼 닫기
map("n", "<M-w>", "<cmd>confirm bdelete<CR>", { silent = true, desc = "Close buffer" })
map(
	"n",
	"<M-W>",
	"<cmd>BufferLineCloseLeft<CR><cmd>BufferLineCloseRight<CR>",
	{ silent = true, desc = "Close others (sides)" }
)

-- 빈 줄 추가 / 라인 삭제
map("n", "<M-CR>", "o<Esc>", { silent = true, desc = "Add blank line below (stay)" })
map("n", "<M-BS>", "dd", { silent = true, desc = "Delete line (dd)" })

-- Bufferline 숫자 점프 (Space+1..9)
for i = 1, 9 do
	map("n", "<leader>" .. i, function()
		local bl = safe_require("bufferline")
		if bl then
			bl.go_to(i, true)
		else
			vim.notify("bufferline not available", vim.log.levels.WARN)
		end
-- 스마트 모션 (motions 모듈)
	end, { desc = "Go to buffer " .. i })
end
-- =========================================================

-- =========================================================
map("n", "w", motions.smart_w_normal, { noremap = true, silent = true, desc = "Smart token →" })
map("x", "w", motions.smart_w_visual, { noremap = true, silent = true, desc = "Smart token →" })
map("o", "w", motions.smart_w_operator, { noremap = true, silent = true, expr = true, desc = "Smart token →" })

map("n", "b", motions.smart_b_normal, { noremap = true, silent = true, desc = "Smart token ←" })
map("x", "b", motions.smart_b_visual, { noremap = true, silent = true, desc = "Smart token ←" })
map("o", "b", motions.smart_b_operator, { noremap = true, silent = true, expr = true, desc = "Smart token ←" })

-- 라인 시작/끝 이동 (커서만)
map({ "n", "x", "o" }, "<M-h>", function()
	vim.cmd("normal! 0")
end, { noremap = true, silent = true, desc = "Go line start" })
map({ "n", "x", "o" }, "<M-l>", function()
	vim.cmd("normal! $")
end, { noremap = true, silent = true, desc = "Go line end" })

-- 라인 전부 선택 확장 (Alt+Shift+H/L)
map("n", "<M-H>", "v0", { noremap = true, silent = true, desc = "Select to line start" })
map("x", "<M-H>", "0", { noremap = true, silent = true, desc = "Extend to line start" })
map("n", "<M-L>", "v$", { noremap = true, silent = true, desc = "Select to line end" })
map("x", "<M-L>", "$", { noremap = true, silent = true, desc = "Extend to line end" })

-- 명령행
map({ "n", "x" }, ";", ":", { noremap = true, desc = "Command-line" })

-- f/t 반복키 재배치
map({ "n", "x", "o" }, "m", ",", { noremap = true, silent = true, desc = "Repeat f/t (prev)" })
map({ "n", "x", "o" }, ",", ";", { noremap = true, silent = true, desc = "Repeat f/t (next)" })

-- Shift+W/B → 비주얼 확장
map("n", "W", function()
	vim.cmd("normal! v")
	motions.smart_w_visual()
end, { noremap = true, silent = true, desc = "Visual smart-W" })
map("x", "W", motions.smart_w_visual, { noremap = true, silent = true, desc = "Visual smart-W" })
map("n", "B", function()
	vim.cmd("normal! v")
	motions.smart_b_visual()
end, { noremap = true, silent = true, desc = "Visual smart-B" })
map("x", "B", motions.smart_b_visual, { noremap = true, silent = true, desc = "Visual smart-B" })

-- H/J/K/L: 비주얼 켜고 연속 이동/확장
local function n_vis(dir)
	local cnt = vim.v.count > 0 and vim.v.count or 1
	vim.cmd(("normal! v%d%s"):format(cnt, dir))
end
local function x_vis(dir)
	local cnt = vim.v.count > 0 and vim.v.count or 1
	vim.cmd(("normal! %d%s"):format(cnt, dir))
end
pcall(vim.keymap.del, "x", "K")
pcall(vim.keymap.del, "n", "K")
pcall(vim.keymap.del, "o", "K")
map("n", "H", function()
	n_vis("h")
end, { noremap = true, silent = true, desc = "Visual ←" })
map("x", "H", function()
	x_vis("h")
end, { noremap = true, silent = true, desc = "Extend ←" })
map("n", "J", function()
	n_vis("j")
end, { noremap = true, silent = true, desc = "Visual ↓" })
map("x", "J", function()
	x_vis("j")
end, { noremap = true, silent = true, desc = "Extend ↓" })
map("n", "K", function()
	n_vis("k")
end, { noremap = true, silent = true, desc = "Visual ↑" })
map("x", "K", function()
	x_vis("k")
end, { noremap = true, silent = true, desc = "Extend ↑" })
map("n", "L", function()
	n_vis("l")
end, { noremap = true, silent = true, desc = "Visual →" })
map("x", "L", function()
	x_vis("l")
end, { noremap = true, silent = true, desc = "Extend →" })

-- 현재만 남기고 전부 닫기
local function close_others_keep_current()
	local current = vim.api.nvim_get_current_buf()
	if vim.fn.exists(":BufferLineCloseOthers") == 2 then
		vim.cmd("BufferLineCloseOthers")
		return
	end
	for _, b in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[b].buflisted and b ~= current then
			pcall(vim.api.nvim_buf_delete, b, { force = false })
		end
	end
end
map("n", "<leader>Q", close_others_keep_current, { silent = true, desc = "Close all others" })
map("n", "<leader>q", "<cmd>bdelete<CR>", { silent = true, desc = "Close buffer" })

-- 매칭까지 선택
map("n", "%", function()
	vim.cmd("normal! v%")
end, { noremap = true, silent = true, desc = "Select to match" })

-- 라인 스왑 / 선택 이동
map("n", "<M-J>", "<cmd>m .+1<CR>==", { noremap = true, silent = true, desc = "Swap line ↓" })
map("n", "<M-K>", "<cmd>m .-2<CR>==", { noremap = true, silent = true, desc = "Swap line ↑" })
map("x", "<M-J>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection ↓" })
map("x", "<M-K>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection ↑" })

-- 화면 스크롤
map({ "n", "x" }, "<M-j>", "<C-d>zz", { noremap = true, silent = true, desc = "Half-page ↓ (center)" })
map({ "n", "x" }, "<M-k>", "<C-u>zz", { noremap = true, silent = true, desc = "Half-page ↑ (center)" })

-- 전체 선택
map({ "n", "x" }, "<M-a>", "ggVG", { desc = "Select all" })
map({ "x" }, "c", "\"_c", { desc = "Select all" })

-- 줄 복사
map({ "n", "x" }, "<M-y>", ":t.<CR>", { desc = "Select all" })

-- =========================================================
-- LSP / Telescope
-- =========================================================

-- 참조: LSP 우선 → Telescope → grep 폴백
map("n", "gr", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if motions.lsp_supports(bufnr, "textDocument/references") then
		local tb = safe_require("telescope.builtin")
		if tb then
			tb.lsp_references({ include_declaration = false, show_line = false })
		else
			vim.lsp.buf.references(nil, { loclist = true })
			vim.cmd("lopen")
		end
	else
		local w = vim.fn.expand("<cword>")
		local tb = safe_require("telescope.builtin")
		if tb then
			tb.grep_string({ search = w })
		else
			vim.cmd("silent! vimgrep /\\<" .. w .. "\\>/gj **/* | copen")
		end
	end
end, { silent = true, desc = "References (smart)" })

-- 정의
map("n", "gd", function()
	local bufnr = vim.api.nvim_get_current_buf()
	if motions.lsp_supports(bufnr, "textDocument/definition") then
		local tb = safe_require("telescope.builtin")
		if tb then
			tb.lsp_definitions({ reuse_win = true })
		else
			vim.lsp.buf.definition()
		end
	else
		vim.notify("No LSP definitions for this buffer", vim.log.levels.WARN)
	end
end, { silent = true, desc = "LSP Definition" })

-- Hover (사용자: 'e' 사용)
map("n", "e", function()
	local bufnr = 0
	if motions.lsp_supports(bufnr, "textDocument/hover") then
		vim.lsp.buf.hover()
	else
		vim.notify("No LSP provides hover for this buffer", vim.log.levels.WARN)
	end
end, { silent = true, desc = "Hover" })

-- Rename
map("n", "<leader>rn", function()
	local bufnr = 0
	if motions.lsp_supports(bufnr, "textDocument/rename") then
		vim.lsp.buf.rename()
	else
		vim.notify("No LSP provides rename for this buffer", vim.log.levels.WARN)
	end
end, { silent = true, desc = "Rename symbol" })

-- Code Actions (미리보기)
map({ "n", "v" }, "<leader>ca", function()
	vim.lsp.buf.code_action({ apply = false })
end, { desc = "Code Action (preview)" })

-- Organize Imports (미리보기)
map("n", "<leader>co", function()
	vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = false })
end, { desc = "Organize Imports (preview)" })

-- 진단 이동 + 팝업
map("n", "]d", function()
	vim.diagnostic.goto_next({ float = diag_float_opts, wrap = true })
end, { desc = "Next diagnostic + popup" })
map("n", "[d", function()
	vim.diagnostic.goto_prev({ float = diag_float_opts, wrap = true })
end, { desc = "Prev diagnostic + popup" })
-- 커서 위치 설명 (이동 X)
map("n", "gl", function()
	vim.diagnostic.open_float(nil, diag_float_opts)
end, { desc = "Show diagnostics here" })
-- 진단 Quickfix
map("n", "<leader>dq", vim.diagnostic.setqflist, { desc = "Diagnostics → quickfix" })
-- =========================================================
map({ "n", "v" }, "<leader>f", function()
	local conform = safe_require("conform")
	if not conform then
		return
	end
	local opts = { async = false, lsp_fallback = true, timeout_ms = 2000 }

	-- 비주얼 모드면 선택 범위만 포맷
	local m = vim.api.nvim_get_mode().mode
	if m == "v" or m == "V" or m == "\22" then
		local s = vim.api.nvim_buf_get_mark(0, "<")
		local e = vim.api.nvim_buf_get_mark(0, ">")
		opts.range = { start = { s[1] - 1, s[2] }, ["end"] = { e[1] - 1, e[2] } }
	end
	conform.format(opts)
end, { desc = "Format (file/selection)" })

-- =========================================================
-- Telescope: 루트 기준 검색
-- =========================================================
local function project_root()
	if motions and motions.project_root then
		return motions.project_root()
	end
	return vim.loop.cwd()
end

map("n", "<leader>ff", function()
	local tb = safe_require("telescope.builtin")
	if not tb then
		return
	end
	tb.find_files({ cwd = project_root() })
end, { desc = "Find files (project root)" })

map("n", "<leader>sg", function()
	local tb = safe_require("telescope.builtin")
	if not tb then
		return
	end
	tb.live_grep({
		cwd = project_root(),
		additional_args = function()
			return { "--hidden", "--glob", "!.git/*" }
		end,
	})
end, { desc = "Live grep (project root)" })

map("n", "<leader>sw", function()
	local tb = safe_require("telescope.builtin")
	if not tb then
		return
	end
	tb.grep_string({
		cwd = project_root(),
		word_match = "-w",
		additional_args = function()
			return { "--hidden", "--glob", "!.git/*" }
		end,
	})
end, { desc = "Grep word under cursor (root)" })

map('n', '<leader>t', function()
  local total_lines = vim.api.nvim_win_get_height(0)
  local terminal_height = math.floor(total_lines * 0.3)  -- 전체의 30%만 터미널로
  vim.cmd('belowright ' .. terminal_height .. 'split | terminal')
end, { silent = true })

vim.keymap.set('t', '<leader>tt', '<C-\\><C-n>', { noremap = true, silent = true })


-- =========================================================
-- CodeCompanion
-- =========================================================
map("n", "<leader>cc", "<cmd>CodeCompanionChat<CR>", { desc = "CodeCompanion: Chat" })
map("v", "<leader>ci", "<cmd>CodeCompanionInline<CR>", { desc = "CodeCompanion: Inline edit" })
map("v", "<leader>cp", "<cmd>CodeCompanionPrompt<CR>", { desc = "CodeCompanion: Prompt on selection" })
map("n", "<leader>cx", "<cmd>CodeCompanionCancel<CR>", { desc = "CodeCompanion: Cancel" })
map("n", "<leader>cL", "<cmd>CodeCompanionLogs<CR>", { desc = "CodeCompanion: Logs" })

do
	local tb = safe_require("telescope.builtin")
	if tb then
		map("n", "<leader>cP", "<cmd>Telescope codecompanion prompts<CR>", { desc = "CodeCompanion: Browse prompts" })
	end
end

-- 참고: 범위 변경 키(-, _)는 webdev.lua의 treesitter 설정에 있음
