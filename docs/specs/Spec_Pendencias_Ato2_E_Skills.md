# SPEC_PENDENCIAS_ATO2_E_SKILLS.md — Especificação Canônica (100% aderente ao `SCHEMA_CANON.md`)

> **Instrução para o Agente de IA:** Siga estritamente `SCHEMA_CANON.md`. Todos os nomes de campos, enums, sinais Dialogic, faixas numéricas (§9) e regras de sigilo (§10) abaixo já estão traduzidos para o padrão canônico do repositório. **Não execute a Seção 4 (Adendo do Ato I) sem aprovação explícita do usuário.**

---

## 1. Ato II — Regiões, Nós de Mapa e Dilemas 2 a 6

Todos os nós abaixo pertencem a `eras/act_02_occitania/map/` (`MapNodeData.tres`) e usam coordenadas lógicas `640×360` (§9) e terrenos canônicos (§6.1). Os diálogos vivem em `eras/act_02_occitania/dialogues/` (`.dtl`) usando **exclusivamente** a gramática de sinais da §5.

> **Sigilo (§10):** Nenhum texto de `.dtl` ou `.tres` abaixo pode conter termos proibidos (*Aeons, simulação, simulacro, mesma alma, mesma consciência, camadas concêntricas*).

### 1.1 Mapa de Nós (`MapNodeData.tres`)

| `node_id` | `display_name` | `region_id` | `node_type` | `terrain` | `map_position` | `gold_per_tick` | `required_for_victory` | `liberation_timeline` |
|---|---|---|---|---|---:|---:|:---:|---|
| `toulouse` | Toulouse | `toulouse` | `CITY` | `plains` | `(135, 190)` | `35` | `true` | `res://eras/act_02_occitania/dialogues/dilema_02_toulouse.dtl` |
| `montagne_noire` | Abadia da Montagne Noire | `montagne_noire` | `FORTRESS` | `forest` | `(240, 82)` | `20` | `true` | `res://eras/act_02_occitania/dialogues/dilema_03_montagne_noire.dtl` |
| `beziers` | Ruínas de Béziers | `beziers` | `CITY` | `urban` | `(445, 238)` | `30` | `true` | `res://eras/act_02_occitania/dialogues/dilema_04_beziers.dtl` |
| `tarascon` | Pântanos de Tarascon | `tarascon` | `RESOURCE` | `river` | `(548, 178)` | `25` | `false` | `res://eras/act_02_occitania/dialogues/dilema_05_tarascon.dtl` |
| `montsegur` | Castrum de Montségur | `montsegur` | `FORTRESS` | `mountain` | `(255, 298)` | `15` | `true` | `res://eras/act_02_occitania/dialogues/dilema_06_montsegur.dtl` |

*(Conectar `neighbors` ao nó já existente de `carcassonne` no centro `(320, 165)` formando o grafo navegável via `MapGraph`.)*

### 1.2 Dilemas 2 a 6 (Sinais Dialogic Canônicos — §5)

#### Dilema 2 — **Toulouse** (`dilema_02_toulouse.dtl` — *O Pacto dos Trovadores e Aragão*)
- **Conflito:** O conselho de Toulouse exige saber se você marchará sob a bandeira diplomática de Aragão (poupando nobres do norte rendidos) ou se convocará os *Faydits* para incendiar os feudos inimigos no oeste.
- **Opção A (Pacifista / Diplomática):**
  `[signal arg="effect|alignment=+8|popular_support=+6|doctrine=-12|charisma=+3|flag=aragon_envoy_pleased|echo=act2_toulouse_truce|decision=act2_toulouse_pact:true"]`
- **Opção B (Revolucionária / Guerrilha):**
  `[signal arg="effect|alignment=-6|popular_support=+2|doctrine=+15|resources=+120|flag=faydits_rallied|echo=act2_toulouse_fire|decision=act2_toulouse_pact:false"]`

#### Dilema 3 — **Montagne Noire** (`dilema_03_montagne_noire.dtl` — *O Tribunal da Abadia*)
- **Conflito:** Ao tomar a abadia fortificada, seus batedores capturam um frade inquisidor com listas de delatores locais. A multidão exige vingança; os *Bons Hommes* pedem que as listas sejam queimadas sem derramamento de sangue.
- **Opção A (Queimar as listas e poupar o inquisidor):**
  `[signal arg="effect|alignment=+10|popular_support=+8|doctrine=-14|flag=inquisitor_spared|echo=act2_mercy_at_abbey|decision=act2_abbey_mercy:true"]`
