# Design

## Context

O Electron só emite `context-menu` no `webContents` quando a página não cancela o evento DOM `contextmenu`. O WhatsApp Web cancela em toda a página para abrir o menu próprio, então um handler só no processo principal nunca dispara. Isso foi medido em 29/09/2026: com o handler instalado e log ligado, nenhum clique direito chegou ao processo principal.

A janela roda com `contextIsolation: true`, `sandbox: true` e `nodeIntegration: false`, e até agora não havia preload. O app não tem suíte de testes, então a verificação é manual, no app rodando com o perfil real.

Na mesma sessão, os testes 2 e 3 do rascunho não valeram: o app instalado tinha sido reaberto, a versão de teste bateu no `requestSingleInstanceLock` e fechou sem janela. O teste do preload ainda está por fazer.

## Goals / Non-Goals

**Goals:**
- Menu do sistema nos dois casos em que o usuário espera por ele: texto selecionado e campo editável.
- Nenhuma superfície nova para a página, e o sandbox continua ligado.

**Non-Goals:**
- Substituir ou esconder o menu do WhatsApp em mensagens.
- Mexer no problema da reação por emoji a partir do menu do WhatsApp, que tem change própria.
- Sugestões do corretor no menu. O bloco existe no código, mas no teste de 29/09/2026 não apareceu, e o dicionário depende do download do servidor do Google. Resolver junto com a pendência `spellcheck-privacidade`.

## Decisions

**1. Preload com listener de captura no `window`, em vez de só o handler no processo principal.**
O preload roda antes de qualquer script da página, e um listener de captura no `window` é o primeiro do caminho do evento. Quando há seleção ou o alvo é editável, ele chama `stopImmediatePropagation()`. Os listeners do WhatsApp não chegam a rodar, o evento não é cancelado e o Electron emite `context-menu`.
Alternativas descartadas: injetar script no mundo principal com `executeJavaScript`, que roda depois dos scripts da página e disputa ordem com eles; desligar `contextIsolation`, que abre a página para o preload.
Premissa a confirmar no teste: `stopImmediatePropagation()` chamado no mundo isolado interrompe também os listeners do mundo principal. O evento DOM é o mesmo objeto nos dois mundos, então deve interromper. Se não interromper, a próxima tentativa é o preload chamar `stopPropagation()` num listener de captura registrado no `document` também, e medir de novo.
Confirmado no teste de 29/09/2026: com o preload, seleção e caixa de digitar abrem o menu do sistema, e mensagem sem seleção segue abrindo o menu do WhatsApp.

**2. O preload só lê a seleção e o alvo, e não usa `contextBridge`.**
Nada é exposto em `window`. O preload decide sem conversar com o processo principal, e quem monta o menu é o `context-menu` do lado principal, com os `params` que o Chromium já entrega (`isEditable`, `selectionText`, `editFlags`, `misspelledWord`, `dictionarySuggestions`, `linkURL`, `mediaType`, `srcURL`).

**3. Menu montado por blocos, só com o que se aplica ao ponto clicado.**
A ordem segue o Chrome: corretor, link, imagem, edição (ou só Copiar quando não é editável). Separador entre blocos. Sem nenhum bloco, não abre menu. Os itens de edição usam `role` do Electron, que já age no `webContents` focado, com `enabled` vindo de `editFlags`.

**4. Link passa pela função `externo()` que já existe.**
Mantém a lista fechada de esquemas. Links `blob:` ficam fora do menu: são mídia interna do WhatsApp, e abrir no navegador não faz sentido.

**5. Salvar imagem usa `downloadURL(srcURL)`.**
Não há handler de `will-download`, então o Electron abre o diálogo de salvar padrão. `srcURL` do WhatsApp costuma ser `blob:`, e `downloadURL` aceita blob da mesma sessão.

## Risks / Trade-offs

- [O WhatsApp registrar listener antes do preload] → Impossível pela ordem de carregamento: o preload roda antes do primeiro script da página.
- [Com seleção ativa, o menu do WhatsApp deixa de abrir sobre aquela mensagem] → É o pedido do usuário. Sem seleção o menu do WhatsApp volta.
- [Seleção que sobra na tela: o usuário seleciona, clica fora e depois dá clique direito numa mensagem] → A seleção ainda existe e o menu do sistema abre no lugar do menu do WhatsApp. Se incomodar no uso, restringir para quando o alvo estiver dentro do intervalo selecionado.
- [`downloadURL` de blob falhar em alguma versão do Electron] → Verificado no teste manual. Se falhar, o item sai e o resto do menu fica.

## Migration Plan

Entra na próxima versão do pacote. Não mexe em dado nem em perfil, e voltar atrás é remover o `preload` das `webPreferences`.
