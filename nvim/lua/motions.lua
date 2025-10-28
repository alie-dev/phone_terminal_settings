local M = {}

-- UTF-8 인식 스마트 w/b 이동 로직
local PUNCTS = {
	["["] = true,
	["]"] = true,
	["{"] = true,
	["}"] = true,
	["("] = true,
	[")"] = true,
	["="] = true,
	[","] = true,
	["."] = true,
	[";"] = true,
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["<"] = true,
	[">"] = true,
	["&"] = true,
	["%"] = true,
	['"'] = true,
	["?"] = true,
	["!"] = true,
	["'"] = true,
}

local function is_space(ch)
	return ch ~= "" and ch:match("%s") ~= nil
end
local function is_punct(ch)
	return PUNCTS[ch] == true
end

local function str_len_chars(line)
	return vim.fn.strchars(line)
end
local function char_at(line, cidx)
	return vim.fn.strcharpart(line, cidx - 1, 1)
end
local function col0_to_charidx(line, col0)
	return vim.str_utfindex(line, col0) + 1
end
local function charidx_to_col0(line, cidx)
	return vim.str_byteindex(line, cidx - 1)
end

local function token_bounds(line, cur)
	local len = str_len_chars(line)
	if len == 0 then
		return cur, cur
	end
	if cur < 1 then
		cur = 1
	end
	if cur > len then
		cur = len
	end

	local ch = char_at(line, cur)
	if ch ~= "" and is_space(ch) then
		local i = cur
		while i <= len and is_space(char_at(line, i)) do
			i = i + 1
		end
		if i > len then
			return len, len
		end
		cur = i
		ch = char_at(line, cur)
	end
	if ch ~= "" and is_punct(ch) then
		return cur, cur
	end

	local s = cur
	while s > 1 do
		local prev = char_at(line, s - 1)
		if is_space(prev) or is_punct(prev) then
			break
		end
		s = s - 1
	end
	local e = cur
	while e < len do
		local nxt = char_at(line, e + 1)
		if is_space(nxt) or is_punct(nxt) then
			break
		end
		e = e + 1
	end
	return s, e
end

local function next_token_start_global(row, e_cidx)
	local lastrow = vim.fn.line("$")

	local line = vim.fn.getline(row)
	local len = str_len_chars(line)
	local i = e_cidx + 1
	while i <= len and is_space(char_at(line, i)) do
		i = i + 1
	end
	if i <= len then
		return row, i
	end

	row = row + 1
	while row <= lastrow do
		line = vim.fn.getline(row)
		len = str_len_chars(line)
		local j = 1
		while j <= len and is_space(char_at(line, j)) do
			j = j + 1
		end
		if j <= len then
			return row, j
		end
		row = row + 1
	end

	local lastline = vim.fn.getline(lastrow)
	local lastlen = str_len_chars(lastline)
	return lastrow, (lastlen > 0 and lastlen or 1)
end

local function prev_token_end_global(row, s_cidx)
	local line = vim.fn.getline(row)
	local len = str_len_chars(line)
	local i = math.min(s_cidx - 1, len)
	while i >= 1 and is_space(char_at(line, i)) do
		i = i - 1
	end
	if i >= 1 then
		local ps, pe = token_bounds(line, i)
		return row, pe
	end

	row = row - 1
	while row >= 1 do
		line = vim.fn.getline(row)
		len = str_len_chars(line)
		local j = len
		while j >= 1 and is_space(char_at(line, j)) do
			j = j - 1
		end
		if j >= 1 then
			local ps, pe = token_bounds(line, j)
			return row, pe
		end
		row = row - 1
	end
	return 1, 1
end

local function next_step_or_start(row, cidx)
	local line = vim.fn.getline(row)
	local len = str_len_chars(line)
	local i = cidx + 1
	if i <= len then
		local ch = char_at(line, i)
		if not is_space(ch) then
			return row, i
		end
	end
	return next_token_start_global(row, cidx)
end

