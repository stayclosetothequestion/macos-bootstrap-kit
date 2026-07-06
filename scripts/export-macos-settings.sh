#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="${ROOT_DIR}/config/exported-macos-settings.conf"
RAW_DIR="${ROOT_DIR}/config/current-defaults"

read_default() {
  local domain="$1"
  local key="$2"
  local fallback="$3"

  defaults read "${domain}" "${key}" 2>/dev/null || printf "%s" "${fallback}"
}

write_var() {
  local name="$1"
  local value="$2"
  printf "%s=%q\n" "${name}" "${value}" >> "${OUT_FILE}"
}

write_array() {
  local name="$1"
  shift

  printf "%s=(" "${name}" >> "${OUT_FILE}"
  local item
  for item in "$@"; do
    printf "%q " "${item}" >> "${OUT_FILE}"
  done
  printf ")\n" >> "${OUT_FILE}"
}

export_domain() {
  local domain="$1"
  local file="$2"

  if [[ "${domain}" == "NSGlobalDomain" ]]; then
    defaults export -g "${RAW_DIR}/${file}" >/dev/null 2>&1 || true
    return
  fi

  if defaults domains | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -Fxq "${domain}"; then
    defaults export "${domain}" "${RAW_DIR}/${file}" >/dev/null 2>&1 || true
  fi
}

mkdir -p "${RAW_DIR}"

{
  printf "# Exported macOS settings for macos-bootstrap-kit\n"
  printf "# Generated at: %s\n" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf "# Review before copying values into config/bootstrap.conf.\n\n"
} > "${OUT_FILE}"

write_var "DOCK_POSITION" "$(read_default com.apple.dock orientation left)"
write_var "DOCK_ICON_SIZE" "$(read_default com.apple.dock tilesize 42)"
write_var "DOCK_AUTOHIDE" "$(read_default com.apple.dock autohide true)"
write_var "KEY_REPEAT" "$(read_default NSGlobalDomain KeyRepeat 2)"
write_var "INITIAL_KEY_REPEAT" "$(read_default NSGlobalDomain InitialKeyRepeat 15)"
write_var "SCREENSHOT_DIR" "$(read_default com.apple.screencapture location "${HOME}/Screenshots")"
write_var "FINDER_SHOW_ALL_EXTENSIONS" "$(read_default NSGlobalDomain AppleShowAllExtensions true)"
write_var "FINDER_SHOW_HIDDEN_FILES" "$(read_default com.apple.finder AppleShowAllFiles false)"
write_var "APPLE_LOCALE" "$(read_default NSGlobalDomain AppleLocale en_US)"
write_var "APPLE_MEASUREMENT_UNITS" "$(read_default NSGlobalDomain AppleMeasurementUnits Centimeters)"
write_var "APPLE_METRIC_UNITS" "$(read_default NSGlobalDomain AppleMetricUnits 1)"

apple_languages=()
while IFS= read -r language; do
  apple_languages+=("${language}")
done < <(
  defaults read NSGlobalDomain AppleLanguages 2>/dev/null |
    sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p' |
    sed '/^$/d'
)

if [[ "${#apple_languages[@]}" -gt 0 ]]; then
  write_array "APPLE_LANGUAGES" "${apple_languages[@]}"
else
  write_array "APPLE_LANGUAGES" "en-US" "ru-US"
fi

export_domain "com.apple.dock" "com.apple.dock.plist"
export_domain "com.apple.finder" "com.apple.finder.plist"
export_domain "com.apple.screencapture" "com.apple.screencapture.plist"
export_domain "com.apple.HIToolbox" "com.apple.HIToolbox.plist"
export_domain "com.apple.symbolichotkeys" "com.apple.symbolichotkeys.plist"
export_domain "NSGlobalDomain" "NSGlobalDomain.plist"

cat <<EOF
Exported portable settings:
  ${OUT_FILE}

Exported raw defaults snapshots:
  ${RAW_DIR}

Keyboard layouts are stored mainly in:
  ${RAW_DIR}/com.apple.HIToolbox.plist

Keyboard shortcuts are stored mainly in:
  ${RAW_DIR}/com.apple.symbolichotkeys.plist

Review these files before applying them on a fresh machine.
EOF
