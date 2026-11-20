#!/usr/bin/env bash
# Rebuild and install Rio with the local sugarloaf fullscreen-freeze patch.
# Usage: ./build-patched-rio.sh [VERSION]      (default: 0.5.32)
# See README.md in this folder.
set -euo pipefail

VERSION="${1:-0.5.32}"
PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH="$PATCH_DIR/sugarloaf-fullscreen-freeze.patch"
SRC="${RIO_PATCHED_SRC:-$HOME/.local/src/rio-patched}"

# 1. Make sure both crates are in the cargo registry cache.
if ! ls -d "$HOME"/.cargo/registry/src/index.crates.io-*/rioterm-"$VERSION" >/dev/null 2>&1 \
   || ! ls -d "$HOME"/.cargo/registry/src/index.crates.io-*/sugarloaf-"$VERSION" >/dev/null 2>&1; then
  echo ">> Fetching rioterm $VERSION sources into the cargo cache..."
  tmp="$(mktemp -d)"
  cargo init -q --name fetch-rio "$tmp"
  (cd "$tmp" && cargo add -q "rioterm@=$VERSION" "sugarloaf@=$VERSION" && cargo fetch -q)
  rm -rf "$tmp"
fi
REG="$(ls -d "$HOME"/.cargo/registry/src/index.crates.io-*/ | head -1)"

# 2. Fresh copies of rioterm + sugarloaf.
echo ">> Preparing sources in $SRC"
mkdir -p "$SRC"
rm -rf "$SRC/rioterm" "$SRC/sugarloaf"
cp -r "$REG/rioterm-$VERSION" "$SRC/rioterm"
cp -r "$REG/sugarloaf-$VERSION" "$SRC/sugarloaf"
chmod -R u+w "$SRC"

# 3. Apply the patch (fails loudly if upstream code changed).
echo ">> Applying $(basename "$PATCH")"
patch -d "$SRC/sugarloaf" -p1 < "$PATCH"

# 4. Point rioterm at the patched sugarloaf.
printf '\n[patch.crates-io]\nsugarloaf = { path = "../sugarloaf" }\n' >> "$SRC/rioterm/Cargo.toml"

# 5. Build and install with WebGPU (needed for CRT filters).
echo ">> Building and installing (this takes a minute)..."
cargo install --path "$SRC/rioterm" --features wgpu

echo ">> Done. Restart Rio to use the new binary."
rio --version