local function prev_step_or_end(row, cidx)
	local line = vim.fn.getline(row)
	local i = cidx - 1
	if i >= 1 then
		local ch = char_at(line, i)
		if not is_space(ch) then
			return row, i
		end
	end
	return prev_token_end_global(row, cidx)
end

local function build_move(cur_row, cur_col_char, tgt_row, tgt_col_char)
	if cur_row == tgt_row then
		local diff = tgt_col_char - cur_col_char
		if diff == 0 then
			return ""
		end
		local key = (diff > 0) and "l" or "h"
		return string.rep(key, math.abs(diff))
	else
		local seq = ""
		local dr = tgt_row - cur_row
		seq = seq .. ((dr > 0) and string.rep("j", dr) or string.rep("k", -dr))
		seq = seq .. "0" .. string.rep("l", tgt_col_char - 1)
		return seq
	end
end

local function smart_toggle_core()
	local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.fn.getline(row)
	local len = str_len_chars(line)

	if len == 0 then
		local tr, tc = next_token_start_global(row, 0)
		local keys = build_move(row, 1, tr, tc)
		local final_col0 = charidx_to_col0(vim.fn.getline(tr), tc)
		return keys, final_col0
	end

	local cur_char = col0_to_charidx(line, col0)
	local s, e = token_bounds(line, cur_char)

	local ch_at_cur = char_at(line, cur_char)
	local cur_space = (ch_at_cur == "" and true) or is_space(ch_at_cur)
	local at_start = (not cur_space) and (cur_char == s)
	local at_end = (not cur_space) and (cur_char == e)
	local is_single_char_any = (s == e)

	local tgt_row, tgt_col_char
	if is_single_char_any then
		tgt_row, tgt_col_char = next_step_or_start(row, e)
	elseif at_start then
		tgt_row, tgt_col_char = row, e
	elseif at_end then
		tgt_row, tgt_col_char = next_token_start_global(row, e)
	elseif cur_space then
		tgt_row, tgt_col_char = next_token_start_global(row, cur_char - 1)
	else
		tgt_row, tgt_col_char = row, e
	end

	local keys = build_move(row, cur_char, tgt_row, tgt_col_char)
	local final_col0 = charidx_to_col0(vim.fn.getline(tgt_row), tgt_col_char)
	return keys, final_col0
end

local function smart_b_core()
	local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.fn.getline(row)
	local len = str_len_chars(line)

	if len == 0 then
		local tr, tc = prev_token_end_global(row, 1)
		local keys = build_move(row, 1, tr, tc)
		local final_col0 = charidx_to_col0(vim.fn.getline(tr), tc)
		return keys, final_col0
	end

	local cur_char = col0_to_charidx(line, col0)
	local s, e = token_bounds(line, cur_char)

	local ch_at_cur = char_at(line, cur_char)
	local cur_space = (ch_at_cur == "" and true) or is_space(ch_at_cur)
	local at_start = (not cur_space) and (cur_char == s)
	local at_end = (not cur_space) and (cur_char == e)
	local is_single_char_any = (s == e)

	local tgt_row, tgt_col_char
	if is_single_char_any then
		tgt_row, tgt_col_char = prev_step_or_end(row, s)
	elseif at_end then
		tgt_row, tgt_col_char = row, s
	elseif at_start then
		tgt_row, tgt_col_char = prev_token_end_global(row, s)
	elseif cur_space then
		tgt_row, tgt_col_char = prev_token_end_global(row, cur_char)
	else
		tgt_row, tgt_col_char = row, s
	end

	local keys = build_move(row, cur_char, tgt_row, tgt_col_char)
	local final_col0 = charidx_to_col0(vim.fn.getline(tgt_row), tgt_col_char)
	return keys, final_col0
end

-- 외부에서 쓰는 래퍼/매핑용 함수
function M.smart_w_normal()
	local keys = select(1, smart_toggle_core())
	if keys ~= "" then
		local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(term, "n", false)
	end
end

