# STATE_LEDGER.md — Livro-Razão de Estado (ler no início de cada sessão de IA)

> Atualizar após **cada** tarefa do agente. Máximo de 120 linhas.
> **Ordem de leitura:** este arquivo → **`SCHEMA_CANON.md`** (nomes/tipos canônicos e tabela de aliases — obrigatório antes de mexer em schema) → `ARCHITECTURE.md` + `ARCHITECTURE_DIFF.md` + `ARCHITECTURE_DIFF_ATO3.md`.

## Situação
- **Fase:** Ato I completo (Nanlu + Hanmen). Ato II: Cidadela de Carcassonne com árvore completa de 19 classes e o dilema 1 "A Água de Carcassonne" (3 ramos jogáveis) — `ACT2_CARCASSONNE_PASS`.
- **Próximo passo:** Ato II — regiões Toulouse, Montagne Noire, Béziers, Tarascon e Montségur com os dilemas 2–6 e as classes míticas (Portador do Consolamentum, Tarasca 2 slots, Eco de Béziers). Adendo tático do Ato I (Cike, Catafractário, Junshi...) ainda não aplicado. Sprint 4 (arte/áudio) aguarda assets.
- **Engine:** Godot 4.7.2 · GDScript puro · `gl_compatibility` · resolução lógica 640×360 (janela 1280×720, Nearest).
- **Validação:** `tests/run_tests.sh` → **140 TEST_PASS**, 0 falhas, sem `SCRIPT ERROR`/`ERROR:` (janela real Xvfb + opengl3 e headless).
- **CI:** `.github/workflows/godot-ci.yml` (suíte + boot `--quit-after 60`).
- **Branch de trabalho:** `ccr-9fc24095-lrv5hy` (nunca fazer push em `main` sem autorização).

## Autoloads e variáveis ativas
| Autoload | Variáveis | Observação |
|---|---|---|
| `EventBus` | sinais: pause_toggled, tick_advanced, time_of_day_changed, node_captured, battle_requested, battle_ended, interlude_requested, interlude_choice_applied, interlude_finished, world_state_changed, era_loaded, era_transition | Sinais sobem; chamadas descem. |
| `WorldState` (visível) | current_act, alignment, popular_support, doctrine, resources, is_paused, captured_nodes, era_config, day_count, time_of_day, player_squads, active_flags, act_echoes, completed_interludes, inventory (ItemData), unlocked_classes | Reinicia na Derrota Falsa (`reset_visible`). |
| `EssenceState` (OCULTO) | completed_acts, alignment_history, doctrine_history, philosophical_echoes (Array[String]), aeon_resistance_flags, ephemeral_meetings_seen, decisions (gravadas uma única vez) | Persiste nos 5 atos. Nunca exibir na UI dos Atos I–IV. |
| `Dialogic` | addon 2.0-Alpha-21 | Timelines leem autoloads direto: `{WorldState.alignment}`. |

## Cenas e scripts existentes
- `core/overworld/OverworldMap.tscn` (cena principal) — OverworldMap, MapNode, SquadToken, MapGraph, PatrolAI, EncounterDirector, RoamingSquadSpawner, EncounterTable/EncounterEntry, SiegeWaterRule, DayNightTint, OverworldHUD, PromotionPanel.
- `core/data/PromotionRules.gd` — requisitos de promoção + `required_item_id` consumido ao confirmar.
- `core/combat/BattleArena.tscn` — CombatResolver (orquestra), SkillMath (elementos, resistências, status, buffs), CombatTargeting, TacticalOrder, BattleConsequences, UnitCardView.
- `core/interlude/InterludeRoom.tscn` — InterludeController, InterludeManager, `shaders/ephemeral_fade.gdshader`.
- `core/data/` — EraConfig, UnitClassData, UnitInstance, SquadData, MapNodeData, ActionSkillData, ItemData.
- `tests/` — TestRunner.tscn, test_combat_3x2, test_world_state, test_overworld, test_interlude, test_mythic, test_act1_fixes, test_act2, run_tests.sh (exige os 3 marcadores).

