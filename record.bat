@echo off
cd /d "%~dp0"

rem ====== SETTINGS ======
set FPS=30
set CRF=18
rem CRF: lower = better quality / bigger file (18 = very good, 23 = normal)
rem ======================

if not exist recordings mkdir recordings
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
set OUT=recordings\orbit_%TS%.mp4

echo.
echo  ============================================
echo   SCREEN RECORDING   (%FPS% fps, quality CRF=%CRF%)
echo  --------------------------------------------
echo   File:  %OUT%
echo.
echo   To STOP recording - press  Q  in this window.
echo  ============================================
echo.

ffmpeg.exe -f gdigrab -framerate %FPS% -i desktop -c:v libx264 -preset veryfast -crf %CRF% -pix_fmt yuv420p -movflags +faststart "%OUT%"

echo.
echo  Done. Video saved to:  %OUT%
echo.
pause
