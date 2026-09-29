# suspensao Specification

## Purpose
Permite suspender o app Electron pela bandeja para liberar a memória da página do WhatsApp quando o usuário não precisa receber mensagens, e voltar com um clique.

## Requirements

### Requirement: Suspender pelo menu da bandeja
O menu da bandeja SHALL ter o item "Suspender". Ao escolher, o app MUST fechar a página do WhatsApp e liberar a memória dela, continuando rodando só com o ícone na bandeja. O app MUST NOT suspender sozinho em nenhuma situação.

#### Scenario: Suspender libera memória
- **WHEN** o usuário escolhe "Suspender" no menu da bandeja
- **THEN** a janela some, o processo da página do WhatsApp deixa de existir e o ícone continua na bandeja

#### Scenario: Nada suspende sozinho
- **WHEN** a janela fica escondida na bandeja por horas
- **THEN** o app continua conectado e recebendo mensagens, como sem esta mudança

### Requirement: Estado suspenso visível
Enquanto suspenso, o ícone da bandeja SHALL ficar cinza, sem contador, e o tooltip MUST dizer que o app está suspenso e não recebe mensagens. O item "Suspender" MUST ficar desabilitado.

#### Scenario: Olhar a bandeja com o app suspenso
- **WHEN** o app está suspenso e o usuário passa o mouse no ícone
- **THEN** o ícone está cinza e o tooltip diz "WhatsApp Linux - suspenso, sem receber mensagens"

### Requirement: Voltar da suspensão
Clicar no ícone da bandeja, escolher "Mostrar / ocultar" ou abrir o app de novo pelo menu de aplicativos SHALL recarregar o WhatsApp e mostrar a janela, com a sessão logada preservada. A janela MUST aparecer mesmo que o app tenha sido iniciado com `--hidden`.

#### Scenario: Clique no ícone
- **WHEN** o app está suspenso e o usuário clica no ícone da bandeja
- **THEN** a janela aparece com o WhatsApp carregando, sem pedir o QR code, e o ícone volta ao normal

#### Scenario: App iniciado oculto
- **WHEN** o app subiu com `--hidden` pelo autostart, foi suspenso e o usuário clica no ícone
- **THEN** a janela aparece

### Requirement: Sair continua funcionando suspenso
Com o app suspenso, "Sair" no menu da bandeja MUST encerrar o app.

#### Scenario: Sair suspenso
- **WHEN** o app está suspenso e o usuário escolhe "Sair"
- **THEN** o processo encerra
