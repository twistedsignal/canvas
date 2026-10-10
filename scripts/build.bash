#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"

rojo="$(find_tool rojo)"
lune="$(find_tool lune)"

"$PROJECT_ROOT/scripts/clean.bash"
"$PROJECT_ROOT/scripts/write-version.bash"
mkdir -p "$PROJECT_ROOT/build"

cd "$PROJECT_ROOT"
"$rojo" build -o build/Canvas.rbxm default.project.json
# a Luau chunk that rebuilds the plugin under Workspace, for the Studio MCP's execute_luau.
"$lune" run scripts/studio-bundle.luau build/Canvas.rbxm build/studio-install.luau
