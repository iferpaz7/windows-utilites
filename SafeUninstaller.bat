@echo off
:: Safe Uninstaller Launcher
:: Automatically elevates and runs the PowerShell script

title Safe Program Uninstaller

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run
) else (
    goto :elevate
)

:elevate
echo Requesting administrator privileges...
powershell -Command "Start-Process '%~f0' -Verb RunAs"
exit /b

:run
:: Run the PowerShell script with elevated privileges
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SafeUninstaller.ps1"

:: Keep window open if there was an error
if %errorLevel% neq 0 (
    echo.
    echo Script execution failed with error code: %errorLevel%
    pause
)

exit /b %errorLevel%
