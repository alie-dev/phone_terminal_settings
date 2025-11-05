-- lua/plugins/init.lua (안전 보강판)

return {
	-- 🎨 컬러스킴 (OneDark Pro)
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("onedarkpro").setup({
				dark_variant = "onedark", -- "onedark_vivid"/"onedark_dark" 등 가능
				styles = { comments = "italic", keywords = "bold" },
			})
			vim.opt.termguicolors = true
			vim.cmd.colorscheme("onedark") -- onedark / onelight
		end,
	},

	-- 아이콘
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- ⛏️ LSP (여기 등록만; 실제 설정은 webdev.lua에서)
	{ "neovim/nvim-lspconfig" },

	-- 🚧 문제 리스트 (setup 명시)
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {}, -- ← 기본값으로 초기화(안전)
	},

	-- 🌳 Treesitter
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- 📁 파일 트리 (Neo-tree)
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				close_if_last_window = true,
				window = {
					mappings = {
						h = "close_node",
						l = "open",
					},
				},
				event_handlers = {
					{
						event = "file_opened",
						handler = function()
							vim.defer_fn(function()
								require("neo-tree.command").execute({ action = "close" })
							end, 0)
						end,
					},
					{
						event = "file_moved",
						handler = function(args)
							-- args = { source = "old/path.ts", destination = "new/path.ts" }
							vim.schedule(function()
								-- 옛 버퍼 진단 지우기 (모든 네임스페이스 대상)
								local oldbuf = vim.fn.bufnr(vim.fn.fnamemodify(args.source, ":p"))
								if oldbuf ~= -1 then
									for _, ns in pairs(vim.api.nvim_get_namespaces()) do
										pcall(vim.diagnostic.reset, ns, oldbuf)
									end
								end
								-- 트리 강제 새로고침
								pcall(require("neo-tree.sources.manager").refresh, "filesystem")
							end)
						end,
					},
					{
						event = "file_renamed",
						handler = function(args)
							-- args = { source = "old/path.ts", destination = "new/path.ts" }
							vim.schedule(function()
								local oldbuf = vim.fn.bufnr(vim.fn.fnamemodify(args.source, ":p"))
								if oldbuf ~= -1 then
									for _, ns in pairs(vim.api.nvim_get_namespaces()) do
										pcall(vim.diagnostic.reset, ns, oldbuf)
									end
								end
								pcall(require("neo-tree.sources.manager").refresh, "filesystem")
							end)
						end,
					},
				},

				filesystem = {
					window = {
						mappings = {
							h = "close_node",
							l = "open",
							-- 📋 Y: 상대경로 복사 (현재 작업 디렉토리 기준)
							Y = {
								function(state)
									local node = state.tree:get_node()
									local filepath = node:get_id()
									local relative = vim.fn.fnamemodify(filepath, ":.")
									vim.fn.setreg("+", relative)
									vim.notify("Copied: " .. relative, vim.log.levels.INFO)
								end,
								desc = "Copy relative path to clipboard",
							},
							-- 📋 P: 외부 파일을 현재 디렉토리에 붙여넣기
							P = {
								function(state)
									local node = state.tree:get_node()
									-- 디렉토리면 그 안에, 파일이면 그 디렉토리에 붙여넣기
									local dest_dir = node.type == "directory" and node:get_id()
										or vim.fn.fnamemodify(node:get_id(), ":h")

									-- macOS: HFS 경로를 POSIX 경로로 변환
									local handle = io.popen('osascript -e "try" -e "POSIX path of (the clipboard as «class furl»)" -e "end try" 2>/dev/null')
									if not handle then
										vim.notify("Failed to read clipboard", vim.log.levels.ERROR)
										return
									end

									local clipboard_path = handle:read("*a")
									handle:close()
									clipboard_path = vim.trim(clipboard_path)

									if clipboard_path == "" then
										vim.notify("No file in clipboard", vim.log.levels.WARN)
										return
									end

									-- 파일 존재 확인
									if vim.fn.filereadable(clipboard_path) == 0 then
										vim.notify("Not a valid file: " .. clipboard_path, vim.log.levels.WARN)
										return
									end

									-- 파일명 추출
									local filename = vim.fn.fnamemodify(clipboard_path, ":t")
									local dest_path = dest_dir .. "/" .. filename

									-- 파일 복사
									local cmd = "cp " .. vim.fn.shellescape(clipboard_path) .. " " .. vim.fn.shellescape(dest_path)
									vim.fn.system(cmd)

									if vim.v.shell_error == 0 then
										vim.notify("Pasted: " .. filename, vim.log.levels.INFO)
										-- Neo-tree 새로고침
										require("neo-tree.sources.manager").refresh("filesystem")
									else
										vim.notify("Failed to copy file", vim.log.levels.ERROR)
									end
								end,
								desc = "Paste file from clipboard",
							},
							-- ✂️ M (Shift+M): 파일/폴더 잘라내기 (이동 준비)
							M = {
								function(state)
									local node = state.tree:get_node()
									local filepath = node:get_id()
									-- 전역 변수에 저장
									vim.g.neotree_move_source = filepath
									vim.notify("Marked for move: " .. vim.fn.fnamemodify(filepath, ":."), vim.log.levels.INFO)
								end,
								desc = "Mark file/folder for move",
							},
							-- 📥 N (Shift+N): 잘라낸 파일/폴더를 여기로 이동 (LSP 리팩토링 포함)
							N = {
								function(state)
									if not vim.g.neotree_move_source then
										vim.notify("No file marked for move. Use Shift+M first.", vim.log.levels.WARN)
										return
									end

									local source = vim.g.neotree_move_source
									local node = state.tree:get_node()

									-- 목적지 디렉토리 결정
									local dest_dir
									if node.type == "directory" then
										dest_dir = node:get_id()
									else
										dest_dir = vim.fn.fnamemodify(node:get_id(), ":h")
									end

									-- 파일명 추출
									local filename = vim.fn.fnamemodify(source, ":t")
									local dest_path = dest_dir .. "/" .. filename

									-- Neo-tree의 파일시스템 명령 사용 (nvim-lsp-file-operations가 자동으로 훅)
									local commands = require("neo-tree.sources.filesystem.commands")

									-- 임시로 소스 노드 생성
									local temp_state = {
										tree = state.tree,
									}

									-- rename 명령 사용 (이게 LSP 리팩토링 트리거함)
									vim.schedule(function()
										local success, err = pcall(vim.loop.fs_rename, source, dest_path)

										if success then
											vim.notify("Moved to: " .. vim.fn.fnamemodify(dest_dir, ":."), vim.log.levels.INFO)
											-- 마크 해제
											vim.g.neotree_move_source = nil
											-- Neo-tree 새로고침
											require("neo-tree.sources.manager").refresh("filesystem")
										else
											vim.notify("Failed to move: " .. tostring(err), vim.log.levels.ERROR)
										end
									end)
								end,
								desc = "Move marked file/folder here (with LSP refactoring)",
							},
						},
					},
					follow_current_file = { enabled = false }, -- 다시 열림 방지
					use_libuv_file_watcher = true, -- ← 변경 감지 정확도↑ (권장)
					filtered_items = { hide_gitignored = false, hide_dotfiles = false },
				},

				window = { width = 35 }, -- 세미콜론 대신 콤마로 통일(취향/일관성)
			})
		end,
	},

	-- 📌 Git signs (사이드라인/워드 단위 diff)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "▎" },
				topdelete = { text = "▎" },
				changedelete = { text = "▎" },
			},
			word_diff = false,
			current_line_blame = false,
		},
	},

	-- 📚 버퍼라인(탭 느낌)
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("bufferline").setup({
				options = {
					themable = true,
					diagnostics = "nvim_lsp",
					separator_style = "slant",
					show_close_icon = false,
					show_buffer_close_icons = false,
					offsets = {
						{ filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
					},
				},
			})
		end,
	},

	-- 📊 상태줄
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "onedark",
					globalstatus = true,
					-- ⬇️ 주석과 옵션 일치(분리자 사용)
					section_separators = { left = "", right = "" },
					component_separators = { left = "/", right = "" },
				},
				sections = {
					lualine_a = { { "mode", padding = { left = 2, right = 2 } } },
					lualine_b = {
						{ "branch", icon = "", padding = { left = 1, right = 1 } },
						{
							"diff",
							symbols = { added = "+", modified = "~", removed = "-" },
							padding = { left = 1, right = 1 },
						},
						{ "diagnostics", sources = { "nvim_diagnostic" }, padding = { left = 1, right = 1 } },
					},
					lualine_c = {
						{
							"filename",
							path = 1,
							symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
							padding = { left = 2, right = 2 },
						},
					},
					lualine_x = {
						function()
							local cs = vim.lsp.get_clients({ bufnr = 0 })
							if #cs == 0 then
								return ""
							end
							local names = {}
							for _, c in ipairs(cs) do
								names[#names + 1] = c.name
							end
							return " " .. table.concat(names, ",")
						end,
						function()
							if vim.bo.expandtab then
								local sw = (vim.bo.shiftwidth > 0) and vim.bo.shiftwidth or vim.bo.tabstop
								return "Spaces:" .. sw
							else
								return "Tab:" .. vim.bo.tabstop
							end
						end,
						"encoding",
						"fileformat",
						"filetype",
					},
					lualine_y = { "progress" },
					lualine_z = {
						{ "location", padding = { left = 1, right = 1 } },
						{
							function()
								return ""
							end,
							on_click = function()
								vim.cmd("Lazy")
							end,
							padding = { left = 1, right = 1 },
						},
					},
				},
			})
		end,
	},
}
