# geometria-da-janela Specification

## Purpose
Define como a janela do app Electron guarda e recupera tamanho, posição e estado maximizado entre uma execução e outra, sem nunca abrir fora da tela.

## Requirements

### Requirement: Lembrar maximizada
Se a janela estava maximizada quando o app foi encerrado, ela SHALL reabrir maximizada. Restaurar pelo botão da barra de título MUST devolver o tamanho normal que ela tinha antes de maximizar, e não o tamanho da tela.

#### Scenario: Fechou maximizada
- **WHEN** o usuário maximiza a janela, encerra o app e abre de novo
- **THEN** a janela abre maximizada, segundo o compositor

#### Scenario: Restaurar depois de reabrir
- **WHEN** a janela reabriu maximizada e o usuário clica em restaurar na barra de título
- **THEN** ela volta ao tamanho normal salvo, menor que a área da tela

### Requirement: Nunca abrir fora da tela
Antes de aplicar os limites salvos, o app MUST conferir se o retângulo salvo cai dentro da área útil de algum monitor conectado. Se não cair, o app MUST descartar a posição e limitar largura e altura à área útil do monitor principal.

#### Scenario: Monitor desconectado
- **WHEN** os limites salvos apontam para uma posição que nenhum monitor conectado cobre
- **THEN** a janela abre num monitor conectado, inteira dentro da área útil

#### Scenario: Estado sem o campo novo
- **WHEN** o `estado.json` foi gravado por uma versão anterior, sem saber se estava maximizada
- **THEN** a janela abre no tamanho salvo, não maximizada
