#!/usr/bin/env bash
# Toggle Rio's CRT filter (Ctrl+Alt+C). Rio live-reloads config.toml on save.
#  - CRT on : uncomment `filters = ...`, strategy = "game"   (continuous redraw → rolling scanlines)
#  - CRT off: comment   `filters = ...`, strategy = "events" (redraw only on changes → low CPU)
# Requires Rio built with `--features wgpu` and `[renderer] backend = "Webgpu"`.
set -euo pipefail
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/rio/config.toml"
if grep -qE '^filters = ' "$cfg"; then
  sed -i -E -e 's|^filters = |# filters = |' -e 's|^strategy = "game"|strategy = "events"|' "$cfg"
else
  sed -i -E -e 's|^# filters = |filters = |' -e 's|^strategy = "events"|strategy = "game"|' "$cfg"
fi
