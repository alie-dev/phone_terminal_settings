return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-ui-select.nvim", -- ✅ 여기 추가
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			extensions = {
				["ui-select"] = require("telescope.themes").get_dropdown({}),
			},
		})
		pcall(telescope.load_extension, "ui-select")
	end,
}
