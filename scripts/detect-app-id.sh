#!/usr/bin/env bash
# KDE Wayland: descobre o app_id real da janela do WhatsApp Web e corrige o
# StartupWMClass da entrada de menu. Rode com a janela do app JA ABERTA.
#
# Motivo: no Wayland o Chromium ignora --class. O app_id vem do proprio navegador,
# no formato <produto>-<host>__-<perfil>. Se o StartupWMClass nao bater, a janela
# aparece na barra de tarefas sem icone e sem agrupar com o lancador.
set -euo pipefail

DESKTOP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/applications/whatsapp-web.desktop"
QDBUS="$(command -v qdbus6 || command -v qdbus || true)"

[ -f "$DESKTOP_FILE" ] && : || { echo "erro: $DESKTOP_FILE nao existe. Rode ./install.sh antes." >&2; exit 1; }
[ -n "$QDBUS" ] || { echo "erro: qdbus6/qdbus nao encontrado (pacote qt6-tools)." >&2; exit 1; }
$QDBUS org.kde.KWin >/dev/null 2>&1 || { echo "erro: KWin nao responde no dbus. Este script e so para KDE." >&2; exit 1; }

TMP_JS="$(mktemp --suffix=.js)"
trap 'rm -f "$TMP_JS"' EXIT
cat > "$TMP_JS" <<'JS'
workspace.windowList().forEach(function (w) {
    print("WAAPPID|" + w.resourceClass + "|" + w.caption);
});
JS

$QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$TMP_JS" wa-appid >/dev/null
$QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null
sleep 1

APPID="$(journalctl --user -b -n 300 --no-pager 2>/dev/null \
    | grep -o 'WAAPPID|[^|]*|[^"]*' \
    | grep -i 'whatsapp' \
    | tail -1 | cut -d'|' -f2 || true)"

if [ -z "$APPID" ]; then
    echo "nao achei a janela. Abra o app (whatsapp-web) e rode de novo." >&2
    exit 1
fi

sed -i "s|^StartupWMClass=.*|StartupWMClass=$APPID|" "$DESKTOP_FILE"
command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$(dirname "$DESKTOP_FILE")" >/dev/null 2>&1 || true
echo "app_id detectado: $APPID"
echo "StartupWMClass atualizado em $DESKTOP_FILE"
