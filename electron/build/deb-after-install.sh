#!/bin/bash
# Este arquivo SUBSTITUI o postinst gerado pelo electron-builder, nao acrescenta.
# Por isso repete o que o original fazia (symlink em /usr/bin e atualizacao das
# bases de mime e desktop) alem da correcao do sandbox.

APP_DIR='/opt/WhatsApp Linux'
BIN="$APP_DIR/whatsapp-linux"

if type update-alternatives 2>/dev/null >&1; then
    if [ -L '/usr/bin/whatsapp-linux' ] && [ -e '/usr/bin/whatsapp-linux' ] \
       && [ "$(readlink '/usr/bin/whatsapp-linux')" != '/etc/alternatives/whatsapp-linux' ]; then
        rm -f '/usr/bin/whatsapp-linux'
    fi
    update-alternatives --install '/usr/bin/whatsapp-linux' 'whatsapp-linux' "$BIN" 100 \
        || ln -sf "$BIN" '/usr/bin/whatsapp-linux'
else
    ln -sf "$BIN" '/usr/bin/whatsapp-linux'
fi

# O postinst padrao decide o modo do sandbox rodando "unshare --user true" COMO
# ROOT. No Ubuntu 24.04 o AppArmor bloqueia user namespace sem privilegio para o
# usuario comum, mas nao para o root: o teste passa, o chrome-sandbox fica 0755
# e o app nao abre para quem instalou. Forcar o SUID cobre os dois casos, e e o
# modo de sandbox que o proprio Chromium oferece para kernel sem userns usavel.
if [ -f "$APP_DIR/chrome-sandbox" ]; then
    chown root:root "$APP_DIR/chrome-sandbox" || true
    chmod 4755 "$APP_DIR/chrome-sandbox" || true
fi

if hash update-mime-database 2>/dev/null; then
    update-mime-database /usr/share/mime || true
fi
if hash update-desktop-database 2>/dev/null; then
    update-desktop-database /usr/share/applications || true
fi
