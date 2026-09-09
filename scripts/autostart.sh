#!/usr/bin/env bash
# Liga ou desliga a abertura automatica junto com a sessao.
# No modo tray o app sobe ja escondido na bandeja.
set -euo pipefail

: "${HOME:?HOME nao definido}"

SRC="${XDG_DATA_HOME:-$HOME/.local/share}/applications/whatsapp-web.desktop"
DST="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/whatsapp-web.desktop"

case "${1:-on}" in
    on)
        [ -f "$SRC" ] || { echo "erro: rode ./install.sh antes." >&2; exit 1; }
        mkdir -p "$(dirname "$DST")"
        cp "$SRC" "$DST"
        # Modo tray: subir oculto. Detecta pelo shebang do lancador.
        EXEC_LINE="$(sed -n 's/^Exec=//p' "$DST")"
        EXEC_BIN="${EXEC_LINE%% *}"
        EXEC_BIN="${EXEC_BIN%\"}"
        EXEC_BIN="${EXEC_BIN#\"}"
        if head -1 "$EXEC_BIN" 2>/dev/null | grep -q python; then
            TMP="$(mktemp)"
            while IFS= read -r linha || [ -n "$linha" ]; do
                case "$linha" in
                    Exec=*) printf '%s\n' "$linha --hidden" ;;
                    *) printf '%s\n' "$linha" ;;
                esac
            done < "$DST" > "$TMP"
            mv "$TMP" "$DST"
            chmod 644 "$DST"
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
