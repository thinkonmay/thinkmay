#!/usr/bin/env bash
# Build tarball and .deb for one Linux architecture.
# Usage: ./packaging/client/linux/build-linux-package.sh <amd64|arm64> <version>
set -euo pipefail

ARCH="${1:?usage: build-linux-package.sh <amd64|arm64> <version>}"
VERSION="${2:?usage: build-linux-package.sh <amd64|arm64> <version>}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ARTIFACTS="${ROOT}/artifacts"
PKG_NAME="thinkmay-client-linux-${ARCH}"
PKGDIR="${ARTIFACTS}/package/${PKG_NAME}"

case "${ARCH}" in
  amd64) GOARCH=amd64 ;;
  arm64) GOARCH=arm64 ;;
  *)
    echo "unsupported arch: ${ARCH}" >&2
    exit 1
    ;;
esac

mkdir -p "${PKGDIR}/lib"
cd "${ROOT}/worker/proxy"
go mod download
CGO_ENABLED=1 GOARCH="${GOARCH}" go build -trimpath -ldflags="-s -w" \
  -o "${PKGDIR}/thinkmay-client-bin" ./cmd/client
chmod +x "${PKGDIR}/thinkmay-client-bin"

copy_deps() {
  local deps lib name
  deps=$(ldd "$1" 2>/dev/null | grep '=> /' | awk '{print $3}' || true)
  for lib in $deps; do
    name=$(basename "$lib")
    case "$name" in
      libc.so*|libm.so*|libdl.so*|librt.so*|libpthread.so*|ld-linux*|linux-vdso*|libgcc_s.so*|libstdc++.so*) continue ;;
    esac
    if [[ ! -f "${PKGDIR}/lib/${name}" ]]; then
      cp "$lib" "${PKGDIR}/lib/"
      copy_deps "$lib"
    fi
  done
}
copy_deps "${PKGDIR}/thinkmay-client-bin"

printf '#!/bin/bash\nSCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"\nexport LD_LIBRARY_PATH="${SCRIPT_DIR}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec "${SCRIPT_DIR}/thinkmay-client-bin" "$@"\n' \
  > "${PKGDIR}/thinkmay-client"
chmod +x "${PKGDIR}/thinkmay-client"
cp "${ROOT}/packaging/client/linux/README.txt" "${PKGDIR}/README.txt"
cp "${ROOT}/packaging/client/linux/thinkmay-client.desktop" "${PKGDIR}/thinkmay-client.desktop"
ldd "${PKGDIR}/thinkmay-client-bin" | tee "${PKGDIR}/thinkmay-client-linux-ldd.txt"

mkdir -p "${ARTIFACTS}/package"
tar -czf "${ARTIFACTS}/${PKG_NAME}.tar.gz" -C "${ARTIFACTS}/package" "${PKG_NAME}"

DEBDIR="${ARTIFACTS}/debian/thinkmay-client_${VERSION}_${ARCH}"
mkdir -p "${DEBDIR}/DEBIAN" "${DEBDIR}/usr/bin" \
  "${DEBDIR}/usr/share/thinkmay-client/lib" "${DEBDIR}/usr/share/applications"

cp "${PKGDIR}/thinkmay-client-bin" "${DEBDIR}/usr/share/thinkmay-client/"
cp -r "${PKGDIR}/lib/"* "${DEBDIR}/usr/share/thinkmay-client/lib/"
printf '#!/bin/bash\nexport LD_LIBRARY_PATH="/usr/share/thinkmay-client/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec "/usr/share/thinkmay-client/thinkmay-client-bin" "$@"\n' \
  > "${DEBDIR}/usr/bin/thinkmay-client"
chmod +x "${DEBDIR}/usr/bin/thinkmay-client"
cp "${ROOT}/packaging/client/linux/thinkmay-client.desktop" "${DEBDIR}/usr/share/applications/"
sed -i 's|Exec=thinkmay-client|Exec=/usr/bin/thinkmay-client|g' "${DEBDIR}/usr/share/applications/thinkmay-client.desktop"

cat > "${DEBDIR}/DEBIAN/control" <<EOF
Package: thinkmay-client
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: Thinkmay <contact@thinkmay.net>
Description: Thinkmay Client Application for remote desktop connection.
EOF

cat > "${DEBDIR}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
    if which update-desktop-database >/dev/null 2>&1; then
        update-desktop-database -q /usr/share/applications || true
    fi
fi
EOF
chmod +x "${DEBDIR}/DEBIAN/postinst"

cat > "${DEBDIR}/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    if which update-desktop-database >/dev/null 2>&1; then
        update-desktop-database -q /usr/share/applications || true
    fi
fi
EOF
chmod +x "${DEBDIR}/DEBIAN/postrm"

dpkg-deb --build "${DEBDIR}" "${ARTIFACTS}/${PKG_NAME}.deb"
echo "Built ${ARTIFACTS}/${PKG_NAME}.tar.gz and ${ARTIFACTS}/${PKG_NAME}.deb"
