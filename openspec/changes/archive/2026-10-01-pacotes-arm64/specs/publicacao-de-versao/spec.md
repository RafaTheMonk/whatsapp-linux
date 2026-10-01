# Spec Delta

## MODIFIED Requirements

### Requirement: Build por tag em máquina limpa
Uma tag `vX.Y.Z` enviada ao repositório SHALL disparar o build dos três pacotes para x64 e para arm64, cada um num runner nativo da arquitetura, a partir do código daquela tag, com as dependências exatas do `package-lock.json`. O build MUST falhar, sem criar release, se a tag não for igual a `v` seguido da `version` do `electron/package.json`.

#### Scenario: Tag certa
- **WHEN** a tag `v1.0.4` é enviada e o `package.json` diz `1.0.4`
- **THEN** o workflow gera AppImage, `.deb` e `tar.gz` da 1.0.4 para x64 e arm64, cada arquivo com a arquitetura no nome, e um `SHA256SUMS.txt` único com os seis

#### Scenario: Tag errada
- **WHEN** a tag `v1.0.5` é enviada e o `package.json` diz `1.0.4`
- **THEN** o workflow falha antes do build, dizendo as duas versões, e nenhuma release é criada

### Requirement: Teste sem release
O workflow SHALL poder ser disparado à mão, gerando os pacotes das duas arquiteturas como artefatos da execução, sem criar release e sem atestação.

#### Scenario: Disparo manual
- **WHEN** o workflow é disparado à mão na branch `main`
- **THEN** os seis pacotes (três por arquitetura) ficam disponíveis como artefato da execução, e nenhuma release é criada
