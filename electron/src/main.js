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
  session,
  shell,
} = require("electron");
const fs = require("fs");
const os = require("os");
const path = require("path");

const URL_ALVO = "https://web.whatsapp.com/";
const HOSTS_PERMITIDOS = new Set(["web.whatsapp.com", "www.whatsapp.com", "whatsapp.com"]);

// O WhatsApp Web recusa user agent que anuncia Electron.
const USER_AGENT =
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) " +
  "Chrome/130.0.0.0 Safari/537.36";

const ARQ_ESTADO = () => path.join(app.getPath("userData"), "estado.json");
const ICONE = path.join(__dirname, "..", "build", "icon.png");
const ICONE_TRAY = path.join(__dirname, "..", "build", "tray.png");

let janela = null;
let tray = null;
let encerrando = false;
let naoLidas = 0;

const comecarOculto = process.argv.includes("--hidden") || process.argv.includes("--oculto");

/* ---------------------------------------------------------------- estado */

function lerEstado() {
  try {
    return JSON.parse(fs.readFileSync(ARQ_ESTADO(), "utf8"));
  } catch {
    return {};
  }
}

function gravarEstado(patch) {
  const atual = lerEstado();
  try {
    fs.mkdirSync(app.getPath("userData"), { recursive: true });
    fs.writeFileSync(ARQ_ESTADO(), JSON.stringify({ ...atual, ...patch }, null, 2));
  } catch (e) {
    console.error("nao consegui gravar o estado:", e.message);
  }
}

/* -------------------------------------------------- integracao no menu */

/**
 * AppImage roda solto: nao aparece no menu de aplicativos sozinho.
 * Na primeira execucao, oferece criar a entrada apontando para o proprio
 * arquivo. Em .deb e tar.gz isso ja vem pronto, entao nem pergunta.
 */
async function oferecerIntegracao() {
  const appimage = process.env.APPIMAGE;
  if (!appimage) return;

  const estado = lerEstado();
  if (estado.integracaoRespondida) return;

  const destinoDesktop = path.join(
    os.homedir(),
    ".local/share/applications/whatsapp-linux.desktop"
  );
  if (fs.existsSync(destinoDesktop)) {
    gravarEstado({ integracaoRespondida: true });
    return;
  }

  const r = await dialog.showMessageBox({
    type: "question",
    title: "WhatsApp Linux",
    message: "Adicionar ao menu de aplicativos?",
    detail:
      "Cria o atalho apontando para este arquivo, com icone. " +
      "Se mover o AppImage de lugar depois, e so responder de novo.",
    buttons: ["Adicionar", "Agora nao"],
    defaultId: 0,
    cancelId: 1,
  });

  gravarEstado({ integracaoRespondida: true });
  if (r.response !== 0) return;

  try {
    const dirIcone = path.join(os.homedir(), ".local/share/icons/hicolor/512x512/apps");
    fs.mkdirSync(dirIcone, { recursive: true });
    fs.copyFileSync(ICONE, path.join(dirIcone, "whatsapp-linux.png"));

    fs.mkdirSync(path.dirname(destinoDesktop), { recursive: true });
    fs.writeFileSync(
      destinoDesktop,
      [
        "[Desktop Entry]",
        "Type=Application",
        "Version=1.0",
        "Name=WhatsApp Linux",
        "GenericName=Mensageiro",
        "Comment=WhatsApp Web em janela propria",
        `Exec="${appimage}"`,
        "Icon=whatsapp-linux",
        "Terminal=false",
        "Categories=Network;InstantMessaging;",
        "Keywords=whatsapp;zap;mensagem;chat;",
        "StartupWMClass=whatsapp-linux",
        "StartupNotify=true",
        "SingleMainWindow=true",
        "",
      ].join("\n")
    );
    fs.chmodSync(destinoDesktop, 0o644);
  } catch (e) {
    dialog.showErrorBox("WhatsApp Linux", "Nao consegui criar o atalho: " + e.message);
  }
}

/* -------------------------------------------------------------- bandeja */

/** Pinta o contador de nao lidas sobre o icone da bandeja. */
function iconeComBadge(n) {
  const base = nativeImage.createFromPath(ICONE_TRAY);
  if (n <= 0 || base.isEmpty()) return base;
  // Sem canvas no processo principal: sinaliza pelo tooltip e pelo badge do
  // dock, e mantem o icone estavel para nao piscar na bandeja.
  return base;
}

