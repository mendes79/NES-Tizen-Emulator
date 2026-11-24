#!/usr/bin/env bash
# build.sh - Script Linux/macOS reproduzível para compilar cores/fceumm/fceumm.wasm para Chromium M85 (Tizen 6.5)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/libretro-fceumm"
CORE_DIR="$SRC_DIR/src"
COMM_DIR="$CORE_DIR/drivers/libretro/libretro-common"
BUILD_DIR="$SCRIPT_DIR/build"
PINNED_COMMIT="e1630de02074801eb96f3bc4ff33f69df9554c69"

if [ ! -d "$SRC_DIR" ]; then
  git clone https://github.com/EmulatorJS/libretro-fceumm.git "$SRC_DIR"
  git -C "$SRC_DIR" checkout "$PINNED_COMMIT"
fi

mkdir -p "$BUILD_DIR"

INC_FLAGS=(
  "-I$CORE_DIR/drivers/libretro"
  "-I$COMM_DIR/include"
  "-I$CORE_DIR"
  "-I$CORE_DIR/input"
  "-I$CORE_DIR/boards"
)

COMMON_FLAGS=(
  -O3 -flto -DNDEBUG -ffast-math -fno-strict-overflow -mno-simd128
  -D__LIBRETRO__ -DFRONTEND_SUPPORTS_RGB565 -DPATH_MAX=1024 -DFCEU_VERSION_NUMERIC=9813 -DLSB_FIRST -DLOCAL_LE=1
  -Wno-deprecated-declarations -Wno-implicit-function-declaration -Wno-int-conversion
)

OBJECTS=()
for src in "$CORE_DIR"/boards/*.c "$CORE_DIR"/input/*.c \
  "$CORE_DIR/drivers/libretro/libretro.c" \
  "$CORE_DIR/drivers/libretro/libretro_dipswitch.c" \
  "$CORE_DIR/cart.c" "$CORE_DIR/cheat.c" "$CORE_DIR/crc32.c" \
  "$CORE_DIR/fceu-endian.c" "$CORE_DIR/fceu-memory.c" "$CORE_DIR/fceu.c" \
  "$CORE_DIR/fds.c" "$CORE_DIR/fds_apu.c" "$CORE_DIR/file.c" \
  "$CORE_DIR/filter.c" "$CORE_DIR/general.c" "$CORE_DIR/input.c" \
  "$CORE_DIR/md5.c" "$CORE_DIR/nsf.c" "$CORE_DIR/palette.c" \
  "$CORE_DIR/ppu.c" "$CORE_DIR/sound.c" "$CORE_DIR/state.c" \
  "$CORE_DIR/video.c" "$CORE_DIR/vsuni.c" "$CORE_DIR/ines.c" \
  "$CORE_DIR/unif.c" "$CORE_DIR/x6502.c" \
  "$COMM_DIR/compat/compat_posix_string.c" \
  "$COMM_DIR/compat/compat_snprintf.c" \
  "$COMM_DIR/compat/compat_strcasestr.c" \
  "$COMM_DIR/compat/compat_strl.c" \
  "$COMM_DIR/compat/fopen_utf8.c" \
  "$COMM_DIR/encodings/encoding_utf.c" \
  "$COMM_DIR/file/file_path.c" \
  "$COMM_DIR/file/file_path_io.c" \
  "$COMM_DIR/streams/file_stream.c" \
  "$COMM_DIR/streams/file_stream_transforms.c" \
  "$COMM_DIR/streams/memory_stream.c" \
  "$COMM_DIR/string/stdstring.c" \
  "$COMM_DIR/time/rtime.c" \
  "$COMM_DIR/vfs/vfs_implementation.c"; do
  rel="${src#$CORE_DIR/}"
  obj="$BUILD_DIR/${rel//\//_}.o"
  emcc -c "$src" -o "$obj" "${COMMON_FLAGS[@]}" "${INC_FLAGS[@]}"
  OBJECTS+=("$obj")
done

EXPORTED_FUNCTIONS='["_retro_init","_retro_deinit","_retro_api_version","_retro_get_system_info","_retro_get_system_av_info","_retro_set_environment","_retro_set_video_refresh","_retro_set_audio_sample","_retro_set_audio_sample_batch","_retro_set_input_poll","_retro_set_input_state","_retro_set_controller_port_device","_retro_reset","_retro_run","_retro_load_game","_retro_unload_game","_retro_get_region","_retro_serialize_size","_retro_serialize","_retro_unserialize","_malloc","_free"]'
EXPORTED_RUNTIME='["cwrap","ccall","addFunction","removeFunction","UTF8ToString","stringToUTF8","HEAPU8","HEAP8","HEAPU16","HEAP16","HEAPU32","HEAP32","HEAPF32"]'

emcc "${OBJECTS[@]}" -o "$SCRIPT_DIR/fceumm.js" \
  -O3 -flto -mno-simd128 \
  -sWASM=1 -sMODULARIZE=1 -sEXPORT_NAME=FceummCore \
  -sALLOW_TABLE_GROWTH=1 -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=16777216 \
  -sFILESYSTEM=0 -sENVIRONMENT='web,node' \
  -sEXPORTED_FUNCTIONS="$EXPORTED_FUNCTIONS" \
  -sEXPORTED_RUNTIME_METHODS="$EXPORTED_RUNTIME"