function M.smart_w_visual()
	local keys = select(1, smart_toggle_core())
	if keys ~= "" then
		local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(term, "x", false)
	end
end

function M.smart_w_operator()
	local keys = select(1, smart_toggle_core())
	return "v" .. keys
end

function M.smart_b_normal()
	local keys = select(1, smart_b_core())
	if keys ~= "" then
		local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(term, "n", false)
	end
end

function M.smart_b_visual()
	local keys = select(1, smart_b_core())
	if keys ~= "" then
		local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
		vim.api.nvim_feedkeys(term, "x", false)
	end
end

function M.smart_b_operator()
	local keys = select(1, smart_b_core())
	return "v" .. keys
end

-- motions.lua
function M.lsp_supports(bufnr, method)
	if type(bufnr) ~= "number" or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end
	for _, c in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if c.supports_method and c:supports_method(method) then
			return true
		end
	end
	return false
end

function M.have(mod)
	return pcall(require, mod)
end
-- utils/root.lua 같은 곳에
function M.project_root()
	-- 1) LSP 루트 우선
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	for _, c in ipairs(clients) do
		local rd = c.config and c.config.root_dir
		if rd and vim.fn.isdirectory(rd) == 1 then
			return rd
		end
	end
	-- 2) git 루트
	local git = vim.fn.systemlist("git -C " .. vim.fn.expand("%:p:h") .. " rev-parse --show-toplevel")[1]
	if vim.v.shell_error == 0 and git and git ~= "" then
		return git
	end
	-- 3) fallback: 현재 작업 디렉토리
	return vim.loop.cwd()
end

-- codeCompanion
local state = { win = nil, buf = nil }
local WIDTH = math.floor(vim.o.columns * 0.15) -- 사이드바 폭

local function find_chat_window()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "codecompanion" then
			return win
		end
	end
end

local function find_chat_buffer()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "codecompanion" then
			return buf
		end
	end
end

function M.toggle_chat(side) -- "right"|"left"
	side = side or "right"

	-- 1) 이미 떠 있으면 닫기
	local chat_win = find_chat_window()
	if chat_win then
		vim.api.nvim_win_close(chat_win, true)
		return
	end

	-- 2) 버퍼/창이 없으면 먼저 CodeCompanionChat으로 "창을 생성"
	local buf = find_chat_buffer()
	if not buf then
		vim.cmd("CodeCompanionChat")
	end

	-- 3) 방금 생긴(또는 기존의) 채팅 창을 찾아서 "그 창 자체"를 옮기고 폭만 조정
	chat_win = find_chat_window()
	if chat_win then
		-- 창을 선택
		vim.api.nvim_set_current_win(chat_win)
		-- 원하는 사이드로 이동
		if side == "left" then
			vim.cmd("wincmd H")
		else
			vim.cmd("wincmd L")
		end
		-- 폭 고정
		vim.wo[chat_win].winfixwidth = true
		vim.api.nvim_win_set_width(chat_win, WIDTH)
		return
	end

	-- 4) 혹시 창은 없는데 버퍼만 있는 희귀 케이스 → 그때만 split 생성
	buf = find_chat_buffer()
	if buf then
		if side == "left" then
			vim.cmd("topleft vsplit")
			vim.cmd("wincmd H")
		else
			vim.cmd("botright vsplit")
			vim.cmd("wincmd L")
		end
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, buf)
		vim.wo[win].winfixwidth = true
		vim.api.nvim_win_set_width(win, WIDTH)
	else
		vim.notify("CodeCompanion Chat buffer not found", vim.log.levels.WARN)
	end
end

function M.get_relative_path()
	local filepath = vim.fn.expand("%:p") -- full path
	local root = vim.fn.getcwd() -- 현재 작업 디렉토리 (nvim 실행 경로)
	return vim.fn.fnamemodify(filepath, ":." .. root)
end
-- 비주얼 선택 텍스트 얻기
--vim.api.nvim_create_user_command("CodeCompanionToggle", M.toggle_chat, {})
return M
