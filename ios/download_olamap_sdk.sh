#!/bin/bash
# Downloads every xcframework OlaMapCore links (including MoEngageCards).
# Usage: download_olamap_sdk.sh [destination_dir]
set -euo pipefail

DEST="${1:-}"
if [ -z "$DEST" ]; then
  DEST="$(cd "$(dirname "$0")" && pwd)/ola_maps/Frameworks"
fi
mkdir -p "$DEST"

copy_xcframeworks() {
  local src="$1"
  # ditto preserves code signatures better than cp -R.
  for fw in "$src"/*.xcframework; do
    [ -d "$fw" ] || continue
    ditto "$fw" "$DEST/$(basename "$fw")"
  done
}

# Xcode 15+ rejects binary xcframeworks whose sealed signature no longer
# matches the copied files. Unsigned frameworks are accepted; invalid
# signatures are not.
sanitize_xcframework_signatures() {
  for fw in "$DEST"/*.xcframework; do
    [ -d "$fw" ] || continue
    if ! codesign --verify "$fw" >/dev/null 2>&1; then
      codesign --remove-signature "$fw" >/dev/null 2>&1 || true
      # codesign leaves an empty _CodeSignature folder; Xcode 15+ then
      # reports "The signature of … cannot be verified".
      rm -rf "$fw/_CodeSignature"
    fi
  done
}

if [ -d "$DEST/OlaMapCore.xcframework" ]; then
  sanitize_xcframework_signatures
  exit 0
fi

# Reuse a CocoaPods checkout when present (example app).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PODS_FW="$SCRIPT_DIR/../example/ios/Pods/OlaMapCore/Frameworks"
if [ -d "$PODS_FW/OlaMapCore.xcframework" ]; then
  copy_xcframeworks "$PODS_FW"
  sanitize_xcframework_signatures
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --branch 1.0.8 https://github.com/ola-maps/ios-map-sdk.git "$TMP/sdk"
copy_xcframeworks "$TMP/sdk/Frameworks"
sanitize_xcframework_signatures
