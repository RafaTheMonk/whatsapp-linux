#!/usr/bin/env bash
# Instala o WhatsApp Web como app standalone no menu do desktop.
# Nao precisa de root: tudo vai para ~/.local.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR/scalable/apps"

# 1. lancador
install -m 755 "$REPO_DIR/src/whatsapp-web" "$BIN_DIR/whatsapp-web"
echo "lancador  -> $BIN_DIR/whatsapp-web"

# 2. icone: SVG sempre, PNGs quando houver rasterizador
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
    echo "icone     -> SVG + PNG 16..512 em $ICON_DIR"
else
    echo "icone     -> so SVG (instale librsvg ou imagemagick para gerar os PNGs)"
fi
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$ICON_DIR" >/dev/null 2>&1 || true

# 3. StartupWMClass depende do navegador que sera usado.
#    O Chromium monta o app_id como <produto>-<host>__-<perfil>.
BROWSER="${WHATSAPP_WEB_BROWSER:-}"
if [ -z "$BROWSER" ]; then
    for b in brave brave-browser chromium chromium-browser google-chrome-stable google-chrome microsoft-edge-stable microsoft-edge vivaldi-stable vivaldi; do
        if command -v "$b" >/dev/null 2>&1; then BROWSER="$b"; break; fi
    done
fi
case "$BROWSER" in
    brave*)          PREFIX="brave" ;;
    chromium*)       PREFIX="chromium" ;;
    google-chrome*)  PREFIX="chrome" ;;
    microsoft-edge*) PREFIX="msedge" ;;
    vivaldi*)        PREFIX="vivaldi" ;;
    *)               PREFIX="chrome" ;;
esac
WMCLASS="${PREFIX}-web.whatsapp.com__-Default"

# 4. entrada de menu
sed -e "s|@EXEC@|$BIN_DIR/whatsapp-web|" \
    -e "s|@WMCLASS@|$WMCLASS|" \
    "$REPO_DIR/src/whatsapp-web.desktop.in" > "$APP_DIR/whatsapp-web.desktop"
chmod 644 "$APP_DIR/whatsapp-web.desktop"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "menu      -> $APP_DIR/whatsapp-web.desktop"

echo
echo "navegador detectado: ${BROWSER:-nenhum}"
echo "StartupWMClass:      $WMCLASS"
echo
echo "Pronto. Abra pelo menu do desktop ou rode: whatsapp-web"
echo "Se a janela aparecer na barra de tarefas sem icone, rode: ./scripts/detect-app-id.sh"
