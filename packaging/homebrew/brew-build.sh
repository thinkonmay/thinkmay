#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ARTIFACTS="${ROOT}/artifacts"
PKG="${ARTIFACTS}/package/thinkmay-client-linux-amd64"

build_linux_tarball() {
  if [[ -f "${ARTIFACTS}/thinkmay-client-linux-amd64.tar.gz" ]]; then
    echo "linux tarball already exists"
    return
  fi

  echo "building Linux client (requires apt/brew build deps)..."
  mkdir -p "${PKG}/lib"
  cd "${ROOT}/worker/proxy"
  go mod download
  CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -o "${PKG}/thinkmay-client-bin" ./cmd/client
  chmod +x "${PKG}/thinkmay-client-bin"

  printf '#!/bin/bash\nSCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"\nexport LD_LIBRARY_PATH="${SCRIPT_DIR}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec "${SCRIPT_DIR}/thinkmay-client-bin" "$@"\n' \
    > "${PKG}/thinkmay-client"
  chmod +x "${PKG}/thinkmay-client"
  cp "${ROOT}/packaging/client/linux/thinkmay-client.desktop" "${PKG}/"
  cp "${ROOT}/packaging/client/linux/README.txt" "${PKG}/"
  mkdir -p "${ARTIFACTS}/package"
  tar -czf "${ARTIFACTS}/thinkmay-client-linux-amd64.tar.gz" -C "${ARTIFACTS}/package" thinkmay-client-linux-amd64
}

build_macos_zip() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "skip macOS zip (not on macOS)" >&2
    return
  fi
  local arch
  case "$(uname -m)" in
    arm64) arch=arm64 ;;
    x86_64) arch=amd64 ;;
    *)
      echo "unsupported macOS arch: $(uname -m)" >&2
      return 1
      ;;
  esac
  local zip="${ARTIFACTS}/thinkmay-client-darwin-${arch}.zip"
  if [[ -f "${zip}" ]]; then
    echo "macOS zip already exists: ${zip}"
    return
  fi
  local version
  version="$(tr -d '[:space:]' < "${ROOT}/packaging/client/VERSION")"
  chmod +x "${ROOT}/packaging/client/macos/build-macos-package.sh"
  "${ROOT}/packaging/client/macos/build-macos-package.sh" "${arch}" "${version}"
}

mkdir -p "${ARTIFACTS}"
if [[ "$(uname -s)" == "Linux" ]]; then
  build_linux_tarball
elif [[ "$(uname -s)" == "Darwin" ]]; then
  build_macos_zip
fi

"${ROOT}/packaging/homebrew/update-formulae.sh" "${ARTIFACTS}"
echo "Formulae updated. Install with brew commands in packaging/homebrew/README.md"
