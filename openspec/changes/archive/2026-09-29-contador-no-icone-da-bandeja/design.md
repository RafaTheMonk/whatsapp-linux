# Design

## Context

`atualizarNaoLidas` em `electron/src/main.js` já extrai o número do título da página e atualiza o tooltip e o `app.setBadgeCount`. A bandeja nasce com `build/tray.png` (22x22) e nunca troca de imagem. O processo principal do Electron não tem canvas nem fonte para desenhar texto. O modo tray desenha a marca com `QPainter`: um círculo vermelho `#e53935` ocupando o quarto superior direito, com o número em branco e negrito, "9+" acima de 9.

## Goals / Non-Goals

**Goals:**
- Mesmo visual do modo tray, legível a 22 px.
- Nada novo para instalar na máquina de quem usa, nada de rede.

**Non-Goals:**
- Contador no ícone da barra de tarefas ou do lançador. O `setBadgeCount` continua como está, e onde não funciona segue sem funcionar.
- Os tamanhos menores do ícone do app (pendência separada da auditoria).

## Decisions

**1. Ícones pré-gerados em vez de desenhar em tempo de execução.**
São 11 estados possíveis (normal, 1 a 9, "9+"). Gerar os PNGs uma vez e versionar custa poucos KB, e trocar a imagem é um `nativeImage.createFromPath`.
Alternativas descartadas: montar um bitmap RGBA na mão com uma fonte de pixels no código, que é muito código para 11 imagens; e desenhar numa janela invisível com canvas, que cria um renderer só para isso.

**2. Script em Python com Pillow, versionado em `electron/scripts/`.**
Pillow desenha texto com a fonte embutida (`ImageFont.load_default(size)`), sem depender de fonte instalada, então o resultado é o mesmo em qualquer máquina. A base 1x é o `build/tray.png` e a base 2x é o `build/icon.png` reduzido para 44 px. O script só roda quando alguém quiser mudar os ícones. O `build.files` não inclui `scripts/`, então ele não vai para o pacote.

**3. Versões `@2x` para todos os estados, incluindo o sem número.**
O `nativeImage.createFromPath` pega sozinho o arquivo `@2x` ao lado. Gerar o `@2x` para todos evita que o ícone mude de nitidez quando o número aparece ou some.

**4. Trocar a imagem só quando o número exibido muda.**
`atualizarNaoLidas` já sai cedo quando o número não mudou. A imagem depende do rótulo ("1" a "9", "9+"), então 12 e 15 usam a mesma e não precisam trocar. Guardar o último rótulo aplicado evita `setImage` à toa.

**5. `montarBandeja` já nasce com o contador atual.**
Se o título chegar antes de a bandeja existir, o número fica guardado em `naoLidas`, e a bandeja criada depois precisa mostrá-lo.

## Risks / Trade-offs

- [O número não bater com a quantidade de mensagens] → É por desenho do WhatsApp: o título conta conversas com não lidas. Visto no teste de 29/09/2026; o navegador mostra o mesmo número. Documentado no README.

- [O KDE ou outro painel ignorar o `@2x` e reduzir a imagem] → Verificado no teste manual. A 1x continua existindo e é a que se usa hoje.
- [Número pequeno demais a 22 px] → Igual ao modo tray, que já está em uso. Se ficar ilegível, trocar o número por um ponto sem texto é mudança só no script.
- [O ícone ficar preso num número antigo se `setImage` falhar] → A troca fica em `try/catch`, e o tooltip continua certo mesmo assim.

## Migration Plan

Entra na próxima versão do pacote. Voltar atrás é tirar a chamada a `setImage`.
