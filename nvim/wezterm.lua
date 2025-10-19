local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font{family = "MesloLGS Nerd Font Mono", weight = "Regular"}
config.font_size = 17

config.line_height = 1.30


config.colors = {
  foreground = "#dcdcdc", -- 연한 회색 글자
  background = "#1e1e1e", -- 딱 Visual Studio Code Dark 같은 검회색
  cursor_bg = "#dcdcdc",
  cursor_fg = "#1e1e1e",
  selection_bg = "#444444",
  selection_fg = "#ffffff",
}

-- 탭/창 스타일
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.96
config.macos_window_background_blur = 20
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.8 }

-- 여백 주기(상단·좌우 살짝 여유)
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

-- 모든 기본 단축키 제거
config.disable_default_key_bindings = true

-- 필요한 키만 다시 정의
config.keys = {
  -- 복사/붙여넣기
  { key = "c", mods = "CMD", action = wezterm.action.CopyTo "Clipboard" },
  { key = "v", mods = "CMD", action = wezterm.action.PasteFrom "Clipboard" },

  -- 탭 전환 (iTerm 스타일 ⌘+숫자)
  { key = "F1", mods = "CMD", action = wezterm.action.ActivateTab(0) },
  { key = "F2", mods = "CMD", action = wezterm.action.ActivateTab(1) },
  { key = "F3", mods = "CMD", action = wezterm.action.ActivateTab(2) },
  { key = "F4", mods = "CMD", action = wezterm.action.ActivateTab(3) },
  { key = "F5", mods = "CMD", action = wezterm.action.ActivateTab(4) },
  { key = "F6", mods = "CMD", action = wezterm.action.ActivateTab(5) },
  { key = "F7", mods = "CMD", action = wezterm.action.ActivateTab(6) },
  { key = "F8", mods = "CMD", action = wezterm.action.ActivateTab(7) },
  { key = "F9", mods = "CMD", action = wezterm.action.ActivateTab(8) },
  { key = "F10", mods = "CMD", action = wezterm.action.ActivateTab(9) },

  -- 창 닫기 (⌘⇧W)
  { key = "w", mods = "CMD|SHIFT", action = wezterm.action.CloseCurrentPane { confirm = true } },
}
-- 여기부턴 키들 nvim으로 보내기 
-- Cmd+Shift+[ / ]  → Alt+[ / Alt+]
table.insert(config.keys, {
  key = "{", mods = "CMD|SHIFT",
  action = wezterm.action.SendString("\x1b{")  -- ESC + {
})
table.insert(config.keys, {
  key = "}", mods = "CMD|SHIFT",
  action = wezterm.action.SendString("\x1b}")  -- ESC + }
})
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

table.insert(config.keys, {
  key = "w", mods = "CMD",
  action = wezterm.action.SendKey{ key = "w", mods = "ALT" },
})


-- Cmd+1 → Alt+1  (사이드 토글용)
table.insert(config.keys, { key = "1", mods = "CMD", action = wezterm.action.SendKey{ key = "1", mods = "ALT" } })

-- Cmd+W → Alt+w  (사이드 닫기)
table.insert(config.keys, { key = "w", mods = "CMD", action = wezterm.action.SendKey{ key = "w", mods = "ALT" } })

-- Cmd+Shift+W → Alt+W  (현재 것만 남기고 나머지 닫기)
table.insert(config.keys, { key = "w", mods = "CMD|SHIFT", action = wezterm.action.SendKey{ key = "w", mods = "ALT|SHIFT" } })

table.insert(config.keys, { key = "j", mods = "CMD", action = wezterm.action.SendKey{ key = "j", mods = "ALT"} })

table.insert(config.keys, { key = "k", mods = "CMD", action = wezterm.action.SendKey{ key = "k", mods = "ALT"} })

-- Alt+Enter → <M-CR>
table.insert(config.keys, {
  key = "Enter", mods = "CMD",
  action = wezterm.action.SendString("\x1b\r"),
})

-- Alt+Backspace → <M-Del> (DEL=0x7f)
table.insert(config.keys, {
  key = "Backspace", mods = "CMD",
  action = wezterm.action.SendString("\x1b\x7f"),
})
-- Cmd+d → Alt+j
table.insert(config.keys, {
  key = "d",
  mods = "SUPER",
  action = wezterm.action.SendKey { key = "j", mods = "ALT" },
})

-- Cmd+u → Alt+k
table.insert(config.keys, {
  key = "u",
  mods = "SUPER",
  action = wezterm.action.SendKey { key = "k", mods = "ALT" },
})

table.insert(config.keys, {
  key = "l",
  mods = "SUPER",
  action = wezterm.action.SendKey { key = "l", mods = "ALT" },
})
table.insert(config.keys, {
  key = "h",
  mods = "SUPER",
  action = wezterm.action.SendKey { key = "h", mods = "ALT" },
})
table.insert(config.keys, {
  key = "l",
  mods = "SUPER|SHIFT",
  action = wezterm.action.SendKey { key = "l", mods = "ALT|SHIFT" },
})
table.insert(config.keys, {
  key = "h",
  mods = "SUPER|SHIFT",
  action = wezterm.action.SendKey { key = "h", mods = "ALT|SHIFT" },
})

table.insert(config.keys, {
  key = "j",
  mods = "SUPER|SHIFT",
  action = wezterm.action.SendKey { key = "j", mods = "ALT|SHIFT" },
})
table.insert(config.keys, {
  key = "k",
  mods = "SUPER|SHIFT",
  action = wezterm.action.SendKey { key = "k", mods = "ALT|SHIFT" },
})
table.insert(config.keys, {
  key = "a",
  mods = "SUPER",
  action = wezterm.action.SendKey { key = "a", mods = "ALT" },
})

return config

