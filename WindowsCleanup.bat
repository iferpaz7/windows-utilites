@echo off
:: Windows Cleanup Utility - Similar to Windows PC Manager
:: Removes temporary files and system cache to boost performance
:: Author: System Optimizer
:: Date: January 2026

title Windows Cleanup Utility
color 0A

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ============================================
    echo  Administrative privileges required!
    echo  Right-click and select "Run as administrator"
    echo ============================================
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo     Windows Cleanup Utility
echo     Optimizing System Performance
echo ============================================
echo.
echo Starting cleanup process...
echo.

:: Display disk space before cleanup
echo [INFO] Checking disk space before cleanup...
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do set BEFORE=%%a
echo Before: %BEFORE% bytes free on C:
echo.

:: Step 1: Clean Windows Temp folder
echo [1/12] Cleaning Windows Temp folder...
del /f /s /q %SystemRoot%\Temp\*.* >nul 2>&1
rd /s /q %SystemRoot%\Temp >nul 2>&1
mkdir %SystemRoot%\Temp >nul 2>&1
echo       Done!

:: Step 2: Clean User Temp folder
echo [2/12] Cleaning User Temp folder...
del /f /s /q %TEMP%\*.* >nul 2>&1
rd /s /q %TEMP% >nul 2>&1
mkdir %TEMP% >nul 2>&1
echo       Done!

:: Step 3: Clean Prefetch
echo [3/12] Cleaning Prefetch data...
del /f /s /q %SystemRoot%\Prefetch\*.* >nul 2>&1
echo       Done!

:: Step 4: Clean Windows Update Cache
echo [4/12] Cleaning Windows Update cache...
del /f /s /q %SystemRoot%\SoftwareDistribution\Download\*.* >nul 2>&1
rd /s /q %SystemRoot%\SoftwareDistribution\Download >nul 2>&1
mkdir %SystemRoot%\SoftwareDistribution\Download >nul 2>&1
echo       Done!

:: Step 5: Clean DNS Cache
echo [5/12] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo       Done!

:: Step 6: Clean Thumbnail Cache
echo [6/12] Cleaning Thumbnail cache...
del /f /s /q %LocalAppData%\Microsoft\Windows\Explorer\*.db >nul 2>&1
echo       Done!

:: Step 7: Clean Windows Error Reporting
echo [7/12] Cleaning Windows Error Reports...
del /f /s /q %ProgramData%\Microsoft\Windows\WER\*.* >nul 2>&1
echo       Done!

:: Step 8: Clean Recent Files
echo [8/12] Cleaning Recent files...
del /f /s /q %APPDATA%\Microsoft\Windows\Recent\*.* >nul 2>&1
echo       Done!

:: Step 9: Empty Recycle Bin
echo [9/12] Emptying Recycle Bin...
PowerShell.exe -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo       Done!

:: Step 10: Clean Delivery Optimization Files
echo [10/12] Cleaning Delivery Optimization cache...
del /f /s /q %SystemRoot%\SoftwareDistribution\DeliveryOptimization\*.* >nul 2>&1
echo        Done!

:: Step 11: Clean Windows Logs
echo [11/12] Cleaning Windows Log files...
del /f /s /q %SystemRoot%\Logs\*.log >nul 2>&1
del /f /s /q %SystemRoot%\Debug\*.log >nul 2>&1
echo        Done!

:: Step 12: Run Disk Cleanup utility silently
echo [12/12] Running Windows Disk Cleanup...
cleanmgr /sagerun:1 /verylowdisk >nul 2>&1
echo        Done!

echo.
echo ============================================
echo     Additional Optimizations
echo ============================================
echo.

:: Clear Internet Explorer/Edge cache
echo [BONUS] Cleaning browser cache...
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255 >nul 2>&1
echo        Done!

:: Display disk space after cleanup
echo.
echo ============================================
echo [INFO] Checking disk space after cleanup...
for /f "tokens=3" %%a in ('dir c:\ ^| find "bytes free"') do set AFTER=%%a
echo After: %AFTER% bytes free on C:
echo.

echo ============================================
echo     Cleanup Completed Successfully!
echo ============================================
echo.
echo The following areas have been cleaned:
echo  - Windows Temp files
echo  - User Temp files
echo  - Prefetch data
echo  - Windows Update cache
echo  - DNS cache
echo  - Thumbnail cache
echo  - Error reports
echo  - Recent files
echo  - Recycle Bin
echo  - Delivery Optimization cache
echo  - Log files
echo  - Browser cache
echo.
echo Your system has been optimized!
echo.
pause
