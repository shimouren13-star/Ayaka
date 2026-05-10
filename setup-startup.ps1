$startup = [Environment]::GetFolderPath('Startup')
$shortcutPath = Join-Path $startup 'ScreenshotAutoSave.lnk'
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = 'wscript.exe'
$shortcut.Arguments = '"C:\Users\15063\Desktop\Ayaka\start-screenshot-saver.vbs"'
$shortcut.WorkingDirectory = 'C:\Users\15063\Desktop\Ayaka'
$shortcut.Save()
Write-Host "Startup shortcut created: $shortcutPath"
