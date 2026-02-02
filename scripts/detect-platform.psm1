# Platform Detection Script for Windows
# Detects Windows version, PowerShell version, and development mode status

function Get-PlatformInfo {
    $info = @{
        OS = "Windows"
        Version = [System.Environment]::OSVersion.Version
        PowerShellVersion = $PSVersionTable.PSVersion
        IsDeveloperModeEnabled = $false
        IsAdmin = $false
    }

    # Check if running as Administrator
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $info.IsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Check Developer Mode by testing symbolic link creation
    # Registry key location changed in Windows 11 25H2, so we test actual capability
    try {
        $testPath = Join-Path $env:TEMP "dotfiles-symlink-test-$(Get-Random)"
        $testTarget = $env:TEMP
        New-Item -ItemType SymbolicLink -Path $testPath -Target $testTarget -ErrorAction Stop | Out-Null
        Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
        $info.IsDeveloperModeEnabled = $true
    } catch {
        # Symbolic link creation failed, Developer Mode likely disabled
    }

    return $info
}

function Test-WindowsVersion {
    $version = [System.Environment]::OSVersion.Version

    # Windows 10 1607 = 10.0.14393
    # Windows 11 = 10.0.22000+
    if ($version.Major -lt 10) {
        Write-Error "Windows 10 or later is required. Current version: $($version.ToString())"
        return $false
    }

    if ($version.Major -eq 10 -and $version.Build -lt 14393) {
        Write-Error "Windows 10 version 1607 or later is required. Current build: $($version.Build)"
        return $false
    }

    return $true
}

function Test-PowerShellVersion {
    $required = [Version]"5.1"
    $current = $PSVersionTable.PSVersion

    if ($current -lt $required) {
        Write-Error "PowerShell $required or later is required. Current version: $current"
        return $false
    }

    return $true
}

function Show-PlatformInfo {
    $info = Get-PlatformInfo

    Write-Host "Platform Information:" -ForegroundColor Cyan
    Write-Host "  OS: $($info.OS)" -ForegroundColor White
    Write-Host "  Version: $($info.Version.ToString())" -ForegroundColor White
    Write-Host "  PowerShell: $($info.PowerShellVersion.ToString())" -ForegroundColor White
    Write-Host "  Administrator: $($info.IsAdmin)" -ForegroundColor White
    Write-Host "  Developer Mode: $($info.IsDeveloperModeEnabled)" -ForegroundColor White

    if (-not $info.IsDeveloperModeEnabled) {
        Write-Host "`nWarning: Developer Mode is not enabled." -ForegroundColor Yellow
        Write-Host "Symbolic links will not work. Junctions will be used for directories instead." -ForegroundColor Yellow
        Write-Host "To enable Developer Mode:" -ForegroundColor Yellow
        Write-Host "  Settings > System > For developers > Developer Mode" -ForegroundColor White
    }

    return $info
}

# Export functions
Export-ModuleMember -Function Get-PlatformInfo, Test-WindowsVersion, Test-PowerShellVersion, Show-PlatformInfo
