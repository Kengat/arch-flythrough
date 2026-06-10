@echo off
chcp 65001 >nul
cd /d "%~dp0"

rem ====== НАСТРОЙКИ ======
set FPS=30
set CRF=18
rem CRF: меньше = выше качество/больше файл (18 - очень хорошо, 23 - обычно)
rem ======================

if not exist recordings mkdir recordings
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set TS=%%i
set OUT=recordings\orbit_%TS%.mp4

echo.
echo  ============================================
echo   ЗАПИСЬ ЭКРАНА   (%FPS% fps, качество CRF=%CRF%)
echo  --------------------------------------------
echo   Файл:  %OUT%
echo.
echo   Чтобы ОСТАНОВИТЬ запись - нажми  Q  в этом окне.
echo  ============================================
echo.

ffmpeg.exe -f gdigrab -framerate %FPS% -i desktop ^
  -c:v libx264 -preset veryfast -crf %CRF% -pix_fmt yuv420p -movflags +faststart ^
  "%OUT%"

echo.
echo  Готово. Видео тут:  %OUT%
echo.
pause