function atualizarNaoLidas(titulo) {
  const m = /\((\d+)\)/.exec(titulo || "");
  const n = m ? parseInt(m[1], 10) : 0;
  if (n === naoLidas) return;
  naoLidas = n;
  if (tray) {
    tray.setToolTip(n ? `WhatsApp Linux - ${n} nao lidas` : "WhatsApp Linux");
    tray.setImage(iconeComBadge(n));
  }
  if (app.isReady() && typeof app.setBadgeCount === "function") {
    app.setBadgeCount(n);
  }
}

function montarBandeja() {
  tray = new Tray(iconeComBadge(0));
  tray.setToolTip("WhatsApp Linux");

  const menu = Menu.buildFromTemplate([
    { label: "Mostrar / ocultar", click: alternar },
    { label: "Recarregar", click: () => janela && janela.webContents.reload() },
    { type: "separator" },
    {
      label: "Iniciar com o sistema",
      type: "checkbox",
      checked: app.getLoginItemSettings().openAtLogin,
      click: (item) => {
        app.setLoginItemSettings({
          openAtLogin: item.checked,
          args: ["--hidden"],
        });
      },
    },
    { type: "separator" },
    {
      label: "Sair",
      click: () => {
        encerrando = true;
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(menu);
  tray.on("click", alternar);
}

function alternar() {
  if (!janela) return;
  if (janela.isVisible() && !janela.isMinimized()) {
    janela.hide();
  } else {
    janela.show();
    janela.focus();
  }
}

/* --------------------------------------------------------------- janela */

function montarJanela() {
  const estado = lerEstado();
  const bounds = estado.bounds || { width: 1100, height: 780 };

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
    },
  });

  const ses = janela.webContents.session;
  ses.setUserAgent(USER_AGENT);

  // Concede so o que o WhatsApp precisa, e so para os hosts dele.
  ses.setPermissionRequestHandler((wc, permissao, aceitar, detalhes) => {
    const liberadas = ["notifications", "media", "clipboard-read", "clipboard-sanitized-write"];
    let host = "";
    try {
      host = new URL(detalhes.requestingUrl || wc.getURL()).hostname;
    } catch {
      host = "";
    }
    aceitar(HOSTS_PERMITIDOS.has(host) && liberadas.includes(permissao));
  });

  // Link externo sai para o navegador padrao em vez de abrir janela do app.
  janela.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
  janela.webContents.on("will-navigate", (e, url) => {
    try {
      if (!HOSTS_PERMITIDOS.has(new URL(url).hostname)) {
        e.preventDefault();
        shell.openExternal(url);
      }
    } catch {
      /* url invalida: deixa o Chromium decidir */
    }
  });

  janela.webContents.on("page-title-updated", (e, titulo) => {
    e.preventDefault();
    atualizarNaoLidas(titulo);
  });

  // X fecha para a bandeja. So encerra de verdade pelo menu Sair.
  janela.on("close", (e) => {
    if (encerrando) {
      salvarBounds();
      return;
    }
    e.preventDefault();
    salvarBounds();
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
  if (janela && !janela.isMinimized() && janela.isVisible()) {
    gravarEstado({ bounds: janela.getNormalBounds() });
  }
}

/* ----------------------------------------------------------- menu minimo */

/**
 * Sem menu, o Chromium do Electron nao registra os atalhos de copiar e colar.
 * O menu fica escondido (autoHideMenuBar), so os aceleradores importam.
 */
function montarMenu() {
  Menu.setApplicationMenu(
    Menu.buildFromTemplate([
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

// Segunda execucao traz a janela existente em vez de subir outro processo.
if (!app.requestSingleInstanceLock()) {
  app.quit();
} else {
  app.on("second-instance", () => {
    if (janela) {
      janela.show();
      janela.focus();
    }
  });

  // No Wayland o Electron usa o nome do app como app_id da janela. Precisa ser
  // igual ao StartupWMClass do .desktop, senao a janela cai na barra de tarefas
  // sem icone e sem agrupar. O nome de exibicao fica no productName do build.
  app.setName("whatsapp-linux");

  app.whenReady().then(async () => {
    session.defaultSession.setUserAgent(USER_AGENT);
    montarMenu();
    montarJanela();
    montarBandeja();
    await oferecerIntegracao();
  });

  // Sem isso o app encerraria ao esconder a unica janela.
  app.on("window-all-closed", (e) => {
    if (!encerrando) e.preventDefault();
  });

  app.on("before-quit", () => {
    encerrando = true;
    salvarBounds();
  });
}
