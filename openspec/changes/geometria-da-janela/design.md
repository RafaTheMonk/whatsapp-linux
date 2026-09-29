# Design

## Context

`salvarBounds` grava `getNormalBounds()` quando a janela está visível e não minimizada, no `close` e no `before-quit`. `montarJanela` espalha os limites salvos no construtor da `BrowserWindow`. No Wayland o compositor ignora a posição pedida pelo cliente, então o risco de abrir fora da tela é do X11. O tamanho vale nos dois.

Lição do modo tray (15/09/2026): comportamento de janela no Wayland só vale medido pelo KWin, acionando pelo compositor, e não pelo que o toolkit reporta.

## Goals / Non-Goals

**Goals:**
- Reabrir maximizada quando fechou maximizada, com restaurar funcionando.
- Nunca abrir fora de todos os monitores.

**Non-Goals:**
- Lembrar em qual monitor abrir no Wayland, que não deixa o cliente escolher.
- Tela cheia (F11): não é persistida.

## Decisions

**1. Gravar `maximizada` junto com os limites normais.**
`getNormalBounds()` já devolve o tamanho de antes de maximizar, então o tamanho normal fica certo mesmo gravando com a janela maximizada. O construtor recebe o tamanho normal, e `maximize()` é chamado antes do `show()`. Assim o compositor recebe a janela já maximizada, com o tamanho normal por baixo para o restaurar.

**2. Validar contra `screen.getAllDisplays()` pela área útil.**
Um retângulo vale se a interseção com a `workArea` de algum monitor tiver pelo menos 100x100 px, o bastante para achar e arrastar a barra de título. Se não valer, a posição sai do objeto (o sistema centraliza) e o tamanho é limitado à `workArea` do monitor principal.

## Risks / Trade-offs

- [`maximize()` antes do primeiro `show()` não pegar no Wayland] → Medido pelo KWin (`maximizeMode`) no teste. Se não pegar, chamar no `ready-to-show` logo depois do `show()`.
- [Tamanho salvo igual ao da tela, herdado de outro bug] → O modo tray teve isso. No Electron o `getNormalBounds` não sofre do mesmo caminho, e o guia registra que o Electron foi testado nesse cenário sem o defeito.

## Migration Plan

Sem migração: o campo novo é opcional.
