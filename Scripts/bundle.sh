#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building Isle…"
swift build -c release --product Isle

BIN="$(swift build -c release --show-bin-path)/Isle"
APP="$ROOT/dist/Isle.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/Isle"
chmod +x "$APP/Contents/MacOS/Isle"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - --identifier com.isle.mac "$APP" >/dev/null
fi

echo "Built $APP"
