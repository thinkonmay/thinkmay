#!/usr/bin/env bash
# Install thinkmay-client from a local git tap (Homebrew rejects bare .rb paths).
# Usage: ./packaging/homebrew/test-install.sh {linux|macos} [artifacts_dir]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLATFORM="${1:?usage: test-install.sh linux|macos [artifacts_dir]}"
ARTIFACTS="${2:-${ROOT}/artifacts}"
# Homebrew file:// URLs must be absolute; relative paths fail in CI (e.g. ./artifacts/...).
if [[ "${ARTIFACTS}" != /* ]]; then
  ARTIFACTS="${ROOT}/${ARTIFACTS#./}"
fi
ARTIFACTS="$(cd "${ARTIFACTS}" && pwd)"

FORMULA_SRC="${ROOT}/packaging/homebrew/Formula/thinkmay-client.rb"
CASK_SRC="${ROOT}/packaging/homebrew/Casks/thinkmay-client.rb"
TAP_NAME="thinkonmay/thinkmay"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

prepare_tap() {
  local tap_dir
  tap_dir="$(mktemp -d)"
  mkdir -p "${tap_dir}/Formula" "${tap_dir}/Casks"
  cp "${FORMULA_SRC}" "${tap_dir}/Formula/"
  cp "${CASK_SRC}" "${tap_dir}/Casks/"

  case "${PLATFORM}" in
    linux)
      local tar="${ARTIFACTS}/thinkmay-client-linux-amd64.tar.gz"
      [[ -f "${tar}" ]] || { echo "missing ${tar}" >&2; exit 1; }
      local sha
      sha="$(sha256_file "${tar}")"
      sed -i.bak "s|url \".*thinkmay-client-linux-amd64.tar.gz\"|url \"file://${tar}\"|" "${tap_dir}/Formula/thinkmay-client.rb"
      sed -i.bak "s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${tap_dir}/Formula/thinkmay-client.rb"
      rm -f "${tap_dir}/Formula/thinkmay-client.rb.bak"
      ;;
    macos)
      local zip="${ARTIFACTS}/thinkmay-client-darwin.zip"
      [[ -f "${zip}" ]] || { echo "missing ${zip}" >&2; exit 1; }
      local sha
      sha="$(sha256_file "${zip}")"
      if [[ "$(uname -s)" == "Darwin" ]]; then
        sed -i '' "s|url \".*thinkmay-client-darwin.zip\"|url \"file://${zip}\"|" "${tap_dir}/Casks/thinkmay-client.rb"
        sed -i '' "s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${tap_dir}/Casks/thinkmay-client.rb"
      else
        sed -i "s|url \".*thinkmay-client-darwin.zip\"|url \"file://${zip}\"|" "${tap_dir}/Casks/thinkmay-client.rb"
        sed -i "s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${tap_dir}/Casks/thinkmay-client.rb"
      fi
      ;;
    *)
      echo "unknown platform: ${PLATFORM}" >&2
      exit 1
      ;;
  esac

  git -C "${tap_dir}" init -q
  git -C "${tap_dir}" -c user.email=brew@test.local -c user.name=brew add .
  git -C "${tap_dir}" -c user.email=brew@test.local -c user.name=brew commit -q -m "local tap"
  printf '%s' "${tap_dir}"
}

if ! command -v brew >/dev/null 2>&1; then
  echo "brew not found in PATH" >&2
  exit 1
fi

TAP_DIR="$(prepare_tap)"
cleanup() {
  brew untap "${TAP_NAME}" 2>/dev/null || true
  rm -rf "${TAP_DIR}"
}
trap cleanup EXIT

brew untap "${TAP_NAME}" 2>/dev/null || true
brew tap "${TAP_NAME}" "${TAP_DIR}"

case "${PLATFORM}" in
  linux)
    brew install "${TAP_NAME}/thinkmay-client"
    thinkmay-client --help || true
    ;;
  macos)
    brew install --cask "${TAP_NAME}/thinkmay-client"
    "/Applications/Thinkmay Client.app/Contents/MacOS/thinkmay-client" --help || true
    ;;
esac

echo "Homebrew ${PLATFORM} install test passed"
