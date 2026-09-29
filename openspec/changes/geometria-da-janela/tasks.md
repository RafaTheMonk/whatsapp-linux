# Tasks

## 1. Guardar e recuperar

- [x] 1.1 Gravar `maximizada` em `salvarBounds` e reabrir maximizada em `montarJanela`, e verificar com `node --check`
- [x] 1.2 Validar os limites salvos contra a área útil dos monitores antes de criar a janela, e verificar com `node --check`

## 2. Medir pelo KWin

- [x] 2.1 Com o app instalado fechado, rodar a versão de teste, maximizar pelo KWin (`setMaximize(true, true)`), encerrar com SIGTERM, reabrir e medir `maximizeMode` pelo KWin: deve ser maximizada; repetir duas vezes
- [x] 2.2 Na janela reaberta maximizada, restaurar pelo KWin (`setMaximize(false, false)`) e medir que o tamanho fica menor que a área útil
- [x] 2.3 Gravar no `estado.json` limites numa posição que nenhum monitor cobre (x=5000, y=5000), reabrir e verificar pelo KWin que a janela está dentro da área útil; gravar um estado sem `maximizada` e verificar que abre não maximizada

## 3. Documentação

- [x] 3.1 Marcar a pendência da geometria como resolvida em `docs/auditorias.md`, com a data, e verificar lendo a seção
