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

: "${HOME:?HOME nao definido}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/whatsapp-web"

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

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR/scalable/apps" "$CONF_DIR"

# 1. icone: SVG sempre, PNGs quando houver rasterizador
install -m 644 "$REPO_DIR/src/whatsapp-web.svg" "$ICON_DIR/scalable/apps/whatsapp-web.svg"
rasterizar() {  # $1 = tamanho, $2 = destino
    case "$RASTER" in
        rsvg-convert) rsvg-convert -w "$1" -h "$1" -o "$2" "$REPO_DIR/src/whatsapp-web.svg" ;;
        # -density antes do input: o ImageMagick rasteriza o SVG no tamanho certo
        # em vez de ampliar um bitmap pequeno e entregar icone borrado.
        magick)  magick -background none -density 384 "$REPO_DIR/src/whatsapp-web.svg" -resize "${1}x${1}" "$2" ;;
        convert) convert -background none -density 384 "$REPO_DIR/src/whatsapp-web.svg" -resize "${1}x${1}" "$2" ;;
    esac
}
RASTER=""
for r in rsvg-convert magick convert; do
    command -v "$r" >/dev/null 2>&1 && { RASTER="$r"; break; }
done
if [ -n "$RASTER" ]; then
    falhou=0
    for s in 16 22 24 32 48 64 128 256 512; do
        mkdir -p "$ICON_DIR/${s}x${s}/apps"
        rasterizar "$s" "$ICON_DIR/${s}x${s}/apps/whatsapp-web.png" 2>/dev/null || falhou=1
    done
    if [ "$falhou" = 0 ]; then
        echo "icone     -> SVG + PNG 16..512 ($RASTER)"
    else
        echo "icone     -> SVG ok, PNGs falharam com $RASTER (o SVG sozinho ja serve)"
    fi
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
    [ -n "$BROWSER" ] || { echo "erro: nenhum navegador Chromium encontrado. Use --modo tray ou instale o Brave/Chromium." >&2; exit 1; }

    # Grava o navegador escolhido para o lancador usar o MESMO da instalacao.
    # Sem isso, instalar com um e executar com outro faz o app_id divergir.
    printf '%s\n' "$BROWSER" > "$CONF_DIR/browser"

    # O prefixo do app_id e o nome do binario COMPILADO (kBrowserProcessExecutableName),
    # nao o nome do wrapper no PATH. Por isso chromium vira "chrome": o Arch, o Debian,
    # o Fedora, o snap e o flatpak renomeiam o arquivo, mas a constante continua chrome.
    # Nao "corrija" isso de volta sem medir com scripts/detect-app-id.sh.
    case "$BROWSER" in
        brave*)          PREFIX="brave" ;;        # medido
        chromium*)       PREFIX="chrome" ;;       # medido
        google-chrome*)  PREFIX="chrome" ;;
        microsoft-edge*) PREFIX="msedge" ;;
        vivaldi*)        PREFIX="vivaldi-bin" ;;  # nao medido, confira com detect-app-id.sh
        *)               PREFIX="chrome" ;;
    esac
    WMCLASS="${PREFIX}-web.whatsapp.com__-Default"
    DETALHE="janela do $BROWSER em --app"
fi
echo "lancador  -> $BIN_DIR/whatsapp-web"

# 3. entrada de menu.
# Substituicao feita no bash, sem sed: caminho com & ou | quebraria o sed
# silenciosamente e deixaria um .desktop corrompido no menu.
DESKTOP_OUT="$APP_DIR/whatsapp-web.desktop"

# Se o detect-app-id.sh ja mediu o app_id real desta maquina, esse valor vale
# mais que o nosso palpite por navegador. Preserva na reinstalacao.
if [ "$MODO" = "leve" ] && [ -f "$DESKTOP_OUT" ]; then
    MEDIDO="$(sed -n 's/^StartupWMClass=//p' "$DESKTOP_OUT")"
    case "$MEDIDO" in
        *web.whatsapp.com*)
            if [ "$MEDIDO" != "$WMCLASS" ]; then
                echo "mantendo o StartupWMClass ja medido nesta maquina: $MEDIDO"
                WMCLASS="$MEDIDO"
            fi
            ;;
    esac
fi
TMP_DESK="$(mktemp)"
while IFS= read -r linha || [ -n "$linha" ]; do
    linha="${linha//@EXEC@/$BIN_DIR/whatsapp-web}"
    linha="${linha//@WMCLASS@/$WMCLASS}"
    printf '%s\n' "$linha"
done < "$REPO_DIR/src/whatsapp-web.desktop.in" > "$TMP_DESK"
mv "$TMP_DESK" "$DESKTOP_OUT"
chmod 644 "$DESKTOP_OUT"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "menu      -> $DESKTOP_OUT"

echo
echo "modo instalado: $MODO ($DETALHE)"
echo "StartupWMClass: $WMCLASS"
echo

case ":$PATH:" in
    *":$BIN_DIR:"*) echo "Abra pelo menu do desktop ou rode: whatsapp-web" ;;
    *)
        echo "Abra pelo menu do desktop, ou rode pelo caminho completo:"
        echo "  $BIN_DIR/whatsapp-web"
        echo "($BIN_DIR nao esta no seu PATH)"
        ;;
esac
[ "$MODO" = "leve" ] && echo "Se a janela aparecer na barra sem icone, rode: ./scripts/detect-app-id.sh"
exit 0
