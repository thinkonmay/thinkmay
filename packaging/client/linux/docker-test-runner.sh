#!/usr/bin/env bash
# Script executed inside the test Docker container to build and verify custom URL handler.
set -euo pipefail

echo "=== 1. Building Thinkmay Linux Client Package ==="
mkdir -p /src/artifacts
chmod +x /src/packaging/client/linux/build-linux-package.sh
ARCH="amd64"
if [[ "$(uname -m)" == "aarch64" ]]; then
    ARCH="arm64"
fi

echo "Detected container architecture: ${ARCH}"
/src/packaging/client/linux/build-linux-package.sh "${ARCH}" 0.1.0

DEB="/src/artifacts/thinkmay-client-linux-${ARCH}.deb"
if [[ ! -f "${DEB}" ]]; then
    echo "ERROR: Compiled Debian package not found at ${DEB}" >&2
    exit 1
fi
echo "Package build succeeded: ${DEB}"

echo "=== 2. Installing Debian Package ==="
dpkg -i "${DEB}" || apt-get install -f -y -qq

echo "=== 3. Verifying Desktop Integration & MIME registration ==="
DESKTOP="/usr/share/applications/thinkmay-client.desktop"
if [[ ! -f "${DESKTOP}" ]]; then
    echo "ERROR: Desktop entry not found at ${DESKTOP}" >&2
    exit 1
fi

desktop-file-validate "${DESKTOP}"

# Ensure update-desktop-database runs
update-desktop-database -q /usr/share/applications

# Verify xdg-mime queries the correct handler
ASSOCIATION=$(xdg-mime query default x-scheme-handler/thinkmay || echo "")
if [[ "${ASSOCIATION}" != "thinkmay-client.desktop" ]]; then
    echo "ERROR: MIME type x-scheme-handler/thinkmay is registered to '${ASSOCIATION}', expected 'thinkmay-client.desktop'" >&2
    exit 1
fi
echo "MIME registration verified: x-scheme-handler/thinkmay is mapped to ${ASSOCIATION}"

echo "=== 4. Testing native custom URL scheme launch via xdg-open ==="
# We rewrite the installed wrapper /usr/bin/thinkmay-client to redirect stdout/stderr to a log file.
# This lets us capture the logs of the background process spawned by xdg-open / desktop manager.
printf '#!/bin/bash\nexport LD_LIBRARY_PATH="/usr/share/thinkmay-client/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec "/usr/share/thinkmay-client/thinkmay-client-bin" "$@" 2>&1 | tee -a /tmp/thinkmay-test-run.log\n' > /usr/bin/thinkmay-client
chmod +x /usr/bin/thinkmay-client

OUTPUT_LOG="/tmp/thinkmay-test-run.log"
rm -f "${OUTPUT_LOG}"

# Dispatch the URL using xdg-open, which simulates double-clicking a link in a browser.
# In a headless container environment, xdg-open falls back to generic mode and checks BROWSER.
BROWSER=thinkmay-client xdg-open "thinkmay:https://saigon2.thinkmay.net/remote?vmid=vm-id-test&video=my-secret-video-token&audio=my-secret-audio-token&data=my-secret-data-token" || true
sleep 1.5

echo "=== 5. Parsing output logs for security and correctness ==="
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

echo "Output log verification passed. Masked logs:"
grep "video client addr=" "${OUTPUT_LOG}"

echo "=========================================================="
echo "ALL LINUX DOCKER BUILD AND CUSTOM URL HANDLER TESTS PASSED"
echo "=========================================================="
