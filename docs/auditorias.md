# Auditorias

Registro das duas revisões que o código passou, com o que foi confirmado, o que
foi refutado e o que ainda não recebeu verificação. Serve para retomar o projeto
sem repetir trabalho: o que está aqui já foi olhado, e o que está em
[Pendências](#pendências) é o que sobrou.

Método nas duas: três revisores independentes em paralelo (uma lente cada),
depois um cético por achado, com a tarefa de **refutar**, não de concordar. Só
entra em "confirmado" o que sobreviveu a isso.

O corte de sete achados por auditoria é do orquestrador, não julgamento de
mérito: os demais simplesmente não chegaram à fase de verificação.


## Auditoria 1 - scripts shell e launcher

Alvo: `install.sh`, `uninstall.sh`, `src/whatsapp-web`, `scripts/`

Saldo: **31 achados**, 3 confirmados, 4 refutados, 24 sem verificação.

### Veredito de cada lente

**shell** — Nao esta seguro para publicar como esta: nao ha caminho de destruicao de dados, mas dois scripts gravam dado errado em arquivo de configuracao sem avisar (detect-app-id pegando o app_id de outra janela, install.sh corrompendo o Exec via sed nao escapado) e o install pode terminar sem entrada de menu deixando o usuario sem saber, alem do lancador aceitar argumentos que anulam o isolamento de perfil que e a razao de existir do projeto.

**navegador** — Nenhuma flag do launcher enfraquece o sandbox nem muda o modelo de segurança do navegador, a criptografia ponta a ponta não é afetada e o risco de bloqueio de conta é praticamente nulo porque o cliente carregado é o oficial, sem UA falsificado nem automação; o que precisa de correção é o `"$@"` que deixa injetar `--no-sandbox` ou `--remote-debugging-port` nessa sessão, a telemetria do Brave que volta ligada no perfil isolado apesar de estar desligada no perfil principal, e o `--purge` que manda a sessão para a lixeira sem desvincular o dispositivo.

**portabilidade** — Funciona bem no ambiente exato do autor (Brave + KDE + Wayland + Arch) e quebra logo de saida em quase toda outra combinacao: o prefixo do app_id do Chromium esta errado (o real e chrome-, verificado na maquina), o StartupWMClass gravado nao casa com nada em sessao X11, e o proprio detect-app-id.sh pode gravar brave-browser por casar com o titulo da janela em vez do app_id.

### Confirmados

#### [MEDIA] detect-app-id grava o app_id de outra janela no .desktop

`scripts/detect-app-id.sh:29` (lente shell)

O script JS imprime resourceClass E caption na mesma linha, e o filtro `grep -i 'whatsapp'` casa em qualquer parte da linha, incluindo o titulo. Depois `tail -1` pega a ULTIMA linha que casou. Reproduzi o pipeline exato: com um jornal contendo `WAAPPID|brave-web.whatsapp.com__-Default|WhatsApp` seguido de `WAAPPID|org.kde.kate|whatsapp-web.desktop.in - Kate`, o resultado do `cut -d'|' -f2` foi `org.kde.kate`. Cenario concreto e provavel: o autor esta editando o repo, tem uma janela do Kate com `whatsapp-web.desktop.in` no titulo ou uma janela do Dolphin em `whatsapp-linux/`. O script grava `StartupWMClass=org.kde.kate` no .desktop, imprime "app_id detectado" como se tivesse acertado, e a partir dai o lancador agrupa com o editor. Pior: ele conserta o problema que dizia consertar so por sorte de ordenacao das janelas.

**Correção proposta:**

```
Filtrar dentro do JS e nunca olhar o caption. Trocar o heredoc por:
```js
workspace.windowList().forEach(function (w) {
    if (/web\.whatsapp\.com/.test(w.resourceClass)) print(MARK + "|" + w.resourceClass);
});
```
e no shell usar um marcador unico por execucao mais `sort -u`, abortando se vier mais de um valor:
```bash
MARK="WAAPPID-$$-$(date +%s)"
APPID="$(journalctl --user --since "$SINCE" --no-pager 2>/dev/null | grep -oP "$MARK\|\K[^|]+" | sort -u)"
[ "$(printf '%s\n' "$APPID" | wc -l)" -eq 1 ] || { echo "erro: achei mais de uma janela" >&2; exit 1; }
```
```

**O cético tentou refutar e não conseguiu:** Tentei refutar e nao consegui: o defeito se reproduz na maquina do autor, agora, com as janelas reais dela.

Rodei o mesmo script KWin do heredoc (so troquei o marcador para nao mexer no .desktop) numa sessao KDE Plasma sobre Wayland viva (kwin_wayland PID 1596, qdbus6 presente). Saida real do journal:

  WAAPPID|plasmashell|
  WAAPPID|org.kde.konsole|~ : claude - Konsole
  WAAPPID|plasmashell|
  WAAPPID|org.kde.kwrite|Sem titulo (...) - KWrite
  WAAPPID|org.kde.konsole|Desktop : claude - Konsole
  WAAPPID|code-oss|README.md - RadarLeads - Code - OSS
  WAAPPID|brave-browser|WhatsApp web no Linux - Claude - Brave
  WAAPPID|brave-browser|Nova guia - Brave

Passando esse journal pelo pipeline exato das linhas 29-32 (grep -o 'WAAPPID|[^|]*|[^"]*' | grep -i whatsapp | tail -1 | cut -d'|' -f2) o resultado foi:

  brave-browser

Ou seja, nao e cenario hipotetico com Kate: o proprio navegador do dia a dia do autor, com uma aba do Claude cujo titulo comeca com "WhatsApp web no Linux", ja casa no filtro. Se ele rodar ./scripts/detect-app-id.sh nesse estado, a linha 39 grava StartupWMClass=brave-browser e a linha 42 imprime "app_id detectado: brave-browser" como sucesso. Combinado com SingleM

#### [MEDIA] Prefixo do app_id do Chromium esta errado: e "chrome", nao "chromium"

`install.sh:47` (lente portabilidade)

Verifiquei na maquina, com as duas janelas abertas em modo --app e lendo o resourceClass real pelo KWin:

  brave    -> brave-web.whatsapp.com__-Default   (bate com o que o install.sh gera)
  chromium -> chrome-web.whatsapp.com__-Default   (o install.sh gera chromium-web.whatsapp.com__-Default)

O prefixo nao vem do nome do executavel no PATH, vem da constante compilada kBrowserProcessExecutableName. Empacotadores renomeiam o arquivo (no Arch o binario e /usr/lib/chromium/chromium) mas a constante continua "chrome". Logo o mapeamento vale para Chromium do Arch, do Debian, do Fedora, do snap e do flatpak: todos dao "chrome". Consequencia: em qualquer maquina que nao tenha Brave (ou seja, a maioria dos usuarios do repo) a janela cai na barra de tarefas sem icone e sem agrupar, que e exatamente o problema que o projeto existe para resolver. O caso chromium-browser (Ubuntu antigo) tambem cai em "chromium" e erra igual. Por consequencia direta do mesmo mecanismo, vivaldi* -> vivaldi tambem e suspeito: o binario do Vivaldi e vivaldi-bin, entao o valor provavel e vivaldi-bin. google-chrome* -> chrome e microsoft-edge* -> msedge estao coerentes com o mecanismo (binarios /opt/google/chrome/chrome e /opt/microsoft/msedge/msedge).

**Correção proposta:**

```
case "$BROWSER" in
    brave*)          PREFIX="brave" ;;      # verificado
    chromium*)       PREFIX="chrome" ;;     # verificado, constante compilada e "chrome"
    google-chrome*)  PREFIX="chrome" ;;
    microsoft-edge*) PREFIX="msedge" ;;
    vivaldi*)        PREFIX="vivaldi-bin" ;;  # nao verificado, confirmar com detect-app-id
    *)               PREFIX="chrome" ;;
esac

E deixar um comentario dizendo que o prefixo e o nome do binario compilado, nao o do wrapper no PATH, para ninguem "corrigir" de volta.
```

**O cético tentou refutar e não conseguiu:** Nao consegui refutar. Medi ao vivo nesta maquina (KDE Wayland real), com as duas janelas --app abertas simultaneamente e lendo w.resourceClass por script do KWin. Resultado: brave -> "brave-web.whatsapp.com__-Default" (controle, bate com install.sh linha 46, valida o metodo de medicao) e chromium -> "chrome-web.whatsapp.com__-Default", enquanto install.sh linha 47 gera "chromium-web.whatsapp.com__-Default". Mismatch confirmado. O mecanismo alegado tambem se confirma no mesmo dump: o resourceName da janela do Chromium e "chromium" (nome do processo) mas o resourceClass comeca com "chrome", provando que o prefixo nao vem do nome do executavel no PATH e sim de constante compilada. Ambiente: chromium 149.0.7827.53-1 do Arch, binario real /usr/lib/chromium/chromium, wrapper /usr/bin/chromium. Isso sustenta a generalizacao para Debian, Fedora, snap e flatpak, e por consequencia o caso chromium-browser do Ubuntu, que cai no mesmo ramo chromium* e erra igual.

Ressalva: a parte vivaldi* -> vivaldi-bin segue NAO verificada, Vivaldi nao esta instalado aqui. Deve entrar como suspeita a confirmar com detect-app-id.sh, nao como conserto aplicado as cegas. google-chrome* -> chrome e microsoft-ed

#### [ALTA] O detect filtra pelo titulo da janela e pega o navegador inteiro

`scripts/detect-app-id.sh:31` (lente portabilidade)

O pipeline faz grep -i 'whatsapp' sobre a linha inteira, que inclui o caption. Qualquer janela com "whatsapp" no titulo entra no sorteio, e o tail -1 decide por ordem de log, nao por relevancia. Isso nao e hipotetico: no dump real desta maquina apareceu

  AUDITID|brave-browser|brave|RafaTheMonk/whatsapp-linux: WhatsApp Web como app standalone no Linux ... - Brave

que e a janela normal do Brave com a pagina do proprio repo aberta. Rodei o pipeline exato do script com essa lista e a saida foi "brave-browser". Ou seja: o script grava StartupWMClass=brave-browser no .desktop, e a partir dai o app passa a agrupar com o navegador do dia a dia, com o icone do navegador. Basta ter a aba do repo, do README ou uma busca sobre whatsapp aberta no momento em que se roda o script, o que e justamente o momento provavel.

**Correção proposta:**

```
Filtrar pelo campo do resourceClass, nao pelo caption. Trocar o bloco por:

APPID="$(journalctl --user -b -n 300 --no-pager 2>/dev/null \
    | sed -n 's/.*WAAPPID|\([^|]*\)|.*/\1/p' \
    | grep -i 'web\.whatsapp\.com' \
    | tail -1 || true)"

Assim so casa um app_id do tipo <prefixo>-web.whatsapp.com__-<perfil>, e a janela normal do navegador nunca entra.
```

**O cético tentou refutar e não conseguiu:** Nao consegui refutar. Reproduzi na propria maquina, agora, com o app FECHADO.

Carreguei um script KWin identico ao do detect-app-id.sh (print de resourceClass|caption) via qdbus6 e a saida real no journalctl --user foi:

  plasmashell|
  org.kde.konsole|~ : claude - Konsole
  org.kde.kwrite|Sem titulo ... - KWrite
  org.kde.konsole|Desktop : claude - Konsole
  code-oss|README.md - RadarLeads - Code - OSS
  brave-browser|RafaTheMonk/whatsapp-linux: WhatsApp Web como app standalone no Linux, sem Electron... - Brave
  brave-browser|Nova guia - Brave

Rodando o pipeline EXATO das linhas 29 a 32 do script sobre esse journal real, a saida foi:

  brave-browser

Ou seja, o script nao teria falhado com a mensagem "nao achei a janela": ele teria seguido para o sed -i da linha 39 e sobrescrito o valor hoje CORRETO em ~/.local/share/applications/whatsapp-web.desktop (StartupWMClass=brave-web.whatsapp.com__-Default) por StartupWMClass=brave-browser, imprimindo "app_id detectado: brave-browser" como se tivesse dado certo. Falha silenciosa que destroi uma config que funcionava.

Pontos que checei tentando derrubar o achado, e por que nao derrubaram:

1. "Talvez o grep nao veja o caption." Ve. O

### Refutados

- **falha do rasterizador aborta o install e deixa instalacao parcial sem entrada de menu** — O cenario exige um rasterizador instalado e quebrado, condicao que nao ocorre neste ambiente. rsvg-convert 2.62.3 esta instalado, entao a linha 64 fixa RASTER=rsvg-convert e o ramo do magick (linha 65 em diante) e inalcancavel, o que elimina os dois gatilhos principais alegados: policy.xml bloqueando o coder SVG e magick sem delegate SVG. Verifiquei ainda que /etc/ImageMagick-7/policy.xml tem a unica linha de SVG comentada, que magick -list format reporta SVG rw+ via RSVG 2.62.3, e que o renderi

- **O launcher repassa qualquer flag do usuário para o Chromium, inclusive as que desligam o sandbox** — Refutado: não existe fronteira de privilégio nenhuma nesse ponto, então o `"$@"` não abre superfície de ataque, e a "porta sem função conhecida" tem função sim.

1. Quem passa argv já é o dono do processo. `src/whatsapp-web` é 755, sem setuid/setgid (`-rwxr-xr-x rafaelbrito rafaelbrito`), e roda com a mesma uid de quem chama. Todo cenário do achado exige um ator que já executa código como rafaelbrito, e nessa posição o passthrough é irrelevante, porque o mesmo ator pode: (a) ler a sessão direto 

- **Em sessao X11 o StartupWMClass gravado nao casa com nenhum campo do WM_CLASS** — Medi os dois casos na maquina, com as flags exatas do lancador.

X11 (Brave 152 forcado com --ozone-platform=x11 sobre XWayland, mesmo backend ozone/x11 de uma sessao X11 real), lido com xprop:
  WM_CLASS(STRING) = "web.whatsapp.com", "WhatsAppWeb"
Wayland (KDE, KWin script lendo resourceClass/resourceName):
  brave-web.whatsapp.com__-Default | brave

Ou seja, a parte descritiva do achado esta certa: no X11 nem a classe ("WhatsAppWeb") nem o nome ("web.whatsapp.com") batem com o brave-web.whatsa

- **"$@" depois das flags permite sobrescrever --user-data-dir e --app e furar o isolamento** — O mecanismo é real, mas o cenário de falha não existe neste projeto, neste ambiente. Detalhamento:

1. Precedência confirmada, sim. Reproduzi em /home/rafaelbrito (Brave 152.1.94.121, não 149): `brave --headless=new --user-data-dir=.../udA --user-data-dir=.../udB --dump-dom about:blank` criou só udB. Última ocorrência vence. Esse ponto do achado está correto.

2. Falta o limite de confiança. Quem consegue colocar argumento em argv de ~/.local/bin/whatsapp-web é exclusivamente o próprio usuário, 

### Levantados, sem verificação adversarial

Não passaram pelo cético. Podem ser reais, podem ser ruído.

- `[?]` script KWin nunca e descarregado, segunda execucao grava valor obsoleto do journal
- `[?]` sed sem escapar & e | corrompe o Exec ou deixa .desktop de 0 byte no menu
- `[?]` Exec nao quotado quebra a entrada de menu se o HOME tiver espaco
- `[?]` --class/--name conflitam com o StartupWMClass fixo do install.sh
- `[?]` O perfil isolado reativa a telemetria do Brave que está desligada no perfil principal
- `[?]` --purge manda a sessão do WhatsApp para a lixeira e não desvincula o dispositivo
- `[?]` O script de detecção despeja o título de todas as janelas abertas no journal persistente
- `[?]` Sessão e histórico ficam em texto claro no perfil, e nada no projeto avisa isso
- `[?]` O script KWin nunca e descarregado, entao a segunda execucao devolve valor velho
- `[?]` O detect exige KDE + Wayland + systemd + qdbus, quando no X11 e uma linha portavel
- `[?]` Fallback do imagemagick gera icone borrado e ignora o ImageMagick 6
- `[?]` Navegador do install e navegador da execucao podem divergir sem aviso
- `[?]` Navegador em Flatpak ou Snap nunca e encontrado, e o Flatpak ainda falharia no --user-data-dir
- `[?]` perfil criado com 755, diretorio da sessao fica navegavel por outros usuarios
- `[?]` autostart copia o .desktop, entao correcao posterior do app_id nao chega na copia
- `[?]` HOME vazio nao e barrado por set -u e todos os alvos viram caminhos na raiz
- `[?]` O grep casa com o título da janela, então o StartupWMClass pode receber a classe de outro app
- `[?]` mkdir com umask 022 deixa o diretório do perfil 0755
- `[?]` Com autostart, o os_crypt pode cair para a chave fixa se o kwallet ainda não estiver aberto
- `[?]` Sem barra de endereços não há como verificar a origem nem revogar câmera e microfone
- `[?]` Reinstalar apaga a correcao feita pelo detect-app-id.sh
- `[?]` Instalador manda rodar whatsapp-web sem checar se ~/.local/bin esta no PATH
- `[?]` Detalhes de spec do .desktop: Exec sem quote, falta Version, SingleMainWindow so vale no GNOME
- `[?]` XDG_CONFIG_HOME ignorado no autostart, incoerente com o resto do codigo


## Auditoria 2 - app Electron

Alvo: `electron/src/main.js`, `electron/package.json`, docs de distribuição

Saldo: **36 achados**, 4 confirmados, 0 refutados, 29 sem verificação.

### Veredito de cada lente

**seguranca** — O núcleo do webPreferences está correto e não achei nenhum caminho que exponha Node ao conteúdo remoto: contextIsolation ligado, nodeIntegration desligado, sandbox ligado, webSecurity no padrão (true), sem preload, sem webview, sem partition alternativa. A superfície real não está no isolamento do renderer, está no que o processo principal aceita da página e do ambiente. Quatro coisas medi rodando o Electron 33.4.11 do próprio node_modules, não deduzi da doc: (1) um 302 vindo de host permitido leva o frame principal para host arbitrário sem passar pelo will-navigate, e como page-title-updated é bloqueado e não existe barra de URL, a janela continua dizendo "WhatsApp Linux" enquanto exibe a página do atacante; (2) esquemas arbitrários (smb://, vscode://, e até um esquema inexistente) chegam intactos no shell.openExternal, tanto por will-navigate quanto por setWindowOpenHandler - file:, data: e javascript: são barrados antes pelo Chromium, então esse vetor específico não existe aqui; (3) sem setPermissionCheckHandler, o caminho síncrono devolve "granted" para tudo em qualquer origem e enumerateDevices() entrega o nome real do hardware ("ACER HD User Facing", "Raptor Lake-P/U/H cAVS") sem nenhuma permissão concedida; (4) uma quebra de linha em process.env.APPIMAGE injeta um segundo Exec= no .desktop e o GKeyFile lê justamente o injetado. Mas o risco que mais pesa para quem baixa isso do Drive não é nenhum desses: é o Chromium 130.0.6723.191 de outubro de 2024 rodando na internet aberta hoje, sem nenhum canal de atualização. Um wrapper que só desenha janela ainda assim é um navegador inteiro, e esse navegador está dois anos atrasado nas correções, com o README oferecendo --no-sandbox como contorno. O setPermissionRequestHandler em si está sólido: requestingUrl vem preenchido pelo Electron para o frame que pede, subframe cross-origin é negado corretamente, e os casos em que requestingUrl vem vazio (about:blank, srcdoc, blob:) são same-origin com o pai de qualquer jeito, então o fallback para wc.getURL() não abre bypass. Nada a corrigir ali além do gêmeo síncrono que falta. Comparando com o modo tray: o Electron está mais frouxo em um ponto concreto - o tray só manda para fora navegação com NavigationTypeLinkClicked, o Electron manda qualquer navegação, inclusive location.href puramente por script.

**robustez** — O nucleo do ciclo de vida esta correto e verifiquei isso rodando, nao lendo: reproduzi o padrao do arquivo (window-all-closed com preventDefault, close com preventDefault + hide, before-quit ligando o flag) num app minimo com o proprio Electron 33 do node_modules e o processo encerra limpo tanto pelo Sair quanto por SIGTERM (before-quit, close com encerrando=true, closed, will-quit, quit, codigo 0). Nao existe caminho em que o processo nunca termine. Tambem derrubei duas suspeitas: o argumento de window-all-closed existe em runtime apesar do electron.d.ts declarar () => void, entao o preventDefault nao lanca (embora seja decorativo, quem segura o quit e o listenerCount do proprio Electron); e app.setPath nao lanca com diretorio inexistente, com o sessionData acompanhando o userData fixado, entao nao ha perfil partido entre dois caminhos. O que sobra sao doze defeitos, dois deles pesados justamente pelo publico do pacote. Primeiro: sem bandeja visivel (GNOME sem a extensao AppIndicator, por exemplo) o app nao tem nenhuma forma de ser encerrado, porque o X so esconde e o menu nao tem acelerador de sair. O modo Python ja resolve esse caso e o Electron perdeu a protecao no caminho que e distribuido para leigos. Segundo, medido nesta maquina: "Iniciar com o sistema" e um no-op no Linux, a caixa desmarca sozinha a cada abertura e o README anuncia o recurso. Depois vem a migracao do perfil, que so cobre o caso feliz e hoje esta em estado inconsistente na propria maquina do autor (os dois diretorios existem), a escrita nao atomica do estado.json, o openExternal sem filtro de esquema, e o contador de nao lidas que so chega ao tooltip porque o iconeComBadge ignora o numero e o setBadgeCount retorna false no KDE. Nenhum desses e complicado de corrigir, e o de mais alto retorno e o acelerador de saida somado ao try/catch na bandeja.

**empacotamento** — O empacotamento esta bem mais cuidadoso que a media de wrapper de WhatsApp: o app.asar tem exatamente 4 arquivos (main.js, package.json e os dois icones, 32 KB, nenhum node_modules, nenhum lock, nenhum README), o campo files esta correto, dist e node_modules estao no gitignore, os binarios nao estao no Git, o SHA256SUMS confere com os artefatos e o postinst do .deb faz update-alternatives e update-desktop-database direito. Mas tres defeitos altos derrubam o pacote justamente nas maquinas que ele diz atender melhor. Primeiro, Electron 33.4.11 esta fora de suporte desde 29/04/2025 e embute Chromium M130, com CVEs de V8 exploradas em ataque real e corrigidas apenas em Chrome 138, 140 e 142 (CVE-2025-6554, CVE-2025-10585, CVE-2025-13223): e um navegador congelado sendo entregue a quem nao sabe que recebeu um navegador, sem nenhuma via de atualizacao, porque o app-update.yml embutido aponta para um repo com zero releases e o codigo nunca consulta nada. Segundo, o postinst gerado pelo electron-builder 25 testa user namespace como root e por isso deixa o chrome-sandbox em 0755 no Ubuntu 24.04, onde o AppArmor bloqueia userns para o usuario comum: o .deb instala e nao abre, exatamente no cenario em que README e DISTRIBUICAO mandam usar o .deb como solucao. Terceiro, o bloco desktop do package.json esta escrito no schema do electron-builder 26 rodando sobre o 25.1.8, entao GenericName, Keywords e StartupNotify foram descartados, o arquivo saiu com a linha invalida entry=[object Object] e o StartupWMClass foi para WhatsApp Linux em vez de whatsapp-linux: o bug de icone e agrupamento que o README descreve em detalhe como resolvido esta presente no pacote entregue, e ironicamente so o AppImage, que monta o .desktop pelo main.js, acerta. Abaixo disso ha um conjunto de promessas que o pacote nao cumpre: Iniciar com o sistema e no-op no Linux nessa versao do Electron, o atalho do AppImage morre se o arquivo for movido e o dialogo nunca reaparece apesar de o proprio texto prometer o contrario, o sandbox do AppImage liga ou desliga conforme o caminho de lancamento sem que isso esteja documentado em nenhum lugar, o tar.gz e oferecido sem .desktop, sem icone e sem sandbox usavel, e as depends nao declaram libgtk-3-0, libasound2, libcups2 e xdg-utils enquanto declaram um libxtst6 que o binario nao usa. Sobre o que a lente perguntou diretamente: o app.asar nao carrega node_modules, o app-update.yml nao vaza nada (owner e repo ja estao no homepage do package.json) mas e peso morto que aponta para um canal vazio, o .desktop gerado nao e valido pelo spec, e a doc do AppImage sem FUSE esta correta (a string dlopen(): error loading libfuse.so.2 esta mesmo no runtime e o --appimage-extract-and-run existe). Antes de mandar esse link para mais alguem: subir o Electron para a linha 44 e republicar, corrigir o SUID do chrome-sandbox por afterInstall, achatar o bloco desktop, arrumar as depends e decidir o que fazer com atualizacao. Os tres primeiros sao mudanca de poucas linhas e um rebuild.

### Confirmados

#### [ALTA] Chromium 130 de outubro de 2024 distribuído hoje, sem nenhum caminho de atualização

`electron/package.json:20` (lente seguranca)

O binário instalado é o Electron 33.4.11 e o motor dentro dele é Chrome/130.0.6723.191 (confirmei com strings no node_modules/electron/dist/electron). O Electron 33 saiu em outubro de 2024 e já está várias majors fora da janela de suporte de três majors do projeto; o Chromium 130 acumula dois anos de CVEs de V8 e Blink sem correção, várias delas com exploração em campo. Esse binário renderiza conteúdo remoto o dia inteiro, é a definição de superfície exposta.

O agravante é que não existe autoUpdater, nem repositório apt, nem checagem de versão no app. O usuário baixa do Google Drive, roda, e o motor congela naquela versão para sempre. Quando você publicar a correção, o único mecanismo é você avisar cada pessoa e cada uma refazer o download manual - e o DISTRIBUICAO.md, que é o texto que essas pessoas leem, não cita atualização em lugar nenhum nem lista o SHA256 (o SHA256SUMS.txt existe em electron/, mas fica fora do que o usuário recebe). Some isso ao README recomendar --no-sandbox como contorno no Ubuntu 24.04 e o pior caso vira: bug de renderer em Chromium de 2024, sem sandbox, virando execução como o usuário.

O ^33.2.0 também deixa a versão flutuando dentro da 33.x, então quem reconstruir do repositório público não produz necessariamente o binário dos hashes publicados.

**Correção proposta:**

```
Subir para uma major suportada do Electron e travar exato, sem caret, para o build ser reproduzível:

  "devDependencies": { "electron": "38.2.2", "electron-builder": "25.1.8" }

(usar a versão estável suportada na data do build; o critério é estar entre as três majors mais novas). Depois de subir, revalidar o USER_AGENT, que está fixo em Chrome/130 e vai destoar do motor real.

Para o canal de atualização, o mínimo viável sem infra: no whenReady, buscar a última tag de https://api.github.com/repos/RafaTheMonk/whatsapp-linux/releases/latest, comparar com app.getVersion() e, se for diferente, mostrar um dialog com botão que chama shell.openExternal da página de releases. Se aceitar depender do electron-updater, publicar em GitHub Releases resolve de vez (o latest-linux.yml que o electron-builder já gera em dist/ existe exatamente para isso). E colocar os SHA256 dentro do DISTRIBUICAO.md, com a linha de conferência: sha256sum -c SHA256SUMS.txt
```

**O cético tentou refutar e não conseguiu:** Tentei derrubar e não consegui. O núcleo do achado é verificável e está confirmado com medição na máquina.

Fatos que confirmei:
1. Motor. `node_modules/electron/dist/version` = 33.4.11 e `strings` no binário empacotado (`dist/linux-unpacked/whatsapp-linux`) devolve `Chrome/130.0.6723.191`. O AppImage, o .deb e o tar.gz em `electron/dist/` foram construídos hoje (09/09/2026) em cima desse motor.
2. Janela de suporte. `npm view electron@latest version` devolve 44.3.0. O projeto está 11 majors atrás, não "várias". Electron 33.0.0 saiu em 15/10/2024 e a última 33.x (33.4.11) foi publicada em 26/04/2025, ou seja, essa linha não recebe correção há mais de um ano e o Chromium dentro dela é de outubro de 2024, cerca de 22 meses de CVEs de V8 e Blink acumulados.
3. Zero caminho de atualização. Li `src/main.js` inteiro: não existe autoUpdater, electron-updater, chamada a releases nem comparação com `app.getVersion()`. `grep -rniE 'autoupdater|electron-updater|releases/latest|getVersion'` em src, package.json, README.md e DISTRIBUICAO.md não retorna nada. O `latest-linux.yml` que o electron-builder gerou está em `dist/` e não é consumido por ninguém.
4. Documento do usuário final. O DISTRIBU

#### [MEDIA] "Iniciar com o sistema" nao faz absolutamente nada no Linux

`electron/src/main.js:202` (lente robustez)

app.setLoginItemSettings e app.getLoginItemSettings sao documentados como @platform darwin,win32 no proprio electron.d.ts da versao instalada (linhas 1201 e 1634). Rodei na maquina do autor, KDE/Wayland, com o Electron 33 do node_modules: setLoginItemSettings({openAtLogin:true, args:["--hidden"]}) nao lanca, nao cria nada em ~/.config/autostart (continuou so com cachyos-hello.desktop) e a releitura devolve openAtLogin:false. Consequencias para quem baixa o binario: marcar a caixa nao habilita nada, e como checked vem de app.getLoginItemSettings().openAtLogin, a caixa aparece desmarcada de novo na proxima abertura. O usuario marca, reinicia, o app nao sobe, ele marca de novo, e assim indefinidamente. O README do electron ainda anuncia o recurso na lista de features.

**Correção proposta:**

```
Escrever o autostart na mao, que e o que o Linux usa de fato:

const AUTOSTART = path.join(os.homedir(), ".config/autostart/whatsapp-linux.desktop");
function autostartAtivo() { return fs.existsSync(AUTOSTART); }
function definirAutostart(ligar) {
  if (!ligar) { try { fs.unlinkSync(AUTOSTART); } catch {} return; }
  const exec = process.env.APPIMAGE || process.execPath;
  fs.mkdirSync(path.dirname(AUTOSTART), { recursive: true });
  fs.writeFileSync(AUTOSTART, `[Desktop Entry]\nType=Application\nName=WhatsApp Linux\nExec="${exec}" --hidden\nIcon=whatsapp-linux\nTerminal=false\nX-GNOME-Autostart-enabled=true\n`);
}

Usar autostartAtivo() no checked e definirAutostart(item.checked) no click. Se preferir nao implementar agora, remover o item do menu e a linha do README, porque hoje ele e uma promessa falsa.
```

**O cético tentou refutar e não conseguiu:** Nao consegui refutar: reproduzi na maquina. Rodei o proprio binario do projeto (node_modules/electron/dist/electron, 33.4.11) em KDE/Wayland chamando exatamente o que o main.js chama. Resultado: setLoginItemSettings({openAtLogin:true, args:["--hidden"]}) nao lanca, nao cria nada em ~/.config/autostart (continuou so com cachyos-hello.desktop) e getLoginItemSettings() devolve openAtLogin:false antes e depois. O electron.d.ts da versao instalada marca as duas APIs como @platform darwin,win32 (linhas 1201 e 1634) e o binario do Electron nao contem nenhuma string "autostart", so os nomes dos metodos. Descartei as saidas alternativas: extrai o .deb de dist/ e ele so instala ./usr/share/applications/whatsapp-linux.desktop, sem autostart e sem nada no postinst; o main.js so escreve .desktop em ~/.local/share/applications (integracao do AppImage), nunca em ~/.config/autostart. O item e montado incondicionalmente em montarBandeja() (src/main.js:200-210) com checked vindo de getLoginItemSettings().openAtLogin, entao o ciclo marca-reinicia-desmarcado acontece de verdade, e o README do electron anuncia o recurso na lista de features. A divergencia com os outros modos tambem confere: scripts/aut

#### [ALTA] Electron 33.4.11 fora de suporte, Chromium M130 sem patch de seguranca ha ~22 meses

`electron/package.json:20` (lente empacotamento)

Electron 33 chegou ao fim de vida em 29/04/2025 (endoflife.date/electron). Hoje as linhas suportadas sao 42, 43 e 44. O binario embute Chromium M130 (out/2024), ou seja quase dois anos de correcoes de seguranca do Chromium ausentes. Tres CVEs de type confusion no V8, todas no catalogo KEV da CISA (exploradas em ataque real), atingem M130 porque foram corrigidas muito acima dele: CVE-2025-6554 (corrigida em 138.0.7204.96, leitura/escrita arbitraria via HTML), CVE-2025-10585 (corrigida em 140.0.7339.185) e CVE-2025-13223 (corrigida em 142.0.7444.175). Cenario concreto: o WhatsApp Web renderiza conteudo que vem de terceiros (mensagem, preview de link, midia, iframe de anuncio de canal) no renderer desse Chromium. E o pior de dois mundos: o usuario leigo baixa de um Drive achando que e so uma janela do WhatsApp, e na pratica instala um navegador congelado que nunca vai receber patch, sem nem saber que tem um navegador ali. O caret "^33.2.0" ainda trava a atualizacao: npm nunca vai passar para 34+, entao o build permanece em EOL para sempre.

**Correção proposta:**

```
Subir para a linha suportada e pinar exato: "electron": "44.x.y" (sem caret) em devDependencies, rodar npm install, revalidar (Electron 34 mudou o comportamento de permissoes e o 36+ mexeu em sandbox/utility process) e republicar os tres artefatos com hash novo. Depois, agendar rebuild a cada release de seguranca do Electron, nao a cada mudanca de feature.
```

**O cético tentou refutar e não conseguiu:** Nao consegui refutar. Tudo que era verificavel se confirmou na maquina. node_modules/electron/dist/version = 33.4.11 e o Chromium embutido e 130.0.6723.191, extraido por strings tanto do node_modules/electron/dist/electron quanto do binario ja empacotado em dist/linux-unpacked/whatsapp-linux. Pelo npm view electron time, a 33.4.11 saiu em 2025-04-26 e e a ultima da linha 33 (21 releases, de 2024-10-15 a 2025-04-26), logo 16,5 meses sem nenhum backport. O npm view electron version devolve 44.3.0 e as linhas 42, 43 e 44 tiveram release em 2026-09-04 e 2026-09-08, batendo com as tres linhas suportadas citadas. O caret tambem confere: ^33.2.0 limita a <34.0.0, npm view electron@^33.2.0 version para em 33.4.11 e o package-lock fixa 33.4.11, entao npm install e npm update nunca saem do EOL. Os tres artefatos em dist/ foram construidos hoje, 13:40 a 13:47, e o SHA256SUMS.txt ja esta gerado, ou seja, isso esta em rota de distribuicao agora.

Dois agravantes que o proprio achado nao citou. Primeiro, nao existe electron-updater nem autoUpdater em lugar nenhum (grep -c electron-updater no package-lock da 0, nada em src/main.js) e o dist/latest-linux.yml gerado pelo electron-builder nao e cons

#### [MEDIA] build.linux.desktop usa o schema do electron-builder 26 com o builder 25: entrada .desktop saiu invalida e sem o StartupWMClass certo

`electron/package.json:47` (lente empacotamento)

Em app-builder-lib 25.1.8 (out/targets/LinuxTargetHelper.js:117-119) as chaves de `linux.desktop` sao espalhadas direto sobre os defaults: `{ ...defaults, ...targetSpecificOptions.desktop }`. O aninhamento `desktop: { entry: { ... } }` so existe no electron-builder 26. Consequencia medida no .desktop que foi de fato para dentro do .deb: apareceu a linha literal `entry=[object Object]` e o `StartupWMClass=WhatsApp Linux`, o valor default derivado do productName. GenericName, Keywords e StartupNotify foram simplesmente descartados. Ou seja: o bug que o README.md documenta como resolvido esta vivo no pacote recomendado. O app chama app.setName("whatsapp-linux"), entao a janela nasce com app_id/WM_CLASS `whatsapp-linux`, que nao casa com `WhatsApp Linux` do .desktop, e no KDE Plasma e no GNOME a janela cai na barra sem icone e sem agrupar com o lancador. Alem disso `entry=[object Object]` e chave invalida pelo desktop entry spec (chave minuscula e desconhecida) e faz desktop-file-validate falhar. Ironia: o .desktop que o proprio main.js escreve para o AppImage (main.js:157) acerta o StartupWMClass, entao quem usa AppImage esta certo e quem usa .deb, o publico maior, esta errado.

**Correção proposta:**

```
Achatar o objeto:
"desktop": {
  "GenericName": "Mensageiro",
  "Keywords": "whatsapp;zap;mensagem;chat;",
  "StartupWMClass": "whatsapp-linux",
  "StartupNotify": "true",
  "SingleMainWindow": "true"
}
Depois de rebuildar, conferir com: dpkg-deb -x pacote.deb /tmp/x && desktop-file-validate /tmp/x/usr/share/applications/whatsapp-linux.desktop
```

**O cético tentou refutar e não conseguiu:** Tentei refutar e nao consegui: o nucleo do achado foi reproduzido no binario que ja esta empacotado, nao e teoria.

O QUE FOI MEDIDO (nao inferido)

1. Versao do builder confirmada: `require('app-builder-lib/package.json').version` = 25.1.8 em /home/rafaelbrito/Desktop/whatsapp-linux/electron/node_modules. Em /home/rafaelbrito/Desktop/whatsapp-linux/electron/node_modules/app-builder-lib/out/targets/LinuxTargetHelper.js o objeto e montado como `{ Name, Exec, Terminal, Type, Icon, StartupWMClass: appInfo.productName, ...extra, ...targetSpecificOptions.desktop }` e depois serializado com `for (const name of Object.keys(desktopMeta)) data += "\n" + name + "=" + desktopMeta[name]`. Ou seja: espalhamento raso e concatenacao de string. Um valor objeto vira `[object Object]`. Nao ha nenhum tratamento de `entry`.

2. Extrai o .desktop de dentro do .deb real (/home/rafaelbrito/Desktop/whatsapp-linux/electron/dist/whatsapp-linux_1.0.0_amd64.deb, via bsdtar por nao haver dpkg-deb no Arch). Conteudo literal:

[Desktop Entry]
Name=WhatsApp Linux
Exec="/opt/WhatsApp Linux/whatsapp-linux" %U
Terminal=false
Type=Application
Icon=whatsapp-linux
StartupWMClass=WhatsApp Linux
entry=[object Object]
Com

### Levantados, sem verificação adversarial

Não passaram pelo cético. Podem ser reais, podem ser ruído.

- `[media]` will-redirect não é tratado: um 302 tira o frame principal do allowlist e a janela continua se chamando WhatsApp Linux
- `[media]` Falta setPermissionCheckHandler: o caminho síncrono ignora o allowlist e vaza o nome do hardware
- `[media]` Linha do .desktop montada com process.env.APPIMAGE sem validar nem escapar
- `[media]` Migracao do perfil so cobre o caso feliz: com os dois diretorios o login antigo e abandonado em silencio
- `[media]` Se a janela for destruida o app fica vivo, sem janela e sem caminho de volta
- `[media]` estado.json e escrito sem atomicidade e lido sem validacao
- `[media]` shell.openExternal recebe qualquer esquema, inclusive file://
- `[media]` O contador de nao lidas so chega ao tooltip: iconeComBadge ignora o numero e o setBadgeCount nao funciona no KDE
- `[media]` A integracao no menu so e oferecida uma vez na vida, e o proprio dialogo promete o contrario
- `[media]` Depends do .deb nao cobrem as bibliotecas que o binario realmente linka, e uma das tres declaradas nao e usada
- `[media]` Nenhum canal de atualizacao: app-update.yml embutido aponta para um repo sem release nenhuma e o codigo nunca consulta nada
- `[media]` "Iniciar com o sistema" e no-op no Linux com Electron 33, mas esta na lista de recursos
- `[media]` integracaoRespondida trava para sempre: atalho do AppImage quebra ao mover o arquivo e a UI nunca mais oferece consertar
- `[media]` O sandbox do AppImage liga e desliga conforme o caminho de lancamento, sem ninguem ser avisado
- `[media]` A secao "Se nao abrir" depende de mensagens de erro que o usuario leigo nunca ve
- `[media]` tar.gz oferecido como "descompactar e rodar" nao tem .desktop, nem icone, nem sandbox usavel
- `[media]` User agent fixo em Chrome/130 num binario sem atualizacao: prazo de validade embutido
- `[baixa]` README oferece --no-sandbox como contorno, em cima de um Chromium sem correções
- `[baixa]` spellcheck ligado faz o app buscar dicionário em servidor do Google, contra o que o DISTRIBUICAO promete
- `[baixa]` HOSTS_PERMITIDOS compara só hostname, sem exigir https
- `[baixa]` O preventDefault de page-title-updated esta no emissor errado e nao impede nada
- `[baixa]` O parser de nao lidas casa parenteses em qualquer lugar do titulo e zera com (99+)
- `[baixa]` Bounds sao restaurados sem conferir se ainda cabem em algum monitor
- `[baixa]` Nenhum tratamento de falha de carga ou de morte do renderer: a janela fica branca para sempre
- `[baixa]` Sem --ozone-platform-hint=auto: em Wayland roda em XWayland, divergindo do modo leve do mesmo projeto
- `[baixa]` backgroundThrottling nao desligado, com a promessa central sendo receber mensagem em segundo plano
- `[baixa]` Metadados do control do .deb invalidos: Maintainer sem e-mail, Section inexistente e Recommends de pacote removido
- `[baixa]` SHA256SUMS.txt esta correto e versionado, mas o documento que acompanha o download nao manda conferir nada
- `[baixa]` Somente um tamanho de icone (512x512) instalado, e nenhum aviso de que so existe build x86_64

## Pendências

Conferido no código em 10/09/2026, não listado de memória. Tudo abaixo é de
severidade baixa ou média e nenhum passou pelo cético, então parte pode ser ruído.
Ordem sugerida de ataque, do que mais incomoda para o que menos.

### App Electron

- **Contador de não lidas só aparece no tooltip.** O `iconeComBadge` foi removido
  na reescrita e nada é desenhado sobre o ícone da bandeja. `app.setBadgeCount`
  devolve `false` no KDE. Para resolver de verdade: compor o número com
  `nativeImage` a partir de um buffer, ou trocar o ícone por variantes pré-geradas
  de 1 a 9 e "9+".
- **`spellcheck: true` baixa dicionário de servidor do Google.** Contradiz o que o
  `DISTRIBUICAO.md` promete sobre não acessar nada além do WhatsApp e da checagem
  de versão. Decidir: desligar, ou declarar na documentação.
- **Geometria restaurada sem conferir se ainda cabe.** Se a janela foi fechada num
  monitor que não existe mais, ela reabre fora da tela. Comparar com
  `screen.getDisplayMatching(bounds)` antes de aplicar.
- **`tar.gz` não traz `.desktop` nem ícone**, mas a documentação o oferece como
  "descompactar e rodar". Ou gerar um instalador junto, ou dizer que ele é para
  quem sabe o que está fazendo.
- **Pacote instala só o ícone 512x512.** Faltam os tamanhos menores que a barra de
  tarefas e o menu usam.
- **`preventDefault` em `page-title-updated` está no emissor errado** e não impede
  nada. Inócuo hoje, mas é código que mente sobre o que faz.

### Modos shell

- **Navegador em Flatpak ou Snap não é detectado** pelo modo leve, que só procura
  binário no `PATH`. E mesmo apontando na mão, o sandbox do Flatpak bloquearia o
  `--user-data-dir`.
- **`--class` e `--name` continuam no comando do modo leve** sem servir para nada
  no Wayland. Funcionam só em X11. Não quebram, mas confundem quem lê.
- **`scripts/autostart.sh` copia o `.desktop`**, então uma correção posterior feita
  pelo `detect-app-id.sh` não chega na cópia. Symlink resolveria, mas o modo tray
  precisa acrescentar `--hidden` à linha `Exec`, o que impede o symlink.
- **`os_crypt` pode cair para chave fixa no autostart**, se o app subir antes do
  kwallet abrir. A sessão fica cifrada com chave previsível em vez da do chaveiro.
- **Perfil novo do Brave nasce com a telemetria padrão ligada**, mesmo com ela
  desligada no perfil principal. Já está documentado, mas não resolvido.

### Fora do código

- **Só existe build x86_64.** Sem ARM64, o que exclui Raspberry Pi e notebooks ARM.
- **A release é publicada na mão.** Um workflow de CI que dispare no push de tag
  evitaria o build sair da máquina de alguém, que é o oposto de reprodutível.
