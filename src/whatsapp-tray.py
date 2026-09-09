#!/usr/bin/env python3
"""WhatsApp Web como app de bandeja.

Modo tray do projeto whatsapp-linux. Diferente do modo leve (janela do Chromium
em --app), aqui a janela e nossa, entao da para interceptar o fechamento: clicar
no X esconde para a bandeja em vez de encerrar. O processo continua vivo, a
sessao continua conectada e as notificacoes continuam chegando.

Requer PyQt6 e PyQt6-WebEngine.
"""

from __future__ import annotations

import os
import re
import signal
import sys
from pathlib import Path

# Precisa estar no ambiente ANTES de qualquer import do QtWebEngine.
#
# --in-process-gpu: em maquina com GPU hibrida (Intel + NVIDIA) o processo de GPU
# do QtWebEngine sobe, o Qt reporta isVisible() True, e a janela nunca e mapeada
# pelo compositor. Nada aparece na tela e nao ha erro no log. Rodar a GPU dentro
# do proprio processo resolve e mantem a aceleracao. Medido em Intel RPL-P +
# GeForce RTX 3050, KDE Plasma sobre Wayland.
#
# Alternativas que tambem funcionam, se esta causar problema na sua maquina:
#   WHATSAPP_QTWEBENGINE_FLAGS="--disable-gpu-compositing" whatsapp-web
#   WHATSAPP_QTWEBENGINE_FLAGS="--use-angle=gl" whatsapp-web
#   WHATSAPP_QTWEBENGINE_FLAGS="--disable-gpu" whatsapp-web
_FLAGS_PADRAO = "--in-process-gpu --disable-features=Translate"
_flags = os.environ.get("WHATSAPP_QTWEBENGINE_FLAGS", _FLAGS_PADRAO)
_anterior = os.environ.get("QTWEBENGINE_CHROMIUM_FLAGS", "")
os.environ["QTWEBENGINE_CHROMIUM_FLAGS"] = f"{_anterior} {_flags}".strip()

from PyQt6.QtCore import QSettings, QSize, Qt, QTimer, QUrl, pyqtSlot
from PyQt6.QtGui import QAction, QColor, QGuiApplication, QIcon, QPainter, QPixmap
from PyQt6.QtNetwork import QLocalServer, QLocalSocket
from PyQt6.QtWebEngineCore import (
    QWebEngineDownloadRequest,
    QWebEnginePage,
    QWebEngineProfile,
    QWebEngineSettings,
)
from PyQt6.QtWebEngineWidgets import QWebEngineView
from PyQt6.QtWidgets import QApplication, QMainWindow, QMenu, QSystemTrayIcon

APP_ID = "whatsapp-web"
APP_NAME = "WhatsApp Web"
URL = "https://web.whatsapp.com/"
SOCKET_NAME = "whatsapp-web-tray"

# O QtWebEngine se identifica como QtWebEngine e o WhatsApp Web recusa.
# Anunciar Chrome puro, na mesma versao do Chromium que o Qt embute.
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/130.0.0.0 Safari/537.36"
)

DATA_DIR = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "whatsapp-web"
PROFILE_DIR = DATA_DIR / "qt-profile"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "whatsapp-web"

ALLOWED_HOSTS = {"web.whatsapp.com", "www.whatsapp.com", "whatsapp.com"}


def load_icon() -> QIcon:
    """Icone do tema, com fallback para o SVG ao lado do script."""
    icon = QIcon.fromTheme(APP_ID)
    if not icon.isNull():
        return icon
    local = Path(__file__).resolve().parent / "whatsapp-web.svg"
    if local.exists():
        return QIcon(str(local))
    return QIcon()


def badge(icon: QIcon, count: int) -> QIcon:
    """Desenha um ponto vermelho com o numero de nao lidas sobre o icone."""
    if count <= 0:
        return icon
    size = 64
    pix = icon.pixmap(QSize(size, size))
    if pix.isNull():
        return icon
    painter = QPainter(pix)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)
    d = size // 2
    painter.setBrush(QColor("#e53935"))
    painter.setPen(Qt.PenStyle.NoPen)
    painter.drawEllipse(size - d, 0, d, d)
    painter.setPen(QColor("white"))
    font = painter.font()
    font.setPixelSize(int(d * 0.7))
    font.setBold(True)
    painter.setFont(font)
    texto = "9+" if count > 9 else str(count)
    painter.drawText(
        size - d, 0, d, d, Qt.AlignmentFlag.AlignCenter, texto
    )
    painter.end()
    return QIcon(pix)


