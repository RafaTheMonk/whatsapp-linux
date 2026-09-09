# Post para o LinkedIn

Três parágrafos, tom direto, sem jargão de marketing. Ajuste o link do repositório
antes de publicar.

---

Quem migra pro Linux sempre sente falta de alguma coisa. Comigo foi o WhatsApp.
No Windows existe o app de desktop, com janela própria, ícone na barra e
notificação que chega sozinha. No Linux não existe cliente nativo oficial: a Meta
nunca lançou um. Sobra o WhatsApp Web numa aba, que se perde no meio das outras
trinta e morre junto quando você fecha o navegador. Fui atrás de resolver isso e
acabei descobrindo que a solução mais confiável era também a mais simples.

A primeira ideia foi embrulhar tudo num Electron. Descartei rápido: o Nativefier,
que era a ferramenta clássica pra isso, foi arquivado pelo autor e gera builds
presos a versões velhas do Chromium, o que faz o próprio WhatsApp Web reclamar de
navegador sem suporte. Escrever um Electron na mão funciona, mas são 200 MB de
runtime e a manutenção fica com você. O que sobrou foi bem melhor: o Chromium já
instalado na máquina tem um modo `--app`, que abre uma URL em janela pura, sem
abas e sem barra de endereços. Somei a isso um `--user-data-dir` apontando pra um
perfil isolado, e de graça vieram três coisas: a sessão do WhatsApp não se mistura
com o navegador do dia a dia, fechar o navegador principal não derruba o app, e as
extensões do perfil normal não interferem na página. Zero dependência nova, zero
código de terceiro entre mim e o site oficial.

O detalhe que consumiu mais tempo foi o que menos aparece: no KDE Plasma sobre
Wayland o Chromium ignora a flag `--class`, então o `StartupWMClass` do arquivo
`.desktop` não batia e a janela aparecia na barra de tarefas sem ícone e sem
agrupar com o lançador. O `app_id` real é montado pelo navegador no formato
`<produto>-<host>__-<perfil>`, tipo `brave-web.whatsapp.com__-Default`. Descobri
isso consultando o KWin por D-Bus, e virou um script do projeto que detecta e
corrige sozinho. Empacotei tudo com instalador, desinstalador, ícone e entrada de
menu, e deixei no GitHub. Se você também sente falta do app do WhatsApp no Linux,
são dois comandos: [link do repositório]

---

## Variação mais curta, se quiser cortar

Use o primeiro e o terceiro parágrafo, e substitua o segundo por:

> Descartei o Electron: o Nativefier está arquivado e escrever um na mão custa
> 200 MB de runtime. A saída foi o modo `--app` do Chromium que já estava
> instalado, com um perfil isolado por cima. Nenhuma dependência nova.

## Hashtags sugeridas

#Linux #KDE #Wayland #WhatsApp #OpenSource #Shell
