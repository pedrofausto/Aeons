# SCHEMA_CANON.md — Schemas Canônicos (fonte única para agentes de IA)

> **Leia antes de criar ou alterar qualquer `.gd`, `.tres` ou `.dtl`.** Ordem de leitura de toda sessão:
> `STATE_LEDGER.md` → **este arquivo** → `ARCHITECTURE.md` (+ diffs).
>
> Atlas, specs, adendos e diffs de design (em `docs/` ou anexados ao chat) descrevem **o que** o jogo precisa.
> **Este arquivo decide os nomes e tipos** com que isso entra no código. Quando um documento usar outro
> nome (`treasury`, `base_hp`, `front_hits`, `EraManager`…), traduza pela **Tabela de Aliases (§7)**.
> **Nunca renomeie, retipe ou apague um campo canônico para "seguir o documento".**

---

## 1. Regras de evolução do schema

1. **A fonte da verdade é o código** em `core/` (este arquivo o espelha). Divergiu? Corrija este arquivo, não o código.
2. **Só adição, nunca migração.** Campo novo = `@export` opcional com **padrão neutro** (o comportamento antigo
   não muda). Ex.: `hits: int = 1`, `min_doctrine: int = -100`, `required_item_id: StringName = &""`.
3. **Nada de era no core.** `core/` não conhece nomes de cidades, facções, classes ou itens. Regras de uma era
   entram como dado (`EraConfig`, `MapNodeData`, `.tres`) ou como flag `enable_*` no `EraConfig`.
4. **Medidores específicos de era não viram variáveis do `WorldState`** (ver §3.4 e §8): use estruturas genéricas.
5. **Antes de adicionar um campo**, procure um existente que já cubra o caso (§7). Ex.: "dano de cerco" já é
   `element = "SIEGE"` + `armor_pierce_pct`; "unidade não letal" já é `traits = ["non_lethal"]`.
6. **Todo campo novo exige:** padrão neutro, comentário de 1 linha, teste em `tests/`, linha neste arquivo e no
   `STATE_LEDGER.md`, e a suíte inteira verde (`tests/run_tests.sh`).
7. **Auto-referência de Resource** (classe que aponta para a própria classe) é tipada como `Resource`/`Array[Resource]`
   (ex.: `promotion_good`): `Array[UnitClassData]` dentro de `UnitClassData` vaza memória no Godot 4.7.
8. **Determinismo:** lógica de jogo não usa RNG livre. Sorteios usam `RandomNumberGenerator` semeado por estado
   (`hash([ato, dia, período, id])`). "Chance" de status vira regra determinística (ex.: alvo mais lento).
9. **Limite de 250 linhas por `.gd`.** Se estourar, extraia um módulo com responsabilidade única.

---

## 2. Estrutura de pastas canônica

```text
res://
├── core/
│   ├── autoloads/   EventBus.gd · WorldState.gd · EssenceState.gd          (NÃO "core/autoload/")
│   ├── data/        EraConfig · UnitClassData · UnitInstance · SquadData   (NÃO "core/resources/")
│   │                MapNodeData · ActionSkillData · ItemData · PromotionRules
│   ├── overworld/   OverworldMap.tscn · MapNode · SquadToken · MapGraph · PatrolAI · EncounterDirector
│   │                RoamingSquadSpawner · EncounterTable · EncounterEntry · SiegeWaterRule
│   │                DayNightTint · OverworldHUD · PromotionPanel
│   ├── combat/      BattleArena.tscn · CombatResolver · SkillMath · CombatTargeting · TacticalOrder
│   │                BattleConsequences · UnitCardView
│   └── interlude/   InterludeRoom.tscn · InterludeController · InterludeManager · shaders/
├── eras/act_0N_<slug>/
│   ├── EraConfig_Act0N.tres · theme_act0N.tres
│   ├── classes/ · map/ · encounters/ · dialogues/ · items/ · art/ (inclui interlude_backdrop.tscn)
├── tests/           TestRunner.tscn · test_*.gd · run_tests.sh
└── docs/            Lore_Simulacros/ (sem spoilers) · Lore_Aeons_Verdade/ (restrito)
```

**Slugs de era canônicos:** `act_01_tianxu` · `act_02_occitania` · `act_03_ash_and_steel` · `act_04_modern` ·
`act_05_technocracy` (o slug antigo `act_03_great_wars` está aposentado).