- **Opção B (Usar as listas para caçar traidores e executar o inquisidor):**
  `[signal arg="effect|alignment=-12|popular_support=-4|doctrine=+14|resources=+90|flag=informants_purged|echo=act2_blood_ledger|decision=act2_abbey_mercy:false"]`

#### Dilema 4 — **Béziers** (`dilema_04_beziers.dtl` — *As Cinzas de Madalena*)
- **Conflito:** Nas ruínas marcadas pelo massacre de 1209, sobreviventes pedem recursos para reerguer o abrigo e enterrar os mortos, enquanto comandantes querem confiscar as pedras e prata da igreja arruinada para construir máquinas de cerco.
- **Opção A (Financiar o abrigo e o luto de Béziers):**
  `[signal arg="effect|alignment=+10|popular_support=+12|doctrine=-8|resources=-80|flag=beziers_sanctuary|echo=act2_beziers_healed|decision=act2_beziers_rebuilt:true"]`
- **Opção B (Confiscar a prata e armar trabucos):**
  `[signal arg="effect|alignment=-10|popular_support=-8|doctrine=+12|resources=+140|flag=beziers_plundered|echo=act2_beziers_ash|decision=act2_beziers_rebuilt:false"]`

#### Dilema 5 — **Tarascon** (`dilema_05_tarascon.dtl` — *O Manuscrito do Rhône e a Fera*)
- **Conflito:** Nos pântanos enevoados, um alquimista guarda um códice proibido que descreve a matéria do mundo como "engrenagem fechada" e oferece um preparo para envenenar a fera do rio. Uma *Parfaite* propõe acalmar a criatura pelo rito de paz.
- **Opção A (Proteger o códice e tentar o rito de paz — libera caminho da Tarasca pacificada):**
  `[signal arg="effect|alignment=+8|popular_support=+4|doctrine=-10|flag=tarasque_calm_rite|echo=act2_rhone_codex|resistance=act2_closed_firmament|decision=act2_tarascon_codex:true"]`
- **Opção B (Entregar o códice por fogo grego e abater a fera):**
  `[signal arg="effect|alignment=-8|doctrine=+10|resources=+110|flag=tarasque_hunt_poison|echo=act2_rhone_alchemy|decision=act2_tarascon_codex:false"]`

#### Dilema 6 — **Montségur** (`dilema_06_montsegur.dtl` — *A Vigília Antes do Abismo*)
- **Conflito:** No rochedo cercado nos Pireneus, quatro *Bons Hommes* preparam a descida secreta pela encosta à noite levando o tesouro espiritual do *castrum*. Você decide se cobre a fuga silenciosa (linha pacifista) ou lidera uma surtida desesperada contra os trabucos no vale (linha revolucionária) antes do encerramento trágico da crônica.
- **Opção A (Cobrir a fuga silenciosa dos quatro *Bons Hommes*):**
  `[signal arg="effect|alignment=+12|popular_support=+10|doctrine=-15|flag=montsegur_four_escaped|echo=act2_montsegur_light|resistance=act2_four_messengers|decision=act2_montsegur_stand:true"]`
- **Opção B (Liderar a surtida incendiária contra o acampamento de cerco):**
  `[signal arg="effect|alignment=+2|popular_support=+6|doctrine=+18|flag=montsegur_last_charge|echo=act2_montsegur_ember|resistance=act2_defiant_pyre|decision=act2_montsegur_stand:false"]`

---

## 2. Ato II — As 3 Classes Míticas (`UnitClassData.tres` + `ActionSkillData.tres`)

Valores calibrados exatamente na escala da §9 (referência Fubing Lv1: `110 HP / 16 ATK / 14 DEF / 6 INT / 9 AGI`; múltiplos golpes com `power` por golpe; `damage_taken_pct` em `% recebido`).

