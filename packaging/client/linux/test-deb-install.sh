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
    apt-get install -y -qq ca-certificates desktop-file-utils xdg-utils libfile-mimeinfo-perl >/dev/null

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

    # Test custom URL scheme handler launch via xdg-open fallback
    # We rewrite the wrapper /usr/bin/thinkmay-client to redirect stdout/stderr to a log file.
    # This lets us capture the logs of the background process spawned by xdg-open.
    printf "#!/bin/bash\nexport LD_LIBRARY_PATH=\"/usr/share/thinkmay-client/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}\"\nexec \"/usr/share/thinkmay-client/thinkmay-client-bin\" \"\$@\" 2>&1 | tee -a /tmp/thinkmay-test-run.log\n" > /usr/bin/thinkmay-client
    chmod +x /usr/bin/thinkmay-client

    OUTPUT_LOG="/tmp/thinkmay-test-run.log"
    rm -f "${OUTPUT_LOG}"

    # Verify xdg-mime query works
    ASSOCIATION=$(xdg-mime query default x-scheme-handler/thinkmay || echo "")
    if [[ "${ASSOCIATION}" != "thinkmay-client.desktop" ]]; then
      echo "ERROR: MIME type x-scheme-handler/thinkmay is registered to '${ASSOCIATION}', expected 'thinkmay-client.desktop'" >&2
      exit 1
    fi

    # Dispatch the URL using xdg-open fallback
    BROWSER=thinkmay-client xdg-open "thinkmay:https://saigon2.thinkmay.net/remote?vmid=vm-id-test&video=my-secret-video-token&audio=my-secret-audio-token&data=my-secret-data-token" || true
    sleep 1.5

    if ! grep -q "video client addr=saigon2.thinkmay.net:443 vmid=vm-id-test" "${OUTPUT_LOG}"; then
      echo "ERROR: Output does not contain expected address or VM ID resolution" >&2
      exit 1
    fi

    # Ensure secret tokens are NOT printed in plain text
    if grep -q "my-secret-video-token" "${OUTPUT_LOG}" || grep -q "my-secret-audio-token" "${OUTPUT_LOG}" || grep -q "my-secret-data-token" "${OUTPUT_LOG}"; then
      echo "ERROR: Security failure! Secret tokens were printed in plain text to the logs." >&2
      exit 1
    fi

    # Ensure masked tokens are printed
    if ! grep -q "token=my-s" "${OUTPUT_LOG}" && ! grep -q "token=\*\*\*" "${OUTPUT_LOG}"; then
      echo "ERROR: Masked tokens were not found in the output logs" >&2
      exit 1
    fi

    echo "Custom URL scheme handler validation passed"
    echo "Debian package install and URL handler verification passed"
  '

echo "Docker deb install test passed (${ARCH})"
