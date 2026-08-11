#!/usr/bin/env bash
#
# Youtube MP3/MP4 Indirici - Linux surumu
# utcudev tarafindan hazirlanmistir - github.com/utcudev
#

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$PWD")"

# --- Renkler (terminal desteklemiyorsa bos birak) ---------------------------

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_CYAN=$(tput setaf 6); C_GREEN=$(tput setaf 2); C_YELLOW=$(tput setaf 3)
    C_RED=$(tput setaf 1); C_DIM=$(tput dim); C_RESET=$(tput sgr0)
else
    C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""; C_RESET=""
fi

say()  { printf '%s%s%s\n' "$1" "$2" "$C_RESET"; }
fail() { say "$C_RED" "$1"; exit 1; }

# Betik kullaniciya soru soruyor; boru hattindan calistirilirsa
# (curl ... | bash) standart girdi betigin kendisi olur ve sorular bozulur.
if [ ! -t 0 ]; then
    say "$C_RED" "Bu betik etkilesimlidir, boru hattiyla calistirilamaz."
    say "$C_YELLOW" "Once indirin, sonra calistirin:"
    echo
    echo "  curl -fsSL https://raw.githubusercontent.com/utcudev/Fast-Youtube-Downloader/main/youtube-indirici.sh -o youtube-indirici.sh"
    echo "  chmod +x youtube-indirici.sh"
    echo "  ./youtube-indirici.sh"
    echo
    exit 1
fi

printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
printf '%s\n' "${C_CYAN}       Youtube MP3/MP4 Indirici          ${C_RESET}"
printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
printf '%s\n' "${C_DIM}   utcudev tarafindan hazirlanmistir     ${C_RESET}"
printf '%s\n' "${C_DIM}   github.com/utcudev                    ${C_RESET}"
printf '%s\n' "${C_CYAN}=========================================${C_RESET}"
echo

# --- Paket yoneticisi ipucu -------------------------------------------------

install_hint() {
    local pkg="$1"
    if   command -v apt    >/dev/null 2>&1; then echo "sudo apt install $pkg"
    elif command -v dnf    >/dev/null 2>&1; then echo "sudo dnf install $pkg"
    elif command -v pacman >/dev/null 2>&1; then echo "sudo pacman -S $pkg"
    elif command -v zypper >/dev/null 2>&1; then echo "sudo zypper install $pkg"
    elif command -v apk    >/dev/null 2>&1; then echo "sudo apk add $pkg"
    else echo "paket yoneticinizle '$pkg' kurun"
    fi
}

# --- Hedef klasor -----------------------------------------------------------

if command -v xdg-user-dir >/dev/null 2>&1; then
    DEFAULT_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
fi
[ -n "${DEFAULT_DIR:-}" ] && [ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME/Desktop"
[ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME/Downloads"
[ -d "$DEFAULT_DIR" ] || DEFAULT_DIR="$HOME"

read -r -p "1) Nereye kaydedilecek? (bos birakirsaniz: $DEFAULT_DIR) " DOWNLOAD_DIR
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$DEFAULT_DIR}"
DOWNLOAD_DIR="${DOWNLOAD_DIR/#\~/$HOME}"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    say "$C_YELLOW" "Klasor bulunamadi, olusturuluyor..."
    mkdir -p "$DOWNLOAD_DIR" || fail "Klasor olusturulamadi: $DOWNLOAD_DIR"
fi

[ -w "$DOWNLOAD_DIR" ] || fail "Bu klasore yazma izniniz yok: $DOWNLOAD_DIR"

# --- Format -----------------------------------------------------------------

FORMAT=""
while [ "$FORMAT" != "1" ] && [ "$FORMAT" != "2" ]; do
    echo
    say "$C_GREEN" "Format secin:"
    echo " 1) MP3 (Sadece Ses)"
    echo " 2) MP4 (Video)"
    read -r -p "Seciminiz (1 veya 2): " FORMAT
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
            # 32-bit ARM icin bagimsiz ikili yayinlanmiyor;
            # python3 gerektiren tasinabilir surumu kullaniyoruz.
            if ! command -v python3 >/dev/null 2>&1; then
                fail "32-bit ARM icin python3 gerekli. Kurun: $(install_hint python3)"
            fi
            ASSET="yt-dlp"
            ;;
        *) fail "Desteklenmeyen mimari: $(uname -m). Alternatif: $(install_hint yt-dlp)" ;;
    esac

    URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/$ASSET"
    say "$C_YELLOW" "yt-dlp bulunamadi, indiriliyor (sadece ilk seferde)..."

    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar -o "$SCRIPT_DIR/yt-dlp" "$URL" \
            || fail "Indirme basarisiz. Alternatif: $(install_hint yt-dlp)"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O "$SCRIPT_DIR/yt-dlp" "$URL" \
            || fail "Indirme basarisiz. Alternatif: $(install_hint yt-dlp)"
    else
        fail "curl veya wget gerekli. Alternatif: $(install_hint yt-dlp)"
    fi

    chmod +x "$SCRIPT_DIR/yt-dlp" || fail "yt-dlp calistirilabilir yapilamadi."
    YTDLP="$SCRIPT_DIR/yt-dlp"
