$ErrorActionPreference = "SilentlyContinue"
$taskName = "TasuHub MM2 Local Launcher"
Stop-ScheduledTask -TaskName $taskName
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
Write-Host "TasuHub yerel baslatici kaldirildi."
