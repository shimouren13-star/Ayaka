# Stop old monitor if running
Get-Process powershell -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.MainWindowTitle -eq "" -and $_.Id -ne $PID) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 2

# Start new monitor
Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\15063\Desktop\Ayaka\auto-save-screenshots.ps1"' -WindowStyle Hidden
Write-Host "Monitor restarted" -ForegroundColor Green
