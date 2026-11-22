@echo off
setlocal EnableDelayedExpansion
title MHGURecomp - merge base game with the 1.4.0 update
color 0F
pushd "%~dp0"

set "OUT=%~dp0dump-1.4.0"
set "WANT=FB08F1D20FD1204F"

echo ==================================================================
echo   Merge a base-game dump with the 1.4.0 update dump
echo ==================================================================
echo.
echo You need BOTH already extracted as folders, each holding  exefs\
echo and  romfs\ . This tool copies the update files ON TOP of the
echo base game ones, which is the part people get wrong.
echo.
echo It does not extract .nsp files and it does not need any keys.
echo.
echo Output folder: %OUT%
echo.

set "BASE=%~1"
if not defined BASE (
  echo [1/3] Drag the BASE GAME dump folder here and press Enter.
  set /p "BASE=Base: "
)
set BASE=!BASE:"=!
if not exist "!BASE!\exefs" goto :badbase
if not exist "!BASE!\romfs" goto :badbase

set "UPD=%~2"
if not defined UPD (
  echo.
  echo [2/3] Drag the 1.4.0 UPDATE dump folder here and press Enter.
  set /p "UPD=Update: "
)
set UPD=!UPD:"=!
if not exist "!UPD!\exefs" goto :badupd
if not exist "!UPD!\romfs" goto :badupd

echo.
echo   base:   !BASE!
echo   update: !UPD!
echo.

if exist "%OUT%" (
  echo [3/3] Removing the previous output ...
  rmdir /s /q "%OUT%"
)
mkdir "%OUT%" >nul 2>&1

echo [3/3] Copying the base game ...
robocopy "!BASE!" "%OUT%" /E /IS /NFL /NDL /NJH /NJS /R:1 /W:1 >nul
if errorlevel 8 goto :copyfail

echo       Copying the 1.4.0 update on top ...
robocopy "!UPD!" "%OUT%" /E /IS /NFL /NDL /NJH /NJS /R:1 /W:1 >nul
if errorlevel 8 goto :copyfail

echo.
echo ==================================================================
set "BID="
if not exist "%OUT%\exefs\main" (
  echo [X] exefs\main is missing from the result.
  goto :bad
)
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('%OUT:\=\\%\exefs\main'); if($b.Length -ge 96 -and [Text.Encoding]::ASCII.GetString($b,0,4) -eq 'NSO0'){ ([BitConverter]::ToString($b[0x40..0x5F]) -replace '-','').TrimEnd('0') } else { 'NOTNSO' }"`) do set "BID=%%i"

if not defined BID (
  echo [X] could not read the result exefs\main
  goto :bad
)
if /i "!BID!"=="NOTNSO" (
  echo [X] the result exefs\main is not a game module.
  goto :bad
)

echo     build id: !BID!
if /i "!BID:~0,16!"=="!WANT!" (
  echo [v] 1.4.0 confirmed. This folder is ready for build-nonavx2.bat.
  echo.
  echo   Merged dump: %OUT%
  echo.
  goto :ok
)
echo [X] the result is still not 1.4.0.
echo     Your update folder did not contain the 1.4.0 exefs\main,
echo     or the two folders were swapped. A 1.4.0 main starts with
echo     build id !WANT!
goto :bad

:ok
echo ==================================================================
echo.
echo Next: run build-nonavx2.bat and drag THIS folder in:
echo   %OUT%
echo.
pause
popd
exit /b 0

:bad
echo ==================================================================
echo.
echo Nothing usable was produced. The half-merged folder is left at
echo   %OUT%
echo so you can look at it; delete it when you are done.
echo.
pause
popd
exit /b 1

:badbase
echo.
echo "!BASE!" does not contain both  exefs  and  romfs .
echo That is not an extracted dump folder.
echo.
pause
popd
exit /b 1

:badupd
echo.
echo "!UPD!" does not contain both  exefs  and  romfs .
echo That is not an extracted dump folder.
echo.
pause
popd
exit /b 1

:copyfail
echo.
echo Copying failed. The usual reasons: not enough free disk space
echo (the result is about the size of the game, ~12 GB), or a file is
echo open in another program.
echo.
pause
popd
exit /b 1