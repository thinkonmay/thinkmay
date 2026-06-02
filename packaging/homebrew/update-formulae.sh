#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION_FILE="${ROOT}/packaging/client/VERSION"
FORMULA="${ROOT}/packaging/homebrew/Formula/thinkmay-client.rb"
CASK="${ROOT}/packaging/homebrew/Casks/thinkmay-client.rb"

ARTIFACTS="${1:-${ROOT}/artifacts}"

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "missing ${VERSION_FILE}" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
LINUX_TAR="${ARTIFACTS}/thinkmay-client-linux-amd64.tar.gz"
MAC_ZIP="${ARTIFACTS}/thinkmay-client-darwin.zip"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

set_version() {
  local file="$1"
  sed -i.bak "s/^  version \".*\"/  version \"${VERSION}\"/" "${file}"
  sed -i.bak "s/^  version \"[^\"]*\"/  version \"${VERSION}\"/" "${file}" 2>/dev/null || true
  rm -f "${file}.bak"
}

set_formula_sha() {
  local sha="$1"
  sed -i.bak "s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${FORMULA}"
  rm -f "${FORMULA}.bak"
}

set_cask_sha() {
  local sha="$1"
  sed -i.bak "s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${CASK}"
  rm -f "${CASK}.bak"
}

set_version "${FORMULA}"
set_version "${CASK}"

if [[ -f "${LINUX_TAR}" ]]; then
  LINUX_SHA="$(sha256_file "${LINUX_TAR}")"
  set_formula_sha "${LINUX_SHA}"
  echo "updated Linux formula sha256=${LINUX_SHA}"
else
  echo "skip Linux sha256 (missing ${LINUX_TAR})" >&2
fi

if [[ -f "${MAC_ZIP}" ]]; then
  MAC_SHA="$(sha256_file "${MAC_ZIP}")"
  set_cask_sha "${MAC_SHA}"
  echo "updated macOS cask sha256=${MAC_SHA}"
else
  echo "skip macOS sha256 (missing ${MAC_ZIP})" >&2
fi

echo "formulae version=${VERSION}"
