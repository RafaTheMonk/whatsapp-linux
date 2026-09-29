# Spec Delta

## Purpose

Lista os servidores com que o app Electron conversa por conta própria, para que a promessa de privacidade do `DISTRIBUICAO.md` seja verificável.

## ADDED Requirements

### Requirement: Só WhatsApp e checagem de versão
Por conta própria, o app SHALL acessar apenas os hosts do WhatsApp e a API de releases do GitHub, esta no máximo uma vez por dia e só enquanto "Avisar sobre atualização" estiver ligado. O app MUST NOT baixar dicionário do corretor nem nenhum outro recurso de servidor de terceiros.

#### Scenario: Primeira execução em perfil novo
- **WHEN** o app roda pela primeira vez, sem nada em `~/.config/whatsapp-linux`
- **THEN** nenhum dicionário é baixado e a pasta `Dictionaries` não é criada

### Requirement: Sem corretor ortográfico
A caixa de digitar MUST NOT sublinhar palavras, e o menu de contexto MUST NOT oferecer sugestões de correção nem "Adicionar ao dicionário".

#### Scenario: Palavra errada na caixa de digitar
- **WHEN** o usuário digita "cassa" e clica com o botão direito na palavra
- **THEN** não há sublinhado e o menu mostra só os itens de edição
