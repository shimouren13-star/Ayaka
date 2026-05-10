# Auto-save screenshots from clipboard + OCR via Python
$savePath = "$env:USERPROFILE\Pictures\Screenshots"
$ocrScript = "C:\Users\15063\Desktop\Ayaka\ocr.py"
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) { $python = "python" }

if (-not (Test-Path $savePath)) { New-Item -ItemType Directory -Path $savePath -Force | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$lastHash = $null
Write-Host "Monitoring clipboard + OCR active"
Write-Host "  Screenshots: $savePath"

while ($true) {
    Start-Sleep -Milliseconds 500

    try {
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $img = [System.Windows.Forms.Clipboard]::GetImage()
            if ($null -eq $img) { continue }

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
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Saved: $filePath"

                # Run Python OCR in background
                Start-Process -FilePath $python -ArgumentList "`"$ocrScript`" `"$filePath`"" -WindowStyle Hidden -NoNewWindow
            }
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}
