"use strict";

/**
 * WhatsApp Linux - wrapper Electron do WhatsApp Web.
 *
 * Existe para distribuicao: o AppImage e o .deb carregam o proprio Chromium,
 * entao quem baixa nao precisa ter navegador, PyQt6 nem nada instalado.
 * A janela e nossa, entao fechar no X esconde para a bandeja em vez de encerrar.
 */

const {
  app,
  BrowserWindow,
  Menu,
  Tray,
  dialog,
  nativeImage,
  net,
  session,
  shell,
} = require("electron");
const fs = require("fs");
const os = require("os");
const path = require("path");

const URL_ALVO = "https://web.whatsapp.com/";
const REPO = "RafaTheMonk/whatsapp-linux";
const API_RELEASE = `https://api.github.com/repos/${REPO}/releases/latest`;
const PAGINA_RELEASES = `https://github.com/${REPO}/releases/latest`;
const INTERVALO_CHECAGEM_MS = 24 * 60 * 60 * 1000;
const HOSTS_PERMITIDOS = new Set(["web.whatsapp.com", "www.whatsapp.com", "whatsapp.com"]);
// shell.openExternal entrega a URL ao handler do sistema. Sem lista fechada,
// a pagina consegue disparar file://, smb://, vscode:// ou qualquer esquema
// registrado na maquina de quem baixou.
const ESQUEMAS_EXTERNOS = new Set(["http:", "https:", "mailto:", "tel:"]);

// O WhatsApp Web recusa user agent que anuncia Electron. Derivar do Chromium
// real em vez de fixar: versao fixa vira mentira no proximo upgrade.
const USER_AGENT =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) " +
  `Chrome/${process.versions.chrome.split(".")[0]}.0.0.0 Safari/537.36`;

// Em build empacotado o Electron deriva o userData do productName, virando
// "WhatsApp Linux" com espaco: diferente do app_id, do nome do .desktop e do
// resto do projeto, e fora do alcance do uninstall. Fixa o caminho antes de
// qualquer uso da sessao.
const DIR_DADOS = path.join(app.getPath("appData"), "whatsapp-linux");
const DIR_ANTIGO = path.join(app.getPath("appData"), "WhatsApp Linux");
migrarPerfilAntigo();
app.setPath("userData", DIR_DADOS);

const ARQ_ESTADO = () => path.join(app.getPath("userData"), "estado.json");
const AUTOSTART = path.join(
  process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config"),
  "autostart",
  "whatsapp-linux.desktop"
);
const DESKTOP_MENU = path.join(
  process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local/share"),
  "applications",
  "whatsapp-linux.desktop"
);
const ICONE = path.join(__dirname, "..", "build", "icon.png");
const ICONE_TRAY = path.join(__dirname, "..", "build", "tray.png");

let janela = null;
let tray = null;
let encerrando = false;
let naoLidas = 0;

const comecarOculto = process.argv.includes("--hidden") || process.argv.includes("--oculto");

/**
 * Renomeia o diretorio da versao antiga. So age quando o destino ainda nao
 * existe: com os dois presentes, abandonar um em silencio faria o usuario
 * perder o login sem entender por que.
 */
function migrarPerfilAntigo() {
  try {
    if (!fs.existsSync(DIR_ANTIGO)) return;
    if (!fs.existsSync(DIR_DADOS)) {
      fs.renameSync(DIR_ANTIGO, DIR_DADOS);
      return;
    }
    console.warn(
      `perfil antigo mantido em ${DIR_ANTIGO}; o app usa ${DIR_DADOS}. ` +
        "Apague o antigo quando tiver certeza de que nao precisa dele."
    );
  } catch (e) {
    console.error("nao consegui migrar o perfil antigo:", e.message);
  }
}

/**
 * A sessao logada mora no userData. Sem isto o diretorio pode ficar 0755 e
 * outro usuario da maquina le os cookies de sessao.
 */
function protegerPerfil() {
  for (const dir of new Set([app.getPath("userData"), app.getPath("sessionData")])) {
    try {
      fs.mkdirSync(dir, { recursive: true });
      fs.chmodSync(dir, 0o700);
    } catch (e) {
      console.error("nao consegui restringir a permissao de", dir, e.message);
    }
  }
}

/* ---------------------------------------------------------------- estado */

