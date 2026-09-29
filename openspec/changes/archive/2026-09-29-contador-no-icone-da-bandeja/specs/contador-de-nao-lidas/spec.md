# Spec Delta

## Purpose

Define como o app Electron mostra o número de conversas com mensagem não lida fora da janela, para que dê para saber que chegou mensagem com a janela escondida na bandeja.

## ADDED Requirements

### Requirement: Número de não lidas no ícone da bandeja
O app SHALL mostrar sobre o ícone da bandeja uma marca com o número que o WhatsApp Web põe no título da página, que é a quantidade de conversas com mensagem não lida, e não de mensagens. De 1 a 9 a marca MUST mostrar o número exato. Acima de 9 MUST mostrar "9+". O ícone MUST ser atualizado sem precisar abrir a janela.

#### Scenario: Chega mensagem com a janela escondida
- **WHEN** a janela está escondida na bandeja e o título da página passa de "WhatsApp" para "(3) WhatsApp"
- **THEN** o ícone da bandeja passa a mostrar a marca com o número 3

#### Scenario: Mais de nove não lidas
- **WHEN** o título da página indica 12 conversas não lidas
- **THEN** o ícone da bandeja mostra a marca com "9+"

#### Scenario: Tudo lido
- **WHEN** o título da página volta a não ter contador
- **THEN** o ícone da bandeja volta ao ícone normal, sem marca

### Requirement: Tooltip continua com o número
O tooltip da bandeja MUST continuar informando o número exato de conversas não lidas, também acima de 9, para quem precisa do valor exato.

#### Scenario: Número exato no tooltip
- **WHEN** há 12 conversas não lidas e o usuário passa o mouse sobre o ícone da bandeja
- **THEN** o tooltip diz "WhatsApp Linux - 12 nao lidas"

### Requirement: Sem dependência nova para quem usa
Mostrar o número no ícone MUST NOT exigir nenhum programa ou biblioteca instalado na máquina de quem roda o pacote, e MUST NOT gerar requisição de rede.

#### Scenario: Pacote em máquina limpa
- **WHEN** o AppImage roda numa distro sem Python nem Pillow
- **THEN** o número aparece no ícone da bandeja do mesmo jeito
