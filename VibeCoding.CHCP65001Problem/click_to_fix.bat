@echo off
chcp 65001 >nul
echo.
echo ==============================================================
echo   修復 cmd / PowerShell 中文亂碼 - 啟動診斷與修復腳本
echo ==============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix_cmd_chinese.ps1"
pause
