<h1 align="center">🎵 Fast YouTube Downloader</h1>

<p align="center">
  Çift tıkla çalışan, Türkçe arayüzlü YouTube MP3/MP4 indirici.<br>
  Kurulum yok, bağımlılık yok — gerekli araçları kendisi indirir.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="PowerShell">
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows">
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux">
  <img src="https://img.shields.io/badge/yt--dlp-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="yt-dlp">
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge" alt="MIT License">
</p>

<p align="center">
  <a href="https://github.com/utcudev/Fast-Youtube-Downloader/releases/latest"><img src="https://img.shields.io/github/v/release/utcudev/Fast-Youtube-Downloader?style=flat-square&color=22C55E" alt="Release"></a>
  <a href="https://github.com/utcudev/Fast-Youtube-Downloader/actions/workflows/lint.yml"><img src="https://img.shields.io/github/actions/workflow/status/utcudev/Fast-Youtube-Downloader/lint.yml?style=flat-square&label=lint" alt="Lint"></a>
  <img src="https://img.shields.io/github/downloads/utcudev/Fast-Youtube-Downloader/total?style=flat-square&color=blue" alt="Downloads">
</p>

---

## Ne yapar

Şarkı adını yazarsın, YouTube'da arar, en iyi kaliteyi bulur ve indirir. Bağ (link) yapıştırırsan doğrudan onu indirir. Bir dosya bitince kapanmaz — sırayla istediğin kadar indirebilirsin.

- **MP3** (sadece ses, en yüksek kalite) veya **MP4** (video)
- Ad ile arama **veya** doğrudan bağ
- Seri indirme — program açık kalır
- `yt-dlp` ve `ffmpeg` ilk çalıştırmada otomatik iner
- Kayıt klasörünü sen seçersin, boş bırakırsan masaüstü

---

## Kurulum

Sisteminin paketini [**Releases**](https://github.com/utcudev/Fast-Youtube-Downloader/releases/latest) sayfasından indir.

### Windows

`Fast-Youtube-Downloader-windows.zip` dosyasını çıkar, `YoutubeIndirici.bat` dosyasına çift tıkla. Hepsi bu.

### Linux

Tek satır:

```bash
curl -fsSL https://raw.githubusercontent.com/utcudev/Fast-Youtube-Downloader/main/youtube-indirici.sh -o youtube-indirici.sh && chmod +x youtube-indirici.sh && ./youtube-indirici.sh
```

### Sonrası ikisinde de aynı

1. Kayıt klasörünü yaz (boş Enter = masaüstü)
2. Format seç: `1` = MP3, `2` = MP4
3. Şarkı adı ya da bağ yaz, Enter
4. Çıkmak için `q` veya boş Enter

```
=========================================
       Youtube MP3/MP4 Indirici
=========================================

1) Nereye kaydedilecek? ...

Format secin:
 1) MP3 (Sadece Ses)
 2) MP4 (Video)
Seciminiz (1 veya 2): 1

Indirmek istediginiz muzigin/videonun adi veya bagi: Baris Manco Gulpembe
Araniyor ve indiriliyor: 'Baris Manco Gulpembe' (mp3)...

[+] Indirme tamamlandi -> C:\Users\isim\Muzikler
```

---

## İlk çalıştırma

İlk seferde araçlar indirilir; internet hızına göre birkaç dakika sürebilir.

| Araç | Boyut | Ne zaman iner |
|---|---|---|
| `yt-dlp.exe` | ~18 MB | Her zaman |
| `ffmpeg.exe` | ~130 MB (zip) | Yalnızca MP3 seçilirse ve sistemde ffmpeg yoksa |

Sonraki çalıştırmalarda bu adım atlanır.

---

## Gereksinimler

**Windows** — Windows 10/11 ve PowerShell 5.1 (sistemle birlikte gelir). `.bat` dosyası betiği `-ExecutionPolicy Bypass` ile çalıştırır, ayrı izin ayarı gerekmez.

**Linux** — bash, ve `curl` ya da `wget`. MP3 indirmek için `ffmpeg` kurulu olmalı:

```bash
sudo apt install ffmpeg
```

Betik hangi paket yöneticisini kullandığını algılar ve doğru komutu söyler (apt / dnf / pacman / zypper / apk). yt-dlp kurulu değilse mimarine uygun ikiliyi kendisi indirir — x86_64, aarch64, armv7l.

---

## Sorun giderme

**"Indirme basarisiz (yt-dlp cikis kodu: 1)"** — YouTube sık sık değişiyor, çoğu zaman yt-dlp eskidiği için olur. Klasörde PowerShell açıp güncelle:

```bash
.\yt-dlp.exe -U
```

**MP3 seçince hata** — ffmpeg inememiş demektir. [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds/releases) sayfasından `ffmpeg-master-latest-win64-gpl.zip` indirip içindeki `ffmpeg.exe` dosyasını bu klasöre koy.

**Dosya adında tuhaf karakterler** — video başlığından geliyor, yt-dlp Windows'ta geçersiz karakterleri kendisi temizler.

---

## Yasal not

Bu araç kişisel kullanım içindir. İndirdiğiniz içeriğin telif hakları size ait değilse, dağıtımı ve ticari kullanımı yasa dışı olabilir. YouTube Hizmet Şartları'na ve bulunduğunuz ülkenin telif mevzuatına uymak kullanıcının sorumluluğundadır.

---

## Teşekkür

Bu araç şu projelerin üzerine kurulu:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — indirme motoru
- [FFmpeg](https://ffmpeg.org/) — ses/video dönüştürme

---

## Lisans

[MIT](LICENSE)