function lerEstado() {
  try {
    const d = JSON.parse(fs.readFileSync(ARQ_ESTADO(), "utf8"));
    return d && typeof d === "object" && !Array.isArray(d) ? d : {};
  } catch {
    return {};
  }
}

/** Escrita atomica: um desligamento no meio do write deixaria JSON truncado. */
function gravarEstado(patch) {
  const alvo = ARQ_ESTADO();
  const tmp = `${alvo}.tmp`;
  try {
    fs.mkdirSync(path.dirname(alvo), { recursive: true });
    fs.writeFileSync(tmp, JSON.stringify({ ...lerEstado(), ...patch }, null, 2));
    fs.renameSync(tmp, alvo);
  } catch (e) {
    console.error("nao consegui gravar o estado:", e.message);
    try {
      fs.unlinkSync(tmp);
    } catch {
      /* nada a fazer */
    }
  }
}

/* ------------------------------------------------------------- autostart */

/**
 * app.setLoginItemSettings e documentado como darwin/win32 apenas: no Linux nao
 * cria nada e a leitura volta sempre false. O que o Linux usa de fato e um
 * .desktop em ~/.config/autostart.
 */
function autostartAtivo() {
  try {
    return fs.existsSync(AUTOSTART);
  } catch {
    return false;
  }
}

function definirAutostart(ligar) {
  try {
    if (!ligar) {
      fs.rmSync(AUTOSTART, { force: true });
      return true;
    }
    fs.mkdirSync(path.dirname(AUTOSTART), { recursive: true });
    fs.writeFileSync(AUTOSTART, montarDesktop(caminhoExecutavel(), ["--hidden"]));
    fs.chmodSync(AUTOSTART, 0o644);
    return true;
  } catch (e) {
    dialog.showErrorBox("WhatsApp Linux", "Nao consegui alterar o autostart: " + e.message);
    return false;
  }
}

/* -------------------------------------------------- integracao no menu */

/**
 * APPIMAGE vem do ambiente. Uma quebra de linha no caminho injeta uma segunda
 * chave Exec= no .desktop, e o parser do freedesktop obedece a injetada.
 */
function caminhoExecutavel() {
  const p = process.env.APPIMAGE || process.execPath;
  if (/[\n\r]/.test(p)) {
    throw new Error("caminho do executavel contem quebra de linha");
  }
  return p;
}

function montarDesktop(exec, args = []) {
  const linhaExec = [`"${exec}"`, ...args].join(" ");
  return [
    "[Desktop Entry]",
    "Type=Application",
    "Version=1.0",
    "Name=WhatsApp Linux",
    "GenericName=Mensageiro",
    "Comment=WhatsApp Web em janela propria",
    `Exec=${linhaExec}`,
    "Icon=whatsapp-linux",
    "Terminal=false",
    "Categories=Network;InstantMessaging;",
    "Keywords=whatsapp;zap;mensagem;chat;",
    "StartupWMClass=whatsapp-linux",
    "StartupNotify=true",
    "SingleMainWindow=true",
    "",
  ].join("\n");
}

/** O atalho aponta para um arquivo que ainda existe? */
function atalhoValido() {
  try {
    const conteudo = fs.readFileSync(DESKTOP_MENU, "utf8");
    const m = /^Exec=(.*)$/m.exec(conteudo);
    if (!m) return false;
    const alvo = m[1].trim().replace(/^"(.*?)"( .*)?$/, "$1");
    return fs.existsSync(alvo);
  } catch {
    return false;
  }
}

function escreverAtalho() {
  const dirIcone = path.join(
    process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local/share"),
    "icons/hicolor/512x512/apps"
  );
  fs.mkdirSync(dirIcone, { recursive: true });
  fs.copyFileSync(ICONE, path.join(dirIcone, "whatsapp-linux.png"));
  fs.mkdirSync(path.dirname(DESKTOP_MENU), { recursive: true });
  fs.writeFileSync(DESKTOP_MENU, montarDesktop(caminhoExecutavel()));
  fs.chmodSync(DESKTOP_MENU, 0o644);
}

/**
 * AppImage roda solto: nao aparece no menu de aplicativos sozinho. Oferece criar
 * a entrada. Volta a oferecer se o atalho existente apontar para um arquivo que
 * sumiu, que e o que acontece quando o AppImage e movido de pasta.
 */
