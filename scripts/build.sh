#!/usr/bin/env bash
# ================================================================== #
#  Build script for IRIS Configuration Manager                          #
#                                                                     #
#  Usage:                                                             #
#    ./scripts/build.sh chrome    — build Chrome package               #
#    ./scripts/build.sh firefox   — build Firefox package              #
#    ./scripts/build.sh all       — build both (default)               #
# ================================================================== #

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$ROOT_DIR/src"
ICONS_DIR="$ROOT_DIR/icons"
MANIFESTS_DIR="$ROOT_DIR/manifests"
DIST_DIR="$ROOT_DIR/dist"

# ---- Helpers ---- #

log() { echo "  → $*"; }

build_target() {
    local target="$1"  # chrome | firefox
    local out="$DIST_DIR/$target"

    echo ""
    echo "Building for $target..."

    # Clean previous build
    rm -rf "$out"
    mkdir -p "$out/icons" "$out/platform" "$out/core/strategies"

    # ---- Copy shared source ---- #

    # Top-level source files (JS, HTML, CSS, .cls)
    cp "$SRC_DIR/api.js"                      "$out/api.js"
    cp "$SRC_DIR/storage.js"                  "$out/storage.js"
    cp "$SRC_DIR/popup.js"                    "$out/popup.js"
    cp "$SRC_DIR/report.js"                   "$out/report.js"
    cp "$SRC_DIR/popup.html"                  "$out/popup.html"
    cp "$SRC_DIR/report.html"                 "$out/report.html"
    cp "$SRC_DIR/privacy.html"                "$out/privacy.html"
    cp "$SRC_DIR/styles.css"                  "$out/styles.css"
    cp "$SRC_DIR/Migration.Framework.cls"     "$out/Migration.Framework.cls"

    # Platform compatibility layer
    cp "$SRC_DIR/platform/browser-polyfill.js" "$out/platform/browser-polyfill.js"

    # Core business logic
    cp "$SRC_DIR/core/bootstrap.js"           "$out/core/bootstrap.js"
    cp "$SRC_DIR/core/compare.js"             "$out/core/compare.js"
    cp "$SRC_DIR/core/registry.js"            "$out/core/registry.js"
    cp "$SRC_DIR/core/strategies/entityCompare.js" "$out/core/strategies/entityCompare.js"
    cp "$SRC_DIR/core/strategies/flatCompare.js"   "$out/core/strategies/flatCompare.js"

    # ---- Copy browser-specific manifest ---- #

    cp "$MANIFESTS_DIR/$target/manifest.json" "$out/manifest.json"

    # ---- Copy icons ---- #

    cp "$ICONS_DIR"/*.png "$out/icons/"

    log "Output: $out/"
    log "Files: $(find "$out" -type f | wc -l)"
}

# ---- Main ---- #

target="${1:-all}"

echo "============================================"
echo "  IRIS Configuration Manager — Build"
echo "============================================"

case "$target" in
    chrome)
        build_target "chrome"
        ;;
    firefox)
        build_target "firefox"
        ;;
    all)
        build_target "chrome"
        build_target "firefox"
        ;;
    *)
        echo "Unknown target: $target"
        echo "Usage: $0 [chrome|firefox|all]"
        exit 1
        ;;
esac

echo ""
echo "Build complete."
