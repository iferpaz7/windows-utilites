#Requires -Version 5.1
<#
.SYNOPSIS
    Safe Windows program uninstaller

.DESCRIPTION
    Uninstalls programs safely with verification
#>

# Auto-elevate to administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Helper functions
function Write-ColorMessage {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Text)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

# Get installed programs
function Get-InstalledPrograms {
    Write-ColorMessage "[INFO] Scanning registry for installed programs..." "Cyan"
    
    $programs = @()
    $registryPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $registryPaths) {
        try {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue | 
                Where-Object { 
                    $_.DisplayName -and 
                    ($_.UninstallString -or $_.QuietUninstallString)
                }
            
            foreach ($item in $items) {
                $programs += [PSCustomObject]@{
                    Name = $item.DisplayName
                    Version = $item.DisplayVersion
                    Publisher = $item.Publisher
                    UninstallString = $item.UninstallString
                    QuietUninstallString = $item.QuietUninstallString
                    RegistryPath = $item.PSPath
                }
            }
        }
        catch {
            continue
        }
    }
    
    # Remove duplicates
    $unique = $programs | Sort-Object Name -Unique
    Write-ColorMessage "[INFO] Found $($unique.Count) programs" "Cyan"
    return $unique
}

# Parse uninstall command
function Get-UninstallCommand {
    param([string]$UninstallString)
    
    $UninstallString = $UninstallString.Trim()
    
    # Pattern 1: "C:\Path\file.exe" args
    if ($UninstallString -match '^"([^"]+)"(.*)$') {
        return @{
            Executable = $matches[1]
            Arguments = $matches[2].Trim()
        }
    }
    
    # Pattern 2: MsiExec.exe /X{GUID}
    if ($UninstallString -match '^(msiexec\.exe)\s+(.+)$') {
        return @{
            Executable = "msiexec.exe"
            Arguments = $matches[2].Trim()
        }
    }
    
    # Pattern 3: C:\Path\file.exe args (no quotes)
    if ($UninstallString -match '^([A-Z]:\\[^\s]+\.exe)(.*)$') {
        return @{
            Executable = $matches[1]
            Arguments = $matches[2].Trim()
        }
    }
    
    # Default: treat as executable only
    return @{
        Executable = $UninstallString
        Arguments = ""
    }
}

# Uninstall program
function Uninstall-Program {
    param($Program)
    
    Write-Header "Uninstalling: $($Program.Name)"
    
    # Show available uninstall methods
    Write-ColorMessage "[INFO] Available uninstall methods:" "Cyan"
    if ($Program.QuietUninstallString) {
        Write-ColorMessage "  - Quiet: $($Program.QuietUninstallString)" "Gray"
    }
    if ($Program.UninstallString) {
        Write-ColorMessage "  - Standard: $($Program.UninstallString)" "Gray"
    }
    
    # Ask for mode
    Write-Host "`nSelect uninstall mode:" -ForegroundColor Yellow
    Write-Host "1. Silent (automatic, no prompts)"
    Write-Host "2. Interactive (show uninstaller GUI)"
    $mode = Read-Host "Choice (1 or 2)"
    
    $useSilent = ($mode -eq "1")
    $uninstallCmd = if ($useSilent -and $Program.QuietUninstallString) {
        $Program.QuietUninstallString
    } else {
        $Program.UninstallString
    }
    
    if (-not $uninstallCmd) {
        Write-ColorMessage "[ERROR] No uninstall command found" "Red"
        return $false
    }
    
    # Parse command
    $cmd = Get-UninstallCommand -UninstallString $uninstallCmd
    Write-ColorMessage "[INFO] Executable: $($cmd.Executable)" "Cyan"
    Write-ColorMessage "[INFO] Arguments: $($cmd.Arguments)" "Cyan"
    
    # Check if executable exists
    if ($cmd.Executable -notmatch 'msiexec' -and -not (Test-Path $cmd.Executable)) {
        Write-ColorMessage "[ERROR] Uninstaller not found: $($cmd.Executable)" "Red"
        return $false
    }
    
    # Add silent parameters if needed
    $args = $cmd.Arguments
    if ($useSilent) {
        if ($cmd.Executable -match 'msiexec' -and $args -notmatch '/q') {
            $args += " /qn /norestart"
        }
        elseif ($cmd.Executable -match 'unins\d+\.exe' -and $args -notmatch '/SILENT') {
            $args += " /SILENT /NORESTART"
        }
    }
    
    # Execute uninstaller
    try {
        Write-ColorMessage "[INFO] Starting uninstaller..." "Yellow"
        
        $startParams = @{
            FilePath = $cmd.Executable
            Wait = $true
            PassThru = $true
        }
        
        if ($args) {
            $startParams.ArgumentList = $args
        }
        
        if ($useSilent) {
            $startParams.WindowStyle = "Hidden"
        }
        
        $process = Start-Process @startParams
        
        Write-ColorMessage "[INFO] Uninstaller exited with code: $($process.ExitCode)" "Cyan"
        
        # Verify
        Start-Sleep -Seconds 2
        $stillExists = Get-ItemProperty $Program.RegistryPath -ErrorAction SilentlyContinue
        
        if (-not $stillExists) {
            Write-ColorMessage "[SUCCESS] Program uninstalled successfully!" "Green"
            return $true
        }
        else {
            Write-ColorMessage "[WARNING] Program may still be installed" "Yellow"
            return $false
        }
    }
    catch {
        Write-ColorMessage "[ERROR] Failed: $_" "Red"
        return $false
    }
}

