<#
.SYNOPSIS
    Uninstall common bloatware applications from Windows.
.EXAMPLE
    WARNING! This script must be executed in this specific way to avoid execution policy errors:
    powershell.exe -ExecutionPolicy Bypass -File .\UninstallBloatware.ps1

.NOTES
    Comment out any applications you do not wish to remove.
#>

#Requires -RunAsAdministrator

# >>> Bloatware Removal >>>

$apps = @(
    "*Clipchamp.Clipchamp*",
    "*LinkedIn*",
    "*Microsoft.BingNews*",
    "*Microsoft.BingWeather*",
    "*Microsoft.GamingApp*",
    "*Microsoft.MicrosoftSolitaireCollection*",
    "*Microsoft.MicrosoftStickyNotes*",
    "*Microsoft.MicrosoftStickyNotes*",
    "*Microsoft.Office.OneNote*",
    "*Microsoft.OutlookForWindows*",
    "*Microsoft.Paint*",
    "*Microsoft.Teams*",
    "*Microsoft.Todos*",
    "*Microsoft.Whiteboard*",
    "*Microsoft.Windows.Photos*",
    "*microsoft.windowscommunicationsapps*", # Mail & Calendar
    "*Microsoft.Xbox*",
    "*Microsoft.YourPhone*",
    "*MicrosoftTeams*",
    "*MSPaint*",
    "*MSTeams*",
    "*SkypeApp*"
)

foreach ($app in $apps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    # Remove provisioned packages to prevent reinstallation for new users
    Get-ProvisionedAppxPackage -Online | Where-Object { $_.PackageName -like $app } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
}

# Microsoft Copilot
winget uninstall -h --id 9WZDNCRD29V9

# OneDrive
winget uninstall -h --id Microsoft.OneDrive

# Microsoft Teams Machine-Wide Installer
$uninstallKeys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
foreach ($key in $uninstallKeys) {
    Get-ChildItem $key -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.DisplayName -eq "Teams Machine-Wide Installer" } | ForEach-Object {
        Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait
    }
}
