# MANUAL - mri_Qstarterpack

## O que o recurso faz
Sistema avançado de kit inicial para frameworks QBCore, ESX e QBOX, entregando aos jogadores itens, veículos e acesso a NPCs interativos, com suporte a múltiplos frameworks e sistemas de diálogo.

## Funcionalidades principais
- Suporte a múltiplos frameworks: QBCore, ESX e QBOX
- Entrega de veículos iniciais (específico ou aleatório)
- Integração com sistemas de target (ox_target, qb-target)
- Sistema de diálogo: Quiz, Captcha ou aceite de regras
- Zonas seguras configuráveis com restrições de armas
- Rastreamento em banco de dados de quem recebeu o kit
- Logs de reivindicação via webhook do Discord
- Múltiplas localizações de kit inicial com NPCs
- Atribuição automática de chaves de veículo e suporte a combustível

## Como funciona (fluxo de trabalho)
1. Jogadores novos interagem com o NPC de kit inicial em uma das localizações configuradas
2. O sistema exibe o diálogo configurado (regras, quiz ou captcha)
3. Ao aceitar, o jogador recebe os itens e veículo configurados no `shared/config.lua`
4. O recebimento é registrado no banco de dados e enviado para o webhook do Discord
5. O jogador pode receber o kit apenas uma vez (rastreado por identifier)

## Opções de configuração disponíveis
Configurações em `shared/config.lua`:
- **Framework**: `Config.TargetResource`, `Config.InventoryResource`, `Config.SQLResource`
- **Itens do kit**: `Config.StarterPackItems` com item e quantidade
- **Localizações**: `Config.Locations` com coords, NPC, veículo e raio de recebimento
- **Sistema de diálogo**: `Config.DialogInfo` com tipo e configurações
- **Zonas seguras**: `safezone` com pontos da zona e regras
- **Comando admin**: `Config.CommandConfig` para comando de entrega manual

## Comandos disponíveis
| Comando | Descrição | Permissão |
|---------|-----------|-----------|
| `/starterpack` | Entrega o kit inicial via comando | Configurável |
| `/checkpacks` | Visualiza jogadores que receberam kits | Admin |

## Eventos que dispara/ouve
### Eventos Client
| Evento | Descrição |
|--------|-----------|
| `cfx-tcd-starterpack:Client:ShowStarterPacks` | Abre UI com registros de kits |
| `cfx-tcd-starterpack:Client:GiveStarterVehicle` | Spawna veículo inicial para o jogador |

### Eventos Server
| Evento | Descrição |
|--------|-----------|
| `cfx-tcd-starterpack:Server:ClaimStarterpack` | Processa reivindicação do kit |
| `cfx-tcd-starterpack:Server:ClaimVehicle` | Processa reivindicação do veículo |
| `cfx-tcd-starterpack:Server:UpdateStarterPack` | Reseta ou remove dados do kit do jogador |

## Exports que fornece/consome
### Exports fornecidos
| Export | Descrição |
|--------|-----------|
| `GetCore()` | Retorna objeto Core e nome do framework ("esx", "qbc", "qbx") |
| `Config.SetFuel(vehicle, fuel)` | Configura combustível do veículo (suporta múltiplos sistemas) |
| `Config.GiveKey(vehicle, plate)` | Atribui chaves do veículo (suporta múltiplos sistemas) |

## Integração com outros recursos MRI Qbox
- `ox_lib`: UI, callbacks e notificações
- `oxmysql`: Persistência em banco de dados
- `ox_target`/`qb-target`: Sistema de interação com NPCs
- `ox_inventory`/`qb-inventory`: Sistema de inventário para itens

## Casos de uso / exemplos práticos
- Configurar kit inicial com 5 burgers, 5 sprunk, phone e $5000 para novos jogadores
- Criar NPC de kit inicial na spawn principal com veículo Adder aleatório
- Configurar quiz de 5 perguntas sobre as regras do servidor antes de entregar o kit
- Receber log no Discord ao jogador "João" receber o kit inicial em 05/05/2026

## Dicas de solução de problemas
- Kit não entrega: Verifique se o jogador já não recebeu o kit (rastreado no banco de dados)
- Veículo não spawna: Confirme se o modelo do veículo está correto e o sistema de chaves/combustível está configurado
- Diálogo não aparece: Verifique as configurações de `Config.DialogInfo`
- Log do Discord não envia: Confirme se a URL do webhook está correta em `server/functions/discordlog.lua`