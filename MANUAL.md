# mri_Qstarterpack — Manual

Kit inicial entregue uma única vez por jogador: itens, dinheiro e veículo, retirados com um NPC no mundo (ou por comando), com regras/quiz/captcha opcionais e registro em banco.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Configuração](#configuração)
5. [Locais de retirada (`Config.Locations`)](#locais-de-retirada-configlocations)
6. [Diálogo de entrada (regras, quiz, captcha)](#diálogo-de-entrada-regras-quiz-captcha)
7. [Comandos](#comandos)
8. [Banco de dados](#banco-de-dados)
9. [Log no Discord](#log-no-discord)
10. [Integrações](#integrações)
11. [Limitações conhecidas](#limitações-conhecidas)
12. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
13. [Localização](#localização)
14. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Declarado em `dependencies`. Diálogos, TextUI, zonas, callbacks, locale, `lib.addCommand` |
| `oxmysql` | Sim | Carregado no `fxmanifest`. Persistência de quem já recebeu o kit |
| Framework (`qbx_core`, `qb-core` ou `es_extended`) | Sim | Detectado automaticamente em `shared/core.lua`. Sem nenhum deles o recurso aborta com "Framework or Core object not found" |
| Inventário (`Config.InventoryResource`) | Sim | Entrega dos itens. Suporta `ox_inventory`, `qb-inventory`, `ps-inventory`, `qs-inventory`, `codem-inventory` |
| Target (`Config.TargetResource`) | Não | Só se `Config.UseTarget = true`. Suporta `ox_target` e `qb-target`. Sem target, a interação usa a tecla **E** |
| Recurso de combustível | Não | `Config.SetFuel` detecta `LegacyFuel`, `cdn-fuel`, `ps-fuel`, `lj-fuel` ou `ox_fuel`; sem nenhum, cai no `SetVehicleFuelLevel` nativo |
| Recurso de chaves | Não | `Config.GiveKey` detecta `wasabi_carlock`, `jaksam-vehicles-keys`, `cd_garage`, `okokGarage`, `t1ger_keys` ou `ak47_vehiclekeys`; sem nenhum, dispara `vehiclekeys:client:SetOwner` |

O `shared/core.lua` valida na inicialização que os recursos apontados por `Config.TargetResource`, `Config.InventoryResource` e `Config.SQLResource` estão realmente iniciados, e derruba o recurso com erro se algum não estiver (o target é ignorado quando `Config.UseTarget = false`).

---

## Instalação

1. Copie a pasta `mri_Qstarterpack` para `resources/`.
2. Importe o SQL:
   ```
   tcd_starterpack.sql
   ```
   Com `Config.DBChecking = true` (padrão), o recurso cria a tabela e as colunas faltantes sozinho na inicialização — a importação manual é o caminho garantido.
3. Adicione ao `server.cfg`:
   ```
   ensure mri_Qstarterpack
   ```
4. Ajuste `shared/config.lua`: os recursos de target/inventário, os itens de `Config.StarterPackItems` e as coordenadas de `Config.Locations` (o local que vem no config é o porto sul de Los Santos).
5. Se quiser log no Discord, preencha o webhook em `server/functions/discordlog.lua`.

Não há conflito conhecido com outros recursos. Os eventos e callbacks mantêm o prefixo upstream `cfx-tcd-starterpack:`.

---

## Permissões (ACE)

Apenas o comando de auditoria é restrito, via `lib.addCommand` com `restricted = 'group.admin'`:

```
add_principal identifier.license:<licenca_do_admin> group.admin
```

O `ox_lib` cria a ACE `command.checkpacks` automaticamente para o grupo. O nome acompanha `Config.CheckPacksCommand` — se você renomear o comando, o nome da ACE muda junto.

O comando de resgate (`Config.CommandConfig.command`) **não** é restrito: qualquer jogador pode usá-lo, e o controle é feito pelo registro de "já recebeu" no banco.

---

## Configuração

Arquivo: `shared/config.lua`.

### Opções globais

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Config.Debug` | bool | Sim | Ativa logs de diagnóstico no console e desenha as zonas (`claimZone` e safezone) |
| `Config.CheckVersion` | bool | Sim | Consulta a release mais recente do repositório upstream no GitHub na inicialização e avisa no console se houver versão nova |
| `Config.DBChecking` | bool | Sim | Cria a tabela `tcd_starterpack` e adiciona colunas faltantes automaticamente ao iniciar |
| `Config.CheckPacksCommand` | string | Sim | Nome do comando de auditoria (restrito a admin). Padrão: `checkpacks` |
| `Config.TargetResource` | string | Sim | Recurso de target: `ox_target` ou `qb-target` |
| `Config.InventoryResource` | string | Sim | Recurso de inventário: `ox_inventory`, `qb-inventory`, `ps-inventory`, `qs-inventory` ou `codem-inventory` |
| `Config.SQLResource` | string | Sim | Recurso SQL: `oxmysql`, `mysql-async` ou `ghmattimysql` |
| `Config.UsePlayerLicense` | bool | Sim | `true` identifica o jogador pelo `license:` (o kit é único por conta FiveM, vale para todos os personagens). `false` usa o `citizenid`/identifier do framework (um kit por personagem) |
| `Config.UseTarget` | bool | Sim | `true` usa o recurso de target para interagir com o NPC. `false` usa uma zona de proximidade com a tecla **E** |
| `Config.Use3DText` | bool | Sim | Sem target, mostra texto 3D no mundo em vez do TextUI do `ox_lib`. Ignorado se `Config.UseTarget = true` |
| `Config.RandomVehicles.vehicles` | array de string | Sim | Modelos sorteados quando `random_vehicle = true` |
| `Config.StarterPackItems` | tabela | Sim | Conteúdo de cada tipo de kit. Chave = nome do tipo (ex.: `normal`), valor = lista de `{ item = <spawn name>, amount = <n> }`. O item `money` do config padrão precisa existir no seu inventário |

### Funções de integração

Três funções do config podem ser reescritas para adaptar o recurso ao seu servidor:

| Função | Descrição |
|---|---|
| `Config.SetFuel(vehicle, fuel)` | Define o combustível do veículo entregue. Já cobre os recursos de combustível mais comuns |
| `Config.GiveKey(vehicle, plate)` | Entrega a chave do veículo. Já cobre os sistemas de chave mais comuns |
| `Config.Notification(message, type, is_server, src)` | Envia notificação ao jogador. Usa `esx:showNotification` no ESX e `QBCore:Notify` nos demais |

### Comando de resgate (`Config.CommandConfig`)

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `enable` | bool | Sim | Registra o comando de resgate. Com `false`, o kit só sai pelo NPC |
| `command` | string | Só se `enable` | Nome do comando. Padrão: `starterpack` |
| `command_help` | string | Só se `enable` | Texto de ajuda do comando |
| `starterpack_type` | string | Só se `enable` | Chave de `Config.StarterPackItems` entregue pelo comando |
| `starter_vehicle.enable` | bool | Só se `enable` | Entrega também um veículo, spawnado na posição do jogador |
| `starter_vehicle.model` | string | Só se veículo | Modelo entregue quando `random_vehicle = false` |
| `starter_vehicle.random_vehicle` | bool | Só se veículo | Sorteia o modelo em `Config.RandomVehicles.vehicles` |

O comando também exige que o jogador esteja dentro do `receiving_radius` de algum local de `Config.Locations` — ele não funciona de qualquer lugar do mapa.

---

## Locais de retirada (`Config.Locations`)

Cada entrada de `Config.Locations` spawna um NPC e define o que ele entrega. A chave é livre (`["1"]`, `["porto"]`, …).

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `starterpack_type` | string \| `false` | Sim | Chave de `Config.StarterPackItems` entregue neste local. `false` entrega só o veículo, sem itens |
| `label` | string | Sim | Texto da opção de target |
| `icon` | string | Sim | Ícone Font Awesome da opção de target (ex.: `fa-solid fa-gift`) |
| `coords` | `vec4` | Sim | Posição e heading do NPC |
| `ped.model` | string | Sim | Modelo do NPC |
| `ped.scenario` | string | Sim | Cenário de animação do NPC (ex.: `Standing`) |
| `safezone.enable` | bool | Sim | Cria uma zona poligonal ao redor do local onde o jogador fica à prova de dano, desarmado e sem poder atirar |
| `safezone.zone_points` | array de `vec3` | Só se `safezone.enable` | Vértices do polígono da zona segura |
| `starter_vehicle.enable` | bool | Sim | Entrega um veículo junto com o kit |
| `starter_vehicle.model` | string | Só se veículo | Modelo entregue quando `random_vehicle = false` |
| `starter_vehicle.random_vehicle` | bool | Só se veículo | Sorteia o modelo em `Config.RandomVehicles.vehicles` |
| `starter_vehicle.teleport_player` | bool | Só se veículo | Coloca o jogador no banco do motorista assim que o veículo spawna |
| `starter_vehicle.vehicle_spawns` | array de `vec4` | Só se veículo | Vagas de spawn testadas em ordem; a primeira livre é usada. Se todas estiverem ocupadas, o jogador é avisado e o veículo não sai |
| `starter_vehicle.fuel` | number | Só se veículo | Nível de combustível do veículo entregue (0.0 a 100.0) |
| `receiving_radius` | number | Sim | Raio, a partir de `coords`, em que o servidor aceita a entrega. Também é o raio da zona de aproximação quando `Config.UseTarget = false` |
| `distance` | number | Sim | Distância máxima para interagir com o NPC |

Os NPCs de todos os locais são criados na inicialização do client e removidos no `onResourceStop`. Peds do jogo que estejam a menos de 1 metro do ponto são apagados antes do spawn, para não empilhar modelos.

---

## Diálogo de entrada (regras, quiz, captcha)

`Config.DialogInfo` adiciona uma etapa antes da entrega. Só **um** tipo fica ativo por vez.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `enable` | bool | Sim | Liga a etapa de diálogo. Com `false`, o kit é entregue direto |
| `title` | string | Sim | Título do alerta e da tela de regras |
| `dialog_type` | string | Sim | `rules`, `quiz` ou `captcha` |
| `alert_description` | string | Sim | Texto do alerta exibido na primeira interação com o NPC |
| `rules` | array | Só se `rules` | Lista de `{ title, description }`. Renderizadas em markdown; o jogador precisa confirmar para receber |
| `quiz.questions` | array | Só se `quiz` | Lista de `{ question, description, answers }`. Cada `answers` é `{ label, correct }`. As perguntas são embaralhadas e **todas** precisam ser acertadas |
| `captcha.captcha_type` | string | Só se `captcha` | `rl` (6 letras), `rn` (6 dígitos) ou `ra` (sorteia entre os dois) |

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/starterpack` | Qualquer jogador | Entrega o kit sem passar pelo NPC. Exige estar dentro do `receiving_radius` de um local. Só existe se `Config.CommandConfig.enable = true`; o nome vem de `Config.CommandConfig.command` |
| `/checkpacks` | `group.admin` | Abre um menu com todos os registros da tabela `tcd_starterpack`. Ao selecionar um jogador, permite **resetar** (libera o kit de novo) ou **apagar** o registro. Nome configurável em `Config.CheckPacksCommand` |

---

## Banco de dados

Tabela `tcd_starterpack` (arquivo `tcd_starterpack.sql`):

```sql
CREATE TABLE `tcd_starterpack` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(50) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `received` tinyint(1) NOT NULL,
  `date_received` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

| Coluna | Descrição |
|---|---|
| `identifier` | Chave de controle. É o `license:` do jogador quando `Config.UsePlayerLicense = true`, senão o `citizenid`/identifier do framework |
| `received` | `1` = já recebeu o kit e não pode receber de novo |
| `date_received` | Data/hora da entrega |
| `name` | Nome do personagem no momento da entrega |

Uma linha é criada com `received = 0` na primeira vez que o jogador é verificado, e atualizada para `1` na entrega. `/checkpacks` é o caminho para reverter (reset) ou apagar um registro.

---

## Log no Discord

Configurado em `server/functions/discordlog.lua`:

| Campo | Descrição |
|---|---|
| `webhook` | URL do webhook. **Vem vazio** — sem preencher, o log é ignorado com um aviso no console |
| `title` | Título do embed |
| `thumbnail` | URL da miniatura do embed |
| `color` | Cor do embed, em decimal |

O embed enviado a cada entrega contém nome do personagem, ID no servidor, license e horário.

---

## Integrações

### ox_target / qb-target

Com `Config.UseTarget = true`, o recurso registra uma opção de target no **modelo** do ped (`addModel` / `AddTargetModel`), usando `label` e `icon` do local. A opção fica indisponível se o jogador estiver em veículo, morto, com uma barra de progresso ativa ou já em processo de resgate. Todas as opções são removidas no `onResourceStop`.

### Inventários

A entrega dos itens usa o export do inventário escolhido em `Config.InventoryResource`. Com `qb-inventory` e `ps-inventory`, o recurso também dispara o evento de "item box" para mostrar o pop-up de item recebido. Item inexistente gera erro no console — confira os spawn names em `Config.StarterPackItems`.

### Combustível e chaves

`Config.SetFuel` e `Config.GiveKey` detectam o recurso em uso por `GetResourceState` na hora de entregar o veículo. Se o seu servidor usa um sistema fora das listas, edite essas duas funções no `shared/config.lua` — é o ponto de extensão previsto.

---

## Limitações conhecidas

Herdadas do upstream, verificáveis no código:

- **Veículo inicial não funciona em QBox puro.** O `shared/core.lua` detecta o `qbx_core` como framework `qbx`, mas o spawn do veículo (`client/main.lua`) e a persistência em `player_vehicles` (`server/main.lua`) só tratam os ramos `esx` e `qbc`. Em um servidor com `qbx_core` e sem `qb-core`, os itens são entregues normalmente, mas o veículo não spawna. Para usar o veículo inicial, é preciso estender esses dois ramos.
- **`Config.CheckVersion` aponta para o repositório upstream** (`Teezy-Core/cfx-tcd-starterpack`). Como este é um fork, o aviso de "nova versão" no console pode ser ruído; desligue com `Config.CheckVersion = false`.

---

## Entrypoints para outros recursos

O recurso não declara exports. O que existe são eventos de servidor que outros recursos podem disparar.

### Entregar o kit

```lua
TriggerServerEvent('cfx-tcd-starterpack:Server:ClaimStarterpack', 'normal')
```

Disparado a partir do client. Recebe a chave de `Config.StarterPackItems`. O servidor recusa se o jogador já recebeu ou se não estiver dentro do `receiving_radius` de um local.

### Resetar ou apagar o registro de um jogador

```lua
TriggerServerEvent('cfx-tcd-starterpack:Server:UpdateStarterPack', identifier, 'reset')  -- libera o kit de novo
TriggerServerEvent('cfx-tcd-starterpack:Server:UpdateStarterPack', identifier, 'delete') -- apaga a linha
```

O `identifier` é o mesmo gravado na coluna `identifier` da tabela. Este é o evento usado pelo menu do `/checkpacks`.

### Consultar se o jogador já recebeu

```lua
local jaRecebeu = lib.callback.await('cfx-tcd-starterpack:CB:CheckPlayer', false)
```

Callback registrado no servidor e chamado do client. Cria a linha do jogador se ainda não existir e retorna se ele já recebeu o kit.

---

## Localização

As strings são traduzidas via `ox_lib` locale. Os arquivos ficam em `locales/`:

- `en.json` — inglês
- `pt-br.json` — português do Brasil

O locale ativo é definido pela convar `ox:locale` no `server.cfg`:

```
setr ox:locale "pt-br"
```

Alguns textos ficam **fora** do sistema de locale e estão em inglês no código: o TextUI de aproximação (`Press [E] to receive your starter pack`), os títulos dos diálogos de regras/quiz/captcha e o menu do `/checkpacks`. Para traduzi-los, edite `client/main.lua` diretamente.

---

## Estrutura de arquivos

```
mri_Qstarterpack/
├── client/
│   ├── main.lua              — spawn dos NPCs, target/zona de proximidade, diálogos (regras, quiz,
│   │                           captcha), animação de entrega, spawn do veículo e menu do /checkpacks
│   └── functions/
│       └── common.lua        — helpers de modelo, animação, props e criação de peds
├── server/
│   ├── main.lua              — entrega de itens, persistência do veículo, registro de recebimento,
│   │                           comandos /starterpack e /checkpacks
│   └── functions/
│       ├── common.lua        — resolução do identifier, checagem de "já recebeu", check de versão
│       ├── discordlog.lua    — configuração do webhook do Discord
│       └── sql.lua           — camada SQL (oxmysql/mysql-async/ghmattimysql) e criação da tabela
├── shared/
│   ├── config.lua            — toda a configuração: locais, itens, veículos, diálogos, comandos
│   ├── core.lua              — detecção do framework (ESX/QBCore/QBox) e validação das dependências
│   └── debug.lua             — debugPrint, ativado por Config.Debug
├── locales/
│   ├── en.json
│   └── pt-br.json
├── tcd_starterpack.sql       — schema da tabela tcd_starterpack
└── fxmanifest.lua
```
