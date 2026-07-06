#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/bootstrap.conf"
EXPORTED_SETTINGS_FILE="${ROOT_DIR}/config/exported-macos-settings.conf"
BREWFILE="${ROOT_DIR}/Brewfile"

if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
else
  echo "Missing config file: ${CONFIG_FILE}" >&2
  exit 1
fi

DRY_RUN="${DRY_RUN:-0}"
SKIP_MACOS_DEFAULTS="${SKIP_MACOS_DEFAULTS:-0}"
USE_EXPORTED_SETTINGS="${USE_EXPORTED_SETTINGS:-0}"

if [[ "${USE_EXPORTED_SETTINGS}" == "1" ]]; then
  if [[ -f "${EXPORTED_SETTINGS_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${EXPORTED_SETTINGS_FILE}"
  else
    echo "Requested exported settings, but file is missing: ${EXPORTED_SETTINGS_FILE}" >&2
    exit 1
  fi
fi

log() {
  printf "\n==> %s\n" "$*"
}

run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf "[dry-run]"
    printf " %q" "$@"
    printf "\n"
  else
    "$@"
  fi
}

append_once() {
  local file="$1"
  local marker="$2"
  local content="$3"

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[dry-run] append to ${file}: ${marker}"
    return
  fi

  mkdir -p "$(dirname "${file}")"
  touch "${file}"

  if ! grep -Fq "${marker}" "${file}"; then
    {
      printf "\n%s\n" "${marker}"
      printf "%s\n" "${content}"
    } >> "${file}"
  fi
}

ensure_xcode_cli_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  log "Installing Xcode Command Line Tools"
  run xcode-select --install
  if [[ "${DRY_RUN}" != "1" ]]; then
    echo "Rerun this script after the Xcode Command Line Tools installer finishes."
    exit 0
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[dry-run] /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

setup_homebrew_shellenv() {
  local brew_bin=""

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    brew_bin="/usr/local/bin/brew"
  elif command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  fi

  if [[ -z "${brew_bin}" ]]; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      brew_bin="/opt/homebrew/bin/brew"
      BREW_PREFIX="/opt/homebrew"
      append_once "${SHELL_PROFILE}" "# macos-bootstrap-kit: Homebrew" "eval \"\$(${brew_bin} shellenv)\""
      echo "[dry-run] assuming Homebrew path: ${brew_bin}"
      return
    fi

    echo "Homebrew is not available on PATH yet. Open a new terminal and rerun this script." >&2
    exit 1
  fi

  eval "$("${brew_bin}" shellenv)"
  BREW_PREFIX="$("${brew_bin}" --prefix)"
  append_once "${SHELL_PROFILE}" "# macos-bootstrap-kit: Homebrew" "eval \"\$(${brew_bin} shellenv)\""
}

install_brew_bundle() {
  log "Installing Homebrew bundle"
  run brew update
  run brew bundle --file "${BREWFILE}"
}

check_container_runtime() {
  if [[ "${REQUIRE_DOCKER:-true}" != "true" ]]; then
    return
  fi

  log "Checking Colima and Docker CLI"

  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "[dry-run] check docker, docker-compose, and colima"
    if [[ "${START_COLIMA:-0}" == "1" ]]; then
      run colima start --cpu "${COLIMA_CPU}" --memory "${COLIMA_MEMORY}" --disk "${COLIMA_DISK}"
    else
      echo "[dry-run] optionally run: colima start --cpu ${COLIMA_CPU} --memory ${COLIMA_MEMORY} --disk ${COLIMA_DISK}"
    fi
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    docker --version
  else
    echo "docker CLI is not on PATH after brew bundle." >&2
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    docker-compose --version
  else
    echo "docker-compose is not on PATH after brew bundle." >&2
  fi

  if command -v colima >/dev/null 2>&1; then
    colima version
  else
    echo "colima is not on PATH after brew bundle." >&2
    return
  fi

  if [[ "${START_COLIMA:-0}" == "1" ]]; then
    run colima start --cpu "${COLIMA_CPU}" --memory "${COLIMA_MEMORY}" --disk "${COLIMA_DISK}"
  else
    echo "Colima installed. Start it when needed with:"
    echo "  colima start --cpu ${COLIMA_CPU} --memory ${COLIMA_MEMORY} --disk ${COLIMA_DISK}"
  fi
}

setup_nvm() {
  local nvm_dir="${HOME}/.nvm"
  local brew_prefix="${BREW_PREFIX:-}"

  if [[ -z "${brew_prefix}" ]]; then
    brew_prefix="$(brew --prefix)"
  fi

  run mkdir -p "${nvm_dir}"

  append_once "${SHELL_PROFILE}" "# macos-bootstrap-kit: nvm" "export NVM_DIR=\"\${HOME}/.nvm\"
[ -s \"${brew_prefix}/opt/nvm/nvm.sh\" ] && . \"${brew_prefix}/opt/nvm/nvm.sh\"
[ -s \"${brew_prefix}/opt/nvm/etc/bash_completion.d/nvm\" ] && . \"${brew_prefix}/opt/nvm/etc/bash_completion.d/nvm\""

  if [[ "${DRY_RUN}" != "1" ]]; then
    # shellcheck source=/dev/null
    source "${brew_prefix}/opt/nvm/nvm.sh"
  fi

  log "Installing Node.js (${NODE_VERSION})"
  run nvm install "${NODE_VERSION}"
  run nvm alias default "${NODE_VERSION}"
}

setup_pyenv() {
  local pyenv_root="${HOME}/.pyenv"

  append_once "${SHELL_PROFILE}" "# macos-bootstrap-kit: pyenv" "export PYENV_ROOT=\"\${HOME}/.pyenv\"
command -v pyenv >/dev/null 2>&1 && eval \"\$(pyenv init -)\""

  export PYENV_ROOT="${pyenv_root}"
  export PATH="${PYENV_ROOT}/bin:${PATH}"

  if [[ "${DRY_RUN}" == "1" ]]; then
    log "Installing Python (${PYTHON_VERSION})"
    run pyenv install "${PYTHON_VERSION}"
    run pyenv global "${PYTHON_VERSION}"
    return
  fi

  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    if ! pyenv versions --bare | grep -Fxq "${PYTHON_VERSION}"; then
      log "Installing Python (${PYTHON_VERSION})"
      run pyenv install "${PYTHON_VERSION}"
    else
      log "Python ${PYTHON_VERSION} already installed"
    fi
    run pyenv global "${PYTHON_VERSION}"
  fi
}

install_global_npm_packages() {
  if [[ "${#NPM_GLOBAL_PACKAGES[@]}" -eq 0 ]]; then
    return
  fi

  log "Installing global npm tools"
  run npm install -g "${NPM_GLOBAL_PACKAGES[@]}"
}

apply_macos_defaults() {
  if [[ "${SKIP_MACOS_DEFAULTS}" == "1" ]]; then
    log "Skipping macOS defaults"
    return
  fi

  log "Applying macOS defaults"
  run mkdir -p "${SCREENSHOT_DIR}"

  run defaults write com.apple.dock orientation -string "${DOCK_POSITION}"
  run defaults write com.apple.dock tilesize -int "${DOCK_ICON_SIZE}"
  run defaults write com.apple.dock autohide -bool "${DOCK_AUTOHIDE}"

  run defaults write NSGlobalDomain KeyRepeat -int "${KEY_REPEAT}"
  run defaults write NSGlobalDomain InitialKeyRepeat -int "${INITIAL_KEY_REPEAT}"
  run defaults write NSGlobalDomain AppleLanguages -array "${APPLE_LANGUAGES[@]}"
  run defaults write NSGlobalDomain AppleLocale -string "${APPLE_LOCALE}"
  run defaults write NSGlobalDomain AppleMeasurementUnits -string "${APPLE_MEASUREMENT_UNITS}"
  run defaults write NSGlobalDomain AppleMetricUnits -bool "${APPLE_METRIC_UNITS}"

  run defaults write NSGlobalDomain AppleShowAllExtensions -bool "${FINDER_SHOW_ALL_EXTENSIONS}"
  run defaults write com.apple.finder AppleShowAllFiles -bool "${FINDER_SHOW_HIDDEN_FILES}"
  run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  run defaults write com.apple.screencapture location -string "${SCREENSHOT_DIR}"

  run killall Dock
  run killall Finder
  run killall SystemUIServer
}

main() {
  log "Starting macos-bootstrap-kit"
  ensure_xcode_cli_tools
  ensure_homebrew
  setup_homebrew_shellenv
  install_brew_bundle
  check_container_runtime
  setup_nvm
  install_global_npm_packages
  setup_pyenv
  apply_macos_defaults
  log "Done. Restart the terminal, then run: node --version && python --version && docker --version && colima version && claude --version && codex --version"
}

main "$@"
