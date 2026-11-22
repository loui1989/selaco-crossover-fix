#!/bin/bash
# Restores the MoltenVK library that came with CrossOver / NotProton.
set -u
shopt -s nullglob
finish() { echo; read -r -p "Press Return to close this window." _; exit "$1"; }

restored=0
for root in /Applications/CrossOver*.app/Contents/SharedSupport/CrossOver \
            "$HOME"/Applications/CrossOver*.app/Contents/SharedSupport/CrossOver \
            "$HOME/Library/Application Support/notproton/runners"/*/CrossOver; do
  for sub in lib64 lib/x86_64 lib/aarch64; do
    t="$root/$sub/libMoltenVK.dylib"
    if [ -f "$t.orig" ]; then
      if cp -p "$t.orig" "$t" && rm -f "$t.orig"; then
        echo "restored $t"; restored=$((restored+1))
      else
        echo "FAILED to restore $t"
      fi
    fi
  done
done
echo
echo "Restored $restored location(s)."
finish 0
