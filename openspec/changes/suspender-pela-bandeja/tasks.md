# Tasks

## 1. Ícone

- [ ] 1.1 Estender `electron/scripts/gerar-icones-bandeja.py` para gerar `tray-suspenso.png` e `tray-suspenso@2x.png` em cinza, rodar e conferir com `file` os tamanhos 22x22 e 44x44 e olhando a imagem

## 2. Suspender e voltar

- [ ] 2.1 Em `electron/src/main.js`, adicionar o item "Suspender" ao menu da bandeja (desabilitado quando suspenso) que salva os limites, zera o contador e destrói a janela, e verificar com `node --check`
- [ ] 2.2 Fazer `desenharContador` e o tooltip refletirem o estado suspenso, e verificar com `node --check`
- [ ] 2.3 Fazer a janela recriada por `alternar` ou `second-instance` aparecer ao ficar pronta mesmo com `--hidden`, e verificar com `node --check`
- [ ] 2.4 Fechar o app instalado, conferir com `pgrep -af` que saiu, rodar a versão de teste e verificar na mão: suspender deixa o ícone cinza e o tooltip certo, clique no ícone volta sem QR code, "Sair" suspenso encerra
- [ ] 2.5 Medir somando o PSS de cada processo do app (`/proc/<pid>/smaps_rollup`) a memória antes e depois de suspender e registrar os números no design
- [ ] 2.6 Rodar a versão de teste com `--hidden`, suspender e confirmar que o clique no ícone mostra a janela

## 3. Documentação

- [ ] 3.1 Explicar em `electron/README.md` ("O que o app faz") e em `electron/DISTRIBUICAO.md` o item Suspender, quanto libera e que suspenso não chegam mensagens, e verificar lendo as seções
