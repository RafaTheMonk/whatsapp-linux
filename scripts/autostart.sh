#!/usr/bin/env bash
# Liga ou desliga a abertura automatica junto com a sessao.
# No modo tray o app sobe ja escondido na bandeja.
set -euo pipefail
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/applications/whatsapp-web.desktop"
DST="$HOME/.config/autostart/whatsapp-web.desktop"

case "${1:-on}" in
    on)
        [ -f "$SRC" ] || { echo "erro: rode ./install.sh antes." >&2; exit 1; }
        mkdir -p "$(dirname "$DST")"
        cp "$SRC" "$DST"
        # Modo tray: subir oculto. Detecta pelo shebang do lancador.
        EXEC_BIN="$(sed -n 's/^Exec=//p' "$DST" | awk '{print $1}')"
        if head -1 "$EXEC_BIN" 2>/dev/null | grep -q python; then
            sed -i 's|^Exec=\(.*\)$|Exec=\1 --hidden|' "$DST"
            echo "autostart ligado (inicia oculto na bandeja): $DST"
        else
            echo "autostart ligado: $DST"
        fi
        ;;
    off)
        rm -f "$DST"
        echo "autostart desligado"
        ;;
    *)
        echo "uso: $0 [on|off]" >&2; exit 1 ;;
esac
