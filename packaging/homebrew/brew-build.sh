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
  if [[ -f "${ARTIFACTS}/thinkmay-client-darwin.zip" ]]; then
    echo "macOS zip already exists"
    return
  fi
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "skip macOS zip (not on macOS)" >&2
    return
  fi

  echo "building macOS app zip..."
  APP="${ARTIFACTS}/macos/Thinkmay Client.app"
  MACOS_DIR="${APP}/Contents/MacOS"
  mkdir -p "${MACOS_DIR}" "${APP}/Contents/Resources"
  cp "${ROOT}/packaging/client/macos/Info.plist" "${APP}/Contents/Info.plist"
  cd "${ROOT}/worker/proxy"
  go mod download
  CGO_ENABLED=1 go build -trimpath -ldflags="-s -w" -o "${MACOS_DIR}/thinkmay-client" ./cmd/client
  chmod +x "${MACOS_DIR}/thinkmay-client"
  ditto -c -k --sequesterRsrc --keepParent "${APP}" "${ARTIFACTS}/thinkmay-client-darwin.zip"
}

mkdir -p "${ARTIFACTS}"
if [[ "$(uname -s)" == "Linux" ]]; then
  build_linux_tarball
elif [[ "$(uname -s)" == "Darwin" ]]; then
  build_macos_zip
fi

"${ROOT}/packaging/homebrew/update-formulae.sh" "${ARTIFACTS}"
echo "Formulae updated. Install with brew commands in packaging/homebrew/README.md"
