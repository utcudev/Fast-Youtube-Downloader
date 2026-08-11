#!/usr/bin/env bash
#
# YouTube MP3/MP4 İndirici - Linux sürümü
# utcudev tarafından hazırlanmıştır - github.com/utcudev
#

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$PWD")"

# --- Renkler (terminal desteklemiyorsa boş bırak) ---------------------------

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_CYAN=$(tput setaf 6); C_GREEN=$(tput setaf 2); C_YELLOW=$(tput setaf 3)
    C_RED=$(tput setaf 1); C_DIM=$(tput dim); C_RESET=$(tput sgr0)
else
    C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""; C_RESET=""
fi

say()  { printf '%s%s%s\n' "$1" "$2" "$C_RESET"; }
fail() { say "$C_RED" "$1"; exit 1; }

# Betik kullanıcıya soru soruyor; boru hattından çalıştırılırsa
# (curl ... | bash) standart girdi betiğin kendisi olur ve sorular bozulur.
if [ ! -t 0 ]; then
    say "$C_RED" "Bu betik etkileşimlidir, boru hattıyla çalıştırılamaz."
    say "$C_YELLOW" "Önce indirin, sonra çalıştırın:"
    echo
    echo "  curl -fsSL https://raw.githubusercontent.com/utcudev/Fast-Youtube-Downloader/main/youtube-indirici.sh -o youtube-indirici.sh"
    echo "  chmod +x youtube-indirici.sh"
    echo "  ./youtube-indirici.sh"
    echo
    exit 1
fi

printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
printf '%s\n' "${C_CYAN}       YouTube MP3/MP4 İndirici          ${C_RESET}"
printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
printf '%s\n' "${C_DIM}   utcudev tarafından hazırlanmıştır     ${C_RESET}"
printf '%s\n' "${C_DIM}   github.com/utcudev                    ${C_RESET}"
printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
echo

# --- Paket yöneticisi ipucu -------------------------------------------------

install_hint() {
    local pkg="$1"
    if   command -v apt    >/dev/null 2>&1; then echo "sudo apt install $pkg"
    elif command -v dnf    >/dev/null 2>&1; then echo "sudo dnf install $pkg"
    elif command -v pacman >/dev/null 2>&1; then echo "sudo pacman -S $pkg"
    elif command -v zypper >/dev/null 2>&1; then echo "sudo zypper install $pkg"
    elif command -v apk    >/dev/null 2>&1; then echo "sudo apk add $pkg"
    else echo "paket yöneticinizle '$pkg' kurun"
    fi
}

# --- Hedef klasör -----------------------------------------------------------

if command -v xdg-user-dir >/dev/null 2>&1; then
    DEFAULT_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
fi
[ -n "${DEFAULT_DIR:-}" ] && [ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME/Desktop"
[ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME/Downloads"
[ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME"

read -r -p "1) Nereye kaydedilecek? (boş bırakırsanız: $DEFAULT_DIR) " DOWNLOAD_DIR
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$DEFAULT_DIR}"
DOWNLOAD_DIR="${DOWNLOAD_DIR/#\~/$HOME}"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    say "$C_YELLOW" "Klasör bulunamadı, oluşturuluyor..."
    mkdir -p "$DOWNLOAD_DIR" || fail "Klasör oluşturulamadı: $DOWNLOAD_DIR"
fi

[ -w "$DOWNLOAD_DIR" ] || fail "Bu klasöre yazma izniniz yok: $DOWNLOAD_DIR"

# --- Format -----------------------------------------------------------------

FORMAT=""
while [ "$FORMAT" != "1" ] && [ "$FORMAT" != "2" ]; do
    echo
    say "$C_GREEN" "Format seçin:"
    echo " 1) MP3 (Sadece Ses)"
    echo " 2) MP4 (Video)"
    read -r -p "Seçiminiz (1 veya 2): " FORMAT
done

# --- yt-dlp -----------------------------------------------------------------

if command -v yt-dlp >/dev/null 2>&1; then
    YTDLP="yt-dlp"
elif [ -x "$SCRIPT_DIR/yt-dlp" ]; then
    YTDLP="$SCRIPT_DIR/yt-dlp"
else
    case "$(uname -m)" in
        x86_64|amd64)  ASSET="yt-dlp_linux" ;;
        aarch64|arm64) ASSET="yt-dlp_linux_aarch64" ;;
        armv7l|armv6l|arm)
            # 32-bit ARM için bağımsız ikili yayınlanmıyor;
            # python3 gerektiren taşınabilir sürümü kullanıyoruz.
            if ! command -v python3 >/dev/null 2>&1; then
                fail "32-bit ARM için python3 gerekli. Kurun: $(install_hint python3)"
            fi
            ASSET="yt-dlp"
            ;;
        *) fail "Desteklenmeyen mimari: $(uname -m). Alternatif: $(install_hint yt-dlp)" ;;
    esac

    URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/$ASSET"
    say "$C_YELLOW" "yt-dlp bulunamadı, indiriliyor (sadece ilk seferde)..."

    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar -o "$SCRIPT_DIR/yt-dlp" "$URL" \
            || fail "İndirme başarısız. Alternatif: $(install_hint yt-dlp)"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$SCRIPT_DIR/yt-dlp" "$URL" \
            || fail "İndirme başarısız. Alternatif: $(install_hint yt-dlp)"
    else
        fail "curl veya wget gerekli. Alternatif: $(install_hint yt-dlp)"
    fi

    chmod +x "$SCRIPT_DIR/yt-dlp" || fail "yt-dlp çalıştırılabilir yapılamadı."
    YTDLP="$SCRIPT_DIR/yt-dlp"
