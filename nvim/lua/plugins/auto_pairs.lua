return {
  -- 다른 플러그인 설정도 이곳에 추가할 수  있습니다.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
}
