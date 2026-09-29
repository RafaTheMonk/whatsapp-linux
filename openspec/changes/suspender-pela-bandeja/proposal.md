# Proposal

## Why

O app Electron ocupa de 800 MB a 1 GB de RAM o tempo todo, mesmo escondido na bandeja. Medido em 29/09/2026: a página do WhatsApp Web sozinha pesa de 470 a 670 MB, e o resto é o piso do Electron. As otimizações testadas (desligar a aceleração por hardware, desligar o corretor) não reduziram o total. A única economia grande é fechar a página quando o usuário não precisa dela, e o usuário pediu isso como uma ação manual.

## What Changes

- Item novo "Suspender" no menu da bandeja: fecha a página do WhatsApp e libera a memória dela, mantendo só o ícone na bandeja.
- Enquanto suspenso, o ícone da bandeja fica cinza e o tooltip avisa que o app está suspenso e não recebe mensagens.
- Clicar no ícone, escolher "Mostrar / ocultar" ou abrir o app de novo pelo menu de aplicativos recarrega o WhatsApp e mostra a janela. O login continua salvo.
- A suspensão é só manual. O app nunca suspende sozinho.
- Correção junto: a janela recriada depois de suspender precisa aparecer mesmo quando o app foi iniciado com `--hidden`. Hoje essa recriação respeitaria o `--hidden` e ficaria invisível.

## Capabilities

### New Capabilities

- `suspensao`: suspender o app pela bandeja para liberar memória, o que muda enquanto está suspenso e como voltar.

### Modified Capabilities

## Impact

- `electron/src/main.js`: menu da bandeja, `alternar`, `second-instance`, `montarJanela` (mostrar ao voltar) e troca do ícone.
- `electron/scripts/gerar-icones-bandeja.py` e `electron/build/`: ícone cinza `tray-suspenso.png` e `@2x`.
- `electron/README.md` e `electron/DISTRIBUICAO.md`: o que é suspender e o que se perde.
- Só o pacote Electron.
