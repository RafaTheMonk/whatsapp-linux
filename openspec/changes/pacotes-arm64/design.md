# Design

## Context

O workflow atual (`release.yml`) tem um job só, em `ubuntu-24.04`, que gera, atesta e cria a release. O electron-builder gera para a arquitetura da máquina em que roda, e o `npm ci` baixa o binário do Electron da mesma arquitetura. Os nomes de AppImage e `.deb` já usam `${arch}`; o do `tar.gz` é o padrão, sem arquitetura.

## Goals / Non-Goals

**Goals:**
- Pacotes arm64 com a mesma garantia dos x64: máquina limpa, lock exato, checksums, atestação.

**Non-Goals:**
- Testar o app rodando em hardware ARM: não há um disponível. A documentação diz isso.
- armv7 (Raspberry Pi 3 e anteriores de 32 bits): a release oficial do Electron 44.3.0 só traz binário Linux para x64 e arm64 (conferido na lista de arquivos da release em 30/09/2026). Não há o que empacotar.

## Decisions

**1. Runner nativo (`ubuntu-24.04-arm`) em vez de compilação cruzada.** O electron-builder consegue gerar arm64 numa máquina x64, mas o AppImage e o `.deb` dependem de ferramentas da arquitetura de destino, e o runner ARM é gratuito para repositório público. Cada job gera e confere o que é seu.

**2. Separar build e release em jobs.** Os jobs da matriz só geram e sobem artefatos, com `contents: read`. Um job `release`, que depende dos dois, baixa tudo, calcula um `SHA256SUMS.txt` único, atesta e cria o rascunho. Só ele tem permissão de escrita e de assinatura. Um `SHA256SUMS.txt` por arquitetura quebraria o `sha256sum -c` de quem baixa os dois, e duas releases concorrentes disputariam o mesmo rascunho.

**3. Conferir a arquitetura dos binários no próprio job.** Depois do build, `file` no executável dentro de `dist/linux*-unpacked/` tem que dizer `x86-64` ou `ARM aarch64`, conforme a matriz. Sem isso, um erro de configuração poderia publicar dois pacotes x64 com nome de arm64.

**4. `tar.gz` com `${arch}` no nome, também no x64.** Nome de arquivo não é contrato do app (a checagem de versão olha só a tag), mas é o que o usuário digita no terminal. Documentação atualizada junto.

## Risks / Trade-offs

- [Pacote arm64 com defeito que só aparece rodando em ARM] → Documentado como "gerado e conferido no CI, sem teste em hardware ARM". Quem testar pode abrir issue.
- [`fpm` ou `appimagetool` sem suporte no runner ARM] → O disparo manual mostra antes de qualquer tag.
- [Quem tem script com o nome antigo do `tar.gz`] → Documentado na nota da versão.

## Migration Plan

Vale a partir da próxima versão. Releases até a 1.0.3 continuam só x64.