---

## 3. Autoloads

### 3.1 `EventBus` — sinais (sobem; chamadas diretas descem)
`pause_toggled(is_paused)` · `tick_advanced(day)` · `time_of_day_changed(time_of_day)` · `node_captured(node_id, faction_id)` ·
`battle_requested(ally_squad, enemy_squad, context)` · `battle_ended(result)` · `interlude_requested(timeline_path, node_id)` ·
`interlude_choice_applied(effects)` · `interlude_finished(timeline_path)` · `world_state_changed()` · `era_loaded(config)` ·
`era_transition(from_act, to_act)` · `player_squad_formed(squad)` (recruta sem vaga forma esquadrão próprio; o `EncounterDirector` cria o token).

### 3.2 `WorldState` — estado visível do ato (reiniciado na Derrota Falsa)
| Campo | Tipo | Faixa / valores |
|---|---|---|
| `current_act` | int | 1..5 |
| `alignment` | int | 0 (Brutal) .. 100 (Honrado) |
| `popular_support` | int | 0..100 (Chaos Frame) |
| `doctrine` | int | −100 (Pacifista) .. +100 (Revolucionária) |
| `resources` | int | moeda do ato (rótulo em `EraConfig.resource_label`) |
| `is_paused` | bool | pausa tática |
| `captured_nodes` | Dictionary | `node_id → "player"/"enemy"/"neutral"` |
| `era_config` | EraConfig | era ativa |
| `day_count` | int | ≥ 1 |
| `time_of_day` | String | `"day"` / `"night"` |
| `player_squads` | Array[SquadData] | |
| `active_flags` | Dictionary | `flag → bool` (locais do ato) |
| `act_echoes` | Array[String] | arquivados no EssenceState ao fim do ato |
| `completed_interludes` | Array[String] | caminhos de `.dtl` já vividos |
| `inventory` | Array[ItemData] | uma entrada por unidade de item |
| `unlocked_classes` | Array[String] | `class_id` liberados |
| `siege` | Dictionary | `node_id → {mode, sorties, income_bonus, garrison_hp_pct}` |
| `liberation_methods` | Dictionary | `node_id → "annihilation"/"morale_break"/"timeout"` (como o jogador tomou o nó em batalha) |
| `faction_trust` | Dictionary | `fac_id → int` (confiança das facções narrativas; ids `fac_*` vêm da era; zera a cada ato) |

**Mutação só pelas funções** (`change_alignment/support/doctrine/resources`, `capture_node`, `set_flag`, `add_echo`,
`apply_effects`, `set_siege`, `add_item/consume_item`, `unlock_class`, `set_time_of_day`, `advance_day`) — elas
fazem *clamp* e emitem `world_state_changed`.

### 3.3 `EssenceState` — memória oculta (persiste nos 5 atos; nunca na UI dos Atos I–IV)
| Campo | Tipo | Uso |
|---|---|---|
| `completed_acts` | Array[int] | |
| `alignment_history` | Dictionary | `act_id → alignment final` |
| `doctrine_history` | Dictionary | `act_id → doctrine final` |
| `philosophical_echoes` | Array[String] | ecos de escolhas (vindos de `act_echoes`) |
| `aeon_resistance_flags` | Array[String] | anomalias/rupturas descobertas |
| `ephemeral_meetings_seen` | Array[String] | encontros únicos do Ato V |
| `decisions` | Dictionary | `chave → bool`, **gravada uma única vez** (`record_decision`) |
| `echo_values` | Dictionary | ecos com valor, `chave → String`, **primeiro registro vale** (`record_echo`/`get_echo`) |
| `act_records` | Dictionary | `act_id → {protagonist, final_alignment, final_popular_support, final_doctrine, flags, faction_trust, false_defeat, + EraConfig.act_record_fields}` (`record_act_completion` mescla) |
| `false_defeats` | Array[String] | ids das derrotas falsas vividas (`act2_montsegur_pyre`); `containment_level()` = 1 + tamanho |

Transição de ato: **`EssenceState.archive_act_and_reset_visible(act_id)`** = `record_act(act_id)` + reset do visível +
próxima era (não existe `EraManager`). Sem próximo ato configurado, a Derrota Falsa chama só `record_act` e mostra
`EraConfig.chronicle_end_text` (flag `chronicle_closed`). Módulo: `core/overworld/FalseDefeat.gd`.

