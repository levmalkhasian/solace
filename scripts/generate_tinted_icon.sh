#!/usr/bin/env bash
# Generate a grayscale "tinted" app icon for iOS 18+ from a source PNG.
# iOS applies the user's accent color to the luminance of this image, so a
# desaturated version of the dark icon reads well under any tint.
#
# Usage: ./generate_tinted_icon.sh <source.png> <output.png>

set -euo pipefail

SRC="${1:-}"
DST="${2:-}"

if [[ -z "$SRC" || -z "$DST" ]]; then
  echo "usage: $0 <source.png> <output.png>"
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: source not found: $SRC"
  exit 1
fi

GRAY_PROFILE="/System/Library/ColorSync/Profiles/Generic Gray Gamma 2.2 Profile.icc"

sips -m "$GRAY_PROFILE" "$SRC" --out "$DST" >/dev/null
echo "wrote $DST"
