@echo off
setlocal EnableDelayedExpansion
title MHGURecomp - dump checker
color 0F

echo ==================================================================
echo   MHGURecomp - is my dump usable?
echo ==================================================================
echo.
echo Drag your game dump folder into this window and press Enter.
echo It must be the folder that holds  exefs  and  romfs .
echo.

set "GAMEDIR=%~1"
if not defined GAMEDIR set /p "GAMEDIR=Folder: "
set GAMEDIR=!GAMEDIR:"=!
if not defined GAMEDIR goto :end

echo.
echo Checking: !GAMEDIR!
echo.

set "OK=1"

if not exist "!GAMEDIR!\exefs" (
  echo [X] no  exefs  folder here
  set "OK=0"
) else (
  echo [v] exefs found
)
if not exist "!GAMEDIR!\romfs" (
  echo [X] no  romfs  folder here
  set "OK=0"
) else (
  echo [v] romfs found
)
if "!OK!"=="0" goto :advice

for %%f in (main sdk rtld subsdk0) do (
  if exist "!GAMEDIR!\exefs\%%f" (
    echo [v] exefs\%%f
  ) else (
    echo [X] exefs\%%f is missing
    set "OK=0"
  )
)

if not exist "!GAMEDIR!\exefs\main" goto :advice
for %%A in ("!GAMEDIR!\exefs\main") do set "SIZE=%%~zA"
if !SIZE! LSS 1000000 (
  echo [X] exefs\main is only !SIZE! bytes - that is not the game
  set "OK=0"
  goto :advice
)

set "BID="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('!GAMEDIR:\=\\!\exefs\main'); if($b.Length -ge 96 -and [Text.Encoding]::ASCII.GetString($b,0,4) -eq 'NSO0'){ ([BitConverter]::ToString($b[0x40..0x5F]) -replace '-','').TrimEnd('0') } else { 'NOTNSO' }"`) do set "BID=%%i"

echo.
if /i "!BID!"=="NOTNSO" (
  echo [X] exefs\main does not start with NSO0 - it is not a game module.
  echo     Probably a shortcut, or the game files were never extracted.
  set "OK=0"
  goto :advice
)
if not defined BID (
  echo [X] could not read exefs\main
  set "OK=0"
  goto :advice
)

echo     build id: !BID!
if /i "!BID:~0,16!"=="FB08F1D20FD1204F" (
  echo [v] this is Monster Hunter Generations Ultimate 1.4.0 - exactly what the build wants
) else (
  echo [X] this is NOT MHGU 1.4.0.
  echo     The build needs the 1.4.0 title update applied on top of the base game.
  echo     A 1.4.0 dump starts with build id FB08F1D20FD1204F.
  set "OK=0"
)

:advice
echo.
echo ==================================================================
if "!OK!"=="1" (
  echo   RESULT: this dump is fine. Run build-nonavx2.bat with it.
) else (
  echo   RESULT: this dump will not build. See the [X] lines above.
  echo.
  echo   How to get a good dump:
  echo     - In Ryujinx or Yuzu: right-click the game, make sure the
  echo       1.4.0 update is installed, then Extract Data / Dump RomFS
  echo       with the update applied.
  echo     - You need the base game AND the 1.4.0 update, with the
  echo       update exefs and romfs copied ON TOP of the base game.
  echo     - The folder you point at must contain  exefs\  and  romfs\
  echo       directly. Not a folder with an .nsp inside, and not
  echo       exefs\exefs\.
)
echo ==================================================================
echo.
pause
exit /b 0

:end
echo Nothing given. Nothing done.
pause
exit /b 1