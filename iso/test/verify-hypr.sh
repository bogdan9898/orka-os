#!/usr/bin/env bash
# Check the OrkaOS Hyprland config without starting Hyprland.
# Copies config/hypr (system defaults) and config/user/hypr (user files) to a
# temporary dir, points the Lua search path there and runs
# `Hyprland --verify-config`. Needs the hyprland package installed.
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
V="$(mktemp -d /tmp/orka-verify-XXXX)"
trap 'rm -rf "$V"' EXIT

mkdir -p "$V/sys" "$V/user"
cp -r "$R/config/hypr/." "$V/sys/"
cp "$R/config/user/hypr/"*.lua "$V/user/"
sed -i "s|/usr/share/orka/hypr|$V/sys|g; s|^package.path = \"|package.path = \"$V/user/?.lua;|" "$V/user/hyprland.lua"

out="$(cd "$V/user" && Hyprland --verify-config -c "$V/user/hyprland.lua" 2>&1 | sed -n '/Config parsing result/,$p' | tail -n +2 | sed '/^$/d')"
echo "$out"
[[ "$out" == "config ok" ]]
