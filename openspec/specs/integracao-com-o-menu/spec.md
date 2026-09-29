# integracao-com-o-menu Specification

## Purpose
Define como o app Electron entra no menu de aplicativos e com quais ícones, em cada formato de pacote (AppImage, deb, tar.gz).

## Requirements

### Requirement: Ícone em vários tamanhos
O `.deb` e o AppImage SHALL instalar o ícone do app nos tamanhos 16, 24, 32, 48, 64, 128, 256 e 512 px no tema hicolor. Criar o atalho pela oferta da primeira execução MUST instalar os mesmos tamanhos em `~/.local/share/icons/hicolor`.

#### Scenario: Conteúdo do deb
- **WHEN** se lista o conteúdo do `.deb` gerado
- **THEN** existe `usr/share/icons/hicolor/NxN/apps/whatsapp-linux.png` para cada um dos oito tamanhos

### Requirement: Atalho também no tar.gz
Na primeira execução de um AppImage ou de um `tar.gz` descompactado, o app SHALL oferecer criar a entrada no menu de aplicativos, apontando para o executável que está rodando. No `.deb`, instalado em `/opt`, o app MUST NOT oferecer, porque o pacote já cria o atalho. A oferta MUST NOT se repetir depois de recusada, salvo quando o atalho existente aponta para um arquivo que sumiu.

#### Scenario: tar.gz descompactado
- **WHEN** o usuário descompacta o `tar.gz` numa pasta e roda o executável pela primeira vez
- **THEN** o app pergunta se quer adicionar ao menu, e "Adicionar" cria `~/.local/share/applications/whatsapp-linux.desktop` apontando para esse executável, com o ícone

#### Scenario: deb instalado
- **WHEN** o app roda a partir de `/opt`
- **THEN** nenhuma pergunta sobre atalho aparece
