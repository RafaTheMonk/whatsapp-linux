# Tasks

## 1. Workflow

- [x] 1.1 Escrever `.github/workflows/release.yml` com os gatilhos, a checagem de versão, o build, os checksums, os artefatos do disparo manual, a atestação e a release em rascunho, e verificar que o YAML carrega com `python3 -c 'import yaml...'`
- [x] 1.2 Rodar localmente os comandos de shell do workflow (checagem de versão com tag certa e errada, checksums), e verificar os códigos de saída
- [ ] 1.3 Com o ok do usuário, fazer push e disparar à mão (`gh workflow run`), acompanhar com `gh run watch` e verificar que os quatro arquivos saíram como artefato e que nenhuma release foi criada

## 2. Documentação

- [x] 2.1 Reescrever "Publicar" no `electron/README.md` para o fluxo por tag (subir versão, tag, revisar rascunho, publicar, copiar o `SHA256SUMS.txt` da release para o repo), e verificar lendo
- [x] 2.2 Acrescentar em "Verificar o binário" do `README.md` o `gh attestation verify`, dizendo que vale a partir da próxima versão, e verificar lendo
- [ ] 2.3 Marcar a pendência em `docs/auditorias.md` e atualizar o guia local, e verificar lendo
