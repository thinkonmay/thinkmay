#!/usr/bin/env bash
# Validate committed client icon assets (format, sizes, completeness).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
errors=0

fail() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

check_png() {
  local path="$1" expected="$2"
  if [[ ! -f "${path}" ]]; then
    fail "missing PNG ${path}"
    return
  fi
  local magic size
  magic=$(head -c 8 "${path}" | od -An -tx1 | tr -d ' \n')
  if [[ "${magic}" != 89504e470d0a1a0a ]]; then
    fail "${path}: invalid PNG magic"
    return
  fi
  size=$(python3 - <<PY
import struct
with open("${path}", "rb") as f:
    f.seek(16)
    w, h = struct.unpack(">II", f.read(8))
print(f"{w}x{h}")
PY
)
  if [[ "${size}" != "${expected}" ]]; then
    fail "${path}: expected ${expected}, got ${size}"
  fi
  if command -v pngcheck >/dev/null 2>&1; then
    pngcheck -q "${path}" >/dev/null 2>&1 || fail "${path}: pngcheck failed"
  fi
}

check_ico() {
  local path="${ROOT}/images/logo.ico"
  if [[ ! -f "${path}" ]]; then
    fail "missing ${path}"
    return
  fi
  python3 - <<'PY' "${path}" || fail "ICO validation failed for ${path}"
import struct, sys
path = sys.argv[1]
with open(path, "rb") as f:
    data = f.read()
if data[:4] != b"\x00\x00\x01\x00":
    raise SystemExit("invalid ICO header")
count = struct.unpack("<H", data[4:6])[0]
if count < 5:
    raise SystemExit(f"expected >= 5 ICO entries, got {count}")
sizes = []
off = 6
for _ in range(count):
    w, h = data[off], data[off + 1]
    size = 256 if w == 0 else w
    sizes.append(size)
    off += 16
print(f"ICO entries ({count}): {sizes}")
PY
}

check_icns() {
  local path="${ROOT}/packaging/client/macos/AppIcon.icns"
  if [[ ! -f "${path}" ]]; then
    fail "missing ${path}"
    return
  fi
  python3 - <<'PY' "${path}" || fail "ICNS validation failed for ${path}"
import struct, sys
required = {b"ic04", b"ic05", b"ic07", b"ic08", b"ic09", b"ic10"}
path = sys.argv[1]
with open(path, "rb") as f:
    data = f.read()
if data[:4] != b"icns":
    raise SystemExit("invalid ICNS header")
found = set()
pos = 8
while pos + 8 <= len(data):
    t = data[pos:pos+4]
    ln = struct.unpack(">I", data[pos+4:pos+8])[0]
    found.add(t)
    pos += ln
missing = required - found
if missing:
    raise SystemExit(f"missing ICNS types: {sorted(m.decode('latin1') for m in missing)}")
print(f"ICNS OK ({len(found)} types)")
PY
}

echo "Validating icon assets..."

check_png "${ROOT}/images/logo.png" "1024x1024"
check_png "${ROOT}/worker/proxy/client/app/logo.png" "512x512"
check_png "${ROOT}/packaging/client/linux/thinkmay-client.png" "256x256"

for size in 48 128 256 512; do
  check_png "${ROOT}/packaging/client/linux/icons/hicolor/${size}x${size}/apps/thinkmay-client.png" "${size}x${size}"
done

check_ico
check_icns

if [[ "${errors}" -gt 0 ]]; then
  echo "${errors} icon validation error(s)" >&2
  exit 1
fi

echo "icon validation passed"
