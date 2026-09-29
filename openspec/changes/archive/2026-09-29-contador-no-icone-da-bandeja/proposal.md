# Proposal

## Why

No pacote Electron o número de mensagens não lidas só aparece no tooltip da bandeja, que ninguém vê sem passar o mouse. `app.setBadgeCount` devolve `false` no KDE e não mostra nada. O modo tray (PyQt6) já desenha o número sobre o ícone, e a auditoria de 10/09/2026 lista a diferença como a primeira pendência do app Electron.

## What Changes

- O ícone da bandeja ganha uma bolinha vermelha com o número de não lidas, de 1 a 9, e "9+" acima disso, no mesmo estilo do modo tray.
- Sem mensagens não lidas, o ícone volta ao normal.
- Os ícones com número são arquivos PNG gerados por um script versionado no repositório e empacotados junto com o app. Nada é desenhado em tempo de execução.
- O tooltip e a chamada a `app.setBadgeCount` continuam como hoje.

## Capabilities

### New Capabilities

- `contador-de-nao-lidas`: como o app Electron mostra o número de mensagens não lidas fora da janela (ícone da bandeja e tooltip).

### Modified Capabilities

## Impact

- `electron/src/main.js`: `atualizarNaoLidas` troca a imagem da bandeja, e `montarBandeja` passa a partir do contador atual.
- `electron/build/`: ícones novos `tray-1.png` a `tray-9.png` e `tray-9mais.png`, com versões `@2x`, mais o `tray@2x.png` sem número.
- `electron/scripts/gerar-icones-bandeja.py`: script novo que gera os PNGs. Precisa de Python com Pillow só para quem regenera os ícones, não para quem roda o app.
- `electron/package.json`: `build.files` passa a incluir os ícones novos.
- `electron/README.md` ("O que o app faz") e a pendência em `docs/auditorias.md`.
- Só o pacote Electron. O modo tray já tem o contador desenhado.
