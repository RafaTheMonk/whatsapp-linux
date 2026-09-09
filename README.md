# WhatsApp Web como app no Linux

App standalone do WhatsApp Web para Linux, sem Electron e sem dependência nova.
Usa o navegador baseado em Chromium que já está na máquina, em modo `--app`, com
perfil isolado. O resultado é uma janela própria, ícone no menu, entrada na barra
de tarefas e notificações do sistema.

Testado em CachyOS com KDE Plasma sobre Wayland e Brave. Deve funcionar em
qualquer distro com um navegador Chromium instalado.

## Por que isso existe

Não existe cliente nativo oficial do WhatsApp para Linux. A Meta lança versão
desktop para Windows e macOS, mas no Linux só sobra o WhatsApp Web. Quem vem do
Windows sente falta da janela separada, do ícone no menu e das notificações.

Os caminhos possíveis:

| Caminho | Veredito |
|---|---|
| Aba fixada no navegador | Funciona, mas se perde no meio das outras abas e morre junto com o navegador |
| PWA instalado pelo próprio navegador | Bom. É o que este projeto faz, com perfil isolado por cima |
| Wrapper pronto de terceiro (ZapZap, whatsapp-for-linux) | Bom, e tem bandeja. Custo: mais um projeto de terceiro no caminho da sua sessão |
| Nativefier | Arquivado pelo autor, sem manutenção. Gera build Electron com Chromium velho, o WhatsApp Web reclama de navegador sem suporte. Não usar |
| Electron escrito na mão | Funciona e dá controle total. Custo: ~200 MB de runtime e a manutenção fica com você |

A escolha aqui foi a de menor superfície: o que roda é o Chromium que já estava
instalado, apontando para o site oficial. Nenhum binário novo, nenhum runtime
extra, nenhum código de terceiro entre você e o WhatsApp.

## O que é instalado

Nada precisa de root. Tudo vai para `~/.local`.

| Caminho | Papel |
|---|---|
| `~/.local/bin/whatsapp-web` | script que sobe a janela |
| `~/.local/share/applications/whatsapp-web.desktop` | entrada no menu do desktop |
| `~/.local/share/icons/hicolor/*/apps/whatsapp-web.*` | ícone, SVG e PNG de 16 a 512 |
| `~/.local/share/whatsapp-web/profile/` | perfil isolado, guarda a sessão logada |

## Instalação

```bash
git clone <url-do-repo> whatsapp-linux
cd whatsapp-linux
./install.sh
```

Depois abra "WhatsApp Web" no menu do desktop, ou rode `whatsapp-web` no terminal.
Escaneie o QR uma vez. A sessão fica no perfil isolado e persiste entre reinícios.

Para escolher o navegador manualmente:

```bash
WHATSAPP_WEB_BROWSER=chromium ./install.sh
```

## Como funciona

O núcleo é uma linha só:

```bash
brave --app=https://web.whatsapp.com/ --user-data-dir=~/.local/share/whatsapp-web/profile
```

`--app` abre a página em modo aplicativo: sem abas, sem barra de endereços, sem
menu do navegador. `--user-data-dir` aponta para um perfil separado, o que dá três
coisas de graça:

1. A sessão do WhatsApp não se mistura com a do navegador do dia a dia.
2. Fechar o navegador principal não derruba o WhatsApp, são processos separados.
3. Extensões e configurações do seu perfil normal não interferem na página.

O resto do projeto é empacotamento: ícone em vários tamanhos, entrada `.desktop`
válida, detecção de navegador e desinstalação limpa.

## A pegadinha do Wayland

No KDE Plasma sobre Wayland o Chromium **ignora** `--class`. O `app_id` da janela é
montado pelo próprio navegador no formato `<produto>-<host>__-<perfil>`. No caso do
Brave:

```
brave-web.whatsapp.com__-Default
```

Se o `StartupWMClass` do arquivo `.desktop` não bater com esse valor, a janela
aparece na barra de tarefas sem ícone e sem agrupar com o lançador. O `install.sh`
já monta o valor certo por navegador. Se mesmo assim ficar errado, abra o app e
rode:

```bash
./scripts/detect-app-id.sh
```

Ele pergunta ao KWin qual o `app_id` real da janela aberta e corrige o `.desktop`.
Por baixo é um script KWin carregado via D-Bus:

```bash
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /tmp/winlist.js winlist
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start
journalctl --user -b -n 200 --no-pager | grep -o 'WINDBG|[^"]*'
```

Serve para descobrir o `app_id` de qualquer janela, não só desta.

## Abrir junto com a sessão

```bash
./scripts/autostart.sh on    # liga
./scripts/autostart.sh off   # desliga
```

## Desinstalação

```bash
./uninstall.sh           # remove app, mantém a sessão logada
./uninstall.sh --purge   # remove também o perfil, mandando para a lixeira
```

## Limitações conhecidas

- **Sem ícone de bandeja e sem "fechar para a bandeja".** Fechar a janela encerra
  o app. É a diferença real para o ZapZap e o whatsapp-for-linux.
- **Notificações** exigem aceitar a permissão do site na primeira vez. Depois
  chegam pelo sistema de notificações do desktop.
- Consome mais ou menos o mesmo que uma aba do navegador, em processo separado.

Se a falta de bandeja incomodar, o **ZapZap** (`paru -S zapzap` ou
`flatpak install flathub com.rtosta.zapzap`) é a melhor alternativa: PyQt6, integra
bem no KDE, mantido ativamente.

## Segurança

- O sandbox do Chromium continua ativo. Nenhuma flag do projeto o enfraquece.
- Nenhum código de terceiro roda: o alvo é `https://web.whatsapp.com/`, o site
  oficial, no mesmo motor de renderização que você já usa para tudo.
- A criptografia ponta a ponta do WhatsApp não é afetada. O wrapper não fica no
  meio da conversa, só desenha a janela.
- O perfil isolado guarda as credenciais de sessão em `~/.local/share/whatsapp-web/profile`,
  com a mesma proteção que o navegador dá ao seu perfil normal. Quem tiver acesso
  de leitura à sua conta de usuário tem acesso à sessão. Vale o mesmo cuidado de
  sempre com disco não criptografado.

## Licença

MIT.
