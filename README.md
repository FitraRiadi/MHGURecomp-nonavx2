# MHGURecomp on a CPU without AVX2 (Windows)

The official MHGURecomp builds are compiled for `x86-64-v3`: AVX2, FMA, BMI1/2, F16C. On a CPU without those, the game closes right after launch and the end of `log.txt` says:

```
[gamelib] ...\mhgugame.dll needs CPU features this CPU lacks: AVX, AVX2, FMA, BMI1, BMI2, F16C
```

There is no "nonavx2" download on the official releases page. You build it yourself, from your own copy of the game — the project's Makefile already has the switch (`GENARCH=-march=x86-64-v2`, documented under *Useful targets and options*). This repo is those steps, written down in one place and wrapped in a script.

**No game files here, and none will ever be added.**

---

## Quick start (one click)

1. Download both **[check-dump.bat](check-dump.bat)** and **[build-nonavx2.bat](build-nonavx2.bat)** (button: *Raw* → *Save as*).
2. Put them in a folder on the **same drive as your game dump**, for example `D:\MHGU-build\`.
3. Double-click **check-dump.bat** and drag your dump folder in. It reads the build id of `exefs\main` and tells you in two seconds whether the dump will build — instead of failing 20 minutes into a compile.
4. Double-click **build-nonavx2.bat**, drag the same folder in. The first run installs MSYS2, Python and the build tools, then compiles. Roughly 10-30 minutes, once.
5. It starts the game when it's done. Next time, just run `MHGURecomp\build\mhgurecomp.exe`.

### If it says "a dump that is not 1.4.0"

That line is the script guessing, not the compiler's own error — the real message is a few lines above it. Almost always one of these:

| What the log says | What it means |
|---|---|
| `No such file or directory` on `exefs/main` | You pointed at the wrong folder, or at a folder holding the `.nsp` instead of the extracted files. |
| `exefs\main` is tiny | A shortcut or a stub, not the real module. |
| It builds, but the game shows wrong text or crashes | The dump is the **base game only** — the 1.4.0 title update was never applied. |

You need the base game **and** the 1.4.0 update, with the update's `exefs` and `romfs` copied **on top of** the base game's (overwrite when asked). In Ryujinx or Yuzu: install the update first, then *Extract Data / Dump RomFS* — the emulator writes out the patched files. A correct 1.4.0 `exefs\main` starts with build id `FB08F1D20FD1204F`; `check-dump.bat` prints yours.

The script downloads only open-source software and the official MHGURecomp source. Your game files never leave your PC.

## Before you build: test the official build first

Plenty of "old" CPUs still have AVX2 — then you need none of this. Grab the official Windows zip from [morerokk/MHGURecomp releases](https://github.com/morerokk/MHGURecomp/releases), put your `exefs` and `romfs` into its `data` folder, run `mhgurecomp.exe`.

- It runs → you're done.
- It closes instantly and `log.txt` ends with the `needs CPU features` line → build it with the script.

---

## Doing it by hand

Same result, if you prefer to see every step. Full details are in the official [README](https://github.com/morerokk/MHGURecomp#building-from-source); this is the short version with the one flag that matters.

**You need:** your own 1.4.0 dump (`exefs` + `romfs`), [MSYS2](https://www.msys2.org/) in `C:\msys64`, [Python](https://www.python.org/) 3.10+, ~5 GB free disk.

In the **MSYS2 UCRT64** shell:

```bash
pacman -S --needed make git diffutils \\
  mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-lld mingw-w64-ucrt-x86_64-pkgconf \\
  mingw-w64-ucrt-x86_64-sdl3 mingw-w64-ucrt-x86_64-shaderc mingw-w64-ucrt-x86_64-nasm \\
  mingw-w64-ucrt-x86_64-vulkan-headers mingw-w64-ucrt-x86_64-vulkan-loader \\
  mingw-w64-ucrt-x86_64-vulkan-memory-allocator
```

Then in a normal Command Prompt:

```bat
git clone https://github.com/morerokk/MHGURecomp
cd MHGURecomp
py -3 -m venv tools\venv
tools\venv\Scripts\pip install -r tools\requirements.txt
```

Back in **UCRT64**, in that folder, with your game files in a folder holding `exefs\` and `romfs\`:

```bash
make gen GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
make -j4 GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
```

`GENARCH` is the whole trick: `-march=x86-64-v2` targets SSE4.2/POPCNT instead of AVX2. Leave it out and you get the official build — the one that crashes on your machine.

`build\` is then a ready-to-run game folder: `mhgurecomp.exe`, `mhgugame.dll`, the DLLs they need, and `data\` (hard links to your game files, no extra disk). Copy it anywhere and run `mhgurecomp.exe`.

---

## Playing with friends

`mhgurecomp.ini` next to the exe:

```ini
Server=
Port=39500
Key=
```

`Server=` empty uses the public hub server. Put the **same** `Key=` on every PC to make a private room your group can find and nobody else can. Close the game before changing it — the key is read at startup.

A build from this recipe is the **same protocol version as the official build**, so you can play with everyone on the official release.

## Things worth knowing

- **Keep the pair together.** `mhgurecomp.exe` and `mhgugame.dll` must come from the same build; a mismatched pair is refused at startup.
- **Every update needs a rebuild.** There's no nonavx2 download, so when a new version ships, run the script again (it reuses the clone and only recompiles what changed).
- **Don't mix this with the Android fork.** [khorne-hub/gu-native](https://github.com/khorne-hub/gu-native) is a separate fork with a different protocol version; rooms from one are not meant to be joined from the other — see [issue #238](https://github.com/khorne-hub/gu-native/issues/238). Same fork on both ends is fine.
- **Officially untested.** `GENARCH=-march=x86-64-v2` is a supported switch but not a tested configuration — the official README says so itself. These notes come from an Intel UHD 610 / Skylake-era laptop, where it works.
- **Keep the dump on the same drive** as the build folder: the build hard-links the game files instead of copying them (saves ~12 GB).

---

*Indonesian version: [README.id.md](README.id.md)*
