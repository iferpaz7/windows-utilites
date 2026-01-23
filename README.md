# Windows Utilities

A collection of powerful Windows maintenance and optimization scripts for system cleanup, health monitoring, and performance analysis.

---

## 📁 Scripts Included

| Script | Description |
|--------|-------------|
| `WindowsCleanup.bat` | System cleanup utility to remove temporary files and optimize performance |
| `PCHealthCheck.bat` | **NEW!** PC health analyzer launcher (double-click to run) |
| `PCHealthCheck.ps1` | PowerShell script for comprehensive health analysis |

---

# 🧹 Windows Cleanup Utility

A comprehensive Windows cleanup batch script similar to Windows PC Manager that removes unnecessary files and optimizes system performance.

## 🚀 Features

This utility cleans the following system areas:

- **Windows Temp Files** - Removes temporary system files
- **User Temp Files** - Cleans user-specific temporary data
- **Prefetch Data** - Clears application prefetch cache
- **Windows Update Cache** - Removes downloaded update files
- **DNS Cache** - Flushes DNS resolver cache
- **Thumbnail Cache** - Clears thumbnail database
- **Error Reports** - Removes Windows Error Reporting files
- **Recent Files** - Clears recent documents history
- **Recycle Bin** - Empties the recycle bin completely
- **Delivery Optimization** - Cleans Windows Update delivery cache
- **Log Files** - Removes old system log files
- **Browser Cache** - Clears Internet Explorer/Edge cache

## 📋 Requirements

- Windows 7/8/10/11
- Administrator privileges (required)

## 🔧 How to Use

1. **Download** the `WindowsCleanup.bat` file
2. **Right-click** on the file
3. Select **"Run as administrator"**
4. Wait for the cleanup process to complete
5. Press any key to close the window

## ⚠️ Important Notes

- **Administrator rights are mandatory** - The script will not run without elevated privileges
- **Safe to use** - Only removes temporary and cache files, not personal data or system files
- **Disk space display** - Shows before/after free space on C: drive
- **Progress tracking** - Displays real-time progress for each cleanup step

## 📊 What You'll See

```
============================================
    Windows Cleanup Utility
    Optimizing System Performance
============================================

Starting cleanup process...

[INFO] Checking disk space before cleanup...
Before: XXXXXXXXX bytes free on C:

[1/12] Cleaning Windows Temp folder...
      Done!
[2/12] Cleaning User Temp folder...
      Done!
...
```

## 🛡️ Safety

This script is **safe** and only removes:
- Temporary files that Windows can regenerate
- Cache files that improve load times but aren't essential
- Files that are safe to delete according to Microsoft guidelines

It does **NOT** delete:
- Personal files or documents
- Installed programs
- System files required for Windows operation
- User settings or configurations

## 💡 When to Use

Run this utility when:
- Your system feels sluggish
- You're running low on disk space
- You want to perform routine maintenance
- After major Windows updates
- Before installing new software

## 🤝 Contributing

Feel free to suggest improvements or report issues!

---

# 🔍 PC Health Check & Performance Analyzer

A powerful PowerShell script that provides comprehensive system diagnostics, detects resource-heavy processes, identifies CPU blockers, and offers optimization recommendations.

## 🚀 Features

### System Analysis
- **System Information** - OS version, CPU, RAM, uptime, boot time
- **CPU Analysis** - Real-time CPU usage sampling, processor queue length monitoring
- **Memory Analysis** - RAM usage, available memory, page file status, committed memory
- **Disk Analysis** - Storage usage per drive, disk I/O queue length detection

### Process Monitoring
- **Top CPU Processes** - Identifies processes consuming the most CPU
- **Top Memory Processes** - Lists memory-heavy applications
- **Blocked Process Detection** - Finds hung/not responding processes
- **Interactive Process Management** - Option to terminate problematic processes

### System Health
- **Startup Programs** - Lists all auto-start applications
- **Services Status** - Checks for failed or problematic services
- **Network Status** - Adapter info, connectivity test, latency measurement
- **Windows Updates** - Pending update count
- **Event Log Errors** - Critical system errors in last 24 hours
- **Battery Status** - For laptops

### Smart Recommendations
- Provides actionable recommendations based on analysis results
- Identifies bottlenecks and performance issues
- Suggests maintenance tasks

## 📋 Requirements

- Windows 10/11
- PowerShell 5.1 or higher
- **Administrator privileges (required)**

## 🔧 How to Use

### Method 1: Double-Click (Recommended) ⭐
1. **Double-click** on `PCHealthCheck.bat`
2. Accept the UAC prompt for Administrator privileges
3. The analysis will start automatically!

> This is the easiest method - no configuration needed!

### Method 2: PowerShell Terminal
```powershell
# Navigate to the script location
cd "path\to\windows-utilities"

# Run the script (as Administrator)
.\PCHealthCheck.ps1
```

### Method 3: Bypass Execution Policy (one-time)
```powershell
powershell -ExecutionPolicy Bypass -File ".\PCHealthCheck.ps1"
```

## 📊 Sample Output

```
╔═══════════════════════════════════════════════════════════════════════╗
║               PC HEALTH CHECK & PERFORMANCE ANALYZER                  ║
╚═══════════════════════════════════════════════════════════════════════╝

======================================================================
  SYSTEM INFORMATION
======================================================================
  Computer Name: MY-PC
  Operating System: Windows 11 Pro 64-bit
  Processor: Intel Core i7-10700 @ 2.90GHz
  Cores/Threads: 8 Cores / 16 Threads
  Total RAM: 32.00 GB

======================================================================
  CPU ANALYSIS
======================================================================
  Average CPU Usage: 23.5%
  Processor Queue Length: 0

======================================================================
  TOP CPU-CONSUMING PROCESSES
======================================================================
  PID   Name           CPU%   Memory     Handles  Threads
  ---   ----           ----   ------     -------  -------
  1234  chrome         15.2   1.25 GB    1500     45
  5678  vscode         8.3    650 MB     890      32
  ...
```

## 🛡️ Security Features

- **Read-only analysis** - Does not modify system files
- **Safe process termination** - Only user processes can be terminated (system processes protected)
- **No external connections** - All analysis is local (except connectivity test to 8.8.8.8)
- **Export reports** - Save results to text file for review

## 💡 When to Use

Run this utility when:
- Your PC feels slow or unresponsive
- You want to identify which programs are using resources
- CPU or memory usage seems unusually high
- Applications are freezing or not responding
- Before and after running cleanup utilities
- Regular system health monitoring

## ⚠️ Important Notes

- Some features require Administrator privileges
- CPU sampling takes a few seconds for accurate readings
- Process CPU percentages are calculated over a 2-second sample
- Terminating system processes may cause instability

---

## 🤝 Contributing

Feel free to suggest improvements or report issues!

## 📝 License

Free to use and modify for personal and commercial purposes.

---

**Created with ❤️ for Windows optimization**
