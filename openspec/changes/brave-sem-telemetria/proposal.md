# Proposal

## Why

O modo leve abre o WhatsApp Web num perfil isolado do navegador. No Brave, perfil novo nasce com a telemetria padrão ligada (P3A, ping diário de uso e relatórios de diagnóstico), mesmo que o usuário tenha desligado tudo no perfil principal: são perfis independentes. O README documentava isso como limitação, e a auditoria de 10/09/2026 deixou como pendência.

## What Changes

- Quando o navegador escolhido é o Brave e o perfil isolado ainda não existe, o modo leve cria o `Local State` do perfil com três opções desligadas: `brave.p3a.enabled`, `brave.stats.reporting_enabled` e `user_experience_metrics.reporting_enabled`, e marca o aviso do P3A como visto.
- Perfil que já existe não é alterado. Quem instalou antes segue as instruções do README para desligar à mão.

## Capabilities

### New Capabilities

- `perfil-isolado-do-modo-leve`: o que o modo leve configura no perfil isolado do navegador ao criá-lo.

### Modified Capabilities

## Impact

- `src/whatsapp-web`: grava o `Local State` antes do `exec`, só com Brave e perfil novo. Continua só em bash, sem dependência.
- `README.md`: a limitação da telemetria vira comportamento, com o caminho manual para perfis antigos.
- `docs/auditorias.md`: a pendência.
