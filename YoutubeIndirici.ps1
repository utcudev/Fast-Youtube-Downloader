<#
.SYNOPSIS
YouTube'dan müzik/video indirme betiği (döngüsel)
.DESCRIPTION
yt-dlp ve ffmpeg'i gerektiğinde otomatik indirir, ardından şarkı adı veya
doğrudan bağlantı ile MP3/MP4 indirir. Çıkmak için 'q' yazın.
#>

$ErrorActionPreference = "Stop"

# Türkçe karakterlerin konsolda düzgün görünmesi için
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       YouTube MP3/MP4 İndirici          " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   utcudev tarafından hazırlanmıştır     " -ForegroundColor DarkGray
Write-Host "   github.com/utcudev                    " -ForegroundColor DarkGray
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# --- Hedef klasör -----------------------------------------------------------

$DownloadFolder = Read-Host "1) Nereye kaydedilecek? (Örn: C:\Users\isim\Muzikler, boş bırakırsanız Masaüstüne kaydeder)"

if ([string]::IsNullOrWhiteSpace($DownloadFolder)) {
    $DownloadFolder = "$env:USERPROFILE\Desktop"
    Write-Host "Masaüstüne kaydedilecek: $DownloadFolder" -ForegroundColor Yellow
}

if (-not (Test-Path $DownloadFolder)) {
    Write-Host "Klasör bulunamadı, oluşturuluyor..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Force -Path $DownloadFolder | Out-Null
    } catch {
        Write-Host "Klasör oluşturulamadı: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Çıkmak için Enter'a basın"
        exit 1
    }
}

# --- Format -----------------------------------------------------------------

$Format = ""
while ($Format -notin @("1", "2")) {
    Write-Host "`nFormat seçin:" -ForegroundColor Green
    Write-Host " 1) MP3 (Sadece Ses)"
    Write-Host " 2) MP4 (Video)"
    $Format = Read-Host "Seçiminiz (1 veya 2)"
}

$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $PWD.Path }

# --- yt-dlp -----------------------------------------------------------------

$ytDlpPath = Join-Path $scriptPath "yt-dlp.exe"
if (-not (Test-Path $ytDlpPath)) {
    Write-Host "`nGerekli araç (yt-dlp) indiriliyor, lütfen bekleyin (sadece ilk seferde)..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" `
            -OutFile $ytDlpPath -UseBasicParsing
    } catch {
        Write-Host "yt-dlp indirilemedi: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "İnternet bağlantınızı kontrol edin." -ForegroundColor Red
        Read-Host "Çıkmak için Enter'a basın"
        exit 1
    }
}

# --- ffmpeg -----------------------------------------------------------------

$ffmpegPath = Join-Path $scriptPath "ffmpeg.exe"
$ffmpegReady = $true
$hasFfmpeg = $false

if (Test-Path $ffmpegPath) {
    $hasFfmpeg = $true
} elseif (Get-Command "ffmpeg" -ErrorAction SilentlyContinue) {
    # Sistemde zaten kurulu, yt-dlp PATH üzerinden bulur
    $ffmpegPath = $null
    $hasFfmpeg = $true
}

if ($Format -eq "1" -and -not $hasFfmpeg) {
    Write-Host "MP3'e dönüştürmek için FFmpeg indiriliyor (sadece ilk seferde, ~130 MB)..." -ForegroundColor Yellow
    $ffmpegZip = Join-Path $scriptPath "ffmpeg.zip"
    $ffmpegTmp = Join-Path $scriptPath "ffmpeg_extracted"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" `
            -OutFile $ffmpegZip -UseBasicParsing

        Write-Host "Arşiv çıkarılıyor..." -ForegroundColor Yellow
        Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegTmp -Force

        $extracted = Get-ChildItem -Path $ffmpegTmp -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
        if (-not $extracted) { throw "Arşivde ffmpeg.exe bulunamadı." }

        Move-Item -Path $extracted.FullName -Destination $ffmpegPath -Force
        $hasFfmpeg = $true
    } catch {
        Write-Host "FFmpeg indirilemedi: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "MP3 dönüşümü yapılamaz. MP4 seçerek devam edebilir veya" -ForegroundColor Yellow
        Write-Host "ffmpeg.exe dosyasını elle bu klasöre koyabilirsiniz." -ForegroundColor Yellow
        $ffmpegReady = $false
    } finally {
        if (Test-Path $ffmpegZip) { Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path $ffmpegTmp) { Remove-Item $ffmpegTmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

if ($Format -eq "1" -and -not $ffmpegReady) {
    Read-Host "Çıkmak için Enter'a basın"
    exit 1
}

if ($Format -eq "2" -and -not $hasFfmpeg) {
    Write-Host "`nFFmpeg bulunamadı. Video ve ses akışları birleştirilemeyeceği için" -ForegroundColor Yellow
    Write-Host "tek parça hâlindeki en iyi MP4 indirilecek (kalite biraz düşük olabilir)." -ForegroundColor Yellow
}

# --- İndirme döngüsü --------------------------------------------------------

$ext = if ($Format -eq "1") { "mp3" } else { "mp4" }

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  KURULUM TAMAMLANDI - İNDİRMEYE HAZIR   " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Şarkı adı yazabilir veya doğrudan bağlantı yapıştırabilirsiniz." -ForegroundColor Yellow
Write-Host "Çıkmak için 'q' yazıp Enter'a basın.`n" -ForegroundColor Yellow

while ($true) {
    $Query = Read-Host "İndirmek istediğiniz müziğin/videonun adı veya bağlantısı"
    $Query = $Query.Trim()

    if ($Query -eq "") {
        Write-Host "Bir şey yazmadınız. Çıkmak için 'q' yazın." -ForegroundColor DarkGray
        continue
    }

    if ($Query.ToLower() -eq "q") {
        Write-Host "Betik sonlandırılıyor, iyi günler!" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        break
    }

    # Bağlantı yapıştırılmışsa doğrudan kullan, değilse YouTube'da ara
    if ($Query -match '^https?://') {
        $target = $Query
        Write-Host "İndiriliyor: $target ($ext)..." -ForegroundColor Cyan
    } else {
        $target = "ytsearch1:$Query"
        Write-Host "Aranıyor ve indiriliyor: '$Query' ($ext)..." -ForegroundColor Cyan
    }

    $argsList = @($target, "--no-playlist", "--no-overwrites",
                  "--paths", $DownloadFolder,
                  "-o", "%(title)s.%(ext)s")

    if ($Format -eq "1") {
        $argsList += @("-x", "--audio-format", "mp3", "--audio-quality", "0")
    } elseif ($hasFfmpeg) {
        $argsList += @("-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best")
    } else {
        # Birleştirici yok - tek dosyalık formatlarla yetin
        $argsList += @("-f", "best[ext=mp4]/best")
    }

    if ($ffmpegPath -and (Test-Path $ffmpegPath)) {
        $argsList += @("--ffmpeg-location", $ffmpegPath)
    }

    & $ytDlpPath $argsList
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "`n[+] İndirme tamamlandı -> $DownloadFolder" -ForegroundColor Green
    } else {
        Write-Host "`n[!] İndirme başarısız (yt-dlp çıkış kodu: $exitCode)." -ForegroundColor Red
        Write-Host "    Bağlantı yanlış olabilir, video erişime kapalı olabilir," -ForegroundColor Yellow
        Write-Host "    ya da yt-dlp güncel değildir. Güncellemek için: .\yt-dlp.exe -U" -ForegroundColor Yellow
    }

    Write-Host "-----------------------------------------`n" -ForegroundColor Cyan
}
