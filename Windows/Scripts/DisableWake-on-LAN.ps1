# Get the specific Realtek adapter
$nic = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Realtek" }

if ($nic) {
    Write-Host "Found: $($nic.InterfaceDescription)" -ForegroundColor Cyan
    
    # Disable the standard Power Management features
    # We use -ErrorAction SilentlyContinue because some drivers don't support all flags
    Set-NetAdapterPowerManagement -InterfaceDescription $nic.InterfaceDescription `
        -WakeOnMagicPacket Disabled `
        -WakeOnPattern Disabled `
        -ErrorAction SilentlyContinue

    # Now we disable the "Magic Packet" and "Pattern Match" at the driver-specific level
    # This is often where the 'Ghost' wakes live for Realtek cards
    Write-Host "Disabling hardware-level Advanced properties..." -ForegroundColor Yellow
    Set-NetAdapterAdvancedProperty -InterfaceDescription $nic.InterfaceDescription -DisplayName "Wake on Magic Packet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -InterfaceDescription $nic.InterfaceDescription -DisplayName "Wake on pattern match" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -InterfaceDescription $nic.InterfaceDescription -DisplayName "Shutdown Wake-On-Lan" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    
    Write-Host "Network wake features have been neutralized." -ForegroundColor Green
} else {
    Write-Warning "Realtek adapter not found via PowerShell."
}
