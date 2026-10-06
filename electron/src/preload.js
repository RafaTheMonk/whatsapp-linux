"use strict";

const { contextBridge, ipcRenderer } = require("electron");

/**
 * O WhatsApp Web cancela o contextmenu da pagina inteira para abrir o menu
 * proprio. Cancelado, o Electron nem emite context-menu e o clique direito
 * sobre texto selecionado ou na caixa de digitar fica sem copiar e colar.
 *
 * Listener de captura no window roda antes de qualquer um da pagina. Quando
 * ha selecao ou o alvo e editavel, o evento para aqui e segue para o menu
 * nativo. No resto (mensagem sem selecao, imagem) o menu do WhatsApp continua.
 */
window.addEventListener(
  "contextmenu",
  (e) => {
    const sel = window.getSelection();
    const temSelecao = sel && !sel.isCollapsed && sel.toString().trim() !== "";
    const alvo = e.target instanceof Element ? e.target : null;
    const editavel = alvo && alvo.closest("input, textarea, [contenteditable]:not([contenteditable='false'])");
    if (temSelecao || editavel) e.stopImmediatePropagation();
  },
  true
);

/**
 * Clicar na notificacao so dispara o onclick da pagina, e o window.focus() que
 * o WhatsApp chama ali nao mostra janela escondida na bandeja. O Notification
 * da pagina vive no mundo principal, fora do alcance do preload isolado: a
 * subclasse e instalada la e avisa por um evento no window, que os dois mundos
 * compartilham. A pagina pode disparar o mesmo evento, e o pior que consegue e
 * mostrar a propria janela.
 */
contextBridge.executeInMainWorld({
  func: () => {
    const Original = window.Notification;
    if (typeof Original !== "function") return;
    window.Notification = class Notification extends Original {
      constructor(...args) {
        super(...args);
        this.addEventListener("click", () => window.dispatchEvent(new Event("whatsapp-linux-notificacao")));
      }
    };
  },
});

window.addEventListener("whatsapp-linux-notificacao", () => ipcRenderer.send("notificacao-clicada"));