### 3.4 Extensão planejada (ainda não implementada): medidores de era
Medidores próprios de uma era (Ato III: suprimento, decifração, cargas de artilharia, alcance de rádio; Ato IV:
energia/banda…) entram como **`WorldState.era_meters: Dictionary`** (`meter_id → int`), declarados pelo
**`EraConfig.meters: Dictionary`** (`meter_id → {label, min, max, start}`). Nunca como `var` dedicada no WorldState.

---

## 4. Resources (`core/data/`)

### 4.1 `UnitClassData`
| Grupo | Campos (tipo = padrão) |
|---|---|
| Identidade | `class_id: String` (único no projeto, `snake_case`, **sem prefixo de ato**; se colidir, prefixe `actN_`) · `display_name: String` · `era_id: int` (número do ato) · `archetype: Archetype` (enum int: VANGUARD, SHOCK, RANGED_STEALTH, ARCANE_TECH, HEALER_MORAL, BARD_INFLUENCE, MYTHIC) · `tier: int = 1` (1 base · 2 elite/sombria · 3 mítica) · `grid_slots: int = 1` (**2 = colossal: ocupa a coluna inteira, `slot` da frente + `slot + 3`; posicione-a sempre num slot 0..2**) |
| Subtipo | `traits: PackedStringArray` (§6.4) · `placeholder_color: Color` (alfa 0 = cor do arquétipo) · `liberation_reputation_bonus: int = 0` |
| Resistências | `damage_taken_pct: Dictionary` (`elemento → % recebido`, 100 = normal) |
| Movimento | `movement: String = "ground"` (§6.2) · `march_speed_pct: int = 100` · `night_march_bonus_pct: int = 0` |
| Atributos | `max_hp` · `max_morale` · `attack` · `defense` · `intellect` · `agility` (crescem +8 HP / +2 por nível) |
| Ações | `front_action: ActionSkillData` · `back_action: ActionSkillData` |
| Promoção | `promotion_good: Resource` · `promotion_evil: Resource` · `promotes_to: Array[Resource]` · `preferred_doctrine: String = "any"` (any/pacifist/revolutionary — informativo) |
| Requisitos **para entrar nesta classe** | `min_level` · `min_alignment` · `max_alignment` · `min_charisma` · `min_doctrine = -100` · `max_doctrine = 100` · `forbidden_flag: String` · `required_item_id: StringName` (consome 1) |

### 4.2 `ActionSkillData`
`skill_id` · `display_name` · `effect: Effect` (PHYSICAL, MAGIC, MORALE_ONLY, HEAL, BUFF) · `targeting: Targeting`
(FRONT_FIRST, BACK_FIRST, ALL_ENEMIES, LEADER, LOWEST_HP_ALLY, ALL_ALLIES, WEAKEST) · `power: int = 100` (% do
atributo, **por golpe**) · `morale_power: int = 0` · `element: String = ""` (§6.3) · `hits: int = 1` · `lifesteal_pct` ·
`armor_pierce_pct` · `inflicts_status` (§6.5) · `ally_buff_trait` (`"*"` = todos) · `ally_buff_attack_pct` ·
`ally_guard_pct` · `target_attack_debuff_pct` · `enemy_morale_drain` · `grants_extra_action: bool` ·
`healthy_allies_bonus_power` · `bonus_element` · `resources_on_hit: int = 0` (saque por acerto com dano > 0) ·
`bonus_terrain: String = ""` + `bonus_terrain_power_pct: int = 0` (poder extra quando a batalha ocorre nesse terreno).
> `CombatResolver.resolve(attacker, defender, attacker_order, defender_order, context = {})`: `context.terrain` vem do nó
> da batalha (EncounterDirector). O evento final (`type = "result"`) traz `bonus_resources = {"attacker": n, "defender": m}`,
> que `BattleConsequences` soma aos recursos do lado do jogador.
> **Enums só crescem no fim** (valores são salvos como inteiros nos `.tres`): nunca reordene nem insira no meio.

