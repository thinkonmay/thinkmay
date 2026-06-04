#!/usr/bin/env bash
# Build .app, .zip, and .dmg for one macOS architecture.
# Usage: ./packaging/client/macos/build-macos-package.sh <arm64|amd64> <version>
set -euo pipefail

ARCH="${1:?usage: build-macos-package.sh <arm64|amd64> <version>}"
VERSION="${2:?usage: build-macos-package.sh <arm64|amd64> <version>}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ARTIFACTS="${ROOT}/artifacts"
APP="${ARTIFACTS}/macos-${ARCH}/Thinkmay Client.app"
MACOS_DIR="${APP}/Contents/MacOS"
FRAMEWORKS="${APP}/Contents/Frameworks"
ZIP="${ARTIFACTS}/thinkmay-client-darwin-${ARCH}.zip"
DMG="${ARTIFACTS}/thinkmay-client-darwin-${ARCH}.dmg"
INFO_PLIST="${ROOT}/packaging/client/macos/Info.plist"

case "${ARCH}" in
  arm64) GOARCH=arm64 ;;
  amd64) GOARCH=amd64 ;;
  *)
    echo "unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

mkdir -p "${MACOS_DIR}" "${APP}/Contents/Resources" "${FRAMEWORKS}"
cp "${INFO_PLIST}" "${APP}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "${APP}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${VERSION}" "${APP}/Contents/Info.plist"

cd "${ROOT}/worker/proxy"
go mod download
CGO_ENABLED=1 GOARCH="${GOARCH}" go build -trimpath -ldflags="-s -w" \
  -o "${MACOS_DIR}/thinkmay-client" ./cmd/client
chmod +x "${MACOS_DIR}/thinkmay-client"

copy_deps() {
  local deps lib base
  deps=$(otool -L "$1" 2>/dev/null | tail -n +2 | awk '{print $1}' \
    | grep -v '^/usr/lib/' | grep -v '^/System/' | grep -v '@executable_path' \
    | grep -v '@rpath' | grep -v '@loader_path' || true)
  for lib in $deps; do
    base=$(basename "$lib")
    if [[ ! -f "${FRAMEWORKS}/${base}" ]]; then
      cp "$lib" "${FRAMEWORKS}/"
      chmod 644 "${FRAMEWORKS}/${base}"
      install_name_tool -id "@executable_path/../Frameworks/${base}" "${FRAMEWORKS}/${base}" 2>/dev/null || true
      copy_deps "${FRAMEWORKS}/${base}"
    fi
    install_name_tool -change "$lib" "@executable_path/../Frameworks/${base}" "$1" 2>/dev/null || true
  done
}

copy_deps "${MACOS_DIR}/thinkmay-client"

for _pass in 1 2 3; do
  for dylib in "${FRAMEWORKS}"/*.dylib; do
    [[ -f "$dylib" ]] || continue
    local_deps=$(otool -L "$dylib" 2>/dev/null | tail -n +2 | awk '{print $1}' \
      | grep -v '^/usr/lib/' | grep -v '^/System/' | grep -v '@executable_path' \
      | grep -v '@rpath' | grep -v '@loader_path' || true)
    for lib in $local_deps; do
      base=$(basename "$lib")
      if [[ -f "${FRAMEWORKS}/${base}" ]]; then
        install_name_tool -change "$lib" "@executable_path/../Frameworks/${base}" "$dylib" 2>/dev/null || true
      fi
    done
  done
done

for f in "${FRAMEWORKS}"/*.dylib; do
  [[ -f "$f" ]] && codesign --force --sign - "$f" 2>/dev/null || true
done
codesign --force --sign - "${MACOS_DIR}/thinkmay-client" 2>/dev/null || true

otool -L "${MACOS_DIR}/thinkmay-client" | tee "${ARTIFACTS}/thinkmay-client-darwin-${ARCH}-otool.txt"
ditto -c -k --sequesterRsrc --keepParent "${APP}" "${ZIP}"
hdiutil create -ov -fs HFS+ -srcfolder "${APP}" -volname "Thinkmay Client" "${DMG}"
echo "Built ${ZIP} and ${DMG}"