async function oferecerIntegracao() {
  if (!process.env.APPIMAGE) return;

  const estado = lerEstado();
  const existe = fs.existsSync(DESKTOP_MENU);
  const quebrado = existe && !atalhoValido();
  if (existe && !quebrado) return;
  if (!existe && estado.integracaoRecusada && !quebrado) return;

  const r = await dialog.showMessageBox({
    type: "question",
    title: "WhatsApp Linux",
    message: quebrado ? "Corrigir o atalho no menu?" : "Adicionar ao menu de aplicativos?",
    detail: quebrado
      ? "O atalho existente aponta para um arquivo que nao esta mais la. " +
        "Posso reapontar para este AppImage."
      : "Cria o atalho apontando para este arquivo, com icone. Se mover o " +
        "AppImage de lugar depois, o app oferece corrigir.",
    buttons: [quebrado ? "Corrigir" : "Adicionar", "Agora nao"],
    defaultId: 0,
    cancelId: 1,
  });

  if (r.response !== 0) {
    gravarEstado({ integracaoRecusada: true });
    return;
  }

  try {
    escreverAtalho();
    gravarEstado({ integracaoRecusada: false });
  } catch (e) {
    dialog.showErrorBox("WhatsApp Linux", "Nao consegui criar o atalho: " + e.message);
  }
}

/* --------------------------------------------------------- atualizacao */

let versaoNova = null;

/** Compara "1.2.10" com "1.3.0" sem trazer dependencia de semver. */
function maisNova(remota, local) {
  const a = String(remota).replace(/^v/, "").split(".").map((n) => parseInt(n, 10) || 0);
  const b = String(local).replace(/^v/, "").split(".").map((n) => parseInt(n, 10) || 0);
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const x = a[i] || 0;
    const y = b[i] || 0;
    if (x !== y) return x > y;
  }
  return false;
}

/**
 * Checa a ultima release publicada no GitHub, no maximo uma vez por dia.
 *
 * Nao baixa nem instala nada: so avisa e abre a pagina se o usuario pedir. E a
 * unica requisicao que o app faz fora do WhatsApp, e pode ser desligada no menu
 * da bandeja. Falha de rede e ausencia de release sao silenciosas de proposito:
 * ninguem quer um popup de erro por causa de wifi ruim.
 */
async function checarAtualizacao({ forcado = false } = {}) {
  const estado = lerEstado();
  if (!forcado && estado.avisarAtualizacao === false) return;
  if (!forcado && estado.ultimaChecagem && Date.now() - estado.ultimaChecagem < INTERVALO_CHECAGEM_MS) {
    return;
  }

  try {
    const r = await net.fetch(API_RELEASE, {
      headers: { Accept: "application/vnd.github+json", "User-Agent": "whatsapp-linux" },
    });
    gravarEstado({ ultimaChecagem: Date.now() });
    if (!r.ok) return; // 404 = nenhuma release publicada ainda
    const dados = await r.json();
    if (dados && dados.tag_name && maisNova(dados.tag_name, app.getVersion())) {
      versaoNova = String(dados.tag_name).replace(/^v/, "");
      if (tray) {
        montarMenuBandeja();
        tray.setToolTip(`WhatsApp Linux - versao ${versaoNova} disponivel`);
      }
    }
  } catch (e) {
    console.error("checagem de atualizacao falhou:", e.message);
  }
}

/* -------------------------------------------------------------- bandeja */

function atualizarNaoLidas(titulo) {
  // O WhatsApp escreve o contador so no inicio do titulo, tipo "(3) WhatsApp".
  const m = /^\((\d+)\+?\)/.exec((titulo || "").trim());
  const n = m ? parseInt(m[1], 10) : 0;
  if (n === naoLidas) return;
  naoLidas = n;
  if (tray) {
    tray.setToolTip(n ? `WhatsApp Linux - ${n} nao lidas` : "WhatsApp Linux");
  }
  // Só funciona em ambiente com Unity launcher; no KDE devolve false.
  try {
    app.setBadgeCount(n);
  } catch {
    /* ambiente sem suporte a badge */
  }
}

