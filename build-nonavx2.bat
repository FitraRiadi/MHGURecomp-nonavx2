@echo off
setlocal EnableDelayedExpansion
title MHGURecomp - build for CPUs without AVX2
color 0F
pushd "%~dp0"

set "HERE=%~dp0"
set "SRC=%HERE%MHGURecomp"
set "MSYS=C:\msys64"
set "BASH=%MSYS%\usr\bin\bash.exe"

echo ==================================================================
echo   MHGURecomp - build for a CPU without AVX2
echo ==================================================================
echo.
echo This builds the game from YOUR OWN dump, compiled without AVX2.
echo Only the open-source project is downloaded. No game files.
echo.

REM ---------------------------------------------------------------- 1
set "GAMEDIR=%~1"
if not defined GAMEDIR (
  echo Drag your game dump folder into this window and press Enter.
  echo It must be the folder that holds  exefs  and  romfs .
  echo.
  set /p "GAMEDIR=Folder: "
)
set GAMEDIR=!GAMEDIR:"=!
if not defined GAMEDIR goto :nofolder
if not exist "!GAMEDIR!\exefs" goto :baddump
if not exist "!GAMEDIR!\romfs" goto :baddump

call :toposix "!GAMEDIR!" MHGU_GAME
call :toposix "%SRC%" MHGU_SRC
call :toposix "%HERE%build.sh" MHGU_BAT
echo Game dump: !GAMEDIR!
echo Project:   %SRC%
echo.

REM ---------------------------------------------------------------- 2
if not exist "%BASH%" (
  echo [1/5] MSYS2 not found. Installing to %MSYS% ...
  curl -L -o "%TEMP%\msys2-setup.exe" https://github.com/msys2/msys2-installer/releases/latest/download/msys2-x86_64-latest.exe
  if errorlevel 1 goto :msysfail
  "%TEMP%\msys2-setup.exe" in --confirm-command --accept-messages --accept-licenses --root "%MSYS%"
  if errorlevel 1 goto :msysfail
  if not exist "%BASH%" goto :msysfail
) else (
  echo [1/5] MSYS2 found.
)

REM ---------------------------------------------------------------- 3
py -3 -c "import sys" >nul 2>&1
if errorlevel 1 (
  echo [2/5] Python not found. Installing ...
  curl -L -o "%TEMP%\py-setup.exe" https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe
  if errorlevel 1 goto :pyfail
  "%TEMP%\py-setup.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0
  set "PYBIN=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
  if not exist "!PYBIN!" goto :pyfail
  echo      Python installed.
) else (
  for /f "delims=" %%i in ('py -3 -c "import sys;print(sys.executable)"') do set "PYBIN=%%i"
  echo [2/5] Python found: !PYBIN!
)

REM ---------------------------------------------------------------- 4
echo [3/5] Installing build tools. This takes a few minutes the first time ...
set "MSYSTEM=UCRT64"
"%BASH%" -l -c "pacman -Syu --noconfirm"
"%BASH%" -l -c "pacman -S --needed --noconfirm make git diffutils mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-lld mingw-w64-ucrt-x86_64-pkgconf mingw-w64-ucrt-x86_64-sdl3 mingw-w64-ucrt-x86_64-shaderc mingw-w64-ucrt-x86_64-nasm mingw-w64-ucrt-x86_64-vulkan-headers mingw-w64-ucrt-x86_64-vulkan-loader mingw-w64-ucrt-x86_64-vulkan-memory-allocator"
if errorlevel 1 goto :pkgfail

REM ---------------------------------------------------------------- 5
if not exist "%SRC%\Makefile" (
  echo [4/5] Downloading the project ...
  "%BASH%" -l -c "git clone https://github.com/morerokk/MHGURecomp '!MHGU_SRC!'"
  if errorlevel 1 goto :clonefail
) else (
  echo [4/5] Project already present.
)

if not exist "%SRC%\tools\venv\Scripts\python.exe" (
  echo      Preparing the build tools' Python environment ...
  "!PYBIN!" -m venv "%SRC%\tools\venv"
  if errorlevel 1 goto :venvfail
  "%SRC%\tools\venv\Scripts\python.exe" -m pip install -q -r "%SRC%\tools\requirements.txt"
  if errorlevel 1 goto :venvfail
)

REM ---------------------------------------------------------------- 6
echo.
echo [5/5] Building without AVX2. First build: 10-30 minutes. Go get tea.
echo.
> "build.sh" echo set -e
>>"build.sh" echo cd "!MHGU_SRC!"
>>"build.sh" echo make gen GAME="!MHGU_GAME!" GENARCH=-march=x86-64-v2
>>"build.sh" echo make -j%NUMBER_OF_PROCESSORS% GAME="!MHGU_GAME!" GENARCH=-march=x86-64-v2
"%BASH%" -l "!MHGU_BAT!"
if errorlevel 1 goto :buildfail
del "build.sh" >nul 2>&1

if not exist "%SRC%\build\mhgurecomp.exe" goto :buildfail
if not exist "%SRC%\build\mhgugame.dll" goto :buildfail

if not exist "%SRC%\build\mhgurecomp.ini" (
  > "%SRC%\build\mhgurecomp.ini" echo Server=
  >>"%SRC%\build\mhgurecomp.ini" echo Port=39500
  >>"%SRC%\build\mhgurecomp.ini" echo Key=
)

echo.
echo ==================================================================
echo   Done. The game is in:
echo   %SRC%\build\
echo ==================================================================
echo.
echo Starting it now. To play with friends, put the same  Key=  in
echo mhgurecomp.ini on every PC, and close the game before changing it.
echo.
start "" "%SRC%\build\mhgurecomp.exe"
echo This window closes in 20 seconds.
timeout /t 20 >nul
popd
exit /b 0

:toposix
set "_v=%~1"
set "_v=!_v:\=/!"
if "!_v:~1,1!"==":" set "_v=/!_v:~0,1!!_v:~2!"
set "%~2=!_v!"
goto :eof

:nofolder
echo.
echo No folder given. Nothing done.
goto :end
:baddump
echo.
echo "!GAMEDIR!" does not contain both  exefs  and  romfs .
echo Point me at the folder that holds them.
goto :end
:msysfail
echo.
echo Could not install MSYS2 automatically.
echo Install it by hand from https://www.msys2.org/ into C:\msys64
echo and run this script again.
goto :end
:pyfail
echo.
echo Could not install Python automatically.
echo Install it by hand from https://www.python.org/downloads/
echo (tick "Add python.exe to PATH") and run this script again.
goto :end
:pkgfail
echo.
echo Installing the build tools failed. Run the script again; if it keeps
echo failing, check your internet or the MSYS2 mirror.
goto :end
:clonefail
echo.
echo Could not download the project from GitHub. Check your internet.
goto :end
:venvfail
echo.
echo Setting up the Python environment for the build tools failed.
echo Delete  %SRC%\tools\venv  and run the script again.
goto :end
:buildfail
echo.
echo The build failed. Scroll up for the compiler's own error message.
echo The most common causes: a dump that is not 1.4.0, a folder without
echo both  exefs  and  romfs , or the dump on a different drive than this
echo script (the build hard-links the game files, so keep them together).
goto :end

:end
echo.
pause
popd
exit /b 1
