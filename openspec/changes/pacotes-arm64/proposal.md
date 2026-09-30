# Proposal

## Why

Só existe pacote x86_64. Quem usa Linux em ARM (Raspberry Pi 4 e 5, notebooks com Snapdragon, Asahi em Mac) não tem o que baixar. Última pendência da auditoria de 10/09/2026. Com a release por CI pronta (29/09/2026), o GitHub oferece runner ARM64 nativo e gratuito para repositório público, sem compilação cruzada.

## What Changes

- O workflow de release gera os três pacotes também para arm64, num runner ARM nativo, em paralelo ao x64.
- Um job final junta os pacotes das duas arquiteturas, calcula um `SHA256SUMS.txt` único, atesta a procedência e cria a release em rascunho.
- **BREAKING (nome de arquivo):** o `tar.gz` passa a levar a arquitetura no nome (`whatsapp-linux-X.Y.Z-x64.tar.gz` e `-arm64.tar.gz`), porque os dois builds teriam o mesmo nome. AppImage e `.deb` já levavam.
- A documentação passa a oferecer ARM64, dizendo que o pacote é gerado e conferido no CI, mas não foi testado rodando em hardware ARM.

## Capabilities

### New Capabilities

### Modified Capabilities

- `publicacao-de-versao`: o build por tag e o teste manual passam a gerar pacotes para x64 e arm64, com checksums e atestação cobrindo os dois.

## Impact

- `.github/workflows/release.yml`: matriz de arquitetura e job de release separado.
- `electron/package.json`: `artifactName` do `tar.gz`.
- `README.md`, `electron/README.md`, `electron/DISTRIBUICAO.md`: tabelas de download e nomes de arquivo.
- `docs/auditorias.md`: a pendência.
- Nenhuma mudança no código do app.
