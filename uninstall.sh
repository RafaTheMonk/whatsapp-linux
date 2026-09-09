#!/usr/bin/env bash
# Remove o app. Por padrao preserva o perfil (sessao logada).
# Use --purge para apagar tambem perfil e cache, mandando para a lixeira.
set -euo pipefail

: "${HOME:?HOME nao definido}"

BIN_DIR="$HOME/.local/bin"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/whatsapp-web"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/whatsapp-web"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/whatsapp-web"
AUTOSTART="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/whatsapp-web.desktop"

rm -f "$BIN_DIR/whatsapp-web" "$BIN_DIR/whatsapp-web.svg"
rm -f "$APP_DIR/whatsapp-web.desktop"
rm -f "$AUTOSTART"
rm -f "$ICON_DIR"/*/apps/whatsapp-web.png "$ICON_DIR/scalable/apps/whatsapp-web.svg"
rm -f "$CONF_DIR/browser" "$CONF_DIR/tray.conf"
rmdir "$CONF_DIR" 2>/dev/null || true
# ate a v1 os modos shell dividiam ~/.config/whatsapp-linux com o app Electron.
rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/whatsapp-linux/browser" \
      "${XDG_CONFIG_HOME:-$HOME/.config}/whatsapp-linux/tray.conf" 2>/dev/null || true
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
echo "removidos: lancador, entrada de menu, icones, autostart"

if [ "${1:-}" = "--purge" ]; then
    for alvo in "$DATA_DIR" "$CACHE_DIR"; do
        [ -d "$alvo" ] || continue
        if command -v gio >/dev/null 2>&1; then
            gio trash "$alvo" && echo "enviado para a lixeira: $alvo"
        else
            echo "gio nao encontrado. Apague manualmente: $alvo"
        fi
    done
    echo
    echo "Apagar o perfil NAO desvincula o dispositivo do WhatsApp."
    echo "A sessao continua listada no celular ate voce remover na mao:"
    echo "  WhatsApp no celular > Dispositivos conectados > desconectar."
    echo "Ate la os dados do perfil seguem na lixeira, recuperaveis."
else
    echo "perfil preservado em $DATA_DIR (use --purge para remover)"
fi
