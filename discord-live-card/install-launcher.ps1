$ErrorActionPreference = "Stop"
$taskName = "TasuHub MM2 Local Launcher"
$nodePath = (Get-Command node.exe -ErrorAction Stop).Source
$launcherPath = Join-Path $PSScriptRoot "src\launcher.mjs"

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot "node_modules"))) {
    Push-Location $PSScriptRoot
    try { npm install } finally { Pop-Location }
}

$userId = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute $nodePath -Argument ('"' + $launcherPath + '"') -WorkingDirectory $PSScriptRoot
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -Hidden `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "TasuHub yerel baslatici kuruldu ve baslatildi: http://127.0.0.1:8786"