## Nomes canônicos — Ato I (Império de Tianxu · Vales de Nanlu)
- **Nós (região nanlu):** Linhai dos Canais (base aliada) · Aldeia dos Terraços (neutra, celeiro) · Templo do Bambu Cinzento (neutro; dilema O Astrônomo Cego) · Forte da Regência (inimigo).
- **Nós (região hanmen, montanha):** Passagem de Hanmen · Portão de Hanmen (fortaleza opcional; General Wei Bo, Feudo dos Três Rios; rota de honra → `hanmen_pact_of_honor`).
- **Astrônomo Cego (Zhuo):** proteger grava `EssenceState.decisions.act1_blind_astronomer_protected = true` (+10 alinhamento, +8 apoio); entregar grava `false` (+300 ouro, −10 alinhamento).
- **Facção inimiga:** Regência do Selo de Ferro (Chanceler Gao Shen).
- **Esquadrões:** Guarda dos Canais (jogador) · Guarnição da Regência (forte) · Cobradores do Selo de Ferro (patrulha fixa, `moral_escort`) · Piratas Fluviais do Delta (`bandit_loot`, dia) · Milícia Camponesa Desesperada (`low_level_trap`).
- **Classes:** Fubing · Alabardeiro Ji · Besteiro Nubing · Daoshi (talismã PURIFY) · Fangshi (fogo alquímico; promove a Xian/Wu Sombrio consumindo 1 `talisma_cinabrio`) · Youxia (promoção boa: Nv4, alinhamento ≥ 65) · Buqu (promoção sombria: Nv4, alinhamento ≤ 35).
- **Míticas:** Jiangshi (undead, imune a moral, recebe 20% físico / 150% SPIRITUAL·PURIFY·FIRE, lento de dia e +50% à noite) · Xamã Wu Sombrio (Sino dos Mortos: +20% ataque a undead) · Huli Jing (CONFUSE em alvo mais lento) · Xian (voa, imune a status e a drenos de moral; Espada de Jade SPIRITUAL; Harmonia em área).
- **Encontros míticos:** Cortejo de Jiangshi (só região `hanmen` e só à noite; +5 apoio; sem penalidade de nível; 25% Talismã de Cinábrio) · Guardiões do Observatório dos Nove Céus (chefe em arquipelago_pengming, até ser vencido; Moral → `pengming_xian_ally` + classe Xian; Aniquilação → Bússola dos Nove Céus: +20% marcha e revela encontros noturnos).
- **Itens:** `talisma_cinabrio` (consumido na promoção do Fangshi) · Bússola dos Nove Céus (única).

## Nomes canônicos — Ato II (Occitânia · Cidadela de Carcassonne)
- **Nós:** Castelo de Cabaret (base, montagne_noire) · Burgo de São Vicente (ocupado) · Pontes do Rio Aude (água) · Cité de Carcassonne (fortaleza cruzada; água = Pontes).
- **Regra da água:** quem guarda a fortaleza sem controlar sua água perde 8% HP (sem morrer) e 15 Moral por dia.
- **Esquadrões:** Companhia de Cabaret (jogador) · Sentinelas do Burgo · Guarnição de Montclair · Escolta da Inquisição (patrulha, moral_escort) · Bando de Routiers · Desertores Famintos.
- **Classes (19, Specs_Classes_Ato2 + Adendo mesclados; Adendo vence nos nomes/faixas):** Sergent d'Armes → Faydit (DOC ≥ +20, CHA 55) / Cavaleiro Hospitalário (DOC ≤ −10) / Routier · Lanceiro-Escudeiro → Chevalier de Languedoc (cavalaria) / Quebra-Muralhas (SIEGE) · Arbalétrier → Batedor dos Pireneus (mira o mais fraco) / Sicário Inquisitorial · Erudito-Boticário → Alquimista Hermético (LIGHT) / Engenheiro de Fogo · Irmão de Caridade → Parfait Cátaro (não letal, DOC ≤ −20; recusa após `act2_aude_poisoned`) / Inquisidor Dominicano · Trovador Occitano → Menestrel da Resistência (ação extra) / Arauto da Cruzada. Elites exigem Nv 9–12; XP do Ato II: 90/vitória, +20 por nível de diferença.
- **Dilema 1 — A Água de Carcassonne** (ao tomar as Pontes): poupar cisternas (pregação, 2 surtidas, rendição intacta, +30% ouro) · assalto noturno (água corre, cavalaria pesada reforça a Cité, +10 Carisma) · cortar a água (sede, guarnição a 50% HP, Parfaits recusam). Estado em `WorldState.siege`.
- **Reservados no atlas:** Barão Guy de Montclair, Abade Arnaut, Irmão Guillaume, Pierre-Roger de Rochefort, Diaconisa Esclarmonde, Capitão Loup-Noir.
- **Ordens:** Focar Líder · Focar Fraco · Poupar/Render.
- **Dilema:** Os Celeiros de Linhai (guardiã: velha Qiu) — distribuir (+alinhamento, +apoio, −doutrina, eco `shared_linhai_rice`) ou confiscar (+recursos, −apoio, +doutrina, eco `seized_linhai_granaries`).
- **Reservados no atlas (não usar com outro papel):** Mestre Shen (Liga dos Youxia), Mestra Lin (Lótus de Cinza), General Wei Bo, Arquivista Xu.

