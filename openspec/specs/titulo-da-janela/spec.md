# titulo-da-janela Specification

## Purpose
Define o título que a janela do app Electron mostra ao sistema, independente do título que o WhatsApp Web põe na página.

## Requirements

### Requirement: Título fixo
A janela SHALL mostrar o título "WhatsApp Linux" o tempo todo. O título da página MUST continuar sendo lido para o contador de não lidas.

#### Scenario: Chega mensagem
- **WHEN** o WhatsApp Web muda o título da página para "(4) WhatsApp"
- **THEN** o compositor continua mostrando "WhatsApp Linux" como título da janela, e o tooltip da bandeja diz "WhatsApp Linux - 4 nao lidas"
