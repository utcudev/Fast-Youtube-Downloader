<#
.SYNOPSIS
YouTube'dan muzik/video indirme scripti (donguSel)
.DESCRIPTION
yt-dlp ve ffmpeg'i gerektiginde otomatik indirir, ardindan sarki adi veya
dogrudan bag ile MP3/MP4 indirir. Cikmak icin bos Enter ya da 'q'.
#>

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       Youtube MP3/MP4 Indirici          " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   utcudev tarafindan hazirlanmistir     " -ForegroundColor DarkGray
Write-Host "   github.com/utcudev                    " -ForegroundColor DarkGray
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# --- Hedef klasor -----------------------------------------------------------

$DownloadFolder = Read-Host "1) Nereye kaydedilecek? (Orn: C:\Users\isim\Muzikler, bos birakirsaniz Masaustune kaydeder)"

if ([string]::IsNullOrWhiteSpace($DownloadFolder)) {
    $DownloadFolder = "$env:USERPROFILE\Desktop"
    Write-Host "Masaustune kaydedilecek: $DownloadFolder" -ForegroundColor Yellow
}

if (-not (Test-Path $DownloadFolder)) {
    Write-Host "Klasor bulunamadi, olusturuluyor..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Force -Path $DownloadFolder | Out-Null
    } catch {
        Write-Host "Klasor olusturulamadi: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Cikmak icin Enter"
        exit 1
    }
}

# --- Format -----------------------------------------------------------------

$Format = ""
while ($Format -notin @("1", "2")) {
    Write-Host "`nFormat secin:" -ForegroundColor Green
    Write-Host " 1) MP3 (Sadece Ses)"
    Write-Host " 2) MP4 (Video)"
    $Format = Read-Host "Seciminiz (1 veya 2)"
}

$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $PWD.Path }

# --- yt-dlp -----------------------------------------------------------------

$ytDlpPath = Join-Path $scriptPath "yt-dlp.exe"
if (-not (Test-Path $ytDlpPath)) {
    Write-Host "`nGerekli arac (yt-dlp) indiriliyor, lutfen bekleyin (sadece ilk seferde)..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" `
            -OutFile $ytDlpPath -UseBasicParsing
    } catch {
        Write-Host "yt-dlp indirilemedi: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Internet baglantinizi kontrol edin." -ForegroundColor Red
        Read-Host "Cikmak icin Enter"
        exit 1
    }
}

# --- ffmpeg (yalnizca MP3 icin gerekli) -------------------------------------

$ffmpegPath = Join-Path $scriptPath "ffmpeg.exe"
$ffmpegReady = $true

if ($Format -eq "1" -and -not (Test-Path $ffmpegPath)) {
    if (Get-Command "ffmpeg" -ErrorAction SilentlyContinue) {
        # Sistemde zaten kurulu, yt-dlp PATH uzerinden bulur
        $ffmpegPath = $null
    } else {
        Write-Host "MP3'e donusturmek icin FFmpeg indiriliyor (sadece ilk seferde, ~130 MB)..." -ForegroundColor Yellow
        $ffmpegZip = Join-Path $scriptPath "ffmpeg.zip"
        $ffmpegTmp = Join-Path $scriptPath "ffmpeg_extracted"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" `
                -OutFile $ffmpegZip -UseBasicParsing

            Write-Host "Zip cikariliyor..." -ForegroundColor Yellow
            Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegTmp -Force

            $extracted = Get-ChildItem -Path $ffmpegTmp -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
            if (-not $extracted) { throw "Arsivde ffmpeg.exe bulunamadi." }

            Move-Item -Path $extracted.FullName -Destination $ffmpegPath -Force
        } catch {
            Write-Host "FFmpeg indirilemedi: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "MP3 donusumu yapilamaz. MP4 secerek devam edebilir veya" -ForegroundColor Yellow
            Write-Host "ffmpeg.exe dosyasini elle bu klasore koyabilirsiniz." -ForegroundColor Yellow
            $ffmpegReady = $false
        } finally {
            if (Test-Path $ffmpegZip) { Remove-Item $ffmpegZip -Force -ErrorAction SilentlyContinue }
            if (Test-Path $ffmpegTmp) { Remove-Item $ffmpegTmp -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}

if ($Format -eq "1" -and -not $ffmpegReady) {
    Read-Host "Cikmak icin Enter"
    exit 1
}

# --- Indirme dongusu --------------------------------------------------------

$ext = if ($Format -eq "1") { "mp3" } else { "mp4" }

Write-Host "`n=========================================" -ForegroundColor Green
Write-Host "  KURULUM TAMAMLANDI - INDIRMEYE HAZIR" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Sarki adi yazabilir veya dogrudan bag (link) yapistirabilirsiniz." -ForegroundColor Yellow
Write-Host "Cikmak icin bos Enter'a basin ya da 'q' yazin.`n" -ForegroundColor Yellow

while ($true) {
    $Query = Read-Host "Indirmek istediginiz muzigin/videonun adi veya bagi"

    if ([string]::IsNullOrWhiteSpace($Query) -or $Query.Trim().ToLower() -eq "q") {
        Write-Host "Script sonlandiriliyor, iyi gunler!" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        break
    }

    $Query = $Query.Trim()

    # Bag yapistirilmissa dogrudan kullan, degilse YouTube'da ara
    if ($Query -match '^https?://') {
        $target = $Query
        Write-Host "Indiriliyor: $target ($ext)..." -ForegroundColor Cyan
    } else {
        $target = "ytsearch1:$Query"
        Write-Host "Araniyor ve indiriliyor: '$Query' ($ext)..." -ForegroundColor Cyan
    }

    $argsList = @($target, "--no-playlist", "--no-overwrites",
                  "--paths", $DownloadFolder,
                  "-o", "%(title)s.%(ext)s")

    if ($Format -eq "1") {
        $argsList += @("-x", "--audio-format", "mp3", "--audio-quality", "0")
    } else {
        $argsList += @("-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best")
    }

    if ($ffmpegPath -and (Test-Path $ffmpegPath)) {
        $argsList += @("--ffmpeg-location", $ffmpegPath)
    }

    & $ytDlpPath $argsList
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "`n[+] Indirme tamamlandi -> $DownloadFolder" -ForegroundColor Green
    } else {
        Write-Host "`n[!] Indirme basarisiz (yt-dlp cikis kodu: $exitCode)." -ForegroundColor Red
        Write-Host "    Bag yanlis olabilir, video erisime kapali olabilir," -ForegroundColor Yellow
        Write-Host "    ya da yt-dlp guncel degildir. Guncellemek icin: .\yt-dlp.exe -U" -ForegroundColor Yellow
    }

    Write-Host "-----------------------------------------`n" -ForegroundColor Cyan
}