### 4.3 `UnitInstance`
`class_data` · `unit_name` · `level` · `experience` (100 por nível) · `alignment` · `charisma` · `slot: int`
(**0..2 frente, 3..5 trás**) · `is_leader` · `hp = -1` / `morale = -1` (−1 = cheio ao iniciar).

### 4.4 `SquadData`
`squad_id` · `display_name` · `faction` · `units: Array[UnitInstance]` · `current_node_id` · `fatigue (0..100)` ·
`patrol_route: Array[String]` · `encounter_tag` (§6.6) · pós-batalha: `supernatural` · `victory_effects: Dictionary` ·
`rare_drop: ItemData` · `rare_drop_chance` · `outcome_rewards: Dictionary` (`victory_type → {flag, unlock_class, item}`) ·
`honor_rule: Dictionary` (`{min_alignment, flag, counts_as}`) — `flag` é procurada em `WorldState.active_flags` **e**
`EssenceState.decisions`. Uma recompensa de `outcome_rewards` pode ter condições: `requires_flag` (flag/decisão ativa) e
`requires_class` (Array de `class_id`; algum vivo no esquadrão do jogador). Contra inimigos `morale_immune`, "vencer por
Moral" se modela com `honor_rule` (ex.: o rito de paz da Tarasca). Em runtime (não exportados): `is_roaming`, `roaming_until_day`.
**Sempre `clone()` antes de usar um `.tres` em jogo**; o recurso original nunca é mutado.

### 4.5 `MapNodeData`
`node_id` · `display_name` · `node_type: NodeType` (CITY, FORTRESS, RESOURCE, SERVER, PASS, SEA — SEA = rota marítima; estradas que tocam um nó SEA são tracejadas na cor `EraConfig.color_sea_lane`) · `faction` (inicial) ·
`region_id` · `terrain` (§6.1) · `required_for_victory = true` · `gold_per_tick` · `map_position` (pixels lógicos
640×360) · `neighbors: Array[String]` (grafo; sem NavigationRegion2D) · `garrison: SquadData` · `liberation_timeline`
(`.dtl`, dispara na 1ª vez sob controle aliado) · `liberation_title` · cerco: `water_source_node` · `sortie_squad` ·
`siege_reinforcements` · `label_side: String = "below"` (`"above"`/`"left"`/`"right"` quando o rótulo colidiria com vizinhos ou com o rótulo de uma guarnição) ·
`visit_timeline` (`.dtl`, dispara na 1ª chegada de um esquadrão do jogador; flag `visited_<nó>`).
Interlúdios nunca se sobrepõem: pedidos durante outro interlúdio/batalha entram na fila do `EncounterDirector`.

### 4.6 `EraConfig`
Identidade (`act_number`, `era_title`, `window_title`, `ui_theme`, `palette_shader`, `reality_layer`, `interlude_style`) ·
vocabulário (`resource_label`, `hp_label`, `morale_label`, `alignment_label`, `support_label`, `doctrine_label`,
`day_label`, `time_of_day_labels`, `order_labels`, `outcome_labels` e todas as mensagens de UI `*_message`/`promotion_*`) ·
paleta (`color_*`) · interlúdio (`interlude_backdrop`, `dialogue_*`, `dissolve_interlude_shader`) · regras
(`enable_siege_water_rule`, `enable_offmap_artillery`, `enable_network_hack`) · conteúdo (`map_nodes`, `unit_classes`,
`starting_squads`, `enemy_patrols`, `encounter_tables`, `item_catalog`, `max_roaming_squads`) · XP (`xp_per_victory`,
`xp_per_defeat`, `xp_per_level_gap`) · `victory_text` · clímax (`protagonist_name`, `climax_timelines` — tocadas em
ordem ao vencer o ato, seguidas da Derrota Falsa —, `false_defeat_id`, `chronicle_end_text`, `act_record_fields`:
`campo → "echo:<chave>" | "flag:<flag>"`) · `next_era_config`.
**Todo texto visível ao jogador vem do EraConfig ou de `.dtl`, nunca de `.gd`.**

### 4.7 `ItemData` · `EncounterTable` · `EncounterEntry`
- `ItemData`: `item_id` · `display_name` · `description` · `unique` · `march_speed_bonus_pct` · `reveals_night_encounters` · `promotion_seal`.
- `EncounterTable`: `region_id` · `spawn_nodes` · `spawn_chance` · `entries: Array[EncounterEntry]`.
- `EncounterEntry`: `squad` · `weight` · `time_of_day` (any/day/night) · `min_party_level` · `max_party_level` · `until_defeated` · `required_region` · `required_flag` (só surge com a flag ativa, ex.: `liberated_<nó>`).