fi

# --- ffmpeg -----------------------------------------------------------------

if command -v ffmpeg >/dev/null 2>&1; then
    HAS_FFMPEG=1
else
    HAS_FFMPEG=0
fi

if [ "$FORMAT" = "1" ] && [ "$HAS_FFMPEG" = "0" ]; then
    say "$C_RED" "MP3'e dönüştürmek için ffmpeg gerekli ama kurulu değil."
    say "$C_YELLOW" "Kurmak için:  $(install_hint ffmpeg)"
    exit 1
fi

if [ "$FORMAT" = "2" ] && [ "$HAS_FFMPEG" = "0" ]; then
    say "$C_YELLOW" "ffmpeg bulunamadı. Video ve ses akışları birleştirilemeyeceği için"
    say "$C_YELLOW" "tek parça hâlindeki en iyi MP4 indirilecek (kalite biraz düşük olabilir)."
    say "$C_YELLOW" "Tam kalite için:  $(install_hint ffmpeg)"
fi

# --- İndirme döngüsü --------------------------------------------------------

if [ "$FORMAT" = "1" ]; then EXT="mp3"; else EXT="mp4"; fi

echo
printf '%s\n' "${C_GREEN}=========================================${C_RESET}"
printf '%s\n' "${C_GREEN}  KURULUM TAMAMLANDI - İNDİRMEYE HAZIR   ${C_RESET}"
printf '%s\n' "${C_GREEN}=========================================${C_RESET}"
say "$C_YELLOW" "Şarkı adı yazabilir veya doğrudan bağlantı yapıştırabilirsiniz."
say "$C_YELLOW" "Çıkmak için 'q' yazıp Enter'a basın."
echo

while true; do
    read -r -p "İndirmek istediğiniz müziğin/videonun adı veya bağlantısı: " QUERY

    QUERY="$(printf '%s' "$QUERY" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    QUERY_LOWER="$(printf '%s' "$QUERY" | tr '[:upper:]' '[:lower:]')"

    if [ -z "$QUERY" ]; then
        say "$C_DIM" "Bir şey yazmadınız. Çıkmak için 'q' yazın."
        continue
    fi

    if [ "$QUERY_LOWER" = "q" ]; then
        say "$C_YELLOW" "Betik sonlandırılıyor, iyi günler!"
        break
    fi

    if [[ "$QUERY" =~ ^https?:// ]]; then
        TARGET="$QUERY"
        say "$C_CYAN" "İndiriliyor: $TARGET ($EXT)..."
    else
        TARGET="ytsearch1:$QUERY"
        say "$C_CYAN" "Aranıyor ve indiriliyor: '$QUERY' ($EXT)..."
    fi

    ARGS=( "$TARGET" --no-playlist --no-overwrites
           --paths "$DOWNLOAD_DIR" -o "%(title)s.%(ext)s" )

    if [ "$FORMAT" = "1" ]; then
        ARGS+=( -x --audio-format mp3 --audio-quality 0 )
    elif [ "$HAS_FFMPEG" = "1" ]; then
        ARGS+=( -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" )
    else
        # Birleştirici yok - tek dosyalık formatlarla yetin
        ARGS+=( -f "best[ext=mp4]/best" )
    fi

    if "$YTDLP" "${ARGS[@]}"; then
        echo
        say "$C_GREEN" "[+] İndirme tamamlandı -> $DOWNLOAD_DIR"
    else
        code=$?
        echo
        say "$C_RED" "[!] İndirme başarısız (yt-dlp çıkış kodu: $code)."
        say "$C_YELLOW" "    Bağlantı yanlış olabilir, video erişime kapalı olabilir,"
        say "$C_YELLOW" "    ya da yt-dlp güncel değildir. Güncellemek için: $YTDLP -U"
    fi

    printf '%s\n\n' "${C_CYAN}-----------------------------------------${C_RESET}"
done
