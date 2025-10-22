#!/usr/bin/env bash
# setup_termux_env.sh
# nvim / tmux / aichat / termux 백업 + aichat-functions 설치 + termux fullscreen 토글 + ttx(fonttools) 설치
# 여러 번 실행해도 안전하게 동작

set -u

DEST_ROOT="${DEST_ROOT:-$PWD}"

ok(){ printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

copy_if_exists() {
  local src="$1" dest="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    ok "Copied: $src -> $dest"
  else
    warn "Missing: $src"
  fi
}

sync_dir() {
  # src 디렉터리의 **내용물 전체(숨김 포함)**를 dest 디렉터리로 동기화
  # rsync가 있으면 rsync -a, 없으면 cp -a "$src"/. "$dest"/ (숨김 포함)
  local src="$1" dest="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dest"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$src"/ "$dest"/
      ok "Rsync dir: $src -> $dest"
    else
      # 점파일까지 포함하려면 반드시 "/." 패턴 사용
      cp -a "$src"/. "$dest"/ 2>/dev/null || true
      ok "Copied (cp -a): $src -> $dest (hidden included)"
    fi
  else
    warn "Missing dir: $src"
  fi
}

# 0) 백업 폴더 준비
mkdir -p "$DEST_ROOT"/{termux,nvim,aichat,tmux}

# 1) Termux 파일들 -> ./termux
copy_if_exists "$HOME/.termux/font.ttf"              "$DEST_ROOT/termux/font.ttf"
copy_if_exists "$HOME/.termux/termux.properties"     "$DEST_ROOT/termux/termux.properties"
copy_if_exists "$HOME/.termux/toggle_fullscreen.py"  "$DEST_ROOT/termux/toggle_fullscreen.py"
copy_if_exists "$HOME/.termux/update_font_height.py" "$DEST_ROOT/termux/update_font_height.py"
#!/bin/bash

# Create the wezterm config directory structure
mkdir -p wezterm/

# Copy the wezterm configuration file
cp ~/.config/wezterm/wezterm.lua wezterm/

echo "Wezterm config copied to wezterm/.config/wezterm/"

# 2) Neovim 전체(내용물) -> ./nvim
sync_dir "$HOME/.config/nvim" "$DEST_ROOT/nvim"

# 3) aichat -> ./aichat
if [ -f "$HOME/.config/aichat/config.yaml" ]; then
  mkdir -p "$DEST_ROOT/aichat"
  # api_key 부분만 <insert key here>로 교체
  sed -E 's/^( *api_key *:).*/\1 <insert key here>/g' "$HOME/.config/aichat/config.yaml" > "$DEST_ROOT/aichat/config.yaml"
  ok "Sanitized aichat/config.yaml (api_key masked)"
else
  warn "Missing: ~/.config/aichat/config.yaml"
fi
sync_dir       "$HOME/.config/aichat/functions"     "$DEST_ROOT/aichat/functions"
sync_dir       "$HOME/.config/aichat/roles"         "$DEST_ROOT/aichat/roles"

# 4) tmux -> ./tmux (파일 하나)
copy_if_exists "$HOME/.tmux.conf"                   "$DEST_ROOT/tmux/.tmux.conf"

# 5) 런타임용 aichat 폴더 보장
mkdir -p "$HOME/.config/aichat/functions" "$HOME/.config/aichat/sessions"
ok "Ensured: ~/.config/aichat/{functions,sessions}"

echo
ok "Done."
echo "Created: $DEST_ROOT/{termux,nvim,aichat,tmux}"

