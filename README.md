# WhatsApp Web como app no Linux

App standalone do WhatsApp Web para Linux, em dois modos. Janela própria, ícone no
menu, notificações do sistema e, no modo tray, ícone na bandeja com fechar para
segundo plano.

Testado em CachyOS com KDE Plasma sobre Wayland. Deve funcionar em qualquer distro.

## Por que isso existe

Não existe cliente nativo oficial do WhatsApp para Linux. A Meta lança versão
desktop para Windows e macOS, mas no Linux só sobra o WhatsApp Web. Quem vem do
Windows sente falta da janela separada, do ícone no menu, das notificações e do
app que continua rodando em segundo plano quando você fecha a janela.

Os caminhos possíveis:

| Caminho | Veredito |
|---|---|
| Aba fixada no navegador | Funciona, mas se perde no meio das outras abas e morre junto com o navegador |
| PWA instalado pelo próprio navegador | Bom. É o modo leve deste projeto, com perfil isolado por cima |
| Wrapper pronto de terceiro (ZapZap, whatsapp-for-linux) | Bom, e tem bandeja. Custo: mais um projeto de terceiro na sua sessão |
| Nativefier | Arquivado pelo autor, sem manutenção. Gera build Electron com Chromium velho, o WhatsApp Web reclama de navegador sem suporte. Não usar |
| Electron escrito na mão | Funciona e dá controle total. Custo: ~200 MB de runtime só para embrulhar um site |

Este projeto não usa Electron em nenhum dos dois modos.

## As três formas

| | modo leve | modo tray | pacote Electron |
|---|---|---|---|
| Motor | Chromium já instalado, em `--app` | QtWebEngine, via PyQt6 | Chromium embutido |
| Dependência nova | nenhuma | `python-pyqt6`, `python-pyqt6-webengine` | nenhuma, vai tudo dentro |
| Ícone na bandeja | não | sim, com contador de não lidas | sim, com contador |
| Fechar no X | encerra o app | esconde para a bandeja | esconde para a bandeja |
| Notificação com a janela fechada | não | sim | sim |
| Peso em disco | 0 | ~26 MB de bindings | ~103 MB (AppImage) ou ~72 MB (deb) |
| Para quem | você, nesta máquina | você, quer bandeja e economia | **distribuir para outras pessoas** |

As duas primeiras são scripts que rodam da própria pasta do repositório. A terceira
é um pacote pronto (`AppImage`, `.deb`, `tar.gz`) para mandar para alguém que só
quer baixar e usar. Detalhes de build e distribuição em [`electron/README.md`](electron/README.md).

O modo tray existe porque o WhatsApp Web não desconecta quando você fecha a janela.
Fechar no X e ter que reabrir e esperar carregar de novo é desperdício: o normal é o
app continuar em segundo plano recebendo mensagem, como no Windows.

## Instalação

```bash
git clone https://github.com/RafaTheMonk/whatsapp-linux
cd whatsapp-linux
./install.sh                 # auto: tray se houver PyQt6, senão leve
./install.sh --modo tray     # força o modo com bandeja
./install.sh --modo leve     # força o modo sem dependência
```

Para gerar o pacote distribuível em vez de instalar aqui:

```bash
cd electron && npm install && npm run dist
```

Dependências do modo tray:

```bash
# Arch / CachyOS
sudo pacman -S python-pyqt6 python-pyqt6-webengine
# Debian / Ubuntu
sudo apt install python3-pyqt6 python3-pyqt6.qtwebengine
# Fedora
sudo dnf install python3-pyqt6 python3-pyqt6-webengine
```

Depois abra "WhatsApp Web" no menu, ou rode `whatsapp-web`. Escaneie o QR uma vez.
A sessão fica no perfil do app e persiste entre reinícios.

Nada precisa de root. Tudo vai para `~/.local`.

| Caminho | Papel |
|---|---|
| `~/.local/bin/whatsapp-web` | lançador do modo instalado |
| `~/.local/share/applications/whatsapp-web.desktop` | entrada no menu |
| `~/.local/share/icons/hicolor/*/apps/whatsapp-web.*` | ícone, SVG e PNG de 16 a 512 |
| `~/.local/share/whatsapp-web/profile/` | perfil do modo leve |
| `~/.local/share/whatsapp-web/qt-profile/` | perfil do modo tray |

## Como funciona o modo leve

O núcleo é uma linha só:

```bash
brave --app=https://web.whatsapp.com/ --user-data-dir=~/.local/share/whatsapp-web/profile
```

`--app` abre a página em modo aplicativo: sem abas, sem barra de endereços, sem menu
do navegador. `--user-data-dir` aponta para um perfil separado, o que dá três coisas
de graça:

1. A sessão do WhatsApp não se mistura com a do navegador do dia a dia.
2. Fechar o navegador principal não derruba o WhatsApp, são processos separados.
3. Extensões e configurações do perfil normal não interferem na página.

O limite desse modo é justamente o fechar: o `--app` do Chromium não tem bandeja,
então clicar no X encerra o processo. Não dá para contornar de fora, porque a janela
é do navegador e ninguém consegue vetar o fechamento dela.

## Como funciona o modo tray

Aqui a janela é nossa, um `QMainWindow` com um `QWebEngineView` dentro. Isso muda o
jogo: dá para sobrescrever o `closeEvent` e trocar fechar por esconder.

