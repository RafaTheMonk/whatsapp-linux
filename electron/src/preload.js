"use strict";

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
