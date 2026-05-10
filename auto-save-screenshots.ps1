# Auto-save screenshots from clipboard
$savePath = "$env:USERPROFILE\Pictures\Screenshots"
if (-not (Test-Path $savePath)) { New-Item -ItemType Directory -Path $savePath -Force | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$lastHash = $null
Write-Host "Monitoring clipboard for screenshots... Save to: $savePath"

while ($true) {
    Start-Sleep -Milliseconds 500

    try {
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $img = [System.Windows.Forms.Clipboard]::GetImage()
            if ($null -eq $img) { continue }

            # Check if it's a new image (simple hash to avoid duplicates)
            $stream = New-Object System.IO.MemoryStream
            $img.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $bytes = $stream.ToArray()
            $stream.Close()
            $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash($bytes))

            if ($hash -ne $lastHash) {
                $lastHash = $hash
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
                $filePath = Join-Path $savePath "screenshot_$timestamp.png"
                [System.IO.File]::WriteAllBytes($filePath, $bytes)
                Write-Host "Saved: $filePath"
            }
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}