### 2.1 `portador_consolamentum` — Portador do Consolamentum (Luz / Pacifista)
- **Identidade:** `class_id = "portador_consolamentum"`, `era_id = 2`, `archetype = MYTHIC`, `tier = 3`, `grid_slots = 1`, `movement = "ground"`, `liberation_reputation_bonus = 8`
- **Traits:** `["celestial", "non_lethal", "morale_drain_immune"]`
- **Resistências (`damage_taken_pct`):** `{"SHADOW": 40, "PHYSICAL": 85}`
- **Atributos Lv1:** `max_hp = 128`, `max_morale = 120`, `attack = 12`, `defense = 16`, `intellect = 24`, `agility = 13`
- **Requisitos de promoção (a partir do `parfait`):** `min_level = 10`, `min_alignment = 75`, `max_alignment = 100`, `min_charisma = 65`, `min_doctrine = -100`, `max_doctrine = 10`, `required_item_id = &"pergaminho_consolamentum"`
- **`front_action` (`selo_de_paz`):** `effect = MORALE_ONLY`, `targeting = ALL_ENEMIES`, `power = 0`, `morale_power = 28`, `element = "LIGHT"`, `hits = 1`, `ally_guard_pct = 20`
- **`back_action` (`luz_do_consolamentum`):** `effect = HEAL`, `targeting = ALL_ALLIES`, `power = 95`, `element = "PURIFY"`, `hits = 1`, `enemy_morale_drain = 12`

### 2.2 `tarasca` — A Tarasca do Rhône (Fera Colossal de 2 Slots)
- **Identidade:** `class_id = "tarasca"`, `era_id = 2`, `archetype = MYTHIC`, `tier = 3`, `grid_slots = 2`, `movement = "swamp"`, `march_speed_pct = 90`
- **Traits:** `["morale_immune", "status_immune"]`
- **Resistências (`damage_taken_pct`):** `{"PHYSICAL": 65, "PIERCE": 70, "LIGHT": 135}`
- **Atributos Lv1:** `max_hp = 210`, `max_morale = 100`, `attack = 24`, `defense = 22`, `intellect = 14`, `agility = 8`
- **Recrutamento (sem promoção comum):** desbloqueada via `SquadData.outcome_rewards["morale_break"]` no encontro chefe de Tarascon (quando vencida por Moral com um `parfait` ou `portador_consolamentum` no esquadrão, exigindo `flag = tarasque_calm_rite`).
- **`front_action` (`mandibula_do_rhone`):** `effect = PHYSICAL`, `targeting = FRONT_FIRST`, `power = 60`, `element = "PHYSICAL"`, `hits = 2`, `armor_pierce_pct = 25`
- **`back_action` (`halito_do_pantano`):** `effect = MAGIC`, `targeting = ALL_ENEMIES`, `power = 75`, `morale_power = 18`, `element = "SHADOW"`, `hits = 1`, `inflicts_status = "POISON"` *(usa a extensão §3.2 abaixo)*

### 2.3 `eco_beziers` — Eco de Béziers (Espectro de Guerra / Sombria)
- **Identidade:** `class_id = "eco_beziers"`, `era_id = 2`, `archetype = MYTHIC`, `tier = 3`, `grid_slots = 1`, `movement = "ethereal"`, `night_march_bonus_pct = 25`
- **Traits:** `["undead", "morale_drain_immune"]`
- **Resistências (`damage_taken_pct`):** `{"PHYSICAL": 25, "PIERCE": 25, "LIGHT": 180, "PURIFY": 200}` *(imunidade quase total a dano físico comum, vulnerável a luz/purificação — fiel a Ogre Battle)*
- **Atributos Lv1:** `max_hp = 115`, `max_morale = 100`, `attack = 18`, `defense = 12`, `intellect = 21`, `agility = 15`
- **Requisitos de promoção / recrutamento:** desbloqueada via encontro noturno `night_encounter` em `beziers` (`outcome_rewards`) ou promoção sombria com `min_level = 9`, `min_alignment = 0`, `max_alignment = 35`, `required_item_id = &"cinza_de_madalena"`.
- **`front_action` (`lamina_de_cinza`):** `effect = PHYSICAL`, `targeting = FRONT_FIRST`, `power = 55`, `element = "SHADOW"`, `hits = 2`, `lifesteal_pct = 30`
- **`back_action` (`lamento_de_beziers`):** `effect = MAGIC`, `targeting = ALL_ENEMIES`, `power = 65`, `morale_power = 26`, `element = "SHADOW"`, `hits = 1`, `target_attack_debuff_pct = 15`

