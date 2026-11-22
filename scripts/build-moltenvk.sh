#!/bin/bash
# Builds MoltenVK 1.4.2 with the triangle-fan patch. Needs Xcode.
# The result is a universal (x86_64 + arm64) libMoltenVK.dylib, copied next to this repo's install.command.
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo/build/MoltenVK-1.4.2"

command -v xcodebuild >/dev/null || { echo "ERROR: Xcode is needed (xcodebuild not found)."; exit 1; }

if [ ! -d "$src/.git" ]; then
  git clone --depth 1 --branch v1.4.2 https://github.com/KhronosGroup/MoltenVK.git "$src"
fi
cd "$src"
grep -q encodeTriangleFanDirect MoltenVK/MoltenVK/Commands/MVKCmdDraw.mm || git apply "$repo/patches/mvk-fan-fastpath.patch"
[ -d External/build ] || ./fetchDependencies --macos
make macos

lib=$(find Package -path '*dynamic/dylib/macOS/libMoltenVK.dylib' | head -1)
lipo -archs "$lib"
cp "$lib" "$repo/libMoltenVK.dylib"
echo "Built $repo/libMoltenVK.dylib. Run install.command to install it."
