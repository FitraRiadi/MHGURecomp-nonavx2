# MHGURecomp di CPU tanpa AVX2 (Windows)

Build resmi MHGURecomp dikompilasi untuk `x86-64-v3`: AVX2, FMA, BMI1/2, F16C. Di CPU yang gak punya itu, game langsung nutup dan ujung `log.txt` bilang:

```
[gamelib] ...\mhgugame.dll needs CPU features this CPU lacks: AVX, AVX2, FMA, BMI1, BMI2, F16C
```

Gak ada download "nonavx2" di halaman rilis resmi. Harus di-build sendiri dari dump game sendiri — tombolnya udah ada di Makefile proyeknya (`GENARCH=-march=x86-64-v2`, ada di bagian *Useful targets and options*). Repo ini isinya langkah-langkah itu, ditulis di satu tempat dan dibungkus jadi script.

**Gak ada file game di sini, dan gak akan pernah ada.**

---

## Cara cepat (sekali klik)

1. Download **[build-nonavx2.bat](build-nonavx2.bat)** (tombol *Raw* → *Save as*).
2. Taruh di folder yang **satu drive dengan dump game** lu, misal `D:\MHGU-build\`.
3. Double-click. Pas diminta folder, **tarik folder dump game** lu (yang isinya `exefs` dan `romfs`) ke jendelanya, tekan Enter.
4. Tunggu. Run pertama install MSYS2, Python, dan tool build, lalu kompilasi. Sekitar 10-30 menit, sekali doang.
5. Selesai, game-nya langsung dibuka. Berikutnya tinggal jalanin `MHGURecomp\build\mhgurecomp.exe`.

Script-nya cuma download software open-source + source resmi MHGURecomp. File game lu gak pernah keluar dari PC lu.

## Sebelum build: tes build resmi dulu

Banyak CPU "jadul" ternyata masih punya AVX2 — kalau iya, lu gak perlu apa-apa. Ambil zip Windows resmi dari [rilis morerokk/MHGURecomp](https://github.com/morerokk/MHGURecomp/releases), taruh `exefs` dan `romfs` ke folder `data`, jalanin `mhgurecomp.exe`.

- Jalan → beres, tutup halaman ini.
- Nutup sekejap dan ujung `log.txt` ada baris `needs CPU features` → build pakai script di atas.

---

## Kalau mau manual

Hasilnya sama. Detail lengkap ada di [README resmi](https://github.com/morerokk/MHGURecomp#building-from-source); ini versi pendek dengan satu flag yang penting.

**Butuh:** dump 1.4.0 milik sendiri (`exefs` + `romfs`), [MSYS2](https://www.msys2.org/) di `C:\msys64`, [Python](https://www.python.org/) 3.10+, ~5 GB disk kosong.

Di shell **MSYS2 UCRT64**:

```bash
pacman -S --needed make git diffutils \\
  mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-lld mingw-w64-ucrt-x86_64-pkgconf \\
  mingw-w64-ucrt-x86_64-sdl3 mingw-w64-ucrt-x86_64-shaderc mingw-w64-ucrt-x86_64-nasm \\
  mingw-w64-ucrt-x86_64-vulkan-headers mingw-w64-ucrt-x86_64-vulkan-loader \\
  mingw-w64-ucrt-x86_64-vulkan-memory-allocator
```

Lalu di Command Prompt biasa:

```bat
git clone https://github.com/morerokk/MHGURecomp
cd MHGURecomp
py -3 -m venv tools\venv
tools\venv\Scripts\pip install -r tools\requirements.txt
```

Balik ke **UCRT64**, di folder itu, dengan file game di folder yang punya `exefs\` dan `romfs\`:

```bash
make gen GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
make -j4 GAME=/c/path/to/game GENARCH="-march=x86-64-v2"
```

`GENARCH` itu intinya: `-march=x86-64-v2` nargetin SSE4.2/POPCNT, bukan AVX2. Kalau dihilangkan, hasilnya build resmi — yang crash di mesin lu.

Folder `build\` jadi game siap jalan: `mhgurecomp.exe`, `mhgugame.dll`, DLL pendukungnya, dan `data\` (hard link ke file game, gak makan disk ekstra). Copy ke mana aja, jalanin `mhgurecomp.exe`.

---

## Mabar sama temen

`mhgurecomp.ini` di sebelah exe:

```ini
Server=
Port=39500
Key=
```

`Server=` kosong = pakai hub server publik. Isi `Key=` yang **sama** di semua PC biar room-nya privat, cuma grup lu yang bisa nemu. Tutup game dulu sebelum ganti key — key dibaca pas game dibuka.

Build dari resep ini **versi protokolnya sama dengan build resmi**, jadi bisa mabar sama semua orang yang pakai rilis resmi.

## Yang perlu diketahui

- **Exe dan dll harus sepasang.** `mhgurecomp.exe` dan `mhgugame.dll` wajib dari build yang sama; kalau beda versi, ditolak pas startup.
- **Tiap update wajib build ulang.** Gak ada download nonavx2, jadi tiap versi baru keluar, jalanin script-nya lagi (clone-nya dipakai ulang, cuma yang berubah yang dikompilasi).
- **Jangan dicampur sama fork Android.** [khorne-hub/gu-native](https://github.com/khorne-hub/gu-native) itu fork lain dengan versi protokol beda; room dari yang satu gak didesain buat dimasuki dari yang lain — lihat [issue #238](https://github.com/khorne-hub/gu-native/issues/238). Sesama fork yang sama aman.
- **Resmi: untested.** `GENARCH=-march=x86-64-v2` itu switch yang didukung tapi bukan konfigurasi yang dites — README resminya sendiri bilang gitu. Catatan ini dari laptop Intel UHD 610 era Skylake, dan di situ jalan.
- **Simpen dump di drive yang sama** dengan folder build: build-nya hard-link file game, bukan copy (hemat ~12 GB).

---

*English version: [README.md](README.md)*
