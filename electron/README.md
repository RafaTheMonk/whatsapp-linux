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
| `WhatsAppLinux-1.0.4-x86_64.AppImage` | ~119 MB | qualquer distro, sem instalar |
| `whatsapp-linux_1.0.4_amd64.deb` | ~85 MB | Ubuntu, Mint, Debian, Pop!_OS |
| `whatsapp-linux-1.0.4-x64.tar.gz` | ~114 MB | descompactar e rodar, e a saída em distro sem `.deb` que tenha AppImageLauncher |

O `npm run dist` local serve para testar. Versão publicada sai do CI
(`.github/workflows/release.yml`), numa máquina limpa, com atestação de procedência:

```bash
# 1. subir "version" no package.json (e no package-lock.json) e commitar
# 2. opcional: notas da versão em electron/notas/vX.Y.Z.md; sem elas o GitHub
#    gera as notas pelos commits
git tag vX.Y.Z && git push origin main vX.Y.Z
# 3. o workflow cria a release em RASCUNHO; revisar e publicar:
gh release edit vX.Y.Z --draft=false
# 4. guardar os checksums no repositório, como segundo canal de conferência:
gh release download vX.Y.Z -p SHA256SUMS.txt -O SHA256SUMS.txt --clobber
git commit -am "chore: checksums dos pacotes da X.Y.Z" && git push
```

O CI gera x64 e arm64, cada um num runner nativo, e confere com `file` que o
binário é da arquitetura do nome antes de subir. A release sai com seis pacotes e
um `SHA256SUMS.txt` único. O `npm run dist` local gera só a arquitetura da máquina.

A tag tem que ser igual a `v` + `version` do `package.json`, que é o que o app
consulta; se não for, o workflow falha antes do build. Ele nunca publica sozinho:
release publicada vira aviso na bandeja de todo mundo em até um dia, então alguém
olha o rascunho antes. Para testar o workflow sem gastar versão:
`gh workflow run release.yml`, e os pacotes saem como artefato da execução.

`dist/` e `node_modules/` estão no `.gitignore`. Os binários não vão para o
repositório: publique em Releases ou num drive.

## O que o app faz

- Fecha para a bandeja no X, em vez de encerrar. A sessão continua conectada e as
  notificações continuam chegando.
- Contador de não lidas lido do título da página, desenhado sobre o ícone da bandeja
  (1 a 9 e "9+"), no tooltip e no badge. É o número do próprio WhatsApp, que conta
  conversas com mensagem não lida, não mensagens. Os ícones com número saem de
  `scripts/gerar-icones.py`.
- User agent de Chrome puro. O WhatsApp Web recusa quem se anuncia como Electron.
- Sem corretor ortográfico, de propósito: o do Chromium baixa o dicionário de um
  servidor do Google. Não basta `spellcheck: false` na janela, a sessão baixa um
  dicionário por idioma da lista; o app também esvazia essa lista.
- Permissões por lista fechada (notificação, mídia, área de transferência) e só
  para hosts do WhatsApp.
- Link externo abre no navegador padrão.
- Clique direito com texto selecionado ou na caixa de digitar abre o menu do sistema
  (copiar, colar, recortar, selecionar tudo). No resto fica o menu do próprio
  WhatsApp. O WhatsApp cancela o clique direito na página inteira, então um preload
  (`src/preload.js`) deixa o evento passar nesses dois casos, sem expor nada à página.
- Instância única: abrir de novo traz a janela existente.
- "Iniciar com o sistema" no menu da bandeja.
- "Suspender" no menu da bandeja fecha a página do WhatsApp e libera a memória dela:
  medido em 29/09/2026, o app caiu de ~840 MB para ~400 MB. O ícone fica cinza e,
  enquanto suspenso, **não chegam mensagens nem notificações**. Clicar no ícone
  recarrega o WhatsApp, com o login salvo. Nunca suspende sozinho. Os ~400 MB que
  sobram são o próprio Electron (processo principal, GPU, rede) e o service worker
  do WhatsApp, que o Electron não tem como parar.
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

