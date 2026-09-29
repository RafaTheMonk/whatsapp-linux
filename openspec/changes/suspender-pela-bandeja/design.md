# Design

## Context

Medições de 29/09/2026 com o app oculto, depois de 90 s carregando: página ~470 a 670 MB, processo principal ~140 MB (o Electron vazio fica em ~90 MB), GPU ~90 MB, rede ~33 MB, auxiliares ~80 MB. Com a GPU desligada o total não caiu (788 contra 796 MB) e a CPU parada subiu de 5% para 7,6%. Sem o corretor, o processo principal caiu só 3 a 6 MB.

`alternar` e o `second-instance` já recriam a janela quando ela não existe, mas o `ready-to-show` só mostra se o app não foi iniciado com `--hidden`.

## Goals / Non-Goals

**Goals:**
- Liberar a memória da página com um clique e voltar com um clique.
- Deixar claro que, suspenso, não chegam mensagens.

**Non-Goals:**
- Suspender sozinho por tempo escondido (decisão do usuário: só manual).
- Reduzir o piso do Electron (principal, GPU, rede), que continua enquanto o ícone existe.

## Decisions

**1. Suspender é destruir a janela, não congelar a página.**
`janela.destroy()` encerra o renderer e devolve a memória. Congelar a página (estado `frozen` do ciclo de vida) para o JavaScript, mas mantém toda a memória, que é justamente o que se quer liberar. `destroy` pula o evento `close`, então o esconder-no-X não interfere. Os limites da janela são salvos antes.

**2. Voltar reaproveita `montarJanela`.**
Um flag `suspenso` diz que a próxima janela criada deve aparecer quando estiver pronta, ignorando o `--hidden` do início. O flag é zerado ao recriar. O mesmo vale para a janela criada pelo `second-instance`, que é quando o usuário abre o app pelo menu. Nesse caso ele quer ver a janela.

**3. Ícone cinza pré-gerado, como os do contador.**
O mesmo script gera `tray-suspenso.png` e `@2x` convertendo a base para tons de cinza. `desenharContador` passa a considerar o estado suspenso antes do número.

**4. O contador zera ao suspender.**
Sem página não há título para ler, e mostrar um número velho enganaria. Ao voltar, o título novo repõe o número.

## Risks / Trade-offs

- [Usuário esquece que suspendeu e perde mensagens] → Ícone cinza, tooltip explícito e nada automático.
- [Quanto sobra suspenso não é conhecido ainda] → Medir na implementação e registrar no README. A estimativa pelo Electron vazio é de 200 a 250 MB.
- [Voltar demora o tempo de o WhatsApp carregar e sincronizar] → Aceito. É o custo da economia.
- [O `window-all-closed` encerrar o app com a janela destruída] → Já faz `preventDefault` quando há bandeja. Sem bandeja o item não existe, porque o menu é da própria bandeja.

## Migration Plan

Entra na próxima versão. Nada muda para quem não usa o item novo.
