# STATE_LEDGER.md — Livro-Razão de Estado (ler no início de cada sessão de IA)

> Atualizar após **cada** tarefa do agente. Máximo de 120 linhas. Fonte técnica: `ARCHITECTURE.md` + `ARCHITECTURE_DIFF.md`.

## Situação
- **Fase:** Vertical Slice do Ato I (Vales de Nanlu) jogável de ponta a ponta. Sprints 1–3 concluídos; Diff de Arquitetura §1–6 aplicado.
- **Próximo passo:** Sprint 4 — sprites Pixelorama + normal maps Laigter + 1 faixa `.ogg` (aguarda arte).
- **Engine:** Godot 4.7.2 · GDScript puro · `gl_compatibility` · resolução lógica 640×360 (janela 1280×720, Nearest).
- **Validação:** `tests/run_tests.sh` → **74 TEST_PASS**, 0 falhas, sem `SCRIPT ERROR`/`ERROR:` (janela real Xvfb + opengl3 e headless).
- **CI:** `.github/workflows/godot-ci.yml` (suíte + boot `--quit-after 60`).
- **Branch de trabalho:** `ccr-9fc24095-lrv5hy` (nunca fazer push em `main` sem autorização).

## Autoloads e variáveis ativas
| Autoload | Variáveis | Observação |
|---|---|---|
| `EventBus` | sinais: pause_toggled, tick_advanced, time_of_day_changed, node_captured, battle_requested, battle_ended, interlude_requested, interlude_choice_applied, interlude_finished, world_state_changed, era_loaded, era_transition | Sinais sobem; chamadas descem. |
| `WorldState` (visível) | current_act, alignment, popular_support, doctrine, resources, is_paused, captured_nodes, era_config, day_count, time_of_day, player_squads, active_flags, act_echoes, completed_interludes | Reinicia na Derrota Falsa (`reset_visible`). |
| `EssenceState` (OCULTO) | completed_acts, alignment_history, doctrine_history, philosophical_echoes (Array[String]), aeon_resistance_flags, ephemeral_meetings_seen | Persiste nos 5 atos. Nunca exibir na UI dos Atos I–IV. |
| `Dialogic` | addon 2.0-Alpha-21 | Timelines leem autoloads direto: `{WorldState.alignment}`. |

## Cenas e scripts existentes
- `core/overworld/OverworldMap.tscn` (cena principal) — OverworldMap, MapNode, SquadToken, MapGraph, PatrolAI, EncounterDirector, RoamingSquadSpawner, EncounterTable/EncounterEntry, DayNightTint, OverworldHUD.
- `core/combat/BattleArena.tscn` — CombatResolver (puro), TacticalOrder, BattleConsequences, UnitCardView.
- `core/interlude/InterludeRoom.tscn` — InterludeController, InterludeManager, `shaders/ephemeral_fade.gdshader`.
- `core/data/` — EraConfig, UnitClassData, UnitInstance, SquadData, MapNodeData, ActionSkillData.
- `tests/` — TestRunner.tscn, test_combat_3x2, test_world_state, test_overworld, test_interlude, run_tests.sh.

## Nomes canônicos — Ato I (Império de Tianxu · Vales de Nanlu)
- **Nós:** Linhai dos Canais (base aliada) · Aldeia dos Terraços (neutra, celeiro) · Templo do Bambu Cinzento (neutro) · Forte da Regência (inimigo).
- **Facção inimiga:** Regência do Selo de Ferro (Chanceler Gao Shen).
- **Esquadrões:** Guarda dos Canais (jogador) · Guarnição da Regência (forte) · Cobradores do Selo de Ferro (patrulha fixa, `moral_escort`) · Piratas Fluviais do Delta (`bandit_loot`, dia) · Milícia Camponesa Desesperada (`low_level_trap`).
- **Classes:** Fubing · Alabardeiro Ji · Besteiro Nubing · Daoshi · Youxia (promoção boa: Nv4, alinhamento ≥ 65) · Buqu (promoção sombria: Nv4, alinhamento ≤ 35).
- **Ordens:** Focar Líder · Focar Fraco · Poupar/Render.
- **Dilema:** Os Celeiros de Linhai (guardiã: velha Qiu) — distribuir (+alinhamento, +apoio, −doutrina, eco `shared_linhai_rice`) ou confiscar (+recursos, −apoio, +doutrina, eco `seized_linhai_granaries`).
- **Reservados no atlas (não usar com outro papel):** Mestre Shen (Liga dos Youxia), Mestra Lin (Lótus de Cinza), General Wei Bo, Arquivista Xu.

## Regra de sigilo narrativo (inviolável)
- **PROIBIDO** mencionar "Aeons", "simulação", "simulacro" ou "mesma alma" em diálogos, UI ou textos visíveis dos Atos I–IV.
- Diálogos dos Atos I–IV: usar **apenas** `docs/Lore_Simulacros/`. `docs/Lore_Aeons_Verdade/` só para `EssenceState` e Ato V.
- Guarda automático: teste `lore_secrecy_acts_1_to_4` (varre eras/, core/ e docs/Lore_Simulacros/).
- Nenhum LLM em tempo real no jogo: diálogos são estáticos no Dialogic 2.

## Decisões e bloqueios conhecidos
- Diff × implementação: `archetype` segue enum inteiro e ações seguem `ActionSkillData` (não StringName); `philosophical_echoes` segue `Array[String]` (contrato do ARCHITECTURE §5).
- `UnitClassData.promotes_to/promotion_good/promotion_evil` tipados como Resource (auto-referência vaza na saída no Godot 4.7).
- Sons de digitação de exemplo do Dialogic desligados (vazavam AudioStreamWAV ao fechar no meio de uma fala).
- Ação `dialogic_default_action` declarada à mão no `project.godot`; o editor reescreve o autoload do Dialogic como `uid://`.
- Pendentes do atlas: "confiscar dobra a marcha", "distribuir atrai Youxia", Jiangshi/encontros noturnos (precisam de classes), áudio "reduzido a cordas" no Ato V.
