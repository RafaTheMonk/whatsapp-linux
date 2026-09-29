# Proposal

## Why

Duas pendências da auditoria de 10/09/2026 no app Electron. A janela reabre sempre no tamanho normal, mesmo que tenha sido fechada maximizada. E os limites salvos são aplicados sem conferir se ainda cabem em algum monitor: fechada num monitor externo que depois foi desconectado, a janela reabre fora da tela (no X11, onde o app escolhe a posição).

## What Changes

- O app lembra se a janela estava maximizada e reabre maximizada, com o tamanho normal de antes guardado para quando o usuário restaurar.
- Antes de aplicar os limites salvos, o app confere se eles caem dentro da área útil de algum monitor. Se não caem, descarta a posição (o sistema escolhe onde abrir) e limita o tamanho ao do monitor.

## Capabilities

### New Capabilities

- `geometria-da-janela`: como a janela do app Electron guarda e recupera tamanho, posição e estado maximizado entre execuções.

### Modified Capabilities

## Impact

- `electron/src/main.js`: `salvarBounds` e a abertura da janela em `montarJanela`, usando o módulo `screen` do Electron.
- `estado.json` ganha o campo `maximizada`. Estados antigos sem o campo continuam valendo como não maximizada.
- `docs/auditorias.md`: a pendência da geometria.
