-- webdev.lua

return {
	---------------------------------------------------------------------------
	-- nvim-cmp
	---------------------------------------------------------------------------
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"roobert/tailwindcss-colorizer-cmp.nvim",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fb)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fb()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fb)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fb()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources(
					{ { name = "nvim_lsp" }, { name = "luasnip" } },
					{ { name = "buffer" }, { name = "path" } }
				),
				formatting = { format = require("tailwindcss-colorizer-cmp").formatter },
			})
		end,
	},

	---------------------------------------------------------------------------
	-- Treesitter
	---------------------------------------------------------------------------
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"svelte",
				"typescript",
				"tsx",
				"javascript",
				"css",
				"html",
				"json",
				"lua",
				"bash",
				"markdown",
			},
			highlight = { enable = true },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "f",
					node_incremental = "f",
					node_decremental = "F",
				},
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},

	---------------------------------------------------------------------------
	-- autotag
	---------------------------------------------------------------------------
	{ "windwp/nvim-ts-autotag", event = "InsertEnter", config = true },

	---------------------------------------------------------------------------
	-- Mason (PATH를 먼저 보정)
	---------------------------------------------------------------------------
	{
		"williamboman/mason.nvim",
		lazy = false,
		priority = 1000, -- lspconfig보다 먼저
		opts = { PATH = "prepend" }, -- mason/bin을 PATH 맨 앞에
		config = function(_, opts)
			require("mason").setup(opts)
		end,
	},

	---------------------------------------------------------------------------
	-- mason-lspconfig
	---------------------------------------------------------------------------
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "neovim/nvim-lspconfig" },
		opts = {
			ensure_installed = { "vtsls", "tailwindcss", "eslint", "lua_ls", "svelte" },
			automatic_installation = true,
		},
	},

	---------------------------------------------------------------------------
	-- LSP (신 API: vim.lsp.config / vim.lsp.enable)
	---------------------------------------------------------------------------
	{
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local util = require("lspconfig.util")
			local caps = require("cmp_nvim_lsp").default_capabilities()

			local function on_attach(_, _) end

			-- vtsls (typescript)
			-- npm 전역:  npm i -g @vtsls/language-server typescript
			vim.lsp.config("vtsls", {
				-- mason PATH prepend이면 cmd 생략 가능. 필요시: cmd = { "vtsls", "--stdio" }
				capabilities = caps,
				on_attach = on_attach,
				single_file_support = true,
				filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
				root_dir = function(fname)
					-- Ensure fname is a string (convert buffer number to filename if needed)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(filename)
						or util.find_git_ancestor(filename)
						or vim.loop.cwd()
				end,
				settings = {
					typescript = {
						updateImportsOnFileMove = { enabled = "always" },
						referencesCodeLens = { enabled = true },
						suggest = { completeFunctionCalls = true },
					},
					javascript = {
						updateImportsOnFileMove = { enabled = "always" },
					},
				},
				on_init = function(_, ctx)
					vim.schedule(function()
						vim.notify(("[vtsls] started (root=%s)"):format(ctx.root_dir or "?"), vim.log.levels.INFO)
					end)
				end,
			})

			-- tailwindcss
			vim.lsp.config("tailwindcss", {
				capabilities = caps,
				on_attach = on_attach,
				settings = {
					tailwindCSS = {
						experimental = {
							classRegex = { "tw`([^`]*)", 'tw%("([^"]*)', "tw%('([^']*)" },
						},
					},
				},
			})

			-- eslint
			vim.lsp.config("eslint", {
				capabilities = caps,
				on_attach = on_attach,
				-- BufWritePre EslintFixAll 제거 (자동저장과 충돌)
				root_dir = function(fname)
					-- Ensure fname is a string (convert buffer number to filename if needed)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern(
						".eslintrc",
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.json",
						"package.json",
						".git"
					)(filename) or util.path.dirname(filename)
				end,
			})

			-- lua_ls
			vim.lsp.config("lua_ls", {
				capabilities = caps,
				on_attach = on_attach,
				root_dir = function(fname)
					-- Ensure fname is a string (convert buffer number to filename if needed)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern(
						".luarc.json",
						".luarc.jsonc",
						".luacheckrc",
						".stylua.toml",
						"stylua.toml",
						"selene.toml",
						"selene.yml",
						".git"
					)(filename) or util.path.dirname(filename) or vim.fn.getcwd()
				end,
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = { enable = false },
					},
				},
			})

			-- svelte
			vim.lsp.config("svelte", {
				capabilities = caps,
				on_attach = on_attach,
				filetypes = { "svelte" },
				root_dir = function(fname)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern("package.json", ".git")(filename) or util.path.dirname(filename)
				end,
			})

			-- enable
			for _, name in ipairs({ "vtsls", "tailwindcss", "eslint", "lua_ls", "svelte" }) do
				vim.lsp.enable(name)
			end

			-- LspAttach: 인레이 힌트
			local grp = vim.api.nvim_create_augroup("MyLspAttach", { clear = true })
			vim.api.nvim_create_autocmd("LspAttach", {
				group = grp,
				callback = function(ev)
					if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
						pcall(vim.lsp.inlay_hint.enable, ev.buf, true)
					end
				end,
			})

			-- === 자동 attach 보강: 이미 열린 버퍼/새 버퍼 모두 보장 ===
			do
				local function ts_root(fname)
					-- Ensure fname is a string (convert buffer number to filename if needed)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(filename)
						or util.find_git_ancestor(filename)
						or vim.loop.cwd()
				end

				local function svelte_root(fname)
					local filename = type(fname) == "string" and fname or vim.api.nvim_buf_get_name(fname)
					return util.root_pattern("package.json", ".git")(filename) or util.path.dirname(filename)
				end

				-- vtsls auto-attach for TypeScript/JavaScript
				vim.api.nvim_create_autocmd("FileType", {
					pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
					callback = function(ev)
						-- 이미 붙어 있으면 스킵
						for _, c in pairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
							if c.name == "vtsls" then
								return
							end
						end
						local file = vim.api.nvim_buf_get_name(ev.buf)
						vim.lsp.start({
							name = "vtsls",
							cmd = { "vtsls", "--stdio" }, -- mason PATH 우선이면 생략 가능
							root_dir = ts_root(file),
							capabilities = caps,
							single_file_support = true,
						})
					end,
				})

				-- svelte auto-attach for Svelte files
				vim.api.nvim_create_autocmd("FileType", {
					pattern = "svelte",
					callback = function(ev)
						-- 이미 붙어 있으면 스킵
						for _, c in pairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
							if c.name == "svelte" then
								return
							end
						end
						local file = vim.api.nvim_buf_get_name(ev.buf)
						vim.lsp.start({
							name = "svelte",
							cmd = { "svelteserver", "--stdio" },
							root_dir = svelte_root(file),
							capabilities = caps,
							single_file_support = true,
						})
					end,
				})

				-- 지금 열려 있는 버퍼가 TS/TSX/JS/JSX면 한 번 트리거
				if
					vim.tbl_contains(
						{ "typescript", "typescriptreact", "javascript", "javascriptreact" },
						vim.bo.filetype
					)
				then
					vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
				end

				-- 지금 열려 있는 버퍼가 Svelte면 한 번 트리거
				if vim.bo.filetype == "svelte" then
					vim.api.nvim_exec_autocmds("FileType", { buffer = 0 })
				end
			end
			-- === 자동 attach 보강 끝 ===
		end,
	},

	---------------------------------------------------------------------------
	-- none-ls (prettierd)
	---------------------------------------------------------------------------
	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "jay-babu/mason-null-ls.nvim" },
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = { null_ls.builtins.formatting.prettierd },
				-- BufWritePre 자동 포맷팅 제거 (자동저장과 충돌)
			})
		end,
	},

	---------------------------------------------------------------------------
	-- mason-null-ls
	---------------------------------------------------------------------------
	{
		"jay-babu/mason-null-ls.nvim",
		opts = {
			ensure_installed = { "prettierd", "eslint_d" },
			automatic_installation = true,
		},
	},

	---------------------------------------------------------------------------
	-- 자동정렬 (Conform + ESLint)
	---------------------------------------------------------------------------
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				javascript = { "eslint_d", "prettierd", "prettier" },
				typescript = { "eslint_d", "prettierd", "prettier" },
				javascriptreact = { "eslint_d", "prettierd", "prettier" },
				typescriptreact = { "eslint_d", "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				html = { "eslint_d", "prettierd", "prettier" },
				svelte = { "eslint_d", "prettierd", "prettier" },
				lua = { "stylua" },
			},
			-- 전역 ESLint 설정 강제 사용 (프로젝트 설정 무시)
			formatters = {
				eslint_d = {
					prepend_args = function()
						local config_path = vim.fn.expand("~/.config/nvim/eslint.config.js")
						-- 항상 전역 설정 사용
						return { "--config", config_path }
					end,
				},
			},
			-- format_on_save 제거 (수동 포맷은 <leader>f로 가능)
		},
	},

	---------------------------------------------------------------------------
	-- 애니메이션 플러그인
	---------------------------------------------------------------------------
	-- 커서 이동 애니메이션
	{
		"gen740/SmoothCursor.nvim",
		event = "VeryLazy",
		opts = {
			type = "default",
			fancy = { enable = true },
		},
	},

	-- 스크롤 애니메이션
	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		opts = {
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "zt", "zz", "zb" },
			easing = "quadratic",
		},
	},

	-- UI 오버홀 (커맨드라인, 메시지, 알림)
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = true,
			},
		},
	},

	-- 빠른 점프 (레이블 점프)
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				char = { enabled = false }, -- f/F/t/T 강화 끔
			},
		},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
		},
	},

	-- 마크다운 체크박스
	{
		"nfrid/markdown-togglecheck",
		dependencies = { "nfrid/treesitter-utils" },
		ft = "markdown",
		keys = {
			{
				"<leader>x",
				function()
					require("markdown-togglecheck").toggle()
				end,
				desc = "Toggle checkbox",
			},
		},
	},

	-- Org mode
	{
		"nvim-orgmode/orgmode",
		event = "VeryLazy",
		ft = "org",
		config = function()
			require("orgmode").setup({
				org_agenda_files = { "~/org/**/*.org" },
				org_refile_targets = {
					{ "~/org/**/*.org", "maxlevel", 4 },
				},
				org_default_notes_file = "~/org/notes.org",
				mappings = {
					org = {
						org_refile = false,
						org_insert_link = false,
					},
				},
			})

			-- telescope-orgmode 키맵 (orgmode 로드 후 설정)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "org",
				callback = function()
					-- 링크 경로 숨기기
					vim.opt_local.conceallevel = 2
					vim.opt_local.concealcursor = "nc"

					local ok, telescope = pcall(require, "telescope")
					if ok then
						pcall(telescope.load_extension, "orgmode")
						if telescope.extensions.orgmode then
							vim.keymap.set("n", "<leader>or", telescope.extensions.orgmode.refile_heading, { buffer = true, desc = "Org Refile" })
							vim.keymap.set("n", "<leader>oli", telescope.extensions.orgmode.insert_link, { buffer = true, desc = "Org Insert Link" })
						end
					end

					-- gh: 현재 위치의 부모 헤더로 이동
					vim.keymap.set("n", "gh", function()
						local current_line = vim.fn.line(".")
						-- 현재 줄부터 위로 검색하여 헤더 찾기
						for line_num = current_line, 1, -1 do
							local line_content = vim.fn.getline(line_num)
							if line_content:match("^%*+%s") then
								vim.fn.cursor(line_num, 1)
								-- 헤더 텍스트 시작 위치로 이동 (* 이후)
								vim.fn.search("%*+%s+", "ce", line_num)
								return
							end
						end
						vim.notify("헤더를 찾을 수 없습니다", vim.log.levels.WARN)
					end, { buffer = true, desc = "Org: 부모 헤더로 이동" })

					-- gf: 스마트 폴드 (헤더면 cycle, 내용이면 부모 헤더 접기)
					vim.keymap.set("n", "gf", function()
						local current_line = vim.fn.line(".")
						local line_content = vim.fn.getline(current_line)
						local orgmode = require("orgmode")

						-- 현재 줄이 헤더인지 확인
						if line_content:match("^%*+%s") then
							-- 헤더 줄이면 orgmode cycle 실행
							orgmode.action("org_mappings.cycle")
						else
							-- 내용 줄이면 부모 헤더 찾아서 무조건 접기
							for line_num = current_line - 1, 1, -1 do
								local parent_line = vim.fn.getline(line_num)
								if parent_line:match("^%*+%s") then
									vim.fn.cursor(line_num, 1)
									vim.cmd("normal! zc")
									return
								end
							end
							vim.notify("부모 헤더를 찾을 수 없습니다", vim.log.levels.WARN)
						end
					end, { buffer = true, desc = "Org: 스마트 폴드" })
				end,
			})
		end,
		keys = {
			{ "<leader>oa", "<cmd>Org agenda<CR>", desc = "Org Agenda" },
			{ "<leader>oc", "<cmd>lua require('orgmode').action('capture.prompt')<CR>", desc = "Org Capture" },
		},
	},
}
