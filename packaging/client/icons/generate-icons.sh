#!/usr/bin/env bash
# Regenerate all client icon assets from images/logo.png.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ICONS_DIR="${ROOT}/packaging/client/icons"

cd "${ICONS_DIR}"
go mod download
go run ./generate

if [[ "$(uname -s)" == "Darwin" ]]; then
  ICONSET="${ROOT}/packaging/client/macos/AppIcon.iconset"
  ICNS="${ROOT}/packaging/client/macos/AppIcon.icns"
  iconutil -c icns "${ICONSET}" -o "${ICNS}"
  echo "generated ${ICNS}"
else
  echo "skip AppIcon.icns (iconutil requires macOS); run this script on macOS before committing icns changes"
fi

"${ICONS_DIR}/validate-icons.sh"
echo "icon generation complete"
