# Spec Delta

## Purpose

Garante que a entrada de autostart dos modos leve e tray use o mesmo `StartupWMClass` da entrada de menu, para a janela aberta na sessão aparecer com ícone.

## ADDED Requirements

### Requirement: Correção do app_id chega ao autostart
Quando `detect-app-id.sh` descobre o `app_id` real da janela, ele SHALL gravá-lo no `StartupWMClass` da entrada de menu e também da entrada de autostart, se ela existir. As outras linhas do autostart, incluindo o `--hidden` do modo tray, MUST continuar iguais.

#### Scenario: Autostart ligado antes da correção
- **WHEN** o autostart foi ligado com `StartupWMClass=antigo` e o `detect-app-id.sh` detecta `novo`
- **THEN** menu e autostart passam a ter `StartupWMClass=novo`, e o `Exec` do autostart mantém o `--hidden`

#### Scenario: Só o autostart desatualizado
- **WHEN** o menu já tem o `app_id` certo e o autostart não
- **THEN** o script corrige o autostart em vez de dizer que já estava tudo certo

#### Scenario: Autostart desligado
- **WHEN** não existe entrada de autostart
- **THEN** o script corrige só o menu e não cria autostart
