-- 1) 기본 옵션/리더키
require("options")

-- 2) 플러그인 (lazy.nvim 부트스트랩 + import 방식)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git","--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
spec = { { import = "plugins" } }, -- lua/plugins/*.lua 자동 로드
})

-- 자동저장
require("auto_save")

-- 키맵 (motions 포함)
require("keymaps")

-- color theme apply
vim.cmd("colorscheme onedark")
require("telescope").load_extension("persisted")  -- 1회만