```python
def closeEvent(self, event):
    """X fecha para a bandeja. So encerra de verdade pelo menu Sair."""
    if self.encerrando or not QSystemTrayIcon.isSystemTrayAvailable():
        event.accept()
        return
    event.ignore()
    self.esconder()
```

O processo continua vivo, a sessão continua conectada e as notificações continuam
chegando. O que mais importa nos detalhes:

- **User agent.** O QtWebEngine se identifica como QtWebEngine e o WhatsApp Web
  recusa. O app anuncia Chrome puro.
- **Contador de não lidas.** O WhatsApp escreve o número no título da página, tipo
  `(3) WhatsApp`. O app lê o `titleChanged`, extrai o número e pinta um badge
  vermelho sobre o ícone da bandeja.
- **Permissões.** Só notificação, microfone, câmera e área de transferência, e só
  para hosts do WhatsApp. Qualquer outra é negada. A API mudou no Qt 6.8, o código
  cobre as duas.
- **Link externo** abre no navegador padrão em vez de virar popup dentro do app.
- **Instância única** via `QLocalServer`: abrir de novo traz a janela existente para
  a frente em vez de subir um segundo processo.

## A pegadinha do Wayland

No KDE Plasma sobre Wayland o Chromium **ignora** `--class`. O `app_id` da janela é
montado pelo próprio navegador no formato `<produto>-<host>__-<perfil>`. No Brave:

```
brave-web.whatsapp.com__-Default
```

Se o `StartupWMClass` do `.desktop` não bater com esse valor, a janela aparece na
barra de tarefas sem ícone e sem agrupar com o lançador. O `install.sh` monta o
valor certo por navegador. Se ainda assim ficar errado, abra o app e rode:

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

No modo tray o problema não existe: o Qt usa `setDesktopFileName("whatsapp-web")`
como `app_id`, que é justamente o nome do arquivo `.desktop`.

## Abrir junto com a sessão

```bash
./scripts/autostart.sh on    # no modo tray, inicia oculto na bandeja
./scripts/autostart.sh off
```

## Desinstalação

```bash
./uninstall.sh           # remove o app, mantém a sessão logada
./uninstall.sh --purge   # remove também perfil e cache, mandando para a lixeira
```

Apagar o perfil **não desvincula o dispositivo**. A sessão continua listada no
celular até você remover na mão, em Dispositivos conectados. E o perfil vai para a
lixeira, não some: até esvaziar a lixeira, os dados de sessão continuam no disco.

## Limitações conhecidas

- **Modo leve:** sem bandeja. Fechar a janela encerra o app. Use o modo tray se isso
  incomodar.
- **Notificações** exigem aceitar a permissão do site na primeira vez.
- **Modo tray em GPU híbrida:** o app passa `--in-process-gpu` ao QtWebEngine. Sem
  isso, em máquina com Intel + NVIDIA a janela nunca é mapeada pelo compositor: o Qt
  reporta `isVisible() == True`, nada aparece na tela e não há erro no log. Se essa
  flag causar problema na sua máquina, sobrescreva:
  `WHATSAPP_QTWEBENGINE_FLAGS="--disable-gpu-compositing" whatsapp-web`
- **Chamadas de voz e vídeo** do WhatsApp Web dependem do que o motor suporta.
  No modo leve funciona igual ao navegador. No modo tray o app já concede microfone
  e câmera, mas o QtWebEngine pode não ter todos os codecs proprietários compilados,
  dependendo de como a distro empacotou.
- **Navegador em Flatpak ou Snap** não é detectado pelo modo leve, que procura
  binário no `PATH`. Mesmo apontando na mão, o sandbox do Flatpak bloquearia o
  `--user-data-dir` fora dele. Use um navegador nativo ou o modo tray.
- **Modo leve não tem barra de endereços**, então não dá para revogar permissão de
  câmera e microfone pela interface. Para revogar, apague o perfil
  (`./uninstall.sh --purge`) ou use o modo tray, onde a lista de permissões é
  fechada no código.
- **Perfil novo do Brave nasce com a telemetria padrão ligada**, mesmo que você a
  tenha desligado no perfil principal. São perfis independentes. Se isso importa,
  abra as configurações do navegador dentro do perfil isolado uma vez, ou use o
  modo tray, que não é Brave.

Alternativa pronta com bandeja: **ZapZap** (`paru -S zapzap` ou
`flatpak install flathub com.rtosta.zapzap`), também PyQt6, mantido ativamente.

## Segurança

- O sandbox do motor continua ativo nos dois modos. Nenhuma flag do projeto o
  enfraquece.
- Nenhum código de terceiro roda: o alvo é `https://web.whatsapp.com/`, o site
  oficial.
- A criptografia ponta a ponta do WhatsApp não é afetada. O wrapper não fica no meio
  da conversa, só desenha a janela.
- No modo tray, permissões do site são concedidas por lista fechada e só para hosts
  do WhatsApp. Navegação para fora sai para o navegador padrão.
- O diretório do perfil é criado com permissão `700`, então outros usuários da
  máquina não leem os cookies de sessão. Continua valendo o cuidado de sempre com
  disco não criptografado: root lê tudo, e o histórico local do WhatsApp Web fica
  em claro dentro do perfil.

## Licença

MIT.
