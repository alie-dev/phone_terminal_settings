#!/usr/bin/env bash
# restore_data_min.sh
# 목적: 복구(./termux, ./nvim, ./aichat, ./tmux -> $HOME) + 설치(Neovim, tmux, Mason, aichat, fonttools, aliases)만 수행
# - 추가 패키지 과다 설치 금지: 필수만 시도
# - macOS: brew 로 nvim/tmux만. aichat은 brew 또는 cargo(있을 때만).
# - Termux: pkg 로 nvim/tmux만.
# - fonttools는 python/pip 있을 때만 설치, 없으면 경고.
# - aichat-functions는 네가 원래 스크립트에 넣어뒀으니 유지(있으면 pull, 없으면 git 있을 때만 clone).
set -euo pipefail

ok(){ printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s || echo unknown)"

# Mason 설치 대상(원하면 실행 시 MASON_PKGS 로 덮어쓰기)
MASON_PKGS="${MASON_PKGS:-lua-language-server typescript-language-server bash-language-server pyright json-lsp yaml-language-server stylua prettier}"

# BSD/macOS sed in-place 호환
inplace_sed() {
  # usage: inplace_sed 's/old/new/g' file
  if [[ "$OS" == "Darwin" ]]; then
    sed -E -i '' "$1" "$2"
  else
    sed -E -i "$1" "$2"
  fi
}

sync_dir_to_home() {
  local src_dir="$1" dest_dir="$2"
  if [ -d "$src_dir" ]; then
    mkdir -p "$dest_dir"
    # rsync 설치 강요하지 않음: 있으면 rsync, 없으면 cp
    if have rsync; then
      rsync -a "$src_dir"/ "$dest_dir"/
    else
      cp -a "$src_dir"/. "$dest_dir"/ 2>/dev/null || true
    fi
    ok "Restore dir: $src_dir -> $dest_dir"
  else
    warn "Skip (missing dir): $src_dir"
  fi
}

copy_file_to_home() {
  local src="$1" dest="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    ok "Restore file: $src -> $dest"
  else
    warn "Skip (missing file): $src"
  fi
}

restore_aichat_config_with_key() {
  local src_cfg="./aichat/config.yaml"
  local dest_cfg="$HOME/.config/aichat/config.yaml"
  local key="$1"

  if [ ! -f "$src_cfg" ]; then
    warn "aichat/config.yaml 백업 없음 → 키 반영 건너뜀"
    return 0
  fi

  mkdir -p "$(dirname "$dest_cfg")"
  cp -a "$src_cfg" "$dest_cfg"

  if grep -q '<insert key here>' "$dest_cfg"; then
    inplace_sed "s#^( *api_key *:).*#\\1 ${key}#g" "$dest_cfg"
    ok "aichat/config.yaml: placeholder → 입력 키"
  elif grep -Eq '^[[:space:]]*api_key[[:space:]]*:' "$dest_cfg"; then
    inplace_sed "s#^( *api_key *:).*#\\1 ${key}#g" "$dest_cfg"
    ok "aichat/config.yaml: 기존 api_key → 입력 키"
  else
    printf "\napi_key: %s\n" "$key" >> "$dest_cfg"
    ok "aichat/config.yaml: api_key 라인 추가"
  fi
}

ensure_min_packages() {
  case "$OS" in
    Darwin)
      # 최소만: neovim, tmux
      if have brew; then
        brew list --versions neovim >/dev/null 2>&1 || brew install neovim
        brew list --versions tmux   >/dev/null 2>&1 || brew install tmux
        ok "[macOS] neovim, tmux 준비"
      else
        err "Homebrew가 없습니다. 설치 후 다시 실행하세요: https://brew.sh"
        exit 1
      fi
      ;;
    Linux)
      if have pkg; then
        # 최소만: neovim, tmux
        yes | pkg update >/dev/null 2>&1 || true
        yes | pkg install -y neovim tmux >/dev/null 2>&1 || warn "nvim/tmux 설치 실패(수동 확인)"
        ok "[Termux] neovim, tmux 준비"
      else
        warn "Linux 감지됨(비-Termux). 이 스크립트는 Termux/macOS 최소 구성을 가정."
      fi
      ;;
    *)
      warn "알 수 없는 OS: $OS"
      ;;
  esac
}

install_aichat_cli() {
  if have aichat; then
    ok "aichat 이미 설치됨"
    return
  fi
  if [[ "$OS" == "Darwin" ]] && have brew; then
    if brew info aichat >/dev/null 2>&1; then
      brew install aichat && { ok "aichat 설치(brew)"; return; }
    fi
  fi
  # cargo가 있을 때만 설치 시도(러스트 자동설치 안 함)
  if have cargo; then
    cargo install aichat && ok "aichat 설치(cargo)" || warn "aichat 설치 실패(cargo)"
  else
    warn "aichat 미설치: cargo 없음. (옵션) rust 설치 후 재실행하거나 brew formula 사용"
  fi
}

deploy_aichat_functions() {
  # 원래 스크립트에 포함되어 있으므로 유지(필요 시만 실행)
  mkdir -p "$HOME/.config/aichat/functions" "$HOME/.config/aichat/sessions"
  sync_dir_to_home "./aichat/functions" "$HOME/.config/aichat/functions"
  sync_dir_to_home "./aichat/roles"     "$HOME/.config/aichat/roles"

  if [ ! -d "$HOME/aichat-functions/.git" ]; then
    if have git; then
      git clone https://github.com/sigoden/llm-functions.git "$HOME/aichat-functions" && ok "Cloned aichat-functions"
    else
      warn "git 없음: aichat-functions 클론 생략(로컬 백업만 적용)"
    fi
  else
    (cd "$HOME/aichat-functions" && git pull --ff-only >/dev/null 2>&1 && ok "Updated aichat-functions" || warn "aichat-functions pull 실패")
  fi

  if [ -d "$HOME/aichat-functions" ]; then
    # rsync 없으면 cp
    if have rsync; then
      rsync -a "$HOME/aichat-functions"/ "$HOME/.config/aichat/functions"/
    else
      cp -a "$HOME/aichat-functions"/. "$HOME/.config/aichat/functions"/ 2>/dev/null || true
    fi
    chmod +x "$HOME/.config/aichat/functions/"*.sh 2>/dev/null || true
    ok "Installed functions → ~/.config/aichat/functions"
  fi
}

