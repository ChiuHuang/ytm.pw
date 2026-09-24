#!/bin/sh
# Fail the build when the layer rule is violated.
# Allowed imports: Core imports nothing of ours; Shared imports Core;
# Native and Redesigned import Core and Shared (never each other);
# App imports anything except nothing; Headers included anywhere.
# Usage: ./scripts/check-layers.sh (runs before every build via Makefile)

set -e
SRC="tweak/Sources"
fail=0

violates() {
  # $1 = dir to check, $2 = forbidden import dir pattern (grep -E)
  dir="$1"
  pattern="$2"
  hits=$(grep -rE "#import.*\.\./($pattern)/" "$SRC/$dir" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "[LAYERS] violation in $dir/:"
    echo "$hits"
    fail=1
  fi
}

violates "Core" "Shared|Native|Redesigned|App"
violates "Shared" "Native|Redesigned|App"
violates "Native" "Redesigned|App"
violates "Redesigned" "Native|App"

if [ "$fail" -ne 0 ]; then
  echo "[LAYERS] fix the imports above"
  exit 1
fi
echo "[LAYERS] OK"
