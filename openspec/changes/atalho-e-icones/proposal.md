# Proposal

## Why

Duas pendências de empacotamento da auditoria de 10/09/2026. O `.deb` instala só o ícone de 512x512 (conferido no pacote 1.0.2), e a barra de tarefas e o menu, que usam 16 a 48 px, reduzem esse na hora ou caem no ícone genérico. E o `tar.gz`, que a documentação oferece como saída para quem tem AppImageLauncher, não cria atalho nem instala ícone: o app só aparece no menu se o usuário escrever o `.desktop` à mão.

## What Changes

- Ícones de 16, 24, 32, 48, 64, 128, 256 e 512 px gerados a partir do `icon.png` e usados pelo electron-builder no `.deb` e no AppImage.
- A oferta "Adicionar ao menu de aplicativos" da primeira execução, que hoje só existe no AppImage, passa a valer também para o `tar.gz`. Criar o atalho instala o ícone em todos os tamanhos.
- O `.deb` continua sem a oferta, porque o pacote já instala o próprio atalho.

## Capabilities

### New Capabilities

- `integracao-com-o-menu`: como o app Electron aparece no menu de aplicativos e com quais ícones, em cada formato de pacote.

### Modified Capabilities

## Impact

- `electron/scripts/gerar-icones-bandeja.py` vira `electron/scripts/gerar-icones.py` e gera também `build/icons/NxN.png`.
- `electron/package.json`: `linux.icon` aponta para `build/icons`, e `build.files` inclui os ícones para a criação de atalho em tempo de execução.
- `electron/src/main.js`: `oferecerIntegracao`, `escreverAtalho` e o texto da pergunta.
- `electron/DISTRIBUICAO.md` (tar.gz) e as duas pendências em `docs/auditorias.md`.