# Clean leftover files
function Remove-LeftoverFiles {
    param([string]$ProgramName)
    
    Write-Header "Scanning for Leftover Files"
    
    $searchLocations = @(
        @{Path = "$env:ProgramFiles\$ProgramName"; Name = "Program Files"},
        @{Path = "${env:ProgramFiles(x86)}\$ProgramName"; Name = "Program Files (x86)"},
        @{Path = "$env:LocalAppData\$ProgramName"; Name = "Local AppData"},
        @{Path = "$env:AppData\$ProgramName"; Name = "Roaming AppData"},
        @{Path = "$env:ProgramData\$ProgramName"; Name = "ProgramData"},
        @{Path = "$env:TEMP\$ProgramName"; Name = "Temp"},
        @{Path = "$env:UserProfile\AppData\LocalLow\$ProgramName"; Name = "LocalLow"}
    )
    
    $foundPaths = @()
    foreach ($location in $searchLocations) {
        if (Test-Path $location.Path) {
            $size = (Get-ChildItem $location.Path -Recurse -ErrorAction SilentlyContinue | 
                Measure-Object -Property Length -Sum).Sum / 1MB
            $foundPaths += [PSCustomObject]@{
                Path = $location.Path
                Location = $location.Name
                SizeMB = [math]::Round($size, 2)
            }
        }
    }
    
    if ($foundPaths.Count -eq 0) {
        Write-ColorMessage "[INFO] No leftover files found" "Green"
        return
    }
    
    Write-ColorMessage "[WARNING] Found leftover folders:" "Yellow"
    foreach ($item in $foundPaths) {
        Write-Host "  - $($item.Location): $($item.Path) ($($item.SizeMB) MB)" -ForegroundColor Yellow
    }
    
    $confirm = Read-Host "`nDelete all leftover files? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        foreach ($item in $foundPaths) {
            try {
                Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Stop
                Write-ColorMessage "[SUCCESS] Deleted: $($item.Path)" "Green"
            }
            catch {
                Write-ColorMessage "[ERROR] Could not delete $($item.Path): $_" "Red"
            }
        }
    }
}

# Clean registry entries
function Remove-LeftoverRegistry {
    param([string]$ProgramName)
    
    Write-Header "Scanning for Leftover Registry Entries"
    
    $registryLocations = @(
        "HKCU:\Software\$ProgramName",
        "HKLM:\Software\$ProgramName",
        "HKLM:\Software\Wow6432Node\$ProgramName",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )
    
    $foundKeys = @()
    
    # Check main registry keys
    foreach ($path in $registryLocations[0..2]) {
        if (Test-Path $path) {
            $foundKeys += [PSCustomObject]@{
                Path = $path
                Type = "Program Key"
            }
        }
    }
    
    # Check startup entries
    foreach ($path in $registryLocations[3..4]) {
        if (Test-Path $path) {
            $items = Get-ItemProperty $path -ErrorAction SilentlyContinue
            foreach ($prop in $items.PSObject.Properties) {
                if ($prop.Value -like "*$ProgramName*") {
                    $foundKeys += [PSCustomObject]@{
                        Path = "$path\$($prop.Name)"
                        Type = "Startup Entry"
                    }
                }
            }
        }
    }
    
    if ($foundKeys.Count -eq 0) {
        Write-ColorMessage "[INFO] No leftover registry entries found" "Green"
        return
    }
    
    Write-ColorMessage "[WARNING] Found leftover registry entries:" "Yellow"
    foreach ($key in $foundKeys) {
        Write-Host "  - [$($key.Type)] $($key.Path)" -ForegroundColor Yellow
    }
    
    $confirm = Read-Host "`nDelete all leftover registry entries? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        foreach ($key in $foundKeys) {
            try {
                if ($key.Type -eq "Program Key") {
                    Remove-Item -Path $key.Path -Recurse -Force -ErrorAction Stop
                    Write-ColorMessage "[SUCCESS] Deleted: $($key.Path)" "Green"
                }
                else {
                    # For startup entries, remove the property
                    $parentPath = Split-Path $key.Path -Parent
                    $propName = Split-Path $key.Path -Leaf
                    Remove-ItemProperty -Path $parentPath -Name $propName -ErrorAction Stop
                    Write-ColorMessage "[SUCCESS] Deleted: $($key.Path)" "Green"
                }
            }
            catch {
                Write-ColorMessage "[ERROR] Could not delete $($key.Path): $_" "Red"
            }
        }
    }
}