---

## 3. Extensões Mínimas de `ActionSkillData` (As 3 Habilidades Pendentes)

Todas seguem rigorosamente a **Regra 2 (§1)** (padrão neutro, zero quebra de comportamento existente) e a **Regra 8 (§1)** (100% determinístico).

### 3.1 Ouro no Saque do *Routier*
- **Novo campo em `ActionSkillData`:** `@export var resources_on_hit: int = 0` — *Recursos (moeda do ato) ganhos ao acertar o alvo; padrão `0`.*
- **Integração:** `CombatResolver` acumula `result.bonus_resources += skill.resources_on_hit` em cada acerto bem-sucedido de unidade aliada; `BattleConsequences` chama `WorldState.change_resources(result.bonus_resources)`.
- **Uso no *Routier*:** na skill `saque_de_estrada`, definir `resources_on_hit = 12`.
- **Teste obrigatório (`tests/test_combat.gd`):** verificar que `resources_on_hit = 0` não altera `WorldState.resources` e que `resources_on_hit = 12` soma exatamente `12 * hits_conectados` ao fim do combate.

### 3.2 Veneno Contínuo do *Sicário* (e *Tarasca*)
- **Novo valor em §6.5 (Status):** adicionar `"POISON"` ao vocabulário fechado de `inflicts_status` (mantendo `"CONFUSE"` intacto).
- **Regra determinística (§1.8):** se `skill.inflicts_status == "POISON"`, o alvo não tiver trait `"status_immune"` e tiver `agility <= attacker.agility` (ou HP atual `< 80%`), aplica `POISON` por **2 rodadas**.
- **Efeito no fim de cada rodada (`CombatResolver`):** unidades com `POISON` perdem `max(1, int(max_hp * 0.10))` de HP (sem matar se o atacante tiver trait `non_lethal`).
- **Teste obrigatório:** verificar aplicação determinística, tick de 10% por 2 rodadas e imunidade via `status_immune`.

### 3.3 Bônus de Dano por Terreno do *Faydit*
- **Novos campos em `ActionSkillData`:**
  - `@export var bonus_terrain: String = ""` — *Terreno canônico (§6.1) que concede bônus de poder; `""` desativa.*
  - `@export var bonus_terrain_power_pct: int = 0` — *Percentual somado ao `power` quando `context.terrain == bonus_terrain`; padrão `0`.*
- **Integração (`SkillMath`):** lê `context.get("terrain", "")` já recebido via `battle_requested(ally_squad, enemy_squad, context)`. Se `skill.bonus_terrain != ""` e bater com o terreno do nó, multiplica o poder efetivo por `(100 + bonus_terrain_power_pct) / 100.0`.
- **Uso no *Faydit*:** definir `bonus_terrain = "mountain"`, `bonus_terrain_power_pct = 25` (e/ou `forest` se variante de emboscada).
- **Teste obrigatório:** comparar dano do *Faydit* em `plains` (base) vs. `mountain` (+25%) com seed idêntica.

> **Checklist §11:** Ao implementar §3.1–§3.3, atualizar `SCHEMA_CANON.md` (§4.2 e §6.5) e `STATE_LEDGER.md` no mesmo commit e rodar `tests/run_tests.sh`.

---

## 4. [BLOQUEADO — AGUARDANDO DECISÃO DO USUÁRIO] Adendo Tático do Ato I

> **Não aplicar esta seção até confirmação explícita do usuário.**

- **Parte 1 (Puramente aditiva — segura):** criar `cike` (`archetype = RANGED_STEALTH`, promoção sombria do `nubing`), `catafractario` (`archetype = SHOCK`, promoção honrada do alabardeiro `ji`) e `junshi` (`archetype = BARD_INFLUENCE`, promoção honrada do estrategista/conselheiro).
- **Parte 2 (Conflito a decidir):**
  - **Conflito A:** transformar `daoshi` em promoção (`tier = 2`) do `fangshi` (em vez de classe base independente).
  - **Conflito B:** alterar `xian.required_item_id` para `&"elixir_pengming"` em vez do talismã atual.
