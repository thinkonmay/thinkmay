#!/usr/bin/env bash
# Install a .deb in a clean Ubuntu container and verify URL handler desktop entry.
# Usage: ./packaging/client/linux/test-deb-install.sh [artifacts_dir] [amd64|arm64]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ARTIFACTS="${1:-${ROOT}/artifacts}"
ARCH="${2:-amd64}"
DEB="${ARTIFACTS}/thinkmay-client-linux-${ARCH}.deb"

case "${ARCH}" in
  amd64)
    IMAGE="${THINKMAY_DEB_TEST_IMAGE:-ubuntu:24.04}"
    DOCKER_PLATFORM=()
    ;;
  arm64)
    IMAGE="${THINKMAY_DEB_TEST_IMAGE_ARM:-ubuntu:24.04}"
    DOCKER_PLATFORM=(--platform linux/arm64)
    ;;
  *)
    echo "unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

if [[ ! -f "${DEB}" ]]; then
  echo "missing ${DEB}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH" >&2
  exit 1
fi

echo "Testing ${DEB} in ${IMAGE} (${ARCH})..."

docker run --rm "${DOCKER_PLATFORM[@]}" \
  -v "${DEB}:/tmp/thinkmay-client.deb:ro" \
  "${IMAGE}" \
  bash -euxo pipefail -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq ca-certificates desktop-file-utils xdg-utils >/dev/null

    dpkg -i /tmp/thinkmay-client.deb || apt-get install -f -y -qq

    DESKTOP="/usr/share/applications/thinkmay-client.desktop"
    if [[ ! -f "${DESKTOP}" ]]; then
      echo "desktop file not installed at ${DESKTOP}" >&2
      exit 1
    fi

    echo "=== installed ${DESKTOP} ==="
    cat "${DESKTOP}"

    desktop-file-validate "${DESKTOP}"

    grep -q "MimeType=.*x-scheme-handler/thinkmay;" "${DESKTOP}" || {
      echo "x-scheme-handler/thinkmay missing from MimeType" >&2
      exit 1
    }
    grep -q "Exec=/usr/bin/thinkmay-client -url %u" "${DESKTOP}" || {
      echo "Exec line must launch /usr/bin/thinkmay-client with -url %u" >&2
      exit 1
    }

    if which update-desktop-database >/dev/null 2>&1; then
      update-desktop-database -q /usr/share/applications
    fi

    thinkmay-client --help || true

    echo "Debian package install and URL handler verification passed"
  '

echo "Docker deb install test passed (${ARCH})"
