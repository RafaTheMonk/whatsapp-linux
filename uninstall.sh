#!/usr/bin/env bash
# Remove o app. Por padrao preserva o perfil (sessao logada).
# Use --purge para apagar tambem o perfil, mandando para a lixeira.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/whatsapp-web"

rm -f "$BIN_DIR/whatsapp-web"
rm -f "$APP_DIR/whatsapp-web.desktop"
rm -f "$HOME/.config/autostart/whatsapp-web.desktop"
rm -f "$ICON_DIR"/*/apps/whatsapp-web.png "$ICON_DIR/scalable/apps/whatsapp-web.svg"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "removidos: lancador, entrada de menu, icones, autostart"

if [ "${1:-}" = "--purge" ]; then
    if [ -d "$DATA_DIR" ]; then
        if command -v gio >/dev/null 2>&1; then
            gio trash "$DATA_DIR"
            echo "perfil enviado para a lixeira: $DATA_DIR"
        else
            echo "gio nao encontrado. Apague manualmente: $DATA_DIR"
        fi
    fi
else
    echo "perfil preservado em $DATA_DIR (use --purge para remover)"
fi
