#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/bootstrap.conf"
BREWFILE="${ROOT_DIR}/Brewfile"

if [[ -f "${CONFIG_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
else
  echo "Missing config file: ${CONFIG_FILE}" >&2
  exit 1
fi

DRY_RUN="${DRY_RUN:-0}"

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
  log "Done. Restart the terminal, then run: node --version && python --version && docker --version && colima version && claude --version && codex --version"
}

main "$@"
