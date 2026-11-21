# MHGURecomp on a CPU without AVX2 (Windows)

The official MHGURecomp builds are compiled for `x86-64-v3`, which means AVX2, FMA, BMI1/2 and F16C. On a CPU that doesn't have those, the game closes right after launch and the end of `log.txt` says:

```
[gamelib] ...\mhgugame.dll needs CPU features this CPU lacks: AVX, AVX2, FMA, BMI1, BMI2, F16C
```

There is no "nonavx2" download on the official releases page. You build it yourself, from your own copy of the game — the project's Makefile already has the switch for it (`GENARCH=-march=x86-64-v2`, documented under "Useful targets and options"). This repo is just those steps written down in one place. No game files here, none will ever be added.

## Step 0 — test the official build first

Lots of "old" CPUs still have AVX2, and then you don't need any of this. Download the official Windows zip from [morerokk/MHGURecomp releases](https://github.com/morerokk/MHGURecomp/releases), put your `exefs` and `romfs` in its `data` folder, and run `mhgurecomp.exe`.

- It runs → you're done, close this tab.
- It closes immediately and `log.txt` ends with the `needs CPU features` line above → keep reading.

## Step 1 — what you need

- Your own game dump: `exefs` and `romfs` from MHGU 1.4.0 (title ID `0100770008DD8000`). The port does not explain how to dump it and this repo won't either.
- [MSYS2](https://www.msys2.org/) installed to `C:\msys64`
- [Python](https://www.python.org/) 3.10 or newer for Windows
- ~5 GB of free disk space (the translated game code alone is ~300 MB)
- A few minutes of patience: the first full build takes about 8 minutes on a 4-core Haswell

## Step 2 — build it

In the **MSYS2 UCRT64** shell:

```bash
pacman -S --needed make git diffutils \
  mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-lld mingw-w64-ucrt-x86_64-pkgconf \
  mingw-w64-ucrt-x86_64-sdl3 mingw-w64-ucrt-x86_64-shaderc mingw-w64-ucrt-x86_64-nasm \
  mingw-w64-ucrt-x86_64-vulkan-headers mingw-w64-ucrt-x86_64-vulkan-loader \
  mingw-w64-ucrt-x86_64-vulkan-memory-allocator
```

Then, in a normal Command Prompt:

```bat
git clone https://github.com/morerokk/MHGURecomp
cd MHGURecomp
py -3 -m venv tools\venv
tools\venv\Scripts\pip install -r tools\requirements.txt
```

Back in the **UCRT64** shell, in the same folder, with your game files in a folder that holds `exefs\` and `romfs\` — the one thing that differs from the official guide is `GENARCH`:

```bash
make gen GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
make -j4 GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
```

`-march=x86-64-v2` targets SSE4.2/POPCNT instead of AVX2. Drop it and you get exactly the official build, which is the one that crashes on your machine.

## Step 3 — play

`build\` is now a ready-to-run game folder: `mhgurecomp.exe`, `mhgugame.dll`, the DLLs they need, and `data\` with hard links to your game files. Copy its contents anywhere and run `mhgurecomp.exe`, or start `run-game.bat` to keep the settings, caches, mods and `log.txt` in a separate `run\` folder.

Multiplayer works exactly like the official build — `Server=`, `Port=`, `Key=` in `mhgurecomp.ini`. A build from this recipe is the same protocol version as the official one, so you can play with everyone on the official release.

## Things worth knowing

- **Keep the pair together.** `mhgurecomp.exe` and `mhgugame.dll` must come from the same build; mixing versions is refused at startup.
- **Every update needs a rebuild.** There is no nonavx2 download, so when a new version comes out you repeat Step 2.
- **Don't mix this with the Android fork.** [khorne-hub/gu-native](https://github.com/khorne-hub/gu-native) is a different fork with a different protocol version; rooms from one aren't meant to be joined from the other ([issue #238](https://github.com/khorne-hub/gu-native/issues/238)). Same fork on both ends is fine.
- **Untested, says the README itself.** `GENARCH=-march=x86-64-v2` is a supported switch but not a tested configuration. It works on an Intel UHD 610 / Skylake-era laptop, which is where these notes come from.

---

### Bahasa Indonesia (ringkas)

Build resmi MHGURecomp butuh AVX2, jadi di CPU lama game langsung nutup dan `log.txt` berakhir dengan baris `needs CPU features this CPU lacks: AVX, AVX2...`. Gak ada download "nonavx2" resmi — harus di-build sendiri dari dump game sendiri, pakai tombol yang emang udah ada di Makefile-nya: `GENARCH="-march=x86-64-v2"`. Ikuti Step 0 dulu (siapa tau CPU lu ternyata udah punya AVX2 dan gak perlu apa-apa), lalu Step 2 kalau beneran crash. Hasilnya di folder `build\`, tinggal jalanin `mhgurecomp.exe`.
