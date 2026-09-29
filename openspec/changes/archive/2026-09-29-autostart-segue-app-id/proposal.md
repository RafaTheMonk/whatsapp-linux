# Proposal

## Why

`scripts/autostart.sh` liga o autostart copiando o `.desktop` do menu para `~/.config/autostart/`, e no modo tray acrescenta `--hidden` ao `Exec`, o que impede um symlink. Se depois o `scripts/detect-app-id.sh` corrige o `StartupWMClass` do menu, a cópia do autostart continua com o valor antigo, e a janela aberta na sessão cai na barra de tarefas sem ícone. Pendência da auditoria de 10/09/2026.

## What Changes

- `detect-app-id.sh` passa a corrigir o `StartupWMClass` também na cópia do autostart, quando ela existe.
- A checagem de "já estava correto" considera os dois arquivos: se o menu está certo e o autostart não, o autostart é corrigido.

## Capabilities

### New Capabilities

- `autostart-dos-modos-shell`: como o autostart dos modos leve e tray fica coerente com a entrada de menu.

### Modified Capabilities

## Impact

- `scripts/detect-app-id.sh`.
- `docs/auditorias.md`: a pendência.
