return {
  "olimorris/persisted.nvim",
  event = "BufReadPre",
  opts = {
    autoload = true,   -- nvim 시작 시 자동으로 최근/현재 폴더 세션 로드
    autosave = true,   -- 종료/전환 시 자동 저장
    use_git_branch = true, -- 폴더 + 현재 git 브랜치 조합으로 세션 구분
  },
  config = function(_, opts)
    local persisted = require("persisted")
    persisted.setup(opts)

    -- 키맵 (원하는 리더키로 바꿔도 됨)
    vim.keymap.set("n", "<leader>st", "<cmd>SessionToggle<CR>", { desc = "Session: Toggle" })
    vim.keymap.set("n", "<leader>ss", "<cmd>SessionSave<CR>",   { desc = "Session: Save" })
    vim.keymap.set("n", "<leader>sl", "<cmd>SessionLoad<CR>",   { desc = "Session: Load (cwd)" })
    vim.keymap.set("n", "<leader>sl", "<cmd>SessionLoadLast<CR>", { desc = "Session: Load Last" })

    -- Telescope 확장 (있으면 UI로 목록 선택 가능)
    pcall(function()
      require("telescope").load_extension("persisted")
      vim.keymap.set("n", "<leader>sp", "<cmd>Telescope persisted<CR>", { desc = "Session: Pick (Telescope)" })
    end)
  end,
}
