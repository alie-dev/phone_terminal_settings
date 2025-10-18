#!/usr/bin/env bash
# restore_data.sh
# 복구(백업된 ./termux, ./nvim, ./aichat, ./tmux -> $HOME) + 설치(Neovim, tmux, Mason, aichat, fonttools, aliases)
# - aichat/config.yaml 의 api_key: 값을 대화형 입력으로 복원
# - Mason 패키지 설치: 기본 세트 or 환경변수 MASON_PKGS 로 지정
# - Termux 환경 가정

set -euo pipefail

ok(){ printf "\033[1;32m[OK]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR]\033[0m %s\n" "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# ====== 설정 가능 값 ======
# 기본 Mason 설치 패키지(원하면 실행 시 MASON_PKGS 로 덮어쓰기)
MASON_PKGS="${MASON_PKGS:-lua-language-server typescript-language-server bash-language-server pyright json-lsp yaml-language-server stylua prettier}"
# =========================

sync_dir_to_home() {
  # ./SRC_DIR 의 "내용물(숨김 포함)"을 DEST_DIR 로 복사
  local src_dir="$1" dest_dir="$2"
  if [ -d "$src_dir" ]; then
    mkdir -p "$dest_dir"
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

  if grep -q '<insert key here>' "$src_cfg"; then
    sed -E "s#^( *api_key *:).*#\1 ${key}#g" "$src_cfg" > "$dest_cfg"
    ok "aichat/config.yaml: <insert key here> → 입력 키로 치환"
  elif grep -Eq '^[[:space:]]*api_key[[:space:]]*:' "$src_cfg"; then
    sed -E "s#^( *api_key *:).*#\1 ${key}#g" "$src_cfg" > "$dest_cfg"
    ok "aichat/config.yaml: 기존 api_key 값을 입력 키로 교체"
  else
    cp -a "$src_cfg" "$dest_cfg"
    printf "\napi_key: %s\n" "$key" >> "$dest_cfg"
    ok "aichat/config.yaml: api_key 라인이 없어 추가"
  fi
}

ensure_packages() {
  # Termux 기본 패키지 설치
  if have pkg; then
    yes | pkg update >/dev/null 2>&1 || true
    # nvim, tmux, git, curl, python, nodejs, build 툴, ripgrep/fd는 편의상
    yes | pkg install -y neovim tmux git curl python nodejs ripgrep fd clang make cmake pkg-config unzip >/dev/null 2>&1 || {
      warn "일부 패키지 설치 실패(무시 가능)"; }
    ok "Base packages ensured (neovim, tmux, git, curl, python, nodejs, ...)"
  else
    warn "'pkg' 명령을 찾을 수 없습니다. Termux가 아닌 환경일 수 있습니다."
  fi
}

install_aichat_cli() {
  if have aichat; then
    ok "aichat 이미 설치됨"
    return
  fi
  # cargo 경로 준비
  if ! have cargo; then
    if have pkg; then
      yes | pkg install -y rust >/dev/null 2>&1 || {
        warn "rust 설치 실패(무시 가능)"; }
    fi
  fi
  if have cargo; then
    cargo install aichat && ok "aichat 설치 완료" || warn "aichat 설치 실패(수동 설치 필요)"
  else
    warn "cargo 없음 → aichat 설치 건너뜀"
  fi
}

deploy_aichat_functions() {
  # ~/.config/aichat/{functions,sessions}
  mkdir -p "$HOME/.config/aichat/functions" "$HOME/.config/aichat/sessions"

  # 로컬 백업에서 functions/roles 복구(이미 위에서 복구해도 idempotent)
  sync_dir_to_home "./aichat/functions" "$HOME/.config/aichat/functions"
  sync_dir_to_home "./aichat/roles"     "$HOME/.config/aichat/roles"

  # 공식 functions 저장소 병합 설치
  if [ ! -d "$HOME/aichat-functions/.git" ]; then
    if have git; then
      git clone https://github.com/sigoden/aichat-functions.git "$HOME/aichat-functions" \
        && ok "Cloned aichat-functions"
    else
      warn "git 없음: aichat-functions 클론 건너뜀"
    fi
  else
    (cd "$HOME/aichat-functions" && git pull --ff-only >/dev/null 2>&1 && ok "Updated aichat-functions" || warn "aichat-functions pull 실패")
  fi

  if [ -d "$HOME/aichat-functions" ]; then
    if have rsync; then
      rsync -a "$HOME/aichat-functions"/ "$HOME/.config/aichat/functions"/
    else
      cp -a "$HOME/aichat-functions"/. "$HOME/.config/aichat/functions"/ 2>/dev/null || true
    fi
    chmod +x "$HOME/.config/aichat/functions/"*.sh 2>/dev/null || true
    ok "Installed functions → ~/.config/aichat/functions"
  fi
}

setup_termux_aliases() {
  mkdir -p "$HOME/.termux"
  # toggle_fullscreen.py 권한(복구된 경우)
  if [ -f "$HOME/.termux/toggle_fullscreen.py" ]; then
    chmod +x "$HOME/.termux/toggle_fullscreen.py" || true
  fi

  local RCFILE
  if [ -n "${ZSH_VERSION-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    RCFILE="$HOME/.zshrc"
  else
    RCFILE="$HOME/.bashrc"
  fi
  touch "$RCFILE"
  sed -i -e '/toggle_fullscreen\.py/d' \
         -e '/^alias tfull=/d' \
         -e '/^alias tunfull=/d' \
         -e '/^alias tftoggle=/d' \
         -e '/^alias tfstatus=/d' "$RCFILE"
  cat >> "$RCFILE" <<'EOF'
# Termux fullscreen toggle aliases
alias tfull='python3 ~/.termux/toggle_fullscreen.py on'
alias tunfull='python3 ~/.termux/toggle_fullscreen.py off'
alias tftoggle='python3 ~/.termux/toggle_fullscreen.py toggle'
alias tfstatus='sh -c '"'"'P="$HOME/.termux/termux.properties"; [ -f "$P" ] && grep -E "^(fullscreen|use-fullscreen-workaround)=" "$P" || echo "fullscreen=(unset)"'"'"
EOF

  # 현재 셸에 적용(가능 시)
  . "$RCFILE" 2>/dev/null || true

  if have termux-reload-settings; then
    termux-reload-settings || true
  fi
  ok "Termux aliases ready (tfull / tunfull / tftoggle / tfstatus)"
}

install_fonttools_ttx() {
  if have ttx; then
    ok "ttx 이미 설치됨"
    return
  fi
  if have pip; then
    pip install --user fonttools && ok "fonttools 설치(ttx)" || warn "fonttools 설치 실패"
  elif have pip3; then
    pip3 install --user fonttools && ok "fonttools 설치(ttx)" || warn "fonttools 설치 실패"
  else
    warn "pip 없음: pkg install python && python -m pip install --user fonttools"
  fi
}

nvim_lazy_sync() {
  if ! have nvim; then warn "nvim 없음 → Lazy sync 건너뜀"; return; fi
  # 플러그인 설치/동기화(사용자 설정에 Lazy.nvim 가정)
  nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "Lazy sync 중 경고(무시 가능)"
  ok "Neovim plugins synced (Lazy)"
}

mason_install() {
  if ! have nvim; then warn "nvim 없음 → Mason 설치 건너뜀"; return; fi
  # Mason 플러그인이 설치되었다는 가정 하에 패키지 설치
  # 여러 패키지를 한 번에 설치
  if [ -n "$MASON_PKGS" ]; then
    nvim --headless +"MasonInstall $MASON_PKGS" +qa >/dev/null 2>&1 || warn "MasonInstall 경고(무시 가능)"
    ok "Mason packages installed: $MASON_PKGS"
  else
    warn "MASON_PKGS 비어있음 → Mason 설치 건너뜀"
  fi
}

# ===================== 실행 순서 =====================

# (0) 기본 패키지 확보(네오빔/티먹스/빌드툴/노드 등) → 이후 단계 의존성 최소화
ensure_packages

# (1) 복구: ./termux -> ~/.termux, ./nvim -> ~/.config/nvim, ./aichat/{functions,roles}, ./tmux/.tmux.conf
sync_dir_to_home "./termux" "$HOME/.termux"
sync_dir_to_home "./nvim"   "$HOME/.config/nvim"
sync_dir_to_home "./aichat/functions" "$HOME/.config/aichat/functions"
sync_dir_to_home "./aichat/roles"     "$HOME/.config/aichat/roles"
copy_file_to_home "./tmux/.tmux.conf" "$HOME/.tmux.conf"

# (2) aichat 키 입력 & config 반영 (복구 후 바로)
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

# (3) aichat CLI 설치 + functions 병합 설치
install_aichat_cli
deploy_aichat_functions

# (4) Termux alias/설정
setup_termux_aliases

# (5) Neovim 플러그인 설치/동기화 → Mason 설치
nvim_lazy_sync
mason_install

# (6) ttx(fonttools) 준비
install_fonttools_ttx

echo
ok "Restore + Install complete."
echo "Restored from ./termux, ./nvim, ./aichat, ./tmux"
echo "Mason packages: ${MASON_PKGS:-<none>}"
echo "Aliases ready: tfull / tunfull / tftoggle / tfstatus"

