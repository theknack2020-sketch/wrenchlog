#!/bin/bash
# generate_icons.sh — Runs GenerateAppIcon.swift to produce app icons
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_FILE="$SCRIPT_DIR/GenerateAppIcon.swift"
OUTPUT_DIR="$SCRIPT_DIR/Assets.xcassets/AppIcon.appiconset"

echo "🔧 Generating app icons..."
swift "$SWIFT_FILE"

echo ""
echo "📁 Output:"
ls -la "$OUTPUT_DIR"/icon_*.png
