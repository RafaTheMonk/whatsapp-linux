# Proposal

## Why

Com `spellcheck: true`, o Chromium do app baixa o dicionário pt-BR (3,9 MB) de um servidor do Google. O `DISTRIBUICAO.md` promete que o app só acessa o WhatsApp e a página de releases do GitHub, e a auditoria de 10/09/2026 apontou a contradição. As sugestões do corretor também não apareceram no menu de contexto no teste de 29/09/2026, e desligar economiza só 3 a 6 MB de RAM. Decisão do usuário em 29/09/2026: desligar.

## What Changes

- O corretor ortográfico do app Electron fica desligado: nada é sublinhado e nenhum dicionário é baixado.
- O menu de contexto perde o bloco de sugestões e "Adicionar ao dicionário", que dependia do corretor.
- A documentação diz que não há corretor e onde fica o dicionário baixado por versões anteriores, para quem quiser apagar.

## Capabilities

### New Capabilities

- `acessos-de-rede`: a quais servidores o app Electron fala, e a garantia de que não fala com mais nenhum.

### Modified Capabilities

## Impact

- `electron/src/main.js`: `spellcheck: false` e remoção do bloco do corretor em `menuDeContexto`.
- `electron/README.md`, `electron/DISTRIBUICAO.md` (Privacidade) e a pendência em `docs/auditorias.md`.
- Quem já usa fica com o arquivo `~/.config/whatsapp-linux/Dictionaries/pt-BR-3-0.bdic` sobrando. O app não apaga nada no perfil do usuário.