---

## 5. Gramática dos efeitos (sinais do Dialogic)

As timelines aplicam efeitos com `[signal arg="effect|chave=valor|chave=valor"]`. **Nenhum diálogo vive em `.gd`.**

| Chave | Valor | Efeito |
|---|---|---|
| `alignment` · `popular_support` · `doctrine` · `resources` · `charisma` | int com sinal | soma no eixo (charisma: todas as unidades do jogador) |
| `flag` | id | `WorldState.set_flag(id)` (local do ato) |
| `echo` | id | eco do ato → `EssenceState.philosophical_echoes` ao arquivar |
| `decision` | `chave:true\|false` | `EssenceState.record_decision` — **uma vez**; se já existir, o sinal inteiro é ignorado |
| `resistance` | id | `EssenceState.aeon_resistance_flags` |
| `siege_mode` | `node:thirst\|poisoned\|preaching\|assault` | modo do cerco |
| `sorties` · `income_bonus` · `garrison_hp_pct` | `node:int` | surtidas pendentes · % extra de renda · HP da guarnição |
| `reinforce` | `node_id` | adiciona `siege_reinforcements` à guarnição |
| `trust` | `fac_id:int` | soma em `WorldState.faction_trust[fac_id]` (uma facção por sinal) |
| `essence_echo` | `chave:valor` | `EssenceState.record_echo` (primeiro valor vale) |
| `item` | `res://…/item.tres` | `WorldState.add_item` |
| `recruit` | `class_id:Nome` | unidade no 1º esquadrão do jogador com vaga (nível = média); sem vaga, forma esquadrão próprio no nó |

Recompensa de batalha (`SquadData.outcome_rewards[tipo]`) aceita `interlude` (`.dtl` aberto ao fim da batalha), além
de `flag`, `item`, `requires_flag`, `requires_class`.

Nova chave só com suporte em `WorldState.apply_effects`/`InterludeController` + teste + linha nesta tabela.

---

## 6. Vocabulários fechados (strings canônicas)

1. **Terreno** (`MapNodeData.terrain`): `plains` · `mountain` · `river` · `forest` · `urban` (Ato III deve acrescentar `mud`, `snow`, `industrial`, `coastal` também em `SquadData.TERRAIN_FACTORS`).
2. **Movimento** (`UnitClassData.movement`): `ground` (infantaria) · `cavalry` · `mountain` · `swamp` · `ethereal` · `flying`.
3. **Elementos** (`ActionSkillData.element`): `PHYSICAL` · `PIERCE` · `SIEGE` · `FIRE` · `LIGHT` · `SPIRITUAL` · `PURIFY` · `SHADOW` · `ARCANE`.
4. **Traits**: `undead` · `celestial` · `trickster` · `evil_shaman` · `morale_immune` · `morale_drain_immune` · `status_immune` · `non_lethal` · `flying`.
5. **Status** (`inflicts_status`, determinísticos):
   - `CONFUSE` — pega se o alvo for mais lento; perde a próxima ação.
   - `POISON` — pega se o alvo não for mais rápido **ou** estiver abaixo de 80% do HP; 2 rodadas; no fim de cada rodada perde `max(1, 10% do HP máx.)` (não mata se o atacante for `non_lethal`).
   - `status_immune` bloqueia ambos.
6. **Tags de encontro**: `bandit_loot` · `moral_escort` · `low_level_trap` · `natural_wildlife` · `mythic_boss` · `night_encounter` · `siege_sortie`.
7. **Facções**: `player` · `enemy` · `neutral` (facções narrativas ficam nos nomes/dados, não no motor).
8. **Período**: `day` · `night`. **Camada de realidade**: `PHYSICAL_WAR` · `RESOURCE_NETWORK` · `VIRTUAL_COGNITIVE`. **Interlúdio**: `camp` · `clandestine_physical` · `ephemeral_metaphysical`.
9. **Desfechos de batalha** (`result.victory_type`): `annihilation` · `morale_break` · `timeout`.

---

## 7. Tabela de aliases (termo dos documentos → canônico)

