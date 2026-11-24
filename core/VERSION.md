# FCEUmm Libretro (WASM Scalar Single-Thread Build for Tizen 6.5 / Chromium M85)

- **Upstream Repository:** `https://github.com/EmulatorJS/libretro-fceumm.git`
- **Pinned Commit:** `e1630de02074801eb96f3bc4ff33f69df9554c69`
- **Toolchain:** Emscripten `3.1.56` (`emcc`)
- **Target Runtime:** Samsung Smart TV BU8000 (Tizen 6.5, Chromium M85, single-thread scalar WebAssembly, no SIMD, no SharedArrayBuffer)
- **Compilation Flags:**
  - `-O3 -flto -DNDEBUG -ffast-math -fno-strict-overflow -mno-simd128`
  - `-D__LIBRETRO__ -DFRONTEND_SUPPORTS_RGB565 -DPATH_MAX=1024 -DFCEU_VERSION_NUMERIC=9813 -DLSB_FIRST -DLOCAL_LE=1`
  - `-sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME=FceummCore -sFILESYSTEM=0 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=16777216 -sALLOW_TABLE_GROWTH=1`
- **In-Memory ROM Patch:** `retro_get_system_info` sets `need_fullpath = false` and `retro_load_game` reads `info->data` and `info->size` directly when `RETRO_ENVIRONMENT_GET_GAME_INFO_EXT` is not used, avoiding any virtual filesystem requirement.

