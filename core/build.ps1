# build.ps1 - Wrapper Windows para compilar cores/fceumm/fceumm.wasm (NES / Famicom) para Chromium M85 (Tizen 6.5)
$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$srcDir = Join-Path $scriptDir "libretro-fceumm"
$coreDir = Join-Path $srcDir "src"
$commDir = Join-Path $coreDir "drivers/libretro/libretro-common"
$buildDir = Join-Path $scriptDir "build"
$pinnedCommit = "e1630de02074801eb96f3bc4ff33f69df9554c69"

if (-not (Test-Path $srcDir)) {
  git clone https://github.com/EmulatorJS/libretro-fceumm.git $srcDir
  git -C $srcDir checkout $pinnedCommit | Out-Null
}

# Garantir patch de carregamento em memoria (info->data / info->size) sem exigir filesystem virtual (-sFILESYSTEM=0)
$libretroCPath = Join-Path $coreDir "drivers/libretro/libretro.c"
$libretroC = Get-Content $libretroCPath -Raw
if ($libretroC -match "info->need_fullpath\s*=\s*true;") {
  $libretroC = $libretroC -replace "info->need_fullpath\s*=\s*true;", "info->need_fullpath    = false;"
  Set-Content -Path $libretroCPath -Value $libretroC -NoNewline
}

$env:PATH = "C:\emsdk;C:\emsdk\upstream\emscripten;C:\emsdk\node\24.19.0_64bit;C:\emsdk\python\3.13.3_64bit;" + $env:PATH
$emcc = "C:\emsdk\upstream\emscripten\emcc.bat"

& $emcc --version

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$incFlags = @(
  "-I$coreDir/drivers/libretro",
  "-I$commDir/include",
  "-I$coreDir",
  "-I$coreDir/input",
  "-I$coreDir/boards"
)

$commonFlags = @(
  "-O3",
  "-flto",
  "-DNDEBUG",
  "-ffast-math",
  "-fno-strict-overflow",
  "-mno-simd128",
  "-D__LIBRETRO__",
  "-DFRONTEND_SUPPORTS_RGB565",
  "-DPATH_MAX=1024",
  "-DFCEU_VERSION_NUMERIC=9813",
  "-DLSB_FIRST",
  "-DLOCAL_LE=1",
  "-Wno-deprecated-declarations",
  "-Wno-implicit-function-declaration",
  "-Wno-int-conversion"
)

$cSources = @()
$cSources += Get-ChildItem -Path (Join-Path $coreDir "boards") -Filter "*.c" | ForEach-Object { $_.FullName }
$cSources += Get-ChildItem -Path (Join-Path $coreDir "input") -Filter "*.c" | ForEach-Object { $_.FullName }

$coreFiles = @(
  "drivers/libretro/libretro.c",
  "drivers/libretro/libretro_dipswitch.c",
  "cart.c",
  "cheat.c",
  "crc32.c",
  "fceu-endian.c",
  "fceu-memory.c",
  "fceu.c",
  "fds.c",
  "fds_apu.c",
  "file.c",
  "filter.c",
  "general.c",
  "input.c",
  "md5.c",
  "nsf.c",
  "palette.c",
  "ppu.c",
  "sound.c",
  "state.c",
  "video.c",
  "vsuni.c",
  "ines.c",
  "unif.c",
  "x6502.c",
  "drivers/libretro/libretro-common/compat/compat_posix_string.c",
  "drivers/libretro/libretro-common/compat/compat_snprintf.c",
  "drivers/libretro/libretro-common/compat/compat_strcasestr.c",
  "drivers/libretro/libretro-common/compat/compat_strl.c",
  "drivers/libretro/libretro-common/compat/fopen_utf8.c",
  "drivers/libretro/libretro-common/encodings/encoding_utf.c",
  "drivers/libretro/libretro-common/file/file_path.c",
  "drivers/libretro/libretro-common/file/file_path_io.c",
  "drivers/libretro/libretro-common/streams/file_stream.c",
  "drivers/libretro/libretro-common/streams/file_stream_transforms.c",
  "drivers/libretro/libretro-common/streams/memory_stream.c",
  "drivers/libretro/libretro-common/string/stdstring.c",
  "drivers/libretro/libretro-common/time/rtime.c",
  "drivers/libretro/libretro-common/vfs/vfs_implementation.c"
)

foreach ($rel in $coreFiles) {
  $cSources += (Join-Path $coreDir $rel)
}

Write-Host "Compilando $($cSources.Count) arquivos C do FCEUmm..." -ForegroundColor Cyan

$objects = @()
foreach ($fullSrc in $cSources) {
  $relName = $fullSrc.Substring($coreDir.Length + 1) -replace '[\\/]', '_'
  $objName = [System.IO.Path]::ChangeExtension($relName, ".o")
  $obj = Join-Path $buildDir $objName
  if (-not (Test-Path $obj) -or ((Get-Item $fullSrc).LastWriteTime -gt (Get-Item $obj).LastWriteTime)) {
    & $emcc -c $fullSrc -o $obj @commonFlags @incFlags
    if ($LASTEXITCODE -ne 0) { throw "Falha ao compilar $fullSrc" }
  }
  $objects += $obj
}

$exportedFunctions = '["_retro_init","_retro_deinit","_retro_api_version","_retro_get_system_info","_retro_get_system_av_info","_retro_set_environment","_retro_set_video_refresh","_retro_set_audio_sample","_retro_set_audio_sample_batch","_retro_set_input_poll","_retro_set_input_state","_retro_set_controller_port_device","_retro_reset","_retro_run","_retro_load_game","_retro_unload_game","_retro_get_region","_retro_serialize_size","_retro_serialize","_retro_unserialize","_malloc","_free"]'
$exportedRuntime = '["cwrap","ccall","addFunction","removeFunction","UTF8ToString","stringToUTF8","HEAPU8","HEAP8","HEAPU16","HEAP16","HEAPU32","HEAP32","HEAPF32"]'

$outJs = Join-Path $scriptDir "fceumm.js"
$rspFile = Join-Path $buildDir "objects.rsp"
($objects | ForEach-Object { '"' + ($_ -replace '\\', '/') + '"' }) -join " " | Set-Content -Path $rspFile -Encoding Ascii

& $emcc "@$rspFile" -o $outJs `
  -O3 -flto -mno-simd128 `
  -sWASM=1 `
  -sMODULARIZE=1 `
  -sEXPORT_NAME=FceummCore `
  -sALLOW_TABLE_GROWTH=1 `
  -sALLOW_MEMORY_GROWTH=1 `
  -sINITIAL_MEMORY=16777216 `
  -sFILESYSTEM=0 `
  -sENVIRONMENT='web,node' `
  "-sEXPORTED_FUNCTIONS=$exportedFunctions" `
  "-sEXPORTED_RUNTIME_METHODS=$exportedRuntime"

if ($LASTEXITCODE -ne 0) { throw "Falha no link de fceumm.wasm" }
Get-Item (Join-Path $scriptDir "fceumm.wasm"), (Join-Path $scriptDir "fceumm.js")