class Page(QWebEnginePage):
    """Mantem a navegacao dentro do WhatsApp. Link externo abre no navegador."""

    def acceptNavigationRequest(self, url: QUrl, tipo, is_main_frame: bool) -> bool:
        externo = url.host() and url.host() not in ALLOWED_HOSTS
        clique = tipo == QWebEnginePage.NavigationType.NavigationTypeLinkClicked
        if externo and clique:
            QGuiApplication.instance().abrir_externo(url)
            return False
        return super().acceptNavigationRequest(url, tipo, is_main_frame)

    def createWindow(self, _tipo):
        # target=_blank: entrega para o navegador padrao em vez de abrir popup.
        page = Page(self.profile(), self)
        page.urlChanged.connect(lambda u: QGuiApplication.instance().abrir_externo(u))
        return page


class Janela(QMainWindow):
    def __init__(self, icone: QIcon, comecar_oculto: bool):
        super().__init__()
        self.icone_base = icone
        self.encerrando = False
        self.nao_lidas = 0

        self.setWindowTitle(APP_NAME)
        self.setWindowIcon(icone)
        self.setMinimumSize(560, 480)

        PROFILE_DIR.mkdir(parents=True, exist_ok=True)
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        # A sessao logada mora no perfil. Sem isso nasce 0755 e outro usuario
        # da maquina consegue ler os cookies de sessao.
        for d in (DATA_DIR, PROFILE_DIR, CACHE_DIR):
            try:
                d.chmod(0o700)
            except OSError:
                pass

        self.profile = QWebEngineProfile("whatsapp", self)
        self.profile.setPersistentStoragePath(str(PROFILE_DIR))
        self.profile.setCachePath(str(CACHE_DIR))
        self.profile.setHttpUserAgent(USER_AGENT)
        # Sem isto o QtWebEngine nao manda Accept-Language e a pagina abre em ingles.
        self.profile.setHttpAcceptLanguage("pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7")
        self.profile.setPersistentCookiesPolicy(
            QWebEngineProfile.PersistentCookiesPolicy.ForcePersistentCookies
        )
        self.profile.downloadRequested.connect(self._download)
        self.profile.setNotificationPresenter(self._notificar)

        self.page = Page(self.profile, self)
        self._ligar_permissoes()

        self.view = QWebEngineView(self)
        self.view.setPage(self.page)
        s = self.page.settings()
        s.setAttribute(QWebEngineSettings.WebAttribute.JavascriptCanAccessClipboard, True)
        s.setAttribute(QWebEngineSettings.WebAttribute.JavascriptCanPaste, True)
        s.setAttribute(QWebEngineSettings.WebAttribute.FullScreenSupportEnabled, True)
        s.setAttribute(QWebEngineSettings.WebAttribute.ScreenCaptureEnabled, True)
        self.setCentralWidget(self.view)

        self.page.titleChanged.connect(self._titulo_mudou)
        self.view.load(QUrl(URL))

        self._montar_bandeja()
        self._restaurar_geometria()
        if not comecar_oculto:
            self.show()

    # ---- bandeja -------------------------------------------------------

    def _montar_bandeja(self) -> None:
        self.tray = QSystemTrayIcon(self.icone_base, self)
        self.tray.setToolTip(APP_NAME)

        menu = QMenu()
        self.acao_mostrar = QAction("Mostrar", self)
        self.acao_mostrar.triggered.connect(self.alternar)
        menu.addAction(self.acao_mostrar)

        recarregar = QAction("Recarregar", self)
        recarregar.triggered.connect(self.view.reload)
        menu.addAction(recarregar)

        menu.addSeparator()
        sair = QAction("Sair", self)
        sair.triggered.connect(self.encerrar)
        menu.addAction(sair)

        self.tray.setContextMenu(menu)
        self.tray.activated.connect(self._clique_bandeja)
        self.tray.show()

    @pyqtSlot(QSystemTrayIcon.ActivationReason)
    def _clique_bandeja(self, motivo) -> None:
        if motivo == QSystemTrayIcon.ActivationReason.Trigger:
            self.alternar()

    def alternar(self) -> None:
        if self.isVisible() and not self.isMinimized():
            self.esconder()
        else:
            self.aparecer()

    def aparecer(self) -> None:
        self.showNormal()
        self.raise_()
        self.activateWindow()
        self.acao_mostrar.setText("Ocultar")

    def esconder(self) -> None:
        self._salvar_geometria()
        self.hide()
        self.acao_mostrar.setText("Mostrar")

    # ---- ciclo de vida -------------------------------------------------

    def closeEvent(self, event) -> None:
        """X fecha para a bandeja. So encerra de verdade pelo menu Sair."""
        if self.encerrando or not QSystemTrayIcon.isSystemTrayAvailable():
            self._salvar_geometria()
            event.accept()
            return
        event.ignore()
        self.esconder()

    def encerrar(self) -> None:
        self.encerrando = True
        self._salvar_geometria()
        self.tray.hide()
        QApplication.instance().quit()

    def _restaurar_geometria(self) -> None:
        geo = QSettings("whatsapp-linux", "tray").value("geometria")
        if geo is not None:
            self.restoreGeometry(geo)
        else:
            self.resize(1100, 780)

    def _salvar_geometria(self) -> None:
        if not self.isMinimized():
            QSettings("whatsapp-linux", "tray").setValue("geometria", self.saveGeometry())

    # ---- integracao ----------------------------------------------------

    def _ligar_permissoes(self) -> None:
        """Concede so o que o WhatsApp precisa: notificacao, microfone, camera.

        A API mudou no Qt 6.8. Cobre as duas para nao quebrar em versao antiga.
        """
        if hasattr(self.page, "permissionRequested"):
            self.page.permissionRequested.connect(self._permissao_qt68)
        elif hasattr(self.page, "featurePermissionRequested"):
            self.page.featurePermissionRequested.connect(self._permissao_antiga)

    def _permissao_qt68(self, permissao) -> None:
        from PyQt6.QtWebEngineCore import QWebEnginePermission

        liberadas = {
            QWebEnginePermission.PermissionType.Notifications,
            QWebEnginePermission.PermissionType.MediaAudioCapture,
            QWebEnginePermission.PermissionType.MediaVideoCapture,
            QWebEnginePermission.PermissionType.MediaAudioVideoCapture,
            QWebEnginePermission.PermissionType.ClipboardReadWrite,
        }
        if permissao.origin().host() in ALLOWED_HOSTS and permissao.permissionType() in liberadas:
            permissao.grant()
        else:
            permissao.deny()

    def _permissao_antiga(self, origem: QUrl, feature) -> None:
        f = QWebEnginePage.Feature
        liberadas = {
            f.Notifications,
            f.MediaAudioCapture,
            f.MediaVideoCapture,
            f.MediaAudioVideoCapture,
        }
        politica = (
            QWebEnginePage.PermissionPolicy.PermissionGrantedByUser
            if origem.host() in ALLOWED_HOSTS and feature in liberadas
            else QWebEnginePage.PermissionPolicy.PermissionDeniedByUser
        )
        self.page.setFeaturePermission(origem, feature, politica)

    def _notificar(self, notificacao) -> None:
        """Manda a notificacao do site para a bandeja do sistema."""
        notificacao.show()
        self.tray.showMessage(
            notificacao.title() or APP_NAME,
            notificacao.message(),
            self.icone_base,
            8000,
        )

    def _download(self, item: QWebEngineDownloadRequest) -> None:
        destino = Path.home() / "Downloads"
        destino.mkdir(parents=True, exist_ok=True)
        item.setDownloadDirectory(str(destino))
        item.accept()
        item.isFinishedChanged.connect(
            lambda: self.tray.showMessage(
                APP_NAME, f"Download concluido: {item.downloadFileName()}", self.icone_base, 5000
            )
        )

    def _titulo_mudou(self, titulo: str) -> None:
        """O WhatsApp poe o numero de nao lidas no titulo, tipo "(3) WhatsApp"."""
        achado = re.search(r"\((\d+)\)", titulo or "")
        n = int(achado.group(1)) if achado else 0
        if n == self.nao_lidas:
            return
        self.nao_lidas = n
        self.tray.setIcon(badge(self.icone_base, n))
        self.tray.setToolTip(f"{APP_NAME} - {n} nao lidas" if n else APP_NAME)


