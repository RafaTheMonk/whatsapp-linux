# Design

## Context

Build atual: `npm ci`, `node node_modules/electron/install.js` (o npm 11 bloqueia o postinstall do Electron) e `npm run dist` em `electron/`. O `publish` do electron-builder está desligado de propósito, para não embutir `app-update.yml`. O app consulta `releases/latest` uma vez por dia.

## Goals / Non-Goals

**Goals:**
- Pacote rastreável até o commit, com procedência assinada.
- Nenhuma publicação automática: rascunho, e um humano publica.

**Non-Goals:**
- ARM64: fica para depois. O mesmo workflow ganha uma matriz com runner ARM quando for a vez.
- Build bit a bit reproduzível: electron-builder grava datas nos pacotes. A garantia aqui é a procedência, não a igualdade de hash com um build local.

## Decisions

**1. Gatilho por tag `v*` e `workflow_dispatch`.** A tag é o ato consciente de lançar uma versão. O disparo manual serve para testar o workflow sem gastar uma versão.

**2. Rascunho em vez de publicar.** Uma release publicada vira aviso na bandeja de todo mundo em até um dia. Um erro no workflow não pode chegar aos usuários sem alguém olhar.

**3. `gh release create` com o `GITHUB_TOKEN` em vez de ação de terceiros.** O `gh` já vem no runner. Menos código de terceiros com permissão de escrita no repositório.

**4. Ações fixadas por SHA de commit** (checkout, setup-node, upload-artifact e attest-build-provenance). Tag de ação pode ser movida. O comentário ao lado do SHA diz a versão, para quem for atualizar.

**5. Permissões mínimas por job.** `contents: read` por padrão. `contents: write`, `id-token: write` e `attestations: write` só no job da tag.

**6. `SHA256SUMS.txt` do repositório continua existindo** como segundo canal, pelo histórico do git. O workflow não escreve na `main`. Depois de publicar, um passo documentado baixa o arquivo da release e o commita.

## Risks / Trade-offs

- [O workflow só é testado de verdade no GitHub] → Disparo manual primeiro. A primeira tag real é a da próxima versão.
- [O runner do GitHub gerar `.deb` diferente do local, por exemplo por falta de dependência do fpm] → O disparo manual mostra isso antes de qualquer tag.
- [Checksums do CI diferentes dos de um build local] → Esperado, por causa das datas. A conferência passa a ser contra a release e a atestação.

## Migration Plan

A próxima versão sai pelo CI. As releases até a 1.0.3 continuam como estão, sem atestação.
