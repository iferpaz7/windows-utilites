@echo off
:: PC Health Check Launcher
:: This batch file launches the PowerShell script with admin elevation

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

:: Launch PowerShell with the script, bypassing execution policy and requesting admin
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%PCHealthCheck.ps1\"' -Verb RunAs"
