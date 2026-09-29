# Proposal

## Why

No app Electron o clique direito não faz nada: com texto selecionado não aparece Copiar, na caixa de digitar não aparece Colar. O Electron não traz menu de contexto pronto, o app nunca montou um, e o WhatsApp Web ainda cancela o evento `contextmenu` da página inteira para abrir o menu próprio. Quem vem do navegador ou do app do Windows espera o menu do sistema nesses pontos.

## What Changes

- Clique direito sobre texto selecionado abre o menu nativo com Copiar.
- Clique direito na caixa de digitar (ou em qualquer campo editável) abre o menu nativo com Desfazer, Refazer, Recortar, Copiar, Colar, Colar sem formatação e Selecionar tudo, cada item habilitado só quando a ação é possível.
- Quando o clique cai num link ou numa imagem dentro desses casos, o menu ganha os itens de link (abrir no navegador, copiar endereço) e de imagem (copiar, salvar como).
- Clique direito numa mensagem sem seleção continua abrindo o menu do WhatsApp, como hoje.

## Capabilities

### New Capabilities

- `menu-de-contexto`: o que o clique direito faz no app Electron, quando o menu é do sistema e quando é do WhatsApp, e quais itens aparecem em cada caso.

### Modified Capabilities

## Impact

- `electron/src/main.js`: handler do evento `context-menu` do `webContents` e `preload` nas `webPreferences` da janela.
- `electron/src/preload.js`: arquivo novo, já coberto pelo `src/**/*` do `build.files`.
- `electron/README.md` e a tabela "Onde olhar no código" do `README.md`.
- Só o pacote Electron. O modo tray (QtWebEngine) tem menu de contexto próprio e o modo leve é o navegador, nenhum dos dois muda.
- Sugestões do corretor ficam fora: no teste de 29/09/2026 não apareceram, e o dicionário depende do download do servidor do Google, que é a pendência `spellcheck-privacidade`. O código que monta as sugestões fica, sem requisito que o garanta.
- Sem dependência nova e sem requisição de rede nova.