function montarBandeja() {
  try {
    tray = new Tray(nativeImage.createFromPath(ICONE_TRAY));
  } catch (e) {
    // GNOME sem extensao AppIndicator, por exemplo. Sem bandeja, esconder no X
    // deixaria o app sem nenhuma forma de voltar nem de encerrar.
    console.error("bandeja indisponivel, o X vai encerrar o app:", e.message);
    tray = null;
    return;
  }
  tray.setToolTip("WhatsApp Linux");
  montarMenuBandeja();
  tray.on("click", alternar);
}

function montarMenuBandeja() {
  if (!tray) return;
  const itens = [];

  if (versaoNova) {
    itens.push(
      {
        label: `Versao ${versaoNova} disponivel`,
        click: () => externo(PAGINA_RELEASES),
      },
      { type: "separator" }
    );
  }

  itens.push(
    { label: "Mostrar / ocultar", click: alternar },
    { label: "Recarregar", click: () => janela && janela.webContents.reload() },
    { type: "separator" },
    {
      label: "Iniciar com o sistema",
      type: "checkbox",
      checked: autostartAtivo(),
      click: (item) => {
        if (!definirAutostart(item.checked)) item.checked = autostartAtivo();
      },
    },
    {
      label: "Avisar sobre atualizacao",
      type: "checkbox",
      checked: lerEstado().avisarAtualizacao !== false,
      click: (item) => {
        gravarEstado({ avisarAtualizacao: item.checked });
        if (item.checked) checarAtualizacao({ forcado: true });
      },
    },
    { type: "separator" },
    { label: "Sair", click: sair }
  );

  tray.setContextMenu(Menu.buildFromTemplate(itens));
}

function alternar() {
  if (!janela || janela.isDestroyed()) {
    montarJanela();
    return;
  }
  if (janela.isVisible() && !janela.isMinimized()) {
    janela.hide();
  } else {
    janela.show();
    janela.focus();
  }
}

function sair() {
  encerrando = true;
  app.quit();
}

/* --------------------------------------------------------------- janela */

function externo(url) {
  try {
    const u = new URL(url);
    if (!ESQUEMAS_EXTERNOS.has(u.protocol)) {
      console.warn("esquema bloqueado:", u.protocol);
      return;
    }
    shell.openExternal(url);
  } catch {
    /* url invalida: ignora */
  }
}

function ehDoWhatsApp(url) {
  try {
    const u = new URL(url);
    return u.protocol === "https:" && HOSTS_PERMITIDOS.has(u.hostname);
  } catch {
    return false;
  }
}

function montarJanela() {
  const bounds = lerEstado().bounds || { width: 1100, height: 780 };

  janela = new BrowserWindow({
    ...bounds,
    minWidth: 560,
    minHeight: 480,
    show: false,
    icon: ICONE,
    autoHideMenuBar: true,
    title: "WhatsApp Linux",
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      spellcheck: true,
      // A promessa central e receber mensagem em segundo plano. Sem isto o
      // Chromium estrangula os timers da janela escondida.
      backgroundThrottling: false,
    },
  });

  const wc = janela.webContents;

  // Link externo sai para o navegador padrao em vez de abrir janela do app.
  wc.setWindowOpenHandler(({ url }) => {
    externo(url);
    return { action: "deny" };
  });

  // will-navigate cobre clique e location.href. will-redirect cobre o 302, que
  // sem isto tira o frame principal do allowlist sem passar por lugar nenhum.
  const barrarSaida = (e, url) => {
    if (!ehDoWhatsApp(url)) {
      e.preventDefault();
      externo(url);
    }
  };
  wc.on("will-navigate", barrarSaida);
  wc.on("will-redirect", barrarSaida);

  wc.on("page-title-updated", (e, titulo) => {
    e.preventDefault();
    atualizarNaoLidas(titulo);
  });

  // Sem isto, uma queda do renderer deixa a janela branca para sempre.
  wc.on("render-process-gone", (e, detalhes) => {
    console.error("renderer caiu:", detalhes.reason);
    if (detalhes.reason !== "clean-exit" && !encerrando) wc.reload();
  });
  wc.on("did-fail-load", (e, code, desc, url, principal) => {
    if (principal && code !== -3) console.error("falha ao carregar:", code, desc, url);
  });

  janela.on("close", (e) => {
    salvarBounds();
    // Sem bandeja nao ha como reabrir nem encerrar: deixa o X fechar de verdade.
    if (encerrando || !tray) return;
    e.preventDefault();
    janela.hide();
  });

  janela.on("closed", () => {
    janela = null;
  });

  janela.loadURL(URL_ALVO, { userAgent: USER_AGENT });
  janela.once("ready-to-show", () => {
    if (!comecarOculto) janela.show();
  });
}