fi

# --- ffmpeg (yalnizca MP3 icin) ---------------------------------------------

if command -v ffmpeg >/dev/null 2>&1; then
    HAS_FFMPEG=1
else
    HAS_FFMPEG=0
fi

if [ "$FORMAT" = "1" ] && [ "$HAS_FFMPEG" = "0" ]; then
    say "$C_RED" "MP3'e donusturmek icin ffmpeg gerekli ama kurulu degil."
    say "$C_YELLOW" "Kurmak icin:  $(install_hint ffmpeg)"
    exit 1
fi

if [ "$FORMAT" = "2" ] && [ "$HAS_FFMPEG" = "0" ]; then
    say "$C_YELLOW" "ffmpeg bulunamadi. Video ve ses akislari birlestirilemeyecegi icin"
    say "$C_YELLOW" "tek parca halindeki en iyi MP4 indirilecek (kalite biraz dusuk olabilir)."
    say "$C_YELLOW" "Tam kalite icin:  $(install_hint ffmpeg)"
fi

# --- Indirme dongusu --------------------------------------------------------

if [ "$FORMAT" = "1" ]; then EXT="mp3"; else EXT="mp4"; fi

echo
printf '%s\n' "${C_GREEN}=========================================${C_RESET}"
printf '%s\n' "${C_GREEN}  KURULUM TAMAMLANDI - INDIRMEYE HAZIR   ${C_RESET}"
printf '%s\n' "${C_GREEN}=========================================${C_RESET}"
say "$C_YELLOW" "Sarki adi yazabilir veya dogrudan bag (link) yapistirabilirsiniz."
say "$C_YELLOW" "Cikmak icin bos Enter'a basin ya da 'q' yazin."
echo

while true; do
    read -r -p "Indirmek istediginiz muzigin/videonun adi veya bagi: " QUERY

    QUERY="$(printf '%s' "$QUERY" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    QUERY_LOWER="$(printf '%s' "$QUERY" | tr '[:upper:]' '[:lower:]')"

    if [ -z "$QUERY" ] || [ "$QUERY_LOWER" = "q" ]; then
        say "$C_YELLOW" "Script sonlandiriliyor, iyi gunler!"
        break
    fi

    if [[ "$QUERY" =~ ^https?:// ]]; then
        TARGET="$QUERY"
        say "$C_CYAN" "Indiriliyor: $TARGET ($EXT)..."
    else
        TARGET="ytsearch1:$QUERY"
        say "$C_CYAN" "Araniyor ve indiriliyor: '$QUERY' ($EXT)..."
    fi

    ARGS=( "$TARGET" --no-playlist --no-overwrites
           --paths "$DOWNLOAD_DIR" -o "%(title)s.%(ext)s" )

    if [ "$FORMAT" = "1" ]; then
        ARGS+=( -x --audio-format mp3 --audio-quality 0 )
    elif [ "$HAS_FFMPEG" = "1" ]; then
        ARGS+=( -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" )
    else
        # Birlestirici yok - tek dosyalik formatlarla yetin
        ARGS+=( -f "best[ext=mp4]/best" )
    fi

    if "$YTDLP" "${ARGS[@]}"; then
        echo
        say "$C_GREEN" "[+] Indirme tamamlandi -> $DOWNLOAD_DIR"
    else
        code=$?
        echo
        say "$C_RED" "[!] Indirme basarisiz (yt-dlp cikis kodu: $code)."
        say "$C_YELLOW" "    Bag yanlis olabilir, video erisime kapali olabilir,"
        say "$C_YELLOW" "    ya da yt-dlp guncel degildir. Guncellemek icin: $YTDLP -U"
    fi

    printf '%s\n\n' "${C_CYAN}-----------------------------------------${C_RESET}"
done