setup_aliases() {
  local RCFILE
  if [ -n "${ZSH_VERSION-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    RCFILE="$HOME/.zshrc"
  else
    RCFILE="$HOME/.bashrc"
  fi
  mkdir -p "$HOME/.termux"
  [ -f "$HOME/.termux/toggle_fullscreen.py" ] && chmod +x "$HOME/.termux/toggle_fullscreen.py" || true

  touch "$RCFILE"
  if [[ "$OS" == "Darwin" ]]; then
    sed -E -i '' -e '/toggle_fullscreen\.py/d' -e '/^alias tfull=/d' -e '/^alias tunfull=/d' -e '/^alias tftoggle=/d' -e '/^alias tfstatus=/d' "$RCFILE"
  else
    sed -E -i    -e '/toggle_fullscreen\.py/d' -e '/^alias tfull=/d' -e '/^alias tunfull=/d' -e '/^alias tftoggle=/d' -e '/^alias tfstatus=/d' "$RCFILE"
  fi

  cat >> "$RCFILE" <<'EOF'
# Termux fullscreen toggle aliases (Termux 사용 시 동작)
alias tfull='python3 ~/.termux/toggle_fullscreen.py on'
alias tunfull='python3 ~/.termux/toggle_fullscreen.py off'
alias tftoggle='python3 ~/.termux/toggle_fullscreen.py toggle'
alias tfstatus='sh -c '"'"'P="$HOME/.termux/termux.properties"; [ -f "$P" ] && grep -E "^(fullscreen|use-fullscreen-workaround)=" "$P" || echo "fullscreen=(unset)"'"'"
EOF

  . "$RCFILE" 2>/dev/null || true
  if have termux-reload-settings; then termux-reload-settings || true; fi
  ok "Aliases ready (tfull / tunfull / tftoggle / tfstatus)"
}

install_fonttools_ttx() {
  if have ttx; then ok "ttx 이미 설치됨"; return; fi
  if have python3 && python3 -m pip --version >/dev/null 2>&1; then
    python3 -m pip install --user fonttools && ok "fonttools 설치(ttx)" || warn "fonttools 설치 실패"
  else
    warn "python3/pip 미발견 → ttx 설치 생략(원하면 나중에 수동 설치)"
  fi
}

nvim_lazy_sync() {
  if ! have nvim; then warn "nvim 없음 → Lazy sync 생략"; return; fi
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "Lazy sync 경고(무시 가능)"
  ok "Neovim plugins synced (Lazy)"
}

mason_install() {
  if ! have nvim; then warn "nvim 없음 → Mason 생략"; return; fi
  if [ -n "$MASON_PKGS" ]; then
    nvim --headless +"MasonInstall $MASON_PKGS" +qa >/dev/null 2>&1 || warn "MasonInstall 경고(무시 가능)"
    ok "Mason packages installed: $MASON_PKGS"
  else
    warn "MASON_PKGS 비어있음 → Mason 설치 생략"
  fi
}

# ===================== 실행 =====================
ensure_min_packages

# 복구
sync_dir_to_home "./termux" "$HOME/.termux"
sync_dir_to_home "./nvim"   "$HOME/.config/nvim"
sync_dir_to_home "./aichat/functions" "$HOME/.config/aichat/functions"
sync_dir_to_home "./aichat/roles"     "$HOME/.config/aichat/roles"
copy_file_to_home "./tmux/.tmux.conf" "$HOME/.tmux.conf"
copy_file_to_home "./wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

# aichat 키 반영
if [ -f "./aichat/config.yaml" ]; then
  printf "Enter your ChatGPT API key (hidden input): "
  stty -echo; read -r KEY; stty echo; printf "\n"
  if [ -n "${KEY:-}" ]; then
    restore_aichat_config_with_key "$KEY"
  else
    warn "빈 키 입력 → aichat/config.yaml 키 반영 생략"
  fi
else
  warn "./aichat/config.yaml 없음 → 키 반영 생략"
fi

# aichat / functions
install_aichat_cli
deploy_aichat_functions

# aliases, Neovim & Mason, fonttools
setup_aliases
nvim_lazy_sync
mason_install
install_fonttools_ttx

#!/bin/bash

# Anthropic API 키를 사용자로부터 입력받기
echo "Anthropic API 키를 입력하세요:"
read -s anthropic_key

# API 키를 임시 파일에 저장
echo "$anthropic_key" > ~/.anthropic-api-key

# GPG로 파일을 AES256 암호화
echo "암호화를 위한 패스워드를 설정하세요:"
gpg --symmetric --cipher-algo AES256 ~/.anthropic-api-key

# 원본 파일 삭제
rm ~/.anthropic-api-key

echo "API 키가 암호화되어 ~/.anthropic-api-key.gpg 파일로 저장되었습니다."

echo
ok "Restore + Install complete (minimal)."
echo "Restored from ./termux, ./nvim, ./aichat, ./tmux, ./wezterm"
echo "Mason packages: ${MASON_PKGS:-<none>}"
echo "Aliases ready: tfull / tunfull / tftoggle / tfstatus"

