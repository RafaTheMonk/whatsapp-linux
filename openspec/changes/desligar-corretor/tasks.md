# Tasks

## 1. Corretor

- [ ] 1.1 Trocar para `spellcheck: false` em `electron/src/main.js` e remover o bloco de sugestões e "Adicionar ao dicionario" de `menuDeContexto`, e verificar com `node --check` e `grep -n misspelled electron/src/main.js` sem resultado
- [ ] 1.2 Rodar a versão de teste com um perfil vazio (`XDG_CONFIG_HOME` apontando para uma pasta temporária) e verificar que a pasta `Dictionaries` não é criada depois de a página carregar
- [ ] 1.3 Fechar o app instalado, conferir com `pgrep -af`, rodar a versão de teste com o perfil real e verificar na mão que palavra errada não é sublinhada e que o clique direito na caixa de digitar mostra só os itens de edição

## 2. Documentação

- [ ] 2.1 Dizer na seção Privacidade do `electron/DISTRIBUICAO.md` que não há corretor e que versões anteriores deixaram `~/.config/whatsapp-linux/Dictionaries/`, que pode ser apagada, e verificar lendo a seção
- [ ] 2.2 Registrar em `electron/README.md` ("O que o app faz") que o corretor é desligado de propósito, e verificar lendo a seção
- [ ] 2.3 Marcar a pendência do spellcheck como resolvida em `docs/auditorias.md`, com a data, e verificar lendo a seção Pendências
