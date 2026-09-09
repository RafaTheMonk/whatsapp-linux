# Build Electron (pacote distribuível)

Esta pasta gera os instaladores para quem só quer baixar e usar, sem ter navegador
Chromium nem PyQt6 na máquina. O Chromium vai dentro do pacote.

## Gerar os pacotes

```bash
cd electron
npm install
# o npm 11 bloqueia o postinstall do Electron; libere uma vez:
node node_modules/electron/install.js
npm run dist          # AppImage + deb + tar.gz
npm run dist:appimage # só o AppImage
```

Saída em `electron/dist/`:

| Arquivo | Tamanho | Para quem |
|---|---|---|
| `WhatsAppLinux-1.0.0-x86_64.AppImage` | ~103 MB | qualquer distro, sem instalar |
| `whatsapp-linux_1.0.0_amd64.deb` | ~72 MB | Ubuntu, Mint, Debian, Pop!_OS |
| `whatsapp-linux-1.0.0.tar.gz` | ~98 MB | descompactar e rodar |

`dist/` e `node_modules/` estão no `.gitignore`. Os binários não vão para o
repositório: publique em Releases ou num drive.

## O que o app faz

- Fecha para a bandeja no X, em vez de encerrar. A sessão continua conectada e as
  notificações continuam chegando.
- Contador de não lidas lido do título da página, no tooltip da bandeja e no badge.
- User agent de Chrome puro. O WhatsApp Web recusa quem se anuncia como Electron.
- Permissões por lista fechada (notificação, mídia, área de transferência) e só
  para hosts do WhatsApp.
- Link externo abre no navegador padrão.
- Instância única: abrir de novo traz a janela existente.
- "Iniciar com o sistema" no menu da bandeja.
- Primeira execução do AppImage oferece criar o atalho no menu de aplicativos.

## Onde ficam os dados

`~/.config/whatsapp-linux/`, com permissão `700`.

O caminho é fixado no código com `app.setPath("userData", ...)`. Sem isso, em build
empacotado o Electron deriva o diretório do `productName` e cria
`~/.config/WhatsApp Linux`, com espaço, diferente do `app_id` e do nome do
`.desktop`. Quem já rodou a versão anterior tem o diretório antigo renomeado
automaticamente na primeira execução, sem perder o login.

Para apagar a sessão: feche o app e remova esse diretório. Isso não desvincula o
dispositivo, que continua listado no celular até você remover em Dispositivos
conectados.

## app_id no Wayland

No Wayland o Electron usa o nome do app como `app_id` da janela. Por isso o código
chama `app.setName("whatsapp-linux")`, igual ao `StartupWMClass` do `.desktop`.
Com `app.setName("WhatsApp Linux")` o `app_id` sai com espaço, não casa, e a janela
cai na barra de tarefas sem ícone. Medido no KDE Plasma sobre Wayland.

## Limites de cada formato

**AppImage** resolve dependência e distro, não resolve tudo:

- O bit de execução se perde ao baixar. Quem recebe precisa marcar como executável.
- Não aparece no menu sozinho. O app oferece criar o atalho na primeira execução.
- Precisa de FUSE 2. Ubuntu 22.04 e mais novos não trazem
  (`sudo apt install libfuse2`). Alternativa sem instalar nada:
  `./WhatsAppLinux-1.0.0-x86_64.AppImage --appimage-extract-and-run`
- No Ubuntu 24.04 o AppArmor bloqueia user namespace sem privilégio e o sandbox do
  Chromium falha. Contornos: usar o `.deb`, ou rodar com `--no-sandbox` (que
  desliga uma camada de segurança, então prefira o `.deb`).

**deb** não tem nenhum desses problemas: instala, cria o atalho e configura o
`chrome-sandbox` com SUID. É o caminho recomendado para Ubuntu e derivados.

## Publicar num drive

Suba o `.AppImage` e o `.deb`, e junto o arquivo `DISTRIBUICAO.md` desta pasta,
que é o texto pronto para quem vai baixar.