| Nos documentos | Use no código |
|---|---|
| `core/autoload/`, `core/resources/` | `core/autoloads/`, `core/data/` |
| `EraManager.gd` | `WorldState.load_era()` + `EssenceState.archive_act_and_reset_visible()` |
| `StrategicMap.tscn` / `SquadBattle.tscn` | `core/overworld/OverworldMap.tscn` / `core/combat/BattleArena.tscn` |
| `battle_finished(result)` | `EventBus.battle_ended(result)` |
| `NavigationRegion2D`, rotas ponderadas | grafo `MapNodeData.neighbors` + `MapGraph` (BFS) + `TERRAIN_FACTORS` |
| `treasury`, `gold`, `gold_or_resource`, `gold_or_resources` | `WorldState.resources` (+ `EraConfig.resource_label`) |
| `CombatScene`, `SquadBattle` | `core/combat/BattleArena.tscn` |
| `Ink`, `GodotInk` | não usado; diálogos são Dialogic 2 (`.dtl`) |
| `day_cycle: enum {DAY, NIGHT}` | `WorldState.time_of_day: "day"/"night"` |
| `essence_alignment_history` / `essence_doctrine_history` (Array) | `EssenceState.alignment_history` / `doctrine_history` (Dictionary act→valor) |
| `aeon_anomalies_discovered`, `philosophical_flags`, `essence_flag` | `EssenceState.aeon_resistance_flags` (anomalias) ou `philosophical_echoes` (ecos) |
| `act3_dilemma_flags: {chave: bool}` e similares | `EssenceState.decisions` com chave `act3_<nome>` (via `decision=` no `.dtl`) |
| `false_defeats_triggered` | `EssenceState.false_defeats: Array[String]` |
| `fac_faydits.trust += 10`, `fac_*.trust` | `trust=fac_faydits:10` → `WorldState.faction_trust` |
| `EssenceState.record_echo("act2_philosophy", "x")`, `get_echo` | `essence_echo=act2_philosophy:x` no `.dtl`; `EssenceState.echo_values` |
| `EssenceState.record_act_completion(n, {...})` | automático em `record_act` (campos extras via `EraConfig.act_record_fields`) |
| `WorldState.get_flag("x")` | `WorldState.has_flag("x")` |
| `InterludeRoom_<Lugar>.tscn` (uma cena por interlúdio) | uma só `InterludeRoom.tscn`; o lugar vem do `.dtl` e do `interlude_backdrop` da era |
| `base_hp / base_atk / base_def / base_agi / base_int` | `max_hp / attack / defense / agility / intellect` |
| `base_cha` | `UnitInstance.charisma` (unidade) · requisito: `min_charisma` (classe) |
| `front_action_name`, `front_hits`, `front_is_aoe`, `front_action_id`, `front_action_count` | `front_action: ActionSkillData` com `display_name`, `hits`, `targeting = ALL_ENEMIES` |
| `DamageType` FIS/PERF/CERCO/LUZ/FOGO | `element` PHYSICAL/PIERCE/SIEGE (+`armor_pierce_pct`)/LIGHT/FIRE |
| `DamageType` MORAL / CURA / BUFF | `effect` MORALE_ONLY / HEAL / BUFF |
| `MovementType` INFANTRY/CAVALRY/MOUNTAIN/SWAMP/ETHEREAL, `terrain_bonus` | `movement` ground/cavalry/mountain/swamp/ethereal |
| `slots_occupied` | `grid_slots` |
| `doctrine_affinity` PACIFISTA/REVOLUCIONARIA/NEUTRA | `preferred_doctrine` pacifist/revolutionary/any; requisito duro: `min_doctrine`/`max_doctrine` |
| `is_non_lethal` | `traits = ["non_lethal"]` |
| `promotes_from`, `promotion_targets` | `promotion_good` / `promotion_evil` / `promotes_to` **na classe de origem** |
| `class_id = "act2_parfait"`, `era_id = &"act_02_occitania"` | `class_id = "parfait"`, `era_id = 2` |
| `ali_range` | `min_alignment` / `max_alignment` |
| `province_id`, `squad_composition`, `moral_event_id` | `EncounterTable.region_id`, `EncounterEntry.squad`, `SquadData.encounter_tag`/`outcome_rewards` |
| `CityData.tres` | `MapNodeData.tres` |
| `uses_offmap_support` | `EraConfig.enable_offmap_artillery` (Ato III) / `enable_network_hack` (IV–V) |
| `uses_supply_lines`, `uses_fog_of_intel` | `EraConfig.enable_supply_lines`, `enable_fog_of_intel` (prefixo `enable_`, §8) |
| `supply_reserve`, `intel_decryption_level`, `offmap_artillery_charges`, `radio_broadcast_reach` | `WorldState.era_meters["supply"/"intel"/"artillery"/"radio"]` (§3.4) |
| `is_supply_source`, `connected_rail_ids` | `MapNodeData.is_supply_source`, `rail_links: Array[String]` (§8) |
| `has_artillery_battery`, `artillery_radius_px` | `MapNodeData.artillery_radius` (0 = sem bateria; pixels lógicos) (§8) |
| `SquadData.is_stealth_air` | trait `stealth_air` na classe + `movement = "flying"` |
| Escalas 1–10, ★1–5, notas S/A/B/C/D | converter para números do schema (ver §9) |
| `core/state/WorldState.gd`, `core/state/EssenceState.gd` | `core/autoloads/` |
| `CombatArena.tscn`, `MapNode.tscn`, `SquadToken.tscn` | `BattleArena.tscn`; `MapNode` e `SquadToken` são scripts instanciados pelo `OverworldMap` |
| `tests/smoke_test.gd`, `SMOKE_TEST_PASS` | `tests/TestRunner.tscn` + `tests/run_tests.sh` (`TEST_PASS\|nome` e marcadores por ato) |
| `AGENT_SETUP_AND_TEST.md`, "Sprint 0" | ambiente já validado: wrapper `~/bin/godot-opengl3`, CI em `.github/workflows/godot-ci.yml` |
| `WorldState.act_id` | `WorldState.current_act` |
| `EssenceState.act_summaries` | `alignment_history` + `doctrine_history` (+ `decisions` para escolhas-chave) |
| `EssenceState.aeon_resistance_score: int` | `EssenceState.aeon_resistance_flags.size()` (não criar contador separado) |
| `EssenceState.false_defeats_triggered: Array[int]` | `EssenceState.false_defeats: Array[String]` (ids como `act2_montsegur_pyre`) |
| `MapNodeData.node_type` como String ("PORT", "INFRASTRUCTURE", "NEURAL_NODE") | enum `NodeType` (inteiro); novos tipos só **no fim** do enum (ex.: `PORT`, `INFRASTRUCTURE`, `NEURAL_NODE` quando os Atos III–V precisarem) |
| `node_id: StringName`, `connected_nodes: Array[StringName]` | `node_id: String`, `neighbors: Array[String]` |
| `owner_faction`, `resource_per_tick` | `faction`, `gold_per_tick` |
| `local_support` (por nó) | não existe; Apoio é global (`WorldState.popular_support`) + `liberation_reputation_bonus` |
| `archetype` como String, `front_action_id`/`back_action_id` | enum `Archetype`; `front_action`/`back_action: ActionSkillData` |
| `GodotInk` | não usado; diálogos são Dialogic 2 (`.dtl`) |
| (Architecture_4) `CombatArena.tscn`, `core/resources/`, `core/autoloads/EraManager.gd` | `BattleArena.tscn`, `core/data/`, `WorldState.load_era` + `EssenceState.archive_act_and_reset_visible` |
| (Architecture_4) `AudioDirector.gd` (AudioStreamSynchronized) | ainda não existe; entra com a Sprint de áudio como autoload `AudioDirector` |
| (Architecture_4) `WorldState.treasury` | `WorldState.resources` |
| (Architecture_4) `WorldState.liberated_nodes: {node_id: {owner, method}}` | `captured_nodes` (dono) + `liberation_methods` (`annihilation`/`morale_break`/`timeout`) |
| (Architecture_4) `EssenceState.act_echoes: {act: {final_*}}` | `EssenceState.act_records` |
| (Architecture_4) `EssenceState.philosophical_flags` | `philosophical_echoes` (ecos) / `aeon_resistance_flags` (anomalias) |
| (Architecture_4) `EssenceState.aeon_containment_level` | `EssenceState.containment_level()` = 1 + `false_defeats.size()` (sem contador próprio) |
| (Architecture_4) `record_false_defeat(act_id, ws)` | `FalseDefeat.trigger(map)` → `EssenceState.record_act` / `archive_act_and_reset_visible` |
| (Architecture_4) ordens "Pressão Moral" / "Defender" | `TacticalOrder.Order.SPARE` (Poupar/Render) / `TacticalOrder.Order.DEFEND` |
| (Architecture_4) "Posto da Regência", `docs/STATE_LEDGER.md`, `docs/lore_public/` | Forte da Regência; `STATE_LEDGER.md` na raiz; `docs/Lore_Simulacros/` |

