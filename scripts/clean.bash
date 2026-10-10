#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"

rm -f "$PROJECT_ROOT/build/Canvas.rbxm" "$PROJECT_ROOT/build/studio-install.luau" "$PROJECT_ROOT/src/Version.luau" "$PROJECT_ROOT/sourcemap.json"
