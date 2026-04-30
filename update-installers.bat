@echo off
REM כפול-לחיצה כאן = מעדכן את כל ההתקנות.
REM לוג נשמר ב-update-log.txt באותה תיקייה.
chcp 65001 >nul
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0update-installers.ps1"
echo.
echo ----- סיים. הקש מקש כלשהו כדי לסגור. -----
pause >nul