---

## 8. Nomes reservados para o Ato III (adicionar só quando o Ato III for implementado)

- `EraConfig`: `enable_supply_lines: bool = false`, `enable_fog_of_intel: bool = false`, `meters: Dictionary = {}`.
- `WorldState`: `era_meters: Dictionary = {}` (reiniciado na Derrota Falsa).
- `MapNodeData`: `is_supply_source: bool = false`, `rail_links: Array[String] = []`, `artillery_radius: float = 0.0`.
- `SquadData`: `supply_level: int = 100` (0 reduz dano e Moral).
- Novos módulos (reaproveitados nos Atos IV–V): `core/overworld/SupplyGraphSystem.gd` (BFS de abastecimento),
  `core/overworld/OffmapStrikeManager.gd` (barragens/transmissões), gancho `pre_round_hook` no `CombatResolver` e o
  status `SUPPRESSED` (perde iniciativa), shaders `core/interlude/shaders/rain_overlay_2d.gdshader` e
  `searchlight_cone.gdshader` (`canvas_item` simples, sem leitura de tela).

---

## 9. Convenções numéricas

- **Resolução lógica 640×360** (janela 1280×720, filtro Nearest); posições e tamanhos em pixels lógicos.
- **Atributos de nível 1** (referência: Fubing 110 HP / 16 ATK / 14 DEF / 6 INT / 9 AGI). Escala 1–10 da spec:
  HP ×14 · ATK ×2,6 · DEF ×1,6 · INT ×2,2 · AGI ×1,5. Notas: S+ = 10, S = 9, A = 7, B = 5, C = 4, D = 2 (depois a escala acima).
