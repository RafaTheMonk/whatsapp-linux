# Tasks

## 1. Ícones

- [ ] 1.1 Renomear o script para `electron/scripts/gerar-icones.py` com `git mv`, gerar também `build/icons/NxN.png` nos oito tamanhos, rodar e conferir com `file` os tamanhos e com `git status` que os ícones da bandeja não mudaram
- [ ] 1.2 Apontar `linux.icon` para `build/icons` e incluir `build/icons/*.png` em `build.files`, gerar o `.deb` e verificar pela listagem do pacote os oito tamanhos em hicolor

## 2. Atalho

- [ ] 2.1 Fazer `oferecerIntegracao` valer para AppImage e para pacote fora de `/opt`, e `escreverAtalho` copiar os oito tamanhos, e verificar com `node --check`
- [ ] 2.2 Descompactar o `tar.gz` gerado numa pasta temporária, rodar com `XDG_DATA_HOME` e `XDG_CONFIG_HOME` temporários, responder "Adicionar" na mão e verificar o `.desktop` e os ícones criados na pasta temporária

## 3. Documentação

- [ ] 3.1 Atualizar o trecho do `tar.gz` em `electron/DISTRIBUICAO.md`, as referências ao nome do script e as duas pendências em `docs/auditorias.md`, e verificar lendo