function salvarBounds() {
  if (janela && !janela.isDestroyed() && !janela.isMinimized() && janela.isVisible()) {
    gravarEstado({ bounds: janela.getNormalBounds() });
  }
}

/* ---------------------------------------------------------- permissoes */

function origemPermitida(url) {
  try {
    const u = new URL(url);
    return u.protocol === "https:" && HOSTS_PERMITIDOS.has(u.hostname);
  } catch {
    return false;
  }
}

function ligarPermissoes(ses) {
  const LIBERADAS = new Set([
    "notifications",
    "media",
    "clipboard-read",
    "clipboard-sanitized-write",
  ]);

  ses.setPermissionRequestHandler((wc, permissao, aceitar, detalhes) => {
    const origem = (detalhes && detalhes.requestingUrl) || (wc ? wc.getURL() : "");
    aceitar(LIBERADAS.has(permissao) && origemPermitida(origem));
  });

  // Gemeo sincrono do handler acima. Sem ele o Chromium responde "granted" para
  // qualquer origem, e enumerateDevices() entrega o nome do hardware sem que
  // nenhuma permissao tenha sido concedida.
  ses.setPermissionCheckHandler((wc, permissao, origem, detalhes) => {
    const alvo = origem || (detalhes && detalhes.requestingUrl) || (wc ? wc.getURL() : "");
    return LIBERADAS.has(permissao) && origemPermitida(alvo);
  });
}

/* ----------------------------------------------------------- menu minimo */

/**
 * Sem menu o Chromium nao registra os atalhos de copiar e colar. Fica escondido
 * (autoHideMenuBar), so os aceleradores importam. O Ctrl+Q e a unica saida por
 * teclado, entao vive aqui.
 */
function montarMenu() {
  Menu.setApplicationMenu(
    Menu.buildFromTemplate([
      {
        label: "Arquivo",
        submenu: [
          { label: "Ocultar janela", accelerator: "CmdOrCtrl+W", click: () => janela && janela.hide() },
          { type: "separator" },
          { label: "Sair", accelerator: "CmdOrCtrl+Q", click: sair },
        ],
      },
      {
        label: "Editar",
        submenu: [
          { role: "undo", label: "Desfazer" },
          { role: "redo", label: "Refazer" },
          { type: "separator" },
          { role: "cut", label: "Recortar" },
          { role: "copy", label: "Copiar" },
          { role: "paste", label: "Colar" },
          { role: "selectAll", label: "Selecionar tudo" },
        ],
      },
      {
        label: "Ver",
        submenu: [
          { role: "reload", label: "Recarregar" },
          { role: "resetZoom", label: "Zoom normal" },
          { role: "zoomIn", label: "Aumentar zoom" },
          { role: "zoomOut", label: "Diminuir zoom" },
          { type: "separator" },
          { role: "togglefullscreen", label: "Tela cheia" },
        ],
      },
    ])
  );
}

/* ----------------------------------------------------------------- boot */

if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on("second-instance", () => {
    if (!janela || janela.isDestroyed()) montarJanela();
    else {
      janela.show();
      janela.focus();
    }
  });

  // No Wayland roda nativo em vez de XWayland, igual ao modo leve do projeto.
  app.commandLine.appendSwitch("ozone-platform-hint", "auto");

  // Em build empacotado o setName nao muda o caminho de dados (ja fixado acima),
  // mas define o app_id da janela no Wayland, que precisa casar com o
  // StartupWMClass do .desktop.
  app.setName("whatsapp-linux");

  app.whenReady().then(async () => {
    protegerPerfil();
    session.defaultSession.setUserAgent(USER_AGENT);
    ligarPermissoes(session.defaultSession);
    montarMenu();
    montarJanela();
    montarBandeja();
    await oferecerIntegracao();
    checarAtualizacao();
  });

  // Sem isto o app encerraria ao esconder a unica janela.
  app.on("window-all-closed", (e) => {
    if (!encerrando && tray) e.preventDefault();
    else app.quit();
  });

  app.on("before-quit", () => {
    encerrando = true;
    salvarBounds();
  });
}
