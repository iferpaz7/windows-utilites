<#
.SYNOPSIS
    PC Health Check & Performance Optimizer
.DESCRIPTION
    Comprehensive script to analyze PC health, detect resource-heavy processes,
    identify CPU blockers, and provide optimization recommendations.
.NOTES
    Author: Windows Utilities
    Version: 1.0
    Requires: PowerShell 5.1+ and Administrator privileges
#>

# ============================================================================
# AUTO-ELEVATION TO ADMINISTRATOR
# ============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    
    # Build the argument list to relaunch this script
    $scriptPath = $MyInvocation.MyCommand.Definition
    
    # Create a new process with elevation
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $processInfo.Verb = "runas"  # This triggers the UAC elevation prompt
    $processInfo.UseShellExecute = $true
    
    try {
        [System.Diagnostics.Process]::Start($processInfo) | Out-Null
    } catch {
        Write-Host "ERROR: Failed to elevate to Administrator. Please run this script as Administrator." -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Exit the current non-elevated process
    exit
}

# ============================================================================
# CONFIGURATION
# ============================================================================
$Config = @{
    CPUThresholdHigh = 80        # CPU usage % considered high
    CPUThresholdCritical = 95    # CPU usage % considered critical
    MemoryThresholdHigh = 80     # Memory usage % considered high
    DiskThresholdHigh = 90       # Disk usage % considered high
    TopProcessCount = 15         # Number of top processes to show
    SampleDurationSeconds = 3    # Duration to sample CPU usage
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Header {
    param([string]$Title)
    $line = "=" * 70
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "$line" -ForegroundColor Cyan
}

function Write-Status {
    param(
        [string]$Label,
        [string]$Value,
        [string]$Status = "Normal"
    )
    $color = switch ($Status) {
        "Good"     { "Green" }
        "Normal"   { "White" }
        "Warning"  { "Yellow" }
        "Critical" { "Red" }
        default    { "White" }
    }
    Write-Host "  $Label" -NoNewline -ForegroundColor Gray
    Write-Host " $Value" -ForegroundColor $color
}

function Get-FormattedSize {
    param([long]$Bytes)
    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes Bytes"
}

# ============================================================================
# SYSTEM INFORMATION
# ============================================================================
function Get-SystemInfo {
    Write-Header "SYSTEM INFORMATION"
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    $cpu = Get-CimInstance Win32_Processor
    $bios = Get-CimInstance Win32_BIOS
    
    Write-Status "Computer Name:" $env:COMPUTERNAME
    Write-Status "Operating System:" "$($os.Caption) $($os.OSArchitecture)"
    Write-Status "OS Version:" $os.Version
    Write-Status "Processor:" $cpu.Name
    Write-Status "Cores/Threads:" "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
    Write-Status "Total RAM:" (Get-FormattedSize ($cs.TotalPhysicalMemory))
    Write-Status "System Uptime:" "$([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)) hours"
    Write-Status "Last Boot:" $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
}

# ============================================================================
# CPU ANALYSIS
# ============================================================================
function Get-CPUAnalysis {
    Write-Header "CPU ANALYSIS"
    
    Write-Host "  Sampling CPU usage for $($Config.SampleDurationSeconds) seconds..." -ForegroundColor Yellow
    
    # Get CPU usage over time
    $cpuSamples = @()
    for ($i = 0; $i -lt $Config.SampleDurationSeconds; $i++) {
        $cpuSamples += (Get-CimInstance Win32_Processor).LoadPercentage
        Start-Sleep -Seconds 1
    }
    $avgCPU = [math]::Round(($cpuSamples | Measure-Object -Average).Average, 1)
    
    $cpuStatus = if ($avgCPU -ge $Config.CPUThresholdCritical) { "Critical" }
                 elseif ($avgCPU -ge $Config.CPUThresholdHigh) { "Warning" }
                 elseif ($avgCPU -le 30) { "Good" }
                 else { "Normal" }
    
    Write-Status "Average CPU Usage:" "$avgCPU%" $cpuStatus
    
    # CPU Queue Length (indicates CPU bottleneck)
    $perfData = Get-CimInstance Win32_PerfFormattedData_PerfOS_System
    $queueLength = $perfData.ProcessorQueueLength
    $queueStatus = if ($queueLength -gt 10) { "Critical" }
                   elseif ($queueLength -gt 5) { "Warning" }
                   else { "Good" }
    
    Write-Status "Processor Queue Length:" $queueLength $queueStatus
    
    if ($queueLength -gt 5) {
        Write-Host "`n  [!] High processor queue indicates CPU bottleneck!" -ForegroundColor Red
    }
    
    return @{ CPUUsage = $avgCPU; QueueLength = $queueLength }
}

# ============================================================================
# MEMORY ANALYSIS
# ============================================================================
function Get-MemoryAnalysis {
    Write-Header "MEMORY ANALYSIS"
    
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMem = $os.TotalVisibleMemorySize * 1KB
    $freeMem = $os.FreePhysicalMemory * 1KB
    $usedMem = $totalMem - $freeMem
    $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
    
    $memStatus = if ($memPercent -ge 95) { "Critical" }
                 elseif ($memPercent -ge $Config.MemoryThresholdHigh) { "Warning" }
                 elseif ($memPercent -le 50) { "Good" }
                 else { "Normal" }
    
    Write-Status "Memory Usage:" "$memPercent% ($(Get-FormattedSize $usedMem) / $(Get-FormattedSize $totalMem))" $memStatus
    Write-Status "Available Memory:" (Get-FormattedSize $freeMem) $(if ($freeMem -lt 1GB) { "Warning" } else { "Good" })
    
    # Check for memory pressure
    $pageFile = Get-CimInstance Win32_PageFileUsage | Select-Object -First 1
    if ($pageFile) {
        $pagePercent = [math]::Round(($pageFile.CurrentUsage / $pageFile.AllocatedBaseSize) * 100, 1)
        $pageStatus = if ($pagePercent -ge 80) { "Warning" } else { "Normal" }
        Write-Status "Page File Usage:" "$pagePercent%" $pageStatus
    }
    
    # Committed memory
    $perfMem = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
    Write-Status "Committed Memory:" (Get-FormattedSize ($perfMem.CommittedBytes))
    Write-Status "Cache Bytes:" (Get-FormattedSize ($perfMem.CacheBytes))
    
    return @{ MemoryPercent = $memPercent; FreeMem = $freeMem }
}

# ============================================================================
# DISK ANALYSIS
# ============================================================================
function Get-DiskAnalysis {
    Write-Header "DISK ANALYSIS"
    
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($disk in $disks) {
        $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
        $diskStatus = if ($usedPercent -ge 95) { "Critical" }
                      elseif ($usedPercent -ge $Config.DiskThresholdHigh) { "Warning" }
                      elseif ($usedPercent -le 50) { "Good" }
                      else { "Normal" }
        
        Write-Status "Drive $($disk.DeviceID)" "$usedPercent% used ($(Get-FormattedSize $disk.FreeSpace) free of $(Get-FormattedSize $disk.Size))" $diskStatus
    }
    
    # Disk Queue Length (indicates disk bottleneck)
    $diskPerf = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk | 
                Where-Object { $_.Name -eq "_Total" }
    
    if ($diskPerf) {
        $diskQueue = $diskPerf.CurrentDiskQueueLength
        $diskQueueStatus = if ($diskQueue -gt 5) { "Critical" }
                           elseif ($diskQueue -gt 2) { "Warning" }
                           else { "Good" }
        Write-Status "Disk Queue Length:" $diskQueue $diskQueueStatus
        
        if ($diskQueue -gt 2) {
            Write-Host "`n  [!] High disk queue may indicate I/O bottleneck!" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# TOP RESOURCE-CONSUMING PROCESSES
# ============================================================================
function Get-TopProcesses {
    Write-Header "TOP CPU-CONSUMING PROCESSES"
    
    Write-Host "  Analyzing process CPU usage..." -ForegroundColor Yellow
    
    # Sample processes twice to calculate CPU percentage
    $first = Get-Process | Where-Object { $_.Id -ne 0 } | 
             Select-Object Id, ProcessName, @{N='CPU';E={$_.CPU}}
    
    Start-Sleep -Seconds 2
    
    $second = Get-Process | Where-Object { $_.Id -ne 0 } | 
              Select-Object Id, ProcessName, @{N='CPU';E={$_.CPU}}, WorkingSet64, Handles, Threads
    
    $cpuCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    
    $processes = foreach ($proc in $second) {
        $firstProc = $first | Where-Object { $_.Id -eq $proc.Id }
        if ($firstProc) {
            $cpuDiff = $proc.CPU - $firstProc.CPU
            $cpuPercent = [math]::Round(($cpuDiff / 2 / $cpuCount) * 100, 2)
            
            [PSCustomObject]@{
                PID = $proc.Id
                Name = $proc.ProcessName
                'CPU%' = $cpuPercent
                Memory = Get-FormattedSize $proc.WorkingSet64
                MemoryBytes = $proc.WorkingSet64
                Handles = $proc.Handles
                Threads = $proc.Threads.Count
            }
        }
    }
    
    $topCPU = $processes | Sort-Object 'CPU%' -Descending | Select-Object -First $Config.TopProcessCount
    
    Write-Host ""
    $topCPU | Format-Table -AutoSize PID, Name, 'CPU%', Memory, Handles, Threads | Out-String | Write-Host
    
    # Identify problematic processes
    $highCPU = $topCPU | Where-Object { $_.'CPU%' -gt 25 }
    if ($highCPU) {
        Write-Host "  [!] HIGH CPU PROCESSES DETECTED:" -ForegroundColor Red
        foreach ($proc in $highCPU) {
            Write-Host "      - $($proc.Name) (PID: $($proc.PID)) using $($_.'CPU%')% CPU" -ForegroundColor Yellow
        }
    }
    
    return $topCPU
}

function Get-TopMemoryProcesses {
    Write-Header "TOP MEMORY-CONSUMING PROCESSES"
    
    $processes = Get-Process | Where-Object { $_.Id -ne 0 } |
                 Sort-Object WorkingSet64 -Descending |
                 Select-Object -First $Config.TopProcessCount |
                 Select-Object Id, ProcessName, 
                               @{N='Memory';E={Get-FormattedSize $_.WorkingSet64}},
                               @{N='MemoryMB';E={[math]::Round($_.WorkingSet64/1MB,1)}},
                               Handles,
                               @{N='Threads';E={$_.Threads.Count}}
    
    $processes | Format-Table -AutoSize Id, ProcessName, Memory, Handles, Threads | Out-String | Write-Host
    
    # Identify memory hogs (>1GB)
    $memHogs = $processes | Where-Object { $_.MemoryMB -gt 1024 }
    if ($memHogs) {
        Write-Host "  [!] HIGH MEMORY PROCESSES (>1GB):" -ForegroundColor Yellow
        foreach ($proc in $memHogs) {
            Write-Host "      - $($proc.ProcessName) (PID: $($proc.Id)) using $($proc.Memory)" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# BLOCKED/HUNG PROCESSES DETECTION
# ============================================================================
function Get-BlockedProcesses {
    Write-Header "BLOCKED/NOT RESPONDING PROCESSES"
    
    $notResponding = Get-Process | Where-Object { $_.Responding -eq $false }
    
    if ($notResponding) {
        Write-Host "  [!] THE FOLLOWING PROCESSES ARE NOT RESPONDING:" -ForegroundColor Red
        foreach ($proc in $notResponding) {
            Write-Host "      - $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Red
        }
        return $notResponding
    } else {
        Write-Host "  [OK] All processes are responding normally." -ForegroundColor Green
        return $null
    }
}

# ============================================================================
# STARTUP PROGRAMS ANALYSIS
# ============================================================================
function Get-StartupPrograms {
    Write-Header "STARTUP PROGRAMS ANALYSIS"
    
    $startupItems = @()
    
    # Registry Run keys
    $runKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    
    foreach ($key in $runKeys) {
        if (Test-Path $key) {
            $items = Get-ItemProperty $key -ErrorAction SilentlyContinue
            $items.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" } | ForEach-Object {
                $startupItems += [PSCustomObject]@{
                    Name = $_.Name
                    Command = $_.Value
                    Location = $key
                }
            }
        }
    }
    
    # Startup folder
    $startupFolder = [Environment]::GetFolderPath('Startup')
    if (Test-Path $startupFolder) {
        Get-ChildItem $startupFolder -File | ForEach-Object {
            $startupItems += [PSCustomObject]@{
                Name = $_.Name
                Command = $_.FullName
                Location = "Startup Folder"
            }
        }
    }
    
    Write-Host "  Found $($startupItems.Count) startup items:" -ForegroundColor Yellow
    $startupItems | Select-Object Name, Location | Format-Table -AutoSize | Out-String | Write-Host
    
    if ($startupItems.Count -gt 10) {
        Write-Host "  [!] Many startup programs can slow down boot time." -ForegroundColor Yellow
        Write-Host "      Consider disabling unnecessary items via Task Manager > Startup." -ForegroundColor Gray
    }
}

# ============================================================================
# SERVICES ANALYSIS
# ============================================================================
function Get-ProblematicServices {
    Write-Header "SERVICES STATUS"
    
    # Services that failed to start
    $failedServices = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
    
    if ($failedServices) {
        Write-Host "  [!] AUTO-START SERVICES NOT RUNNING:" -ForegroundColor Yellow
        $failedServices | Select-Object Name, DisplayName, Status | 
                         Format-Table -AutoSize | Out-String | Write-Host
    } else {
        Write-Host "  [OK] All automatic services are running." -ForegroundColor Green
    }
    
    # High-impact services that are disabled
    $criticalServices = @('wuauserv', 'BITS', 'Winmgmt', 'Schedule', 'EventLog')
    $disabledCritical = Get-Service | Where-Object { $_.Name -in $criticalServices -and $_.StartType -eq 'Disabled' }
    
    if ($disabledCritical) {
        Write-Host "`n  [!] CRITICAL SERVICES DISABLED:" -ForegroundColor Red
        $disabledCritical | Select-Object Name, DisplayName | 
                           Format-Table -AutoSize | Out-String | Write-Host
    }
}

# ============================================================================
# NETWORK ANALYSIS
# ============================================================================
function Get-NetworkStatus {
    Write-Header "NETWORK STATUS"
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    
    foreach ($adapter in $adapters) {
        Write-Status "Adapter:" $adapter.Name "Good"
        Write-Status "  Speed:" "$($adapter.LinkSpeed)"
        
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ipConfig) {
            Write-Status "  IP Address:" $ipConfig.IPAddress
        }
    }
    
    # Test internet connectivity
    Write-Host "`n  Testing internet connectivity..." -ForegroundColor Yellow
    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction SilentlyContinue
    
    if ($pingResult) {
        # Handle both PowerShell 5.x (ResponseTime) and PowerShell 7.x (Latency)
        $latencyProp = if ($pingResult[0].PSObject.Properties['Latency']) { 'Latency' } else { 'ResponseTime' }
        $avgLatency = [math]::Round(($pingResult | Measure-Object -Property $latencyProp -Average).Average, 1)
        $latencyStatus = if ($avgLatency -gt 100) { "Warning" } elseif ($avgLatency -gt 50) { "Normal" } else { "Good" }
        Write-Status "Internet:" "Connected (Latency: ${avgLatency}ms)" $latencyStatus
    } else {
        Write-Status "Internet:" "Not Connected or Blocked" "Critical"
    }
}

# ============================================================================
# TEMPERATURE & HEALTH (if available)
# ============================================================================
function Get-SystemHealth {
    Write-Header "SYSTEM HEALTH"
    
    # Battery status (for laptops)
    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $batteryStatus = switch ($battery.BatteryStatus) {
            1 { "Discharging" }
            2 { "AC Power" }
            3 { "Fully Charged" }
            4 { "Low" }
            5 { "Critical" }
            default { "Unknown" }
        }
        $battColor = if ($battery.EstimatedChargeRemaining -lt 20) { "Warning" } else { "Good" }
        Write-Status "Battery:" "$($battery.EstimatedChargeRemaining)% - $batteryStatus" $battColor
    }
    
    # Check Windows Update status
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $pendingUpdates = $updateSearcher.Search("IsInstalled=0").Updates.Count
        
        $updateStatus = if ($pendingUpdates -gt 10) { "Warning" } 
                       elseif ($pendingUpdates -gt 0) { "Normal" } 
                       else { "Good" }
        Write-Status "Pending Updates:" $pendingUpdates $updateStatus
    } catch {
        Write-Status "Pending Updates:" "Unable to check" "Normal"
    }
    
    # Event Log Errors (last 24 hours)
    $yesterday = (Get-Date).AddDays(-1)
    $criticalEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Level = 1,2  # Critical, Error
        StartTime = $yesterday
    } -MaxEvents 50 -ErrorAction SilentlyContinue
    
    $eventStatus = if ($criticalEvents.Count -gt 20) { "Warning" } 
                   elseif ($criticalEvents.Count -gt 0) { "Normal" } 
                   else { "Good" }
    Write-Status "System Errors (24h):" $criticalEvents.Count $eventStatus
}

# ============================================================================
# RECOMMENDATIONS
# ============================================================================
function Get-Recommendations {
    param(
        $CPUData,
        $MemoryData,
        $BlockedProcesses,
        $TopProcesses
    )
    
    Write-Header "RECOMMENDATIONS"
    
    $recommendations = @()
    
    # CPU recommendations
    if ($CPUData.CPUUsage -ge $Config.CPUThresholdHigh) {
        $recommendations += "[CPU] High CPU usage detected. Consider closing resource-heavy applications."
    }
    if ($CPUData.QueueLength -gt 5) {
        $recommendations += "[CPU] High processor queue. System may need more CPU cores or workload reduction."
    }
    
    # Memory recommendations
    if ($MemoryData.MemoryPercent -ge $Config.MemoryThresholdHigh) {
        $recommendations += "[MEMORY] High memory usage. Consider closing unused applications or adding more RAM."
    }
    if ($MemoryData.FreeMem -lt 1GB) {
        $recommendations += "[MEMORY] Very low free memory. Close applications or restart the system."
    }
    
    # Blocked processes
    if ($BlockedProcesses) {
        $recommendations += "[PROCESSES] Found not responding processes. Consider terminating them."
    }
    
    # High CPU processes
    $highCPU = $TopProcesses | Where-Object { $_.'CPU%' -gt 50 }
    if ($highCPU) {
        foreach ($proc in $highCPU) {
            $recommendations += "[PROCESS] $($proc.Name) is using $($_.'CPU%')% CPU. Consider investigating or restarting it."
        }
    }
    
    # General recommendations
    $recommendations += "[MAINTENANCE] Run Disk Cleanup to free up space: cleanmgr"
    $recommendations += "[MAINTENANCE] Run SFC to check system files: sfc /scannow"
    $recommendations += "[MAINTENANCE] Check for Windows Updates regularly"
    
    if ($recommendations.Count -eq 0) {
        Write-Host "  [OK] System appears to be running well. No critical issues found." -ForegroundColor Green
    } else {
        $i = 1
        foreach ($rec in $recommendations) {
            $color = if ($rec -match "^\[CPU\]|^\[MEMORY\]|^\[PROCESS\]") { "Yellow" } else { "Gray" }
            Write-Host "  $i. $rec" -ForegroundColor $color
            $i++
        }
    }
}

# ============================================================================
# OPTIONAL: KILL HIGH CPU PROCESS
# ============================================================================
function Stop-HighCPUProcess {
    param($TopProcesses)
    
    Write-Header "PROCESS MANAGEMENT"
    
    $highCPU = $TopProcesses | Where-Object { $_.'CPU%' -gt 50 -and $_.Name -notin @('System', 'Idle', 'svchost', 'csrss', 'wininit', 'services') }
    
    if (-not $highCPU) {
        Write-Host "  No user processes with extremely high CPU usage found." -ForegroundColor Green
        return
    }
    
    Write-Host "  High CPU processes that can be terminated:" -ForegroundColor Yellow
    $highCPU | Format-Table PID, Name, 'CPU%' -AutoSize | Out-String | Write-Host
    
    $response = Read-Host "  Would you like to terminate any of these processes? (Enter PID or 'N' to skip)"
    
    if ($response -match '^\d+$') {
        $procToKill = Get-Process -Id $response -ErrorAction SilentlyContinue
        if ($procToKill) {
            try {
                Stop-Process -Id $response -Force -ErrorAction Stop
                Write-Host "  [OK] Process $($procToKill.ProcessName) (PID: $response) terminated." -ForegroundColor Green
            } catch {
                Write-Host "  [ERROR] Failed to terminate process: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  [ERROR] Process with PID $response not found." -ForegroundColor Red
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
function Start-PCHealthCheck {
    Clear-Host
    Write-Host @"
    
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║               PC HEALTH CHECK & PERFORMANCE ANALYZER                  ║
    ║                        Windows Utilities v1.0                         ║
    ╚═══════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    Write-Host "  Starting comprehensive system analysis..." -ForegroundColor White
    Write-Host "  Please wait while data is being collected...`n" -ForegroundColor Gray
    
    # Run all analyses
    Get-SystemInfo
    $cpuData = Get-CPUAnalysis
    $memData = Get-MemoryAnalysis
    Get-DiskAnalysis
    $topProcs = Get-TopProcesses
    Get-TopMemoryProcesses
    $blocked = Get-BlockedProcesses
    Get-StartupPrograms
    Get-ProblematicServices
    Get-NetworkStatus
    Get-SystemHealth
    Get-Recommendations -CPUData $cpuData -MemoryData $memData -BlockedProcesses $blocked -TopProcesses $topProcs
    
    # Interactive process management
    Write-Host ""
    $manageProcs = Read-Host "Would you like to manage high-CPU processes? (Y/N)"
    if ($manageProcs -eq 'Y' -or $manageProcs -eq 'y') {
        Stop-HighCPUProcess -TopProcesses $topProcs
    }
    
    Write-Header "ANALYSIS COMPLETE"
    Write-Host "  Report generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "  Run this script regularly to monitor system health.`n" -ForegroundColor Gray
    
    # Export option
    $export = Read-Host "Would you like to export this report to a file? (Y/N)"
    if ($export -eq 'Y' -or $export -eq 'y') {
        $reportPath = "$env:USERPROFILE\Desktop\PCHealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        # Re-run with transcript
        Start-Transcript -Path $reportPath -Force
        Get-SystemInfo
        Get-CPUAnalysis | Out-Null
        Get-MemoryAnalysis | Out-Null
        Get-DiskAnalysis
        Get-TopProcesses | Out-Null
        Get-TopMemoryProcesses
        Get-BlockedProcesses | Out-Null
        Get-StartupPrograms
        Get-ProblematicServices
        Get-NetworkStatus
        Get-SystemHealth
        Stop-Transcript
        Write-Host "`n  Report exported to: $reportPath" -ForegroundColor Green
    }
}

# Run the health check
Start-PCHealthCheck
