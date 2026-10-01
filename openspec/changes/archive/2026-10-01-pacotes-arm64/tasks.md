# Tasks

## 1. Build

- [x] 1.1 Pôr `${arch}` no `artifactName` do `tar.gz` e verificar com um `npm run dist` local que sai `whatsapp-linux-X.Y.Z-x64.tar.gz`
- [x] 1.2 Reescrever `.github/workflows/release.yml`: matriz `ubuntu-24.04` e `ubuntu-24.04-arm` para gerar e conferir a arquitetura com `file`; job `release` (só na tag) que junta, calcula checksums, atesta e cria o rascunho. Verificar que o YAML carrega e que as permissões de escrita estão só no job `release`
- [x] 1.3 Com o ok do usuário, fazer push, disparar à mão e verificar pelos logs que o passo de conferência disse `ARM aarch64` no job arm64 e `x86-64` no x64, e que os seis pacotes saíram como artefato

## 2. Documentação

- [x] 2.1 Atualizar as tabelas de download e os nomes de arquivo no `README.md`, `electron/README.md` e `electron/DISTRIBUICAO.md`, com ARM64 marcado como não testado em hardware, e verificar lendo
- [x] 2.2 Marcar a pendência do ARM64 em `docs/auditorias.md` e atualizar o guia local, e verificar lendo
