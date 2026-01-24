# 1. Disable Wake Timers in the Active Power Plan using Aliases
# This works even if the GUIDs are non-standard.
$activeScheme = (powercfg /getactivescheme | ForEach-Object { $_.split(' ')[3] })

Write-Host "--- Power Plan Security ---" -ForegroundColor Cyan
try {
    # 0 = Disabled, 1 = Enabled, 2 = Important Only
    powercfg /setacvalueindex $activeScheme SUB_SLEEP RTCWAKE 0
    powercfg /setdcvalueindex $activeScheme SUB_SLEEP RTCWAKE 0
    powercfg /setactive $activeScheme
    Write-Host "[OK] Global Wake Timers disabled for active scheme: $activeScheme" -ForegroundColor Green
} catch {
    Write-Warning "Failed to set Power Plan via Aliases."
}

# 2. Neutralize 'WakeToRun' Scheduled Tasks
Write-Host "`n--- Scanning Scheduled Tasks ---" -ForegroundColor Cyan
Import-Module ScheduledTasks
$tasks = Get-ScheduledTask | Where-Object {$_.Settings.WakeToRun}

if ($tasks) {
    foreach ($task in $tasks) {
        try {
            $settings = $task.Settings
            $settings.WakeToRun = $false
            Set-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Settings $settings -ErrorAction Stop
            Write-Host "[FIXED] Disabled wake trigger for: $($task.TaskName)" -ForegroundColor Yellow
        } catch {
            Write-Warning "[LOCKED] Could not modify $($task.TaskName) - Likely Protected by System."
        }
    }
} else {
    Write-Host "[OK] No rogue wake-up tasks found." -ForegroundColor Green
}

# 3. Final Verification
Write-Host "`n--- Current Wake Status ---" -ForegroundColor Cyan
powercfg /waketimers
