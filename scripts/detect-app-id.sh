#!/usr/bin/env bash
# KDE Wayland: descobre o app_id real da janela do WhatsApp Web e corrige o
# StartupWMClass da entrada de menu. Rode com a janela do app JA ABERTA.
#
# Motivo: no Wayland o Chromium ignora --class. O app_id vem do proprio navegador,
# no formato <produto>-<host>__-<perfil>. Se o StartupWMClass nao bater, a janela
# aparece na barra de tarefas sem icone e sem agrupar com o lancador.
#
# O filtro olha SO o resourceClass, nunca o titulo da janela. Filtrar por titulo
# casaria com qualquer janela que tenha "whatsapp" no nome, inclusive a aba do
# navegador comum, e gravaria a classe errada dizendo que acertou.
set -euo pipefail

: "${HOME:?HOME nao definido}"

DESKTOP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/applications/whatsapp-web.desktop"
QDBUS="$(command -v qdbus6 || command -v qdbus || true)"
MARK="WAAPPID$$"
SCRIPT_NAME="wa-appid-$$"

[ -f "$DESKTOP_FILE" ] || { echo "erro: $DESKTOP_FILE nao existe. Rode ./install.sh antes." >&2; exit 1; }
[ -n "$QDBUS" ] || { echo "erro: qdbus6/qdbus nao encontrado (pacote qt6-tools)." >&2; exit 1; }
$QDBUS org.kde.KWin >/dev/null 2>&1 || { echo "erro: KWin nao responde no dbus. Este script e so para KDE." >&2; exit 1; }

TMP_JS="$(mktemp --suffix=.js)"
trap 'rm -f "$TMP_JS"; $QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$SCRIPT_NAME" >/dev/null 2>&1 || true' EXIT

# So imprime o resourceClass, e so das janelas que sao o app.
# Modo leve: <produto>-web.whatsapp.com__-<perfil>. Modo tray: whatsapp-web.
cat > "$TMP_JS" <<JS
workspace.windowList().forEach(function (w) {
    var c = String(w.resourceClass);
    if (/web\.whatsapp\.com/.test(c) || c === "whatsapp-web") {
        print("$MARK|" + c);
    }
});
JS

# Janela de tempo curta: so o que este processo acabou de logar.
SINCE="$(date '+%Y-%m-%d %H:%M:%S')"
$QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$TMP_JS" "$SCRIPT_NAME" >/dev/null
$QDBUS org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null
sleep 1

APPID="$(journalctl --user --since "$SINCE" --no-pager 2>/dev/null \
    | sed -n "s/.*${MARK}|\([A-Za-z0-9._-]*\).*/\1/p" \
    | sort -u)"

QUANTOS="$(printf '%s' "$APPID" | grep -c . || true)"

if [ "$QUANTOS" -eq 0 ]; then
    echo "nao achei a janela do WhatsApp." >&2
    echo "Abra o app (whatsapp-web), espere carregar e rode de novo." >&2
    exit 1
fi
if [ "$QUANTOS" -gt 1 ]; then
    echo "achei mais de uma janela candidata, nao vou adivinhar:" >&2
    printf '  %s\n' $APPID >&2
    echo "Feche as extras e rode de novo." >&2
    exit 1
fi

ATUAL="$(sed -n 's/^StartupWMClass=//p' "$DESKTOP_FILE")"
if [ "$ATUAL" = "$APPID" ]; then
    echo "app_id ja estava correto: $APPID"
    exit 0
fi

# Substituicao sem sed para nao precisar escapar & e | no valor.
TMP_DESK="$(mktemp)"
while IFS= read -r linha; do
    case "$linha" in
        StartupWMClass=*) printf '%s\n' "StartupWMClass=$APPID" ;;
        *) printf '%s\n' "$linha" ;;
    esac
done < "$DESKTOP_FILE" > "$TMP_DESK"
mv "$TMP_DESK" "$DESKTOP_FILE"
chmod 644 "$DESKTOP_FILE"

command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$(dirname "$DESKTOP_FILE")" >/dev/null 2>&1 || true

echo "app_id detectado: $APPID"
echo "era:              ${ATUAL:-vazio}"
echo "StartupWMClass atualizado em $DESKTOP_FILE"
