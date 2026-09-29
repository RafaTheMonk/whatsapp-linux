# Tasks

## 1. Ícones

- [x] 1.1 Criar `electron/scripts/gerar-icones-bandeja.py` que gera `tray@2x.png`, `tray-1.png` a `tray-9.png`, `tray-9mais.png` e as versões `@2x` em `electron/build/`, e verificar rodando o script e conferindo com `file electron/build/tray*.png` os tamanhos 22x22 e 44x44
- [x] 1.2 Olhar os PNGs gerados (1, 5, 9+ nas duas escalas) e confirmar que o número está legível e a marca segue o visual do modo tray
- [x] 1.3 Incluir os ícones novos em `build.files` do `electron/package.json` e verificar com `npm run dist:appimage` seguido de listar o `app.asar` ou o `linux-unpacked` que eles estão no pacote

## 2. Bandeja

- [x] 2.1 Em `electron/src/main.js`, trocar a imagem da bandeja pelo rótulo do contador em `atualizarNaoLidas`, só quando o rótulo muda e com `try/catch`, e verificar com `node --check`
- [x] 2.2 Fazer `montarBandeja` partir da imagem do contador atual e verificar com `node --check`
- [x] 2.3 Fechar o app instalado, conferir com `pgrep -af` que ele saiu, rodar `npm start` e verificar na mão: mensagem nova com a janela escondida mostra o número no ícone, ler a conversa tira a marca, e o tooltip continua com o número exato

## 3. Documentação

- [x] 3.1 Atualizar em `electron/README.md` a linha do contador em "O que o app faz" e verificar lendo a seção
- [x] 3.2 Tirar a pendência do contador de `docs/auditorias.md`, com a data da correção, e verificar lendo a seção Pendências
- [x] 3.3 Explicar no cabeçalho do script como regenerar os ícones (Pillow só para isso) e verificar lendo o arquivo
