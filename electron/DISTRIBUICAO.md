# WhatsApp para Linux

App de desktop do WhatsApp. Janela própria, ícone na bandeja e, ao fechar no X,
continua rodando em segundo plano recebendo mensagem, igual ao app do Windows.

Não precisa ter navegador nem instalar dependência: já vem tudo dentro.

**Baixe sempre pela página de releases:**
https://github.com/RafaTheMonk/whatsapp-linux/releases/latest

## Ubuntu, Mint, Debian, Pop!_OS

Baixe o arquivo `.deb` e instale com dois cliques, ou pelo terminal:

```bash
sudo apt install ./whatsapp-linux_1.0.0_amd64.deb
```

Depois procure "WhatsApp Linux" no menu de aplicativos.

## Qualquer outra distro (Fedora, Arch, openSUSE, Manjaro)

Baixe o arquivo `.AppImage` e libere a execução:

```bash
chmod +x WhatsAppLinux-1.0.0-x86_64.AppImage
./WhatsAppLinux-1.0.0-x86_64.AppImage
```

Sem terminal: clique com o botão direito no arquivo, Propriedades, Permissões,
marque "É executável". Depois é só dar dois cliques.

Na primeira vez o app pergunta se quer adicionar ao menu de aplicativos. Responda
"Adicionar" e ele aparece junto com os outros programas. Se depois você mover o
arquivo de pasta, ele oferece corrigir o atalho sozinho.

## Conferir o arquivo antes de rodar

Junto dos pacotes vai um `SHA256SUMS.txt`. Na pasta onde você baixou:

```bash
sha256sum -c SHA256SUMS.txt
```

Se aparecer `SUCESSO`, o arquivo é exatamente o que foi publicado. Se não bater,
não rode.

O código está aberto em https://github.com/RafaTheMonk/whatsapp-linux

## Primeiro uso

Abra o app e escaneie o QR code com o celular, em WhatsApp > Dispositivos
conectados > Conectar dispositivo. Só precisa fazer isso uma vez.

## Atualização

O app não se atualiza sozinho e não instala nada por conta própria. Uma vez por
dia ele consulta a página de releases e, se tiver saído versão nova, aparece um
aviso no menu da bandeja com um link para baixar.

Se preferir que ele não consulte nada, desmarque "Avisar sobre atualização" no
menu da bandeja.

Vale acompanhar: o app carrega o WhatsApp Web num navegador embutido, e navegador
desatualizado é problema de segurança. Versão nova costuma ser exatamente isso.

## Se não abrir

**"dlopen(): error loading libfuse.so.2"** (Ubuntu 22.04 ou mais novo):

```bash
sudo apt install libfuse2
```

Ou rode sem instalar nada:

```bash
./WhatsAppLinux-1.0.0-x86_64.AppImage --appimage-extract-and-run
```

**Erro de sandbox no Ubuntu 24.04:** use o `.deb` em vez do AppImage. Ele já vem
preparado para essa versão.

**Você tem o AppImageLauncher instalado:** ele intercepta o AppImage, move o arquivo
de lugar e cria um atalho que roda o app com `--no-sandbox`, desligando uma camada
de proteção. Prefira o `.deb`, ou o `tar.gz`:

```bash
tar -xzf whatsapp-linux-1.0.0.tar.gz -C ~/.local/lib/
~/.local/lib/whatsapp-linux-1.0.0/whatsapp-linux
```

## Privacidade

O app abre o WhatsApp Web oficial, nada mais. A criptografia ponta a ponta das suas
conversas não muda: ele só desenha a janela. A sessão fica só no seu computador, em
`~/.config/whatsapp-linux`, com permissão restrita ao seu usuário.

A única coisa que ele acessa fora do WhatsApp é a página de releases do GitHub, para
a checagem de versão descrita acima, e isso pode ser desligado.
