@echo off
REM ---------------------------------------------------------------------------
REM  Aarush Suzuki - client preview link
REM  Double-click this file. It starts the local site and opens a temporary
REM  public https link through Cloudflare (trycloudflare.com).
REM  - The link works only while BOTH windows stay open and this PC is online.
REM  - A new link is generated every time you run this.
REM  - Close both windows to take the preview offline.
REM ---------------------------------------------------------------------------
cd /d "%~dp0"
start "Aarush Suzuki - local site" powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1 -Port 5250 -Root site
timeout /t 3 /nobreak >nul
echo.
echo   Starting the preview link... look for a line ending in  .trycloudflare.com
echo   Copy that https link and share it.
echo.
tools\cloudflared.exe tunnel --no-autoupdate --http-host-header localhost:5250 --url http://localhost:5250
pause