O `app_id` da janela precisa casar com o `StartupWMClass` do `.desktop`
(`whatsapp-linux`); se não casa, a janela cai na barra de tarefas sem ícone. Quem
define o `app_id` não é o `app.setName`: no pacote ele vem do `executableName` do
`package.json` e no `npm start` do `name`, os dois `whatsapp-linux`. Mudar o
`app.setName` não muda o `app_id`. Medido no KDE Plasma sobre Wayland com
Electron 44, em 11/09/2026.

## Versão do Electron e atualização

O projeto pina a versão exata do Electron, sem caret, para o build ser
reproduzível. Hoje: **Electron 44.5.1, com Chromium 152**.

Isto não é detalhe de dependência, é postura de segurança. Um wrapper é um
navegador inteiro: entregar um Electron fora de suporte é entregar um navegador
com CVE conhecida para alguém que nem sabe que recebeu um navegador. A primeira
versão deste projeto saiu com Electron 33 (Chromium 130, de outubro de 2024), que
já estava fora de suporte e vulnerável a três CVEs de V8 no catálogo KEV da CISA.
Foi corrigido antes de qualquer distribuição.

Regra: **rebuild a cada release de segurança do Electron**, não a cada mudança de
funcionalidade. Confira a linha suportada em https://endoflife.date/electron.

O app não tem auto-update: não baixa nem instala nada sozinho. O que ele faz é
consultar a última release publicada no GitHub, no máximo uma vez por dia, e, se
houver versão mais nova, mostrar um item no menu da bandeja que abre a página de
downloads. Falha de rede e ausência de release são silenciosas de propósito.

É a única requisição que o app faz fora do WhatsApp, e o usuário desliga em
"Avisar sobre atualização", no próprio menu da bandeja. O `publish` do
electron-builder continua desligado, para não embutir um `app-update.yml` que o
código não usa.

## O .deb e o sandbox

O `postinst` do pacote é substituído por `build/deb-after-install.sh`. Motivo: o
script padrão do electron-builder decide o modo do sandbox rodando
`unshare --user true` **como root**. No Ubuntu 24.04 o AppArmor bloqueia user
namespace sem privilégio para o usuário comum, mas não para o root, então o teste
passa, o `chrome-sandbox` fica `0755` e o app não abre para quem instalou. O script
próprio força o SUID, que é o modo de sandbox que o Chromium oferece para kernel
sem userns utilizável, e repete o `update-alternatives` do original (o
`afterInstall` substitui o postinst inteiro, não acrescenta).

## Limites de cada formato

**AppImage** resolve dependência e distro, não resolve tudo:

- O bit de execução se perde ao baixar. Quem recebe precisa marcar como executável.
- Não aparece no menu sozinho. O app oferece criar o atalho na primeira execução.
- Precisa de FUSE 2. Ubuntu 22.04 e mais novos não trazem
  (`sudo apt install libfuse2`). Alternativa sem instalar nada:
  `./WhatsAppLinux-1.0.4-x86_64.AppImage --appimage-extract-and-run`
- No Ubuntu 24.04 o AppArmor bloqueia user namespace sem privilégio e o sandbox do
  Chromium falha. Use o `.deb`, que instala o `chrome-sandbox` com SUID e por isso
  não depende de user namespace. Não use `--no-sandbox`.

**AppImageLauncher**, se estiver instalado na máquina de quem baixa, intercepta a
execução de qualquer AppImage por `binfmt`, move o arquivo para `~/Applications`
renomeado com um hash, e cria uma entrada de menu própria que acrescenta
`--no-sandbox`. Ou seja: desliga uma camada de segurança do Chromium sem avisar
ninguém, e volta a fazer isso a cada execução, independente de onde o arquivo
esteja. Não há como o app impedir. Quem tem essa ferramenta deve usar o `.deb` ou
o `tar.gz`.

**deb** não tem nenhum desses problemas: instala, cria o atalho e configura o
`chrome-sandbox` com SUID. É o caminho recomendado para Ubuntu e derivados.

## Publicar num drive

Suba o `.AppImage` e o `.deb`, e junto o arquivo `DISTRIBUICAO.md` desta pasta,
que é o texto pronto para quem vai baixar.