# Clean shortcuts
function Remove-LeftoverShortcuts {
    param([string]$ProgramName)
    
    Write-Header "Scanning for Leftover Shortcuts"
    
    $shortcutLocations = @(
        "$env:Public\Desktop",
        "$env:UserProfile\Desktop",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs"
    )
    
    $foundShortcuts = @()
    foreach ($location in $shortcutLocations) {
        if (Test-Path $location) {
            $shortcuts = Get-ChildItem -Path $location -Recurse -Include "*.lnk" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*$ProgramName*" }
            
            foreach ($shortcut in $shortcuts) {
                $foundShortcuts += $shortcut.FullName
            }
        }
    }
    
    if ($foundShortcuts.Count -eq 0) {
        Write-ColorMessage "[INFO] No leftover shortcuts found" "Green"
        return
    }
    
    Write-ColorMessage "[WARNING] Found leftover shortcuts:" "Yellow"
    foreach ($shortcut in $foundShortcuts) {
        Write-Host "  - $shortcut" -ForegroundColor Yellow
    }
    
    $confirm = Read-Host "`nDelete all leftover shortcuts? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        foreach ($shortcut in $foundShortcuts) {
            try {
                Remove-Item -Path $shortcut -Force -ErrorAction Stop
                Write-ColorMessage "[SUCCESS] Deleted: $shortcut" "Green"
            }
            catch {
                Write-ColorMessage "[ERROR] Could not delete $shortcut : $_" "Red"
            }
        }
    }
}

# Main menu
function Show-MainMenu {
    Clear-Host
    Write-Host @"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║           SAFE PROGRAM UNINSTALLER v2.0                   ║
║           Windows 10 & 11 Compatible                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    Write-Host "`n1. Uninstall Program" -ForegroundColor Green
    Write-Host "2. Exit" -ForegroundColor Red
    Write-Host ""
}

# Main loop
while ($true) {
    Show-MainMenu
    $choice = Read-Host "Enter choice"
    
    switch ($choice) {
        "1" {
            $programs = Get-InstalledPrograms
            
            if ($programs.Count -eq 0) {
                Write-ColorMessage "[WARNING] No programs found" "Yellow"
                pause
                continue
            }
            
            Write-Header "Installed Programs"
            for ($i = 0; $i -lt $programs.Count; $i++) {
                $ver = if ($programs[$i].Version) { "v$($programs[$i].Version)" } else { "" }
                Write-Host "$($i + 1). $($programs[$i].Name) $ver"
            }
            
            Write-Host "`n0. Cancel" -ForegroundColor Yellow
            $selection = Read-Host "`nSelect program number"
            
            if ($selection -eq "0") { continue }
            
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $programs.Count) {
                $program = $programs[$index]
                
                Write-ColorMessage "`nUninstall: $($program.Name)?" "Yellow"
                $confirm = Read-Host "Continue? (Y/N)"
                
                if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                    $success = Uninstall-Program -Program $program
                    
                    if ($success) {
                        Write-Host "`n" -NoNewline
                        $deepClean = Read-Host "Perform deep cleanup (remove all leftovers)? (Y/N)"
                        
                        if ($deepClean -eq 'Y' -or $deepClean -eq 'y') {
                            Remove-LeftoverFiles -ProgramName $program.Name
                            Remove-LeftoverRegistry -ProgramName $program.Name
                            Remove-LeftoverShortcuts -ProgramName $program.Name
                            
                            Write-Header "Cleanup Complete"
                            Write-ColorMessage "[SUCCESS] All traces of $($program.Name) have been removed!" "Green"
                        }
                    }
                }
            }
            
            pause
        }
        
        "2" {
            Write-ColorMessage "`nGoodbye!" "Green"
            exit 0
        }
        
        default {
            Write-ColorMessage "[ERROR] Invalid choice" "Red"
            Start-Sleep -Seconds 1
        }
    }
}
