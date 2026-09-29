# menu-de-contexto Specification

## Purpose
Define o que o clique direito faz no app Electron: quando abre o menu do sistema, com copiar e colar, e quando fica com o menu do próprio WhatsApp Web.

## Requirements

### Requirement: Menu do sistema sobre texto selecionado
O app SHALL abrir o menu de contexto do sistema quando o clique direito acontece com texto selecionado na página, mesmo que o WhatsApp Web tente cancelar o evento. O menu MUST conter o item Copiar, que copia o texto selecionado para a área de transferência.

#### Scenario: Copiar trecho de mensagem
- **WHEN** o usuário seleciona parte do texto de uma mensagem e clica com o botão direito sobre a seleção
- **THEN** o menu do sistema aparece com Copiar, e escolher Copiar deixa o trecho na área de transferência

#### Scenario: Seleção só de espaços
- **WHEN** a seleção contém apenas espaços ou quebras de linha
- **THEN** o app trata como se não houvesse seleção e o clique segue para o WhatsApp

### Requirement: Menu do sistema em campo editável
O app SHALL abrir o menu de contexto do sistema quando o clique direito acontece em campo editável, incluindo a caixa de digitar mensagem e a busca. O menu MUST conter Desfazer, Refazer, Recortar, Copiar, Colar, Colar sem formatação e Selecionar tudo, e cada item MUST ficar desabilitado quando a ação não é possível naquele momento.

#### Scenario: Colar na caixa de digitar
- **WHEN** há texto na área de transferência e o usuário clica com o botão direito na caixa de digitar
- **THEN** o menu do sistema aparece com Colar habilitado, e escolher Colar insere o texto na caixa

#### Scenario: Caixa vazia
- **WHEN** a caixa de digitar está vazia e sem seleção
- **THEN** Recortar e Copiar aparecem desabilitados

### Requirement: Itens de link e imagem
Quando o menu do sistema abre sobre um link, ele SHALL incluir "Abrir link no navegador" e "Copiar endereço do link". Abrir o link MUST seguir a mesma lista fechada de esquemas externos que o app já usa para links. Links `blob:` MUST ficar de fora. Quando o menu abre sobre uma imagem, ele SHALL incluir "Copiar imagem" e "Salvar imagem como...".

#### Scenario: Link com esquema bloqueado
- **WHEN** o menu abre sobre um link com esquema fora da lista (por exemplo `file:`)
- **THEN** "Abrir link no navegador" não abre nada, igual ao clique normal num link desses

### Requirement: Menu do WhatsApp preservado no resto
Fora dos casos de seleção e de campo editável, o clique direito SHALL chegar ao WhatsApp Web sem interferência, para que o menu próprio dele (responder, reagir, encaminhar e outros) continue abrindo. Quando nenhum item do menu do sistema se aplica, o app MUST NOT abrir menu vazio.

#### Scenario: Mensagem sem seleção
- **WHEN** o usuário clica com o botão direito numa mensagem sem nada selecionado
- **THEN** abre o menu do WhatsApp, como antes desta mudança

### Requirement: Sem exposição nova para a página
A interceptação do clique direito MUST NOT expor API do Node, do Electron ou do app para o código da página, e MUST NOT gerar requisição de rede nova.

#### Scenario: Página não enxerga o app
- **WHEN** o código do WhatsApp Web inspeciona `window`
- **THEN** não encontra nenhum objeto ou função colocado pelo app