- **Golpes múltiplos:** `power` é por golpe; "2×" ≈ 55 por golpe, "3×" ≈ 45–50 por golpe (total ≈ 110–150).
- **Resistência "X%":** "resiste 80%" = `damage_taken_pct = 20`; "recebe 150%" = `150`.
- **Eixos:** alinhamento 0..100; doutrina −100..+100; carisma 0..100. **XP:** 100 por nível; ritmo por era no EraConfig.

---

## 10. Sigilo narrativo (aplica-se a todo texto visível: `.dtl`, `.tres`, UI)

- **Atos I–IV:** proibido "Aeons", "simulação", "simulacro", "matriz", "mesma alma", "mesma consciência", "camada(s) concêntrica(s)" e qualquer sugestão de que os 5 protagonistas são a mesma pessoa. ("matriz" e "camada concêntrica" são checados só no conteúdo jogável — `eras/` e `core/` — porque "Matriz de Classes" é título legítimo de documento.)
- **Ato III (adicional):** proibido "vida passada", "China", "Carcassonne" (e qualquer nome próprio de outro ato).
  Linguagem permitida: "mão invisível nas cifras", "guerra desenhada para moer gerações", "burocracia acima dos generais".
- O teste `lore_secrecy_acts_1_to_4` varre `eras/`, `core/` e `docs/Lore_Simulacros/`; ao criar o Ato III, acrescente a
  lista adicional dele em `tests/test_interlude.gd` (`EXTRA_FORBIDDEN`).

---

## 11. Checklist antes de tocar no schema

- [ ] O campo já existe com outro nome? (§7)
- [ ] Dá para resolver com dado (`.tres`, trait, element, tag, efeito de `.dtl`) sem mexer no core?
- [ ] O padrão é neutro e o comportamento antigo continua idêntico?
- [ ] Teste novo + suíte verde (`tests/run_tests.sh` exige `TEST_PASS` e os marcadores de cada ato)?
- [ ] Este arquivo e o `STATE_LEDGER.md` atualizados no mesmo commit?
