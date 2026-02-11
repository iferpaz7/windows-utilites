# Agent Instructions for Windows System Maintenance Scripts

## Project Overview
This project contains Windows system maintenance utilities including health checks, cleanup tools, and safe uninstallation scripts. All scripts are provided in both PowerShell (.ps1) and Batch (.bat) formats for compatibility.

## Code Style Guidelines

### PowerShell Scripts
- Use proper error handling with try-catch blocks
- Include administrator privilege checks at script start
- Add clear console output with Write-Host for user feedback
- Use proper PowerShell cmdlets over legacy commands
- Include confirmation prompts for destructive operations
- Add comprehensive logging for troubleshooting
- Follow verb-noun naming conventions for functions

### Batch Scripts
- Include @echo off at the start
- Check for administrator privileges using net session
- Provide clear echo statements for user feedback
- Use proper error level checking after critical operations
- Add pause statements where user confirmation is needed
- Keep syntax compatible with Windows 7 and later

## Safety Requirements

### Critical Safety Checks
- Always verify administrator/elevated privileges before system modifications
- Implement confirmation prompts before deleting files or registry entries
- Create restore points or backups before making system changes
- Validate paths and file existence before operations
- Use safe deletion methods (move to temp/recycle bin when possible)
- Log all operations for audit trail

### Testing Approach
- Test scripts in isolated VM environments first
- Verify compatibility across Windows versions (7, 10, 11)
- Check both PowerShell and Batch versions produce equivalent results
- Test with and without administrator privileges
- Validate error handling with invalid inputs

## Common Patterns

### Administrator Check (PowerShell)
```powershell
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges"
    exit
}
```

### Administrator Check (Batch)
```batch
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges
    pause
    exit /b 1
)
```

### User Confirmation
Always ask before destructive operations and provide clear information about what will be affected.

## File Organization
- Keep paired .ps1 and .bat files with identical base names
- Place documentation in README.md
- Store license information in LICENSE
- Use .kiro/steering/ for agent instructions

## When Adding New Features
- Implement in both PowerShell and Batch unless technically infeasible
- Add appropriate error handling and logging
- Update README.md with usage instructions
- Test thoroughly before committing
- Consider backward compatibility with older Windows versions
