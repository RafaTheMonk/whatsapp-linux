# WhatsApp para Linux

App de desktop do WhatsApp. Janela própria, ícone na bandeja e, ao fechar no X,
continua rodando em segundo plano recebendo mensagem, igual ao app do Windows.

Não precisa ter navegador nem instalar dependência: já vem tudo dentro.

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
"Adicionar" e ele aparece junto com os outros programas.

## Primeiro uso

Abra o app e escaneie o QR code com o celular, em WhatsApp > Dispositivos
conectados > Conectar dispositivo. Só precisa fazer isso uma vez.

## Se não abrir

**"dlopen(): error loading libfuse.so.2"** (Ubuntu 22.04 ou mais novo):

```bash
sudo apt install libfuse2
```

Ou rode sem instalar nada:

```bash
./WhatsAppLinux-1.0.0-x86_64.AppImage --appimage-extract-and-run
```

**Erro de sandbox no Ubuntu 24.04:** use o `.deb` em vez do AppImage. É o caminho
certo nessa versão.

## Privacidade

O app abre o WhatsApp Web oficial, nada mais. A criptografia ponta a ponta das suas
conversas não muda: ele só desenha a janela. A sessão fica só no seu computador.
