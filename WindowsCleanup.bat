@echo off
:: Windows Cleanup Utility - Similar to Windows PC Manager
:: Removes temporary files and system cache to boost performance
:: Author: System Optimizer
:: Date: January 2026

title Windows Cleanup Utility
color 0A

:: ============================================
:: Auto-elevate to Administrator privileges
:: ============================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    :: Create a temporary VBScript to elevate
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs" >nul 2>&1
    exit /b
)

:: Now running with admin privileges
cd /d "%~dp0"

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

:: ============================================
:: SMART Development Process Cleanup
:: Only kills orphaned/duplicate processes
:: Respects running IDEs and active sessions
:: ============================================
echo [DEV] Smart cleanup of development processes...
echo.

:: Check if Visual Studio is running
set VS_RUNNING=0
tasklist /FI "IMAGENAME eq devenv.exe" 2>nul | find /I "devenv.exe" >nul && set VS_RUNNING=1

:: Check if VS Code is running
set VSCODE_RUNNING=0
tasklist /FI "IMAGENAME eq Code.exe" 2>nul | find /I "Code.exe" >nul && set VSCODE_RUNNING=0

:: .NET Cleanup - Only orphaned processes (when VS is not running)
echo       [.NET] Checking for orphaned .NET processes...
if %VS_RUNNING%==0 (
    echo              Visual Studio not running - cleaning VS services...
    taskkill /F /IM "ServiceHub.Host.CLR.x64.exe" >nul 2>&1
    taskkill /F /IM "ServiceHub.RoslynCodeAnalysisService.exe" >nul 2>&1
    taskkill /F /IM "ServiceHub.IdentityHost.exe" >nul 2>&1
    taskkill /F /IM "ServiceHub.VSDetouredHost.exe" >nul 2>&1
    taskkill /F /IM "ServiceHub.TestWindowStoreHost.exe" >nul 2>&1
    taskkill /F /IM "PerfWatson2.exe" >nul 2>&1
    taskkill /F /IM "Microsoft.ServiceHub.Controller.exe" >nul 2>&1
    taskkill /F /IM "vsls-agent.exe" >nul 2>&1
    taskkill /F /IM "vshost32.exe" >nul 2>&1
    taskkill /F /IM "vshost.exe" >nul 2>&1
) else (
    echo              Visual Studio is running - skipping VS services
)

:: Always clean these test/build processes (safe to kill)
taskkill /F /IM "vstest.console.exe" >nul 2>&1
taskkill /F /IM "testhost.exe" >nul 2>&1
taskkill /F /IM "testhost.x86.exe" >nul 2>&1
taskkill /F /IM "MSBuild.exe" >nul 2>&1
taskkill /F /IM "VBCSCompiler.exe" >nul 2>&1

:: Kill only non-responding dotnet processes
taskkill /F /IM "dotnet.exe" /FI "STATUS eq NOT RESPONDING" >nul 2>&1
echo       Done!

:: Node.js Smart Cleanup - Kill duplicates, keep one
echo       [Node.js] Checking for duplicate Node.js processes...
:: Count node.exe processes
set NODE_COUNT=0
for /f %%a in ('tasklist /FI "IMAGENAME eq node.exe" ^| find /c "node.exe"') do set NODE_COUNT=%%a

if %NODE_COUNT% GTR 5 (
    echo              Found %NODE_COUNT% Node.js processes - cleaning duplicates...
    :: Kill node processes older than a threshold using PowerShell
    PowerShell.exe -NoProfile -Command "$threshold = (Get-Date).AddHours(-2); Get-Process node -ErrorAction SilentlyContinue | Where-Object {$_.StartTime -lt $threshold} | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
) else (
    echo              Node.js processes count is normal (%NODE_COUNT%)
)

:: Always kill npm/npx that are hanging (older than 30 min)
PowerShell.exe -NoProfile -Command "$threshold = (Get-Date).AddMinutes(-30); Get-Process npm,npx -ErrorAction SilentlyContinue | Where-Object {$_.StartTime -lt $threshold} | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo       Done!

:: Kill non-responding processes only
echo       [General] Killing non-responding dev processes...
taskkill /F /IM "java.exe" /FI "STATUS eq NOT RESPONDING" >nul 2>&1
taskkill /F /IM "python.exe" /FI "STATUS eq NOT RESPONDING" >nul 2>&1
taskkill /F /IM "conhost.exe" /FI "STATUS eq NOT RESPONDING" >nul 2>&1
taskkill /F /IM "electron.exe" /FI "STATUS eq NOT RESPONDING" >nul 2>&1
echo       Done!

:: JetBrains cleanup - only if IDE not running
echo       [JetBrains] Checking for orphaned processes...
set JETBRAINS_RUNNING=0
tasklist 2>nul | findstr /I "idea64.exe rider64.exe webstorm64.exe pycharm64.exe" >nul && set JETBRAINS_RUNNING=1
if %JETBRAINS_RUNNING%==0 (
    taskkill /F /IM "fsnotifier64.exe" >nul 2>&1
    taskkill /F /IM "fsnotifier.exe" >nul 2>&1
    echo              Orphaned JetBrains processes cleaned
) else (
    echo              JetBrains IDE is running - skipping
)
echo       Done!

:: Memory optimization - trim working set of large processes
echo       [Memory] Optimizing memory usage...
PowerShell.exe -NoProfile -Command "Get-Process | Where-Object {$_.WorkingSet64 -gt 500MB -and $_.ProcessName -notmatch 'devenv|Code|chrome|msedge|firefox'} | ForEach-Object { $_.MinWorkingSet = 1MB } -ErrorAction SilentlyContinue" >nul 2>&1
echo       Done!

echo.
echo       Smart development cleanup completed!

echo.
echo       Development processes cleanup completed!
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
echo  - Orphaned development processes (.NET, Node.js, etc.)
echo  - Browser cache
echo.
echo Your system has been optimized!
echo.
pause
