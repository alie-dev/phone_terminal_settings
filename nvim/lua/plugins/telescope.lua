return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-orgmode/telescope-orgmode.nvim",
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				["ui-select"] = require("telescope.themes").get_dropdown({}),
			},
		})
		pcall(telescope.load_extension, "ui-select")
		pcall(telescope.load_extension, "orgmode")

		-- orgmode telescope 키맵 (전역)
		vim.keymap.set("n", "<leader>oh", telescope.extensions.orgmode.search_headings, { desc = "Org Headlines" })
	end,
}
