# publicacao-de-versao Specification

## Purpose
Define como uma versão do pacote Electron é gerada, conferida e publicada, para que os binários venham de um build rastreável até o código do repositório e não da máquina de alguém.

## Requirements

### Requirement: Build por tag em máquina limpa
Uma tag `vX.Y.Z` enviada ao repositório SHALL disparar o build dos três pacotes para x64 e para arm64, cada um num runner nativo da arquitetura, a partir do código daquela tag, com as dependências exatas do `package-lock.json`. O build MUST falhar, sem criar release, se a tag não for igual a `v` seguido da `version` do `electron/package.json`.

#### Scenario: Tag certa
- **WHEN** a tag `v1.0.4` é enviada e o `package.json` diz `1.0.4`
- **THEN** o workflow gera AppImage, `.deb` e `tar.gz` da 1.0.4 para x64 e arm64, cada arquivo com a arquitetura no nome, e um `SHA256SUMS.txt` único com os seis

#### Scenario: Tag errada
- **WHEN** a tag `v1.0.5` é enviada e o `package.json` diz `1.0.4`
- **THEN** o workflow falha antes do build, dizendo as duas versões, e nenhuma release é criada

### Requirement: Release só como rascunho
O workflow SHALL criar a release como rascunho, com os três pacotes e o `SHA256SUMS.txt`. Publicar MUST continuar sendo um passo humano, porque o app consulta a última release publicada para avisar os usuários.

#### Scenario: Depois do build
- **WHEN** o build da tag termina sem erro
- **THEN** existe uma release em rascunho com os quatro arquivos, e a API de "última release" continua apontando para a versão anterior

### Requirement: Procedência verificável
Cada pacote SHALL ter atestação de procedência assinada pelo GitHub, ligando o arquivo ao workflow e ao commit que o gerou.

#### Scenario: Conferir um pacote baixado
- **WHEN** alguém roda `gh attestation verify <pacote> --repo RafaTheMonk/whatsapp-linux`
- **THEN** a verificação passa para os pacotes da release e falha para um arquivo alterado

### Requirement: Teste sem release
O workflow SHALL poder ser disparado à mão, gerando os pacotes das duas arquiteturas como artefatos da execução, sem criar release e sem atestação.

#### Scenario: Disparo manual
- **WHEN** o workflow é disparado à mão na branch `main`
- **THEN** os seis pacotes (três por arquitetura) ficam disponíveis como artefato da execução, e nenhuma release é criada
