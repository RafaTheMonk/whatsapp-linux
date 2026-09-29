# perfil-isolado-do-modo-leve Specification

## Purpose
Define o que o modo leve configura no perfil isolado do navegador quando o cria, para que o perfil do WhatsApp não mande telemetria que o usuário não escolheu.

## Requirements

### Requirement: Brave nasce sem telemetria no perfil isolado
Ao criar o perfil isolado com o Brave, o modo leve SHALL gravar no `Local State` do perfil `brave.p3a.enabled`, `brave.stats.reporting_enabled` e `user_experience_metrics.reporting_enabled` como `false`, e `brave.p3a.notice_acknowledged` como `true`, antes de o navegador abrir pela primeira vez. As opções MUST continuar desligadas depois que o Brave abre e fecha.

#### Scenario: Primeira abertura com Brave
- **WHEN** o modo leve roda com o Brave e o perfil isolado não existe
- **THEN** depois de o Brave abrir e fechar, o `Local State` do perfil tem as três opções desligadas

### Requirement: Perfil existente e outros navegadores intocados
O modo leve MUST NOT alterar o `Local State` de um perfil que já existe, e MUST NOT gravar nada disso quando o navegador não é o Brave.

#### Scenario: Perfil já existente
- **WHEN** o perfil isolado já tem `Local State`
- **THEN** o arquivo continua igual depois de o modo leve rodar

#### Scenario: Chromium
- **WHEN** o navegador escolhido é o Chromium e o perfil é novo
- **THEN** o modo leve não grava `Local State`, e o Chromium cria o seu