## Ato III — A Frente de Cinza e Aço (catálogo canônico; AINDA NÃO IMPLEMENTADO)
- **Slug:** `eras/act_03_ash_and_steel/`. **Regiões (region_id):** `no_mans_land` (Trincheira Setor 7, Ponte do Rio Cinza) · `grey_strait` (Porto de Brevilles) · `maquis_woods` (Planalto de Verneuil) · `eisenwerk_hub` (Entroncamento, Depósito Químico) · `alpine_pass` (Estação X) · `stahlstadt_hq` (Bastião de Aço).
- **Facções (dados, não motor):** Diretório de Aço · Comissariado & Censura · Maquisards · Corpo Médico & Rádio Livre · Criptógrafos da Estação X · Bruxas da Noite (mítica; exige `act3_chemical_depot_sealed`).
- **Decisões (EssenceState.decisions):** `act3_winter_truce_honored` · `act3_brevilles_civilians_warned` · `act3_eisenwerk_viaduct_spared` · `act3_chemical_depot_sealed` · `act3_final_radio_truth_aired`.
- **Anomalias (aeon_resistance_flags):** `pengming_fixed_stars` (I) · `montsegur_archon_codex` (II) · `station_x_balanced_war_cipher` (III). **Derrotas falsas (planejado `EssenceState.false_defeats`):** `act1_tiandu_eclipse` · `act2_montsegur_pyre` · `act3_stahlstadt_classified_armistice`.
- **Motor previsto (nomes reservados em SCHEMA_CANON §8):** `enable_supply_lines`, `enable_fog_of_intel`, `era_meters` (supply/intel/artillery/radio), `SupplyGraphSystem`, `OffmapStrikeManager`, status `SUPPRESSED`.

## Regra de sigilo narrativo (inviolável)
- **PROIBIDO** mencionar "Aeons", "simulação", "simulacro" ou "mesma alma" em diálogos, UI ou textos visíveis dos Atos I–IV.
- **Ato III, adicional:** proibido "matriz", "vida passada", "China", "Carcassonne" (nomes de outros atos); teste `EXTRA_FORBIDDEN` em `tests/test_interlude.gd`.
- Diálogos dos Atos I–IV: usar **apenas** `docs/Lore_Simulacros/`. `docs/Lore_Aeons_Verdade/` só para `EssenceState` e Ato V.
- Guarda automático: teste `lore_secrecy_acts_1_to_4` (varre eras/, core/ e docs/Lore_Simulacros/).
- Nenhum LLM em tempo real no jogo: diálogos são estáticos no Dialogic 2.

## Decisões e bloqueios conhecidos
- Diff × implementação: `archetype` segue enum inteiro e ações seguem `ActionSkillData` (não StringName); `philosophical_echoes` segue `Array[String]` (contrato do ARCHITECTURE §5).
- `UnitClassData.promotes_to/promotion_good/promotion_evil` tipados como Resource (auto-referência vaza na saída no Godot 4.7).
- Sons de digitação de exemplo do Dialogic desligados (vazavam AudioStreamWAV ao fechar no meio de uma fala).
- Ação `dialogic_default_action` declarada à mão no `project.godot`; o editor reescreve o autoload do Dialogic como `uid://`.
- Spec mítica × schema: arquétipos MYTHIC_* viram `MYTHIC`/`HEALER_MORAL` + `traits`; "80% de resistência física" = recebe 20%; CONFUSE é determinístico (alvo mais lento); Xian usa `morale_drain_immune` (não `morale_immune`) para a vitória por Moral contra o chefe ser possível; Fangshi foi criado (não existia).
- Região pengming tem tabela registrada (chefe Xian), mas seus nós ainda não existem no mapa.
- Pendentes do atlas: "confiscar dobra a marcha", "distribuir atrai Youxia", áudio "reduzido a cordas" no Ato V; dilemas do Ato II.
