#!/usr/bin/env bash
# Liga ou desliga a abertura automatica junto com a sessao.
set -euo pipefail
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/applications/whatsapp-web.desktop"
DST="$HOME/.config/autostart/whatsapp-web.desktop"

case "${1:-on}" in
    on)
        [ -f "$SRC" ] || { echo "erro: rode ./install.sh antes." >&2; exit 1; }
        mkdir -p "$(dirname "$DST")"
        cp "$SRC" "$DST"
        echo "autostart ligado: $DST"
        ;;
    off)
        rm -f "$DST"
        echo "autostart desligado"
        ;;
    *)
        echo "uso: $0 [on|off]" >&2; exit 1 ;;
esac
