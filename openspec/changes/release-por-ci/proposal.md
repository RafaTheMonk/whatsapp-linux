# Proposal

## Why

Até a 1.0.3 os pacotes foram gerados e publicados na mão, na máquina do autor. Quem baixa não tem como saber se o binário saiu do código do repositório ou de um estado local qualquer, e o próprio `dist/` local já chegou a ter pacote com nome de uma versão e conteúdo de outra (29/09/2026). Pendência "fora do código" da auditoria de 10/09/2026.

## What Changes

- Workflow do GitHub Actions que, ao receber uma tag `vX.Y.Z`, confere se ela bate com a versão do `electron/package.json`, gera AppImage, `.deb` e `tar.gz` numa máquina limpa a partir do `package-lock.json`, calcula o `SHA256SUMS.txt`, gera a atestação de procedência dos pacotes e cria a release como **rascunho**.
- Disparo manual do mesmo workflow, que só gera os pacotes como artefatos, sem release, para testar.
- Ações de terceiros fixadas por SHA de commit.
- Documentação: como publicar uma versão pelo CI e como conferir a procedência com `gh attestation verify`.

## Capabilities

### New Capabilities

- `publicacao-de-versao`: como uma versão do pacote Electron é gerada, conferida e publicada.

### Modified Capabilities

## Impact

- `.github/workflows/release.yml`: novo.
- `electron/README.md` (publicar), `README.md` (verificar o binário) e o guia local.
- `docs/auditorias.md`: a pendência.
- Nenhuma mudança no app.
