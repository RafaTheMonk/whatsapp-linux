#!/usr/bin/env bash
# Instala o WhatsApp Web como app standalone. Nao precisa de root: tudo em ~/.local.
#
# Modos:
#   --modo leve   janela do Chromium em --app. Zero dependencia nova.
#                 Fechar no X encerra o app.
#   --modo tray   app Qt proprio, com icone na bandeja. Fechar no X esconde
#                 para a bandeja e a sessao continua conectada.
#                 Requer python-pyqt6 e python-pyqt6-webengine.
#   --modo auto   (padrao) usa tray se as dependencias existirem, senao leve.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"

MODO="auto"
while [ $# -gt 0 ]; do
    case "$1" in
        --modo) MODO="${2:-auto}"; shift 2 ;;
        --modo=*) MODO="${1#*=}"; shift ;;
        --tray) MODO="tray"; shift ;;
        --leve) MODO="leve"; shift ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "opcao desconhecida: $1" >&2; exit 1 ;;
    esac
done

tem_pyqt() {
    command -v python3 >/dev/null 2>&1 || return 1
    python3 - <<'PY' >/dev/null 2>&1
import PyQt6.QtWidgets, PyQt6.QtWebEngineWidgets
PY
}

case "$MODO" in
    auto)
        if tem_pyqt; then MODO="tray"; else
            MODO="leve"
            echo "PyQt6 nao encontrado, instalando o modo leve."
            echo "Para o modo com bandeja: sudo pacman -S python-pyqt6 python-pyqt6-webengine"
            echo
        fi
        ;;
    tray)
        if ! tem_pyqt; then
            echo "erro: modo tray precisa de PyQt6 e PyQt6-WebEngine." >&2
            echo "  Arch/CachyOS: sudo pacman -S python-pyqt6 python-pyqt6-webengine" >&2
            echo "  Debian/Ubuntu: sudo apt install python3-pyqt6 python3-pyqt6.qtwebengine" >&2
            echo "  Fedora: sudo dnf install python3-pyqt6 python3-pyqt6-webengine" >&2
            exit 1
        fi
        ;;
    leve) ;;
    *) echo "modo invalido: $MODO (use leve, tray ou auto)" >&2; exit 1 ;;
esac

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR/scalable/apps"

# 1. icone: SVG sempre, PNGs quando houver rasterizador
install -m 644 "$REPO_DIR/src/whatsapp-web.svg" "$ICON_DIR/scalable/apps/whatsapp-web.svg"
RASTER=""
command -v rsvg-convert >/dev/null 2>&1 && RASTER=rsvg-convert
[ -z "$RASTER" ] && command -v magick >/dev/null 2>&1 && RASTER=magick
if [ -n "$RASTER" ]; then
    for s in 16 22 24 32 48 64 128 256 512; do
        mkdir -p "$ICON_DIR/${s}x${s}/apps"
        if [ "$RASTER" = "rsvg-convert" ]; then
            rsvg-convert -w "$s" -h "$s" -o "$ICON_DIR/${s}x${s}/apps/whatsapp-web.png" "$REPO_DIR/src/whatsapp-web.svg"
        else
            magick -background none "$REPO_DIR/src/whatsapp-web.svg" -resize "${s}x${s}" "$ICON_DIR/${s}x${s}/apps/whatsapp-web.png"
        fi
    done
    echo "icone     -> SVG + PNG 16..512"
else
    echo "icone     -> so SVG (instale librsvg ou imagemagick para gerar os PNGs)"
fi
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$ICON_DIR" >/dev/null 2>&1 || true

# 2. lancador e StartupWMClass, que dependem do modo
if [ "$MODO" = "tray" ]; then
    install -m 755 "$REPO_DIR/src/whatsapp-tray.py" "$BIN_DIR/whatsapp-web"
    install -m 644 "$REPO_DIR/src/whatsapp-web.svg" "$BIN_DIR/whatsapp-web.svg"
    # O Qt usa setDesktopFileName("whatsapp-web") como app_id no Wayland.
    WMCLASS="whatsapp-web"
    DETALHE="app Qt com bandeja"
else
    install -m 755 "$REPO_DIR/src/whatsapp-web" "$BIN_DIR/whatsapp-web"
    BROWSER="${WHATSAPP_WEB_BROWSER:-}"
    if [ -z "$BROWSER" ]; then
        for b in brave brave-browser chromium chromium-browser google-chrome-stable google-chrome microsoft-edge-stable microsoft-edge vivaldi-stable vivaldi; do
            if command -v "$b" >/dev/null 2>&1; then BROWSER="$b"; break; fi
        done
    fi
    # O Chromium monta o app_id como <produto>-<host>__-<perfil>.
    case "$BROWSER" in
        brave*)          PREFIX="brave" ;;
        chromium*)       PREFIX="chromium" ;;
        google-chrome*)  PREFIX="chrome" ;;
        microsoft-edge*) PREFIX="msedge" ;;
        vivaldi*)        PREFIX="vivaldi" ;;
        *)               PREFIX="chrome" ;;
    esac
    WMCLASS="${PREFIX}-web.whatsapp.com__-Default"
    DETALHE="janela do ${BROWSER:-navegador} em --app"
fi
echo "lancador  -> $BIN_DIR/whatsapp-web"

# 3. entrada de menu
sed -e "s|@EXEC@|$BIN_DIR/whatsapp-web|" \
    -e "s|@WMCLASS@|$WMCLASS|" \
    "$REPO_DIR/src/whatsapp-web.desktop.in" > "$APP_DIR/whatsapp-web.desktop"
chmod 644 "$APP_DIR/whatsapp-web.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "menu      -> $APP_DIR/whatsapp-web.desktop"

echo
echo "modo instalado: $MODO ($DETALHE)"
echo "StartupWMClass: $WMCLASS"
echo
echo "Abra pelo menu do desktop ou rode: whatsapp-web"
[ "$MODO" = "leve" ] && echo "Se a janela aparecer na barra sem icone, rode: ./scripts/detect-app-id.sh"
exit 0
