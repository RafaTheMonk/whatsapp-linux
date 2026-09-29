# Proposal

## Why

A pendência da auditoria dizia que o `preventDefault` de `page-title-updated` estava no emissor errado e "não impede nada, inócuo hoje". Não é inócuo: medido em 11/09/2026 (projeto irmão sitweb-cassi) e de novo em 29/09/2026 pelo KWin, a barra de título e a barra de tarefas mostram o título da página, "(1) WhatsApp", em vez de "WhatsApp Linux". Junto disso, o `electron/README.md` e um comentário no código afirmam que `app.setName` define o `app_id` no Wayland, o que foi medido como falso.

## What Changes

- O título da janela fica fixo em "WhatsApp Linux". O contador de não lidas continua lendo o título da página.
- A seção "app_id no Wayland" do `electron/README.md` e o comentário junto de `app.setName` passam a dizer o que foi medido: o `app_id` vem do `executableName` no pacote e do `name` do `package.json` no `npm start`.

## Capabilities

### New Capabilities

- `titulo-da-janela`: o título que a janela do app Electron mostra ao sistema.

### Modified Capabilities

## Impact

- `electron/src/main.js`: o `preventDefault` sai do `webContents` e vai para o evento da `BrowserWindow`. Comentário do `app.setName`.
- `electron/README.md`, seção "app_id no Wayland", e a pendência em `docs/auditorias.md`.
