#!/bin/bash
# Selaco fix for CrossOver: installs a patched MoltenVK 1.4.2 into CrossOver and NotProton.
# The original library is kept next to it as libMoltenVK.dylib.orig, so uninstall.command can restore it.
set -u
shopt -s nullglob
here="$(cd "$(dirname "$0")" && pwd)"
new="$here/libMoltenVK.dylib"

finish() { echo; read -r -p "Press Return to close this window." _; exit "$1"; }

[ -f "$new" ] || { echo "libMoltenVK.dylib is missing. Keep it in the same folder as this script."; finish 1; }

if pgrep -xq CrossOver || pgrep -fq 'wineserver'; then
  echo "Quit CrossOver, Steam games running through CrossOver/NotProton, and any Windows apps first, then run this again."
  finish 1
fi

targets=()
for root in /Applications/CrossOver*.app/Contents/SharedSupport/CrossOver \
            "$HOME"/Applications/CrossOver*.app/Contents/SharedSupport/CrossOver \
            "$HOME/Library/Application Support/notproton/runners"/*/CrossOver; do
  for sub in lib64 lib/x86_64 lib/aarch64; do
    [ -f "$root/$sub/libMoltenVK.dylib" ] && targets+=("$root/$sub/libMoltenVK.dylib")
  done
done

if [ ${#targets[@]} -eq 0 ]; then
  echo "No CrossOver or NotProton installation was found."
  finish 1
fi

ok=0; failed=0
for t in "${targets[@]}"; do
  echo "== $t"
  if [ ! -f "$t.orig" ]; then
    cp -p "$t" "$t.orig" || { echo "   could not back up the original, skipped"; failed=$((failed+1)); continue; }
  fi
  if cp "$new" "$t" && xattr -c "$t" && codesign -f -s - "$t" 2>/dev/null; then
    echo "   installed"; ok=$((ok+1))
  else
    echo "   FAILED. If macOS blocked Terminal from modifying an app, allow Terminal under"
    echo "   System Settings > Privacy & Security > App Management, then run this again."
    failed=$((failed+1))
  fi
done

echo
echo "Installed in $ok location(s), $failed failed."
echo "A CrossOver update puts the original library back. Run this again after updating CrossOver."
finish 0
