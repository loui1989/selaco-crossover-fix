# Selaco fix for CrossOver on Apple Silicon

This fixes **Selaco** (Chapter 2: *The Machines of War*, Steam) under **CrossOver 26.x** on Apple Silicon Macs, whether you run it directly in CrossOver or through [NotProton](https://github.com/notprotonnot/notproton).

Without the fix, the main menu works, but when you start a level the game:

- freezes forever on the loading screen, or
- crashes, or
- shows a black screen while the sound keeps playing.

With a newer stock MoltenVK alone, it runs, but the frame rate is very poor.

## Install

1. Download **`Selaco-CrossOver-Fix.zip`** from [Releases](../../releases) and unzip it.
2. Quit CrossOver and any games or apps running through it.
3. Double-click **`install.command`**. If macOS refuses to open it, right-click it and choose **Open**, or run `bash install.command` in Terminal.
4. If macOS says Terminal was prevented from modifying apps, allow Terminal under **System Settings → Privacy & Security → App Management**, then run the installer again.
5. Use Selaco's Vulkan renderer. Adding `+vid_preferbackend 1` to the game's launch options forces it. The OpenGL renderer doesn't work on macOS.

The installer replaces `libMoltenVK.dylib` in every `CrossOver*.app` it finds in `/Applications` or `~/Applications`, and in every NotProton runner. It keeps each original as `libMoltenVK.dylib.orig` and signs the new library ad hoc on your Mac.

To undo it, run **`uninstall.command`**. A CrossOver update also restores the original library, so run `install.command` again after updating CrossOver.

## What's wrong, and what this changes

Vulkan games on CrossOver run on [MoltenVK](https://github.com/KhronosGroup/MoltenVK), which translates Vulkan to Metal. Metal has no triangle fans, so MoltenVK emulates them. Selaco's GZDoom-based engine draws its level geometry as triangle fans taken from one large vertex buffer.

1. **The hang, crash and black screen:** MoltenVK 1.2.10, which ships with CrossOver 26.3, sizes its temporary index buffer for `vertexCount` indices but writes `firstVertex + vertexCount` of them. With a large `firstVertex`, that overruns the buffer, corrupts memory, and makes the GPU read past the end too (`kIOGPUCommandBufferCallbackErrorPageFault`). Upstream fixed this in MoltenVK 1.3.0.
2. **The frame rate:** even the fixed versions emulate every fan draw with an indirect draw. That means a temporary index buffer sized for MoltenVK's 1-million-vertex maximum, a compute pass to convert the indices, and a restart of the Metal render pass, for every draw and thousands of times a frame.

This package is **MoltenVK 1.4.2** with [`patches/mvk-fan-fastpath.patch`](patches/mvk-fan-fastpath.patch) applied. For a triangle fan without tessellation, the CPU writes the triangle-list indices, 3 per triangle in the same order MoltenVK's own conversion uses, and the fan is drawn directly. There's no compute pass and no render pass restart. Every other draw uses MoltenVK's normal code.

## Notes

- The patched MoltenVK applies to **every Vulkan game** in that CrossOver install, not just Selaco. If another Vulkan game behaves worse, uninstall.
- Tested with Selaco Chapter 2 on an M3 Max, macOS 27, CrossOver 26.3 through NotProton (Rosetta runner). Other setups are untested; reports are welcome in [Issues](../../issues).
- The released library is not notarized. Download it only from this repository's Releases page, or build it yourself.
- The short magenta splash screen while the game starts up is a separate, cosmetic issue. This doesn't fix it.

## Build it yourself

You need Xcode. Then run:

```
scripts/build-moltenvk.sh
```

That clones MoltenVK v1.4.2, applies the patch, builds a universal library and puts `libMoltenVK.dylib` next to `install.command`. Building the dependencies takes a while the first time.

## License and credits

MoltenVK is © The Khronos Group, licensed under the Apache License 2.0 ([LICENSE](LICENSE)). The patch and scripts in this repository are released under the same license. The modified files are `MoltenVK/MoltenVK/Commands/MVKCmdDraw.h` and `MVKCmdDraw.mm`.

I diagnosed the problem and wrote the patch with the help of Claude (Anthropic).
