# Third-party components and their licenses

The original application code of this project is under the MIT License (see LICENSE).
The components below are third-party and keep their own licenses. This project is
free and non-commercial.

## FCEUmm (emulation core)
- Files: `js/fceumm.wasm`, `js/fceumm.js` (compiled with Emscripten).
- Origin: https://github.com/libretro/fceumm (FCEUmm, a maintained fork of FCE Ultra).
- License: GNU General Public License v2.
- Build reproducibility: see `core/` (build.sh, build.ps1 and VERSION.md), Emscripten
  emcc 3.1.56, single-thread scalar, `-mno-simd128`, RGB565, in-memory ROM loading.

## 240p Test Suite — NES (bundled free ROM)
- File: `roms_pub/240pee.nes`.
- Author: Damian Yerrick (pinobatch), based on the original 240p Test Suite by Artemio Urbina.
- Project: https://github.com/pinobatch/240p-test-mini (release v0.23).
- License: GNU GPL v2 or later (`roms_pub/240p-GPLv2.txt`).
- The binary is redistributed unmodified; corresponding source is publicly available at
  the link above. See `roms_pub/CREDITS.md`.

## Artwork
- Controller photo (`img/joy_photo.jpg`): photo by Ravi Palwe on Unsplash
  (https://unsplash.com/photos/_JTF0Prc7jc), used under the Unsplash License
  (free for commercial and non-commercial use, attribution not required; credited here
  regardless). Used as the base for the interactive joystick configuration diagram.
- The highlight overlays (`img/overlays/`) are authored for this project (generated masks
  aligned to the controller photo). The app icon and the selection wallpaper are authored
  for this project.

## Commercial ROMs
- Commercial game ROMs are NOT included in this repository. The private `roms/`
  folder and `roms.json` are git-ignored. Only freely distributable ROMs ship
  in `roms_pub/`.
