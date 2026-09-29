# Tasks

## 1. Limpar o rascunho

- [x] 1.1 Remover de `electron/src/main.js` as linhas de diagnóstico `DBG` (logs de permissão, `console-message`, `will-download` e os do menu) e confirmar com `grep -n DBG electron/src/main.js` sem resultado e `node --check electron/src/main.js` ok
- [x] 1.2 Conferir que `electron/src/preload.js` não usa `contextBridge` nem `require` e só registra o listener de captura, lendo o arquivo

## 2. Menu de contexto

- [x] 2.1 Revisar `menuDeContexto` em `electron/src/main.js` contra os requisitos da spec (blocos, `enabled` por `editFlags`, `blob:` fora, sem menu vazio) e verificar com `node --check`
- [x] 2.2 Fechar o app instalado e confirmar com `pgrep -f .local/lib/whatsapp-linux` sem resultado antes de rodar a versão de teste, para não bater no lock de instância única
- [x] 2.3 Rodar `npm start` em `electron/` e verificar na mão: seleção numa mensagem mostra Copiar e copia, caixa de digitar mostra Colar e cola, caixa vazia mostra Recortar e Copiar desabilitados
- [x] 2.4 Verificar na mão: clique direito numa mensagem sem seleção abre o menu do WhatsApp; link selecionado oferece abrir e copiar endereço; imagem oferece copiar e salvar, e o diálogo de salvar abre
- [x] 2.5 (não precisou, a 2.3 passou) Se a 2.3 falhar porque o WhatsApp ainda recebe o evento, aplicar a alternativa do design (listener também no `document`), medir de novo e registrar o resultado no design

## 3. Documentação

- [x] 3.1 Acrescentar em "O que o app faz" do `electron/README.md` o menu de contexto do sistema com seleção e em campo editável, e verificar lendo a seção
- [x] 3.2 Acrescentar na tabela "Onde olhar no código" do `README.md` a linha do preload e do handler de `context-menu`, e verificar lendo a tabela
