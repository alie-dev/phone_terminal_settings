-- webdev.lua (완성본)

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
					init_selection = "4",
					node_incremental = "4",
					node_decremental = "$",
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
			ensure_installed = { "ts_ls", "tailwindcss", "eslint", "lua_ls" },
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

			-- typescript-language-server 경로 자동 탐색 (+ mason 폴백)
			local function ts_cmd()
				local exe = vim.fn.exepath("typescript-language-server")
				if exe == "" then
					local mason = vim.fn.stdpath("data") .. "/mason/bin/typescript-language-server"
					if vim.fn.executable(mason) == 1 then
						exe = mason
					end
				end
				if exe == "" then
					vim.schedule(function()
						vim.notify(
							"[ts_ls] typescript-language-server not found. Install via :Mason or `npm i -g typescript typescript-language-server`",
							vim.log.levels.ERROR
						)
					end)
					return nil
				end
				return { exe, "--stdio" }
			end

			-- ts_ls
			vim.lsp.config("ts_ls", {
				cmd = ts_cmd(), -- 자동 탐색 + mason 폴백
				capabilities = caps,
				on_attach = on_attach,
				single_file_support = true,
				filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
				-- root_dir은 절대 nil이 나오지 않게 폴백을 충분히 둔다
				root_dir = function(fname)
					return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(fname)
						or util.find_git_ancestor(fname)
						or vim.loop.cwd()
				end,
				on_init = function(_, ctx)
					vim.schedule(function()
						vim.notify(("[ts_ls] started (root=%s)"):format(ctx.root_dir or "?"), vim.log.levels.INFO)
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
				on_attach = function(client, bufnr)
					pcall(on_attach, client, bufnr)
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							pcall(vim.cmd, "EslintFixAll")
						end,
					})
				end,
				root_dir = function(fname)
					return util.root_pattern(
						".eslintrc",
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.json",
						"package.json",
						".git"
					)(fname) or util.path.dirname(fname)
				end,
			})

			-- lua_ls
			vim.lsp.config("lua_ls", {
				capabilities = caps,
				on_attach = on_attach,
				root_dir = function(fname)
					return util.root_pattern(
						".luarc.json",
						".luarc.jsonc",
						".luacheckrc",
						".stylua.toml",
						"stylua.toml",
						"selene.toml",
						"selene.yml",
						".git"
					)(fname) or util.path.dirname(fname) or vim.fn.getcwd()
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

			-- enable
			for _, name in ipairs({ "ts_ls", "tailwindcss", "eslint", "lua_ls" }) do
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
					return util.root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(fname)
						or util.find_git_ancestor(fname)
						or vim.loop.cwd()
				end

				vim.api.nvim_create_autocmd("FileType", {
					pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
					callback = function(ev)
						-- 이미 붙어 있으면 스킵
						for _, c in pairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
							if c.name == "ts_ls" then
								return
							end
						end
						local cmd = ts_cmd()
						if not cmd then
							return
						end
						local file = vim.api.nvim_buf_get_name(ev.buf)
						vim.lsp.start({
							name = "ts_ls",
							cmd = cmd,
							root_dir = ts_root(file),
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
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format({ async = false })
							end,
						})
					end
				end,
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
	-- codecompanion AI자동 분석기
	---------------------------------------------------------------------------

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			opts = { log_level = "DEBUG" }, -- DEBUG / TRACE

			adapters = {
				http = {
					anthropic = function()
						return require("codecompanion.adapters").extend("anthropic", {
							env = { api_key = vim.env.ANTHROPIC_API_KEY },
							-- endpoint = "https://api.anthropic.com/v1/messages", -- 필요시 명시
						})
					end,

					opts = {
						timeout = 30000, -- ms 단위, API 호출 타임아웃
					},
				},
			},

			strategies = {
				chat = {
					adapter = "anthropic",
					model = "claude-opus-4-1",
					params = { max_output_tokens = 32000 },
				},
				inline = {
					adapter = "anthropic",
					model = "claude-sonnet-4",
					params = { max_output_tokens = 64000 },
				},
			},
		},
	},
	---------------------------------------------------------------------------
	-- 자동정렬
	---------------------------------------------------------------------------

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				javascript = { "prettierd", "prettier" },
				typescript = { "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				html = { "prettierd", "prettier" },
				lua = { "stylua" },
				-- 필요시 추가…
			},
			format_on_save = { lsp_fallback = true, timeout_ms = 2000 },
		},
	},
}
