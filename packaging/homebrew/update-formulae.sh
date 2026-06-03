#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION_FILE="${ROOT}/packaging/client/VERSION"
FORMULA="${ROOT}/packaging/homebrew/Formula/thinkmay-client.rb"
CASK="${ROOT}/packaging/homebrew/Casks/thinkmay-client.rb"

ARTIFACTS="${1:-${ROOT}/artifacts}"
if [[ "${ARTIFACTS}" != /* ]]; then
  ARTIFACTS="${ROOT}/${ARTIFACTS#./}"
fi

if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "missing ${VERSION_FILE}" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
LINUX_AMD64_TAR="${ARTIFACTS}/thinkmay-client-linux-amd64.tar.gz"
LINUX_ARM64_TAR="${ARTIFACTS}/thinkmay-client-linux-arm64.tar.gz"
MAC_ARM64_ZIP="${ARTIFACTS}/thinkmay-client-darwin-arm64.zip"
MAC_AMD64_ZIP="${ARTIFACTS}/thinkmay-client-darwin-amd64.zip"

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

set_formula_sha_for_arch() {
  local arch="$1"
  local sha="$2"
  sed -i.bak "/thinkmay-client-linux-${arch}.tar.gz/,+1 s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${FORMULA}"
  rm -f "${FORMULA}.bak"
}

set_cask_sha_for_arch() {
  local arch="$1"
  local sha="$2"
  sed -i.bak "/thinkmay-client-darwin-${arch}.zip/,+1 s/sha256 \"[0-9a-f]\{64\}\"/sha256 \"${sha}\"/" "${CASK}"
  rm -f "${CASK}.bak"
}

set_version "${FORMULA}"
set_version "${CASK}"

if [[ -f "${LINUX_AMD64_TAR}" ]]; then
  LINUX_AMD64_SHA="$(sha256_file "${LINUX_AMD64_TAR}")"
  set_formula_sha_for_arch "amd64" "${LINUX_AMD64_SHA}"
  echo "updated Linux amd64 formula sha256=${LINUX_AMD64_SHA}"
else
  echo "skip Linux amd64 sha256 (missing ${LINUX_AMD64_TAR})" >&2
fi

if [[ -f "${LINUX_ARM64_TAR}" ]]; then
  LINUX_ARM64_SHA="$(sha256_file "${LINUX_ARM64_TAR}")"
  set_formula_sha_for_arch "arm64" "${LINUX_ARM64_SHA}"
  echo "updated Linux arm64 formula sha256=${LINUX_ARM64_SHA}"
else
  echo "skip Linux arm64 sha256 (missing ${LINUX_ARM64_TAR})" >&2
fi

if [[ -f "${MAC_ARM64_ZIP}" ]]; then
  MAC_ARM64_SHA="$(sha256_file "${MAC_ARM64_ZIP}")"
  set_cask_sha_for_arch "arm64" "${MAC_ARM64_SHA}"
  echo "updated macOS arm64 cask sha256=${MAC_ARM64_SHA}"
else
  echo "skip macOS arm64 sha256 (missing ${MAC_ARM64_ZIP})" >&2
fi

if [[ -f "${MAC_AMD64_ZIP}" ]]; then
  MAC_AMD64_SHA="$(sha256_file "${MAC_AMD64_ZIP}")"
  set_cask_sha_for_arch "amd64" "${MAC_AMD64_SHA}"
  echo "updated macOS amd64 cask sha256=${MAC_AMD64_SHA}"
else
  echo "skip macOS amd64 sha256 (missing ${MAC_AMD64_ZIP})" >&2
fi

echo "formulae version=${VERSION}"