class App(QApplication):
    def abrir_externo(self, url: QUrl) -> None:
        from PyQt6.QtGui import QDesktopServices

        QDesktopServices.openUrl(url)


def instancia_unica(app: App) -> QLocalServer | None:
    """Se ja houver uma instancia, pede para ela aparecer e sai."""
    socket = QLocalSocket()
    socket.connectToServer(SOCKET_NAME)
    if socket.waitForConnected(300):
        socket.write(b"mostrar")
        socket.flush()
        socket.waitForBytesWritten(300)
        return None
    QLocalServer.removeServer(SOCKET_NAME)
    servidor = QLocalServer(app)
    servidor.listen(SOCKET_NAME)
    return servidor


def main() -> int:
    comecar_oculto = "--hidden" in sys.argv or "--oculto" in sys.argv

    app = App(sys.argv)
    app.setApplicationName(APP_NAME)
    app.setDesktopFileName(APP_ID)
    app.setQuitOnLastWindowClosed(False)

    servidor = instancia_unica(app)
    if servidor is None:
        print("ja existe uma instancia rodando", file=sys.stderr)
        return 0

    icone = load_icon()
    app.setWindowIcon(icone)

    if not QSystemTrayIcon.isSystemTrayAvailable():
        print("aviso: bandeja indisponivel, o X vai encerrar o app", file=sys.stderr)

    janela = Janela(icone, comecar_oculto)
    servidor.newConnection.connect(lambda: (servidor.nextPendingConnection(), janela.aparecer()))

    signal.signal(signal.SIGINT, lambda *_: janela.encerrar())
    timer = QTimer()
    timer.start(500)
    timer.timeout.connect(lambda: None)  # deixa o Python processar sinais

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
