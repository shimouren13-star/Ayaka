param(
    [string]$ImagePath = "",
    [string]$Language = "zh-Hans"
)

# Helper: block on WinRT async operation (.NET Framework compatible)
function Await-WinRT($operation) {
    while ($operation.Status -eq [Windows.Foundation.AsyncStatus]::Started) {
        Start-Sleep -Milliseconds 10
    }
    if ($operation.Status -eq [Windows.Foundation.AsyncStatus]::Error) {
        throw "Async operation failed: $($operation.ErrorCode.Message)"
    }
    return $operation.GetResults()
}

function Get-TextFromImage {
    param([string]$Path, [string]$Lang)

    # Load WinRT types
    [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
    [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics, ContentType = WindowsRuntime] | Out-Null
    [Windows.Media.Ocr.OcrEngine, Windows.Media, ContentType = WindowsRuntime] | Out-Null
    [Windows.Foundation.AsyncStatus, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null

    # Load file via StorageFile
    $storageFile = Await-WinRT ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path))
    $stream = Await-WinRT ($storageFile.OpenReadAsync())
    $decoder = Await-WinRT ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream))
    $bitmap = Await-WinRT ($decoder.GetSoftwareBitmapAsync())

    # Create OCR engine
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($Lang)
    if ($null -eq $engine) {
        $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
    }
    if ($null -eq $engine) {
        throw "No OCR engine available"
    }

    return Await-WinRT ($engine.RecognizeAsync($bitmap))
}

if (-not $ImagePath) {
    $screenshotDir = "$env:USERPROFILE\Pictures\Screenshots"
    $latest = Get-ChildItem $screenshotDir -Filter "screenshot_*.png" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $ImagePath = $latest.FullName
        Write-Host "Using latest screenshot: $($latest.Name)" -ForegroundColor Cyan
    } else {
        Write-Error "No screenshots found. Specify: .\ocr.ps1 -ImagePath 'image.png'"
        exit 1
    }
}

if (-not (Test-Path $ImagePath)) {
    Write-Error "File not found: $ImagePath"
    exit 1
}

Write-Host "OCR Processing: $ImagePath" -ForegroundColor Cyan

try {
    $ocrResult = Get-TextFromImage -Path $ImagePath -Lang $Language

    $text = ""
    foreach ($line in $ocrResult.Lines) {
        $lineText = ""
        foreach ($word in $line.Words) {
            $lineText += $word.Text + " "
        }
        $text += $lineText.TrimEnd() + "`n"
    }

    Write-Host ("=" * 50) -ForegroundColor Yellow
    Write-Host "  OCR Result:" -ForegroundColor Yellow
    Write-Host ("=" * 50) -ForegroundColor Yellow

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "(No text detected in image)" -ForegroundColor DarkGray
    } else {
        Write-Host $text.TrimEnd()
    }

    Write-Host ("=" * 50) -ForegroundColor Yellow

    $txtPath = [System.IO.Path]::ChangeExtension($ImagePath, ".txt")
    if ([string]::IsNullOrWhiteSpace($text)) {
        "[No text detected]" | Out-File -FilePath $txtPath -Encoding UTF8
    } else {
        $text.TrimEnd() | Out-File -FilePath $txtPath -Encoding UTF8
    }
    Write-Host "Result saved: $txtPath" -ForegroundColor Green

} catch {
    Write-Error "OCR failed: $_"
    exit 1
}
