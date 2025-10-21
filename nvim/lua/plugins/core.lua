-- lua/plugins/init.lua (예시)
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

  -- ⛏️ LSP
  { "neovim/nvim-lspconfig" },

  -- 🚧 문제 리스트
  { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },

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

      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            vim.defer_fn(function()
              require("neo-tree.command").execute({ action = "close" })
            end, 0)
          end,
        },
      },

      filesystem = {
        follow_current_file = { enabled = false }, -- 다시 열림 방지
        filtered_items = { hide_gitignored = false, hide_dotfiles = false},
      },

      window = { width = 26; },
      
    })
  end,
},

  -- 📌 Git signs (사이드라인/워드 단위 diff)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "▎" },
        topdelete    = { text = "▎" },
        changedelete = { text = "▎" },
      },
      word_diff = true,
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
          offsets = { { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true } },
        },
      })
    end,
  },

  -- 📊 상태줄 (스샷 같은 배치)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- LSP 이름
      local function lsp_name()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then return "" end
        local names = {}
        for _, c in ipairs(clients) do names[#names+1] = c.name end
        return "  " .. table.concat(names, ",")
      end
      -- 인덴트 정보
      local function indent_info()
        if vim.bo.expandtab then
          local sw = (vim.bo.shiftwidth > 0) and vim.bo.shiftwidth or vim.bo.tabstop
          return "Spaces:" .. sw
        else
          return "Tab:" .. vim.bo.tabstop
        end
      end
      -- ⚙ 버튼 (클릭 시 Lazy 열기; 원하면 Mason/Telescope 등으로 변경)
      local settings_button = {
        "",
        padding = { left = 1, right = 1 },
        on_click = function() vim.cmd("Lazy") end,
      }

      require("lualine").setup({
  options = {
    theme = "onedark",
    globalstatus = true,
    -- 반원/화살표 없애기
    section_separators = { left = "", right = "" },
    -- 왼쪽 컴포넌트들 사이에는 "/" 스타일, 오른쪽은 없음
    component_separators = { left = "/", right = "" },
  },
  sections = {
    lualine_a = { { "mode", padding = { left = 2, right = 2 } } },
    lualine_b = {
      { "branch", icon = "", padding = { left = 1, right = 1 } },
      { "diff",   symbols = { added = "+", modified = "~", removed = "-" }, padding = { left = 1, right = 1 } },
      { "diagnostics", sources = { "nvim_diagnostic" }, padding = { left = 1, right = 1 } },
    },
    lualine_c = {
      { "filename", path = 1, symbols = { modified = "●", readonly = "", unnamed = "[No Name]" },
        padding = { left = 2, right = 2 } },
    },
    lualine_x = {
      function()
        local cs = vim.lsp.get_clients({ bufnr = 0 })
        if #cs == 0 then return "" end
        local names = {}
        for _, c in ipairs(cs) do names[#names+1] = c.name end
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
        function() return "" end,
        on_click = function() vim.cmd("Lazy") end,
        padding = { left = 1, right = 1 },
      },
    },
  },
})
    end,
  },
}

