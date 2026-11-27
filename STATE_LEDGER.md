# STATE_LEDGER.md — Livro-Razão de Estado (ler no início de cada sessão de IA)

> Atualizar após **cada** tarefa do agente. Máximo de 120 linhas.
> **Ordem de leitura:** este arquivo → **`SCHEMA_CANON.md`** (nomes/tipos canônicos e tabela de aliases — obrigatório antes de mexer em schema) → `ARCHITECTURE.md` + `ARCHITECTURE_DIFF.md` + `ARCHITECTURE_DIFF_ATO3.md`.

## Situação
- **Fase:** Ato I completo (Nanlu + Hanmen). Ato II com as 6 regiões (Spec_Pendencias §1), dilemas 1–6, 22 classes (inclui míticas Portador do Consolamentum, Tarasca de 2 slots e Eco de Béziers) e skills pendentes (saque, veneno, bônus de terreno) — `ACT2_CARCASSONNE_PASS`.
- **Próximo passo:** Derrota Falsa de Montségur (transição para o Ato III) e Ato III. Sprint 4 (arte/áudio) aguarda assets.
- **Adendo tático do Ato I aplicado** (aprovado pelo usuário): Cike, Catafractário, Conselheiro Yuefu → Junshi; Daoshi é promoção do Fangshi; Xian exige o Elixir de Pengming — `ACT1_ADENDO_PASS`.
- **Engine:** Godot 4.7.2 · GDScript puro · `gl_compatibility` · resolução lógica 640×360 (janela 1280×720, Nearest) · projeto `Aeon`.
- **Kit de Personagens/Objetos:** `antigravity-character-kit/` ignorado por `.gdignore`; 24 ícones copiados para `eras/act_01..05/art/items/`, 10 sprites + 13 retratos recortados (`slice_characters.py`) e ligados às 45 classes dos Atos I–II, `UnitCardView`, `SquadToken`, `EquipmentPanel` e `CharacterCreationTest.tscn` (`EQUIPMENT_KIT_PASS`).
- **Navegação, Cidades & Combate por Turnos:** clique/toque no mapa, 14 ícones pixel-art de cidades/nós, fundos próprios por local (`LocationRoom.tscn` + `InterludeController` + `BattleArena`), e `TurnBattleSession` com escolha de golpe e alvo por personagem (`GAMEPLAY_UPGRADES_PASS`).
- **Blocos A, B e C (Arena 2.5D Plana + Macro):** sheets 4×4 ligados em `youxia`/`ji_halberdier`/`fangshi`/`faydit`, `Combat Forecast` determinístico, `Hitstop`/shake, `Y-Sorting` + `Flying Layer Override` + manutenção diária (`daily_upkeep`) no mapa, e palco 3D plano rotacionável `Q/E` (`BattleStage25D`, `BattleUnit3D`, `SquadHudPanel`) em `BattleArena`.
- **Pacote 2.5D Ato I (`battle_25d`):** extraído seletivamente (`eras/act_01_tianxu/art/battle_25d/`, 6 skills em `classes/skills/`, `unit_hit_flash.gdshader`, `UnitActor25D`/`BattleArena25DLayout`) preservando `.tres` canônicos (`fubing`, `youxia`, `fangshi`, `nubing_crossbow`); piso e sheets 3-quadros integrados em `BattleStage25D`/`BattleUnit3D`.
- **Validação:** `tests/run_tests.sh` → `TEST_SUMMARY|pass=225|fail=0` (`OK: todos os testes passaram sem erros.`).
- **CI:** `.github/workflows/godot-ci.yml` (suíte + boot `--quit-after 60`).
- **Branch de trabalho:** `main` (push direto em `main` permitido).

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
- **Nós (região nanlu):** Linhai dos Canais (base aliada) · Aldeia dos Terraços (neutra, celeiro) · Templo do Bambu Cinzento (neutro; interlúdio O Caminho do Templo, Abade Zhuo) · Forte da Regência (inimigo, (510,165)) · Estreito de Linhai (nó SEA; única rota para Pengming).
- **Arquipélago de Pengming (região pengming, opcional):** Cais da Neblina (O Barqueiro da Neblina: 80 ouro → `pengming_tide_route`, guarnição da Ponte a 70%) · Gruta dos Elixires de Jade (Corsários da Maré Cinzenta; vitória → `elixir_pengming`) · Santuários do Bambu · Ponte da Maré (Expedição da Regência: Inquisidor Legalista Mo + Cike + Besteiros) · Observatório dos Nove Céus (dilema do Arquivista Xu). Espíritos da Névoa (Huli Jing) à noite após o Cais; Guardiões do Observatório só depois do encontro com Xu.
- **Templo (Abade Zhuo):** fala conforme a Doutrina — ≥ +15 fita vermelha (+5 DOC, +5 apoio) · ≤ −15 chá (+5 ALI, +5 apoio) · entre elas o jogador escolhe (±10 DOC). Ecos `temple_path_revolution`/`temple_path_peace`.
- **Nós (região hanmen, montanha):** Passagem de Hanmen · Portão de Hanmen (fortaleza opcional; General Wei Bo, Feudo dos Três Rios; rota de honra → `hanmen_pact_of_honor`).
- **Astrônomo Cego (Arquivista Xu, Observatório):** preservar em silêncio (`decisions.act1_blind_astronomer_protected = true`, +10 ALI, +8 apoio, −10 DOC, Carta Celeste dos Nove Céus, Fangshi Lan, eco `act1_sky_grid = observation`) · arma política (`true`, +20 apoio, +15 DOC, flag `act1_charts_published` → Caçadores Cike rondam Nanlu, eco `rupture`) · fogo alquímico (`false`, +300 ouro, −10 ALI, guarnição de Hanmen a 50%, `fac_youxia` −15, eco `betrayed_truth`). As duas primeiras gravam a anomalia `pengming_fixed_stars`.
- **Facção inimiga:** Regência do Selo de Ferro (Chanceler Gao Shen).
- **Esquadrões:** Guarda dos Canais (jogador) · Guarnição da Regência (forte) · Cobradores do Selo de Ferro (patrulha fixa, `moral_escort`) · Piratas Fluviais do Delta (`bandit_loot`, dia) · Milícia Camponesa Desesperada (`low_level_trap`).
- **Classes (árvore alinhada ao ledger de lore v2):** Fubing → Youxia / Buqu · Alabardeiro Ji → Catafractário / Saqueador das Estepes · Besteiro Nubing → Arqueiro Montado / Assassino Cike · Fangshi → Daoshi / Alquimista Sombrio (consome 1 `talisma_cinabrio`) + Xian (mítica, consome 1 `elixir_pengming`) · Médico Imperial → Monge Taoísta / Xamã Wu Sombrio (Nv9, ALI ≤ 40) · Conselheiro Yuefu → Estrategista Junshi / Intrigante Legalista. Míticas: Xian, Jiangshi, Huli Jing. Ge Xuan (Guarda dos Canais) já começa como Daoshi.
- **Míticas:** Jiangshi (undead, imune a moral, recebe 20% físico / 150% SPIRITUAL·PURIFY·FIRE, lento de dia e +50% à noite) · Xamã Wu Sombrio (Sino dos Mortos: +20% ataque a undead) · Huli Jing (CONFUSE em alvo mais lento) · Xian (voa, imune a status e a drenos de moral; Espada de Jade SPIRITUAL; Harmonia em área).
- **Encontros míticos:** Cortejo de Jiangshi (só região `hanmen` e só à noite; +5 apoio; sem penalidade de nível; 25% Talismã de Cinábrio) · Guardiões do Observatório dos Nove Céus (chefe no Observatório, surge após o encontro com Xu e até ser vencido; Moral → `pengming_xian_ally` + classe Xian; Aniquilação → Bússola dos Nove Céus: +20% marcha e revela encontros noturnos).
- **Itens:** `talisma_cinabrio` (Alquimista Sombrio; drop 25% do Cortejo em Hanmen à noite) · `elixir_pengming` (Xian; vitória sobre os Corsários na Gruta dos Elixires de Jade) · `carta_celeste` (única; revela encontros noturnos) · Bússola dos Nove Céus (única; chefe de Pengming).

## Nomes canônicos — Ato II (Occitânia · Cidadela de Carcassonne)
- **Protagonista:** Aimeric de Val-Clair (líder da Companhia de Cabaret; registrado em `act_records[2]`). Trovador da Companhia: Guillem. Pierre-Roger de Rochefort (Faydit) e Diaconisa Esclarmonde falam nas cenas.
- **Regiões (region_id):** `act2_carcassonne` (Burgo, Pontes, Cité) · `act2_albi` (Cabaret, Abadia da Montagne Noire) · `act2_toulouse` · `act2_montsegur` · `act2_beziers` · `act2_tarascon` (secreta).
- **Facções (`trust=`, `WorldState.faction_trust`):** `fac_crusaders` (Guy de Montclair) · `fac_inquisition` (Abade Arnaut, Irmão Guillaume) · `fac_faydits` (Pierre-Roger) · `fac_cathars` (Esclarmonde) · `fac_aragon` · `fac_routiers` (Loup-Noir).
- **Cenas:** 2.1 Muralhas de Carcassonne (ao libertar o Burgo; Ferro: DOC +15, ALI −5, Faydits +10 · Água: DOC −15, ALI +10, Apoio +10, Cátaros +10; decisão `act2_walls_doctrine`) · 2.2 Vigília de Esclarmonde (1ª chegada a Montségur ou vitória sobre a Escolta da Inquisição; eco `act2_philosophy` = `shatter_walls`/`awaken_within`) · 2.3 Queda de Montségur (clímax após a vitória do ato; fala de Aimeric conforme DOC ≥ 0) → Derrota Falsa `act2_montsegur_pyre`, "FIM DA CRÔNICA II — A RESISTÊNCIA CAIU.".
- **Encontro:** Feras dos Pireneus (noite, trilhas de Montségur; Lobos Gigantes + Urso da Montanha; `natural_wildlife`, sem impacto moral).
- **Nós:** Castelo de Cabaret (base, act2_albi) · Burgo de São Vicente (ocupado) · Pontes do Rio Aude (água) · Cité de Carcassonne (fortaleza cruzada em (320,165); água = Pontes) · Toulouse · Abadia da Montagne Noire (inimiga; Guarda da Abadia — vitória por Moral dá o Pergaminho do Consolamentum) · Ruínas de Béziers (Ecos de Béziers à noite) · Pântanos de Tarascon (opcional; Tarasca surge após a libertação) · Castrum de Montségur.
- **Dilemas 2–6 (decisões em EssenceState.decisions):** `act2_toulouse_pact` · `act2_abbey_mercy` · `act2_beziers_rebuilt` · `act2_tarascon_codex` (rito de paz = `tarasque_calm_rite`) · `act2_montsegur_stand`. Vitória do ato: Cité e Abadia (nós obrigatórios inimigos).
- **Regra da água:** quem guarda a fortaleza sem controlar sua água perde 8% HP (sem morrer) e 15 Moral por dia.
- **Esquadrões:** Companhia de Cabaret (jogador) · Sentinelas do Burgo · Guarnição de Montclair · Escolta da Inquisição (patrulha, moral_escort) · Bando de Routiers · Desertores Famintos.
- **Classes (22; ramo sombrio do Erudito = Ocultista; a mítica de 2 slots chama-se Domador da Tarasca; trovador da Companhia = Guillem):** Sergent d'Armes → Faydit (DOC ≥ +20, CHA 55) / Cavaleiro Hospitalário (DOC ≤ −10) / Routier · Lanceiro-Escudeiro → Chevalier de Languedoc (cavalaria) / Quebra-Muralhas (SIEGE) · Arbalétrier → Batedor dos Pireneus (mira o mais fraco) / Sicário Inquisitorial · Erudito-Boticário → Alquimista Hermético (LIGHT) / Ocultista · Irmão de Caridade → Parfait Cátaro (não letal, DOC ≤ −20; recusa após `act2_aude_poisoned`) / Inquisidor Dominicano · Trovador Occitano → Menestrel da Resistência (ação extra) / Arauto da Cruzada. Elites exigem Nv 9–12; XP do Ato II: 90/vitória, +20 por nível de diferença.
- **Dilema 1 — A Água de Carcassonne** (ao tomar as Pontes): poupar cisternas (pregação, 2 surtidas, rendição intacta, +30% ouro) · assalto noturno (água corre, cavalaria pesada reforça a Cité, +10 Carisma) · cortar a água (sede, guarnição a 50% HP, Parfaits recusam). Estado em `WorldState.siege`.
- **Reservados no atlas:** Barão Guy de Montclair, Abade Arnaut, Irmão Guillaume, Pierre-Roger de Rochefort, Diaconisa Esclarmonde, Capitão Loup-Noir.
- **Ordens:** Focar Líder · Focar Fraco · Poupar/Render.
- **Dilema:** Os Celeiros de Linhai (guardiã: velha Qiu) — distribuir (+alinhamento, +apoio, −doutrina, eco `shared_linhai_rice`) ou confiscar (+recursos, −apoio, +doutrina, eco `seized_linhai_granaries`).
- **Reservados no atlas (não usar com outro papel):** Mestre Shen (Liga dos Youxia), Mestra Lin (Lótus de Cinza), General Wei Bo, Arquivista Xu.

## Ato III — A Frente de Cinza (catálogo canônico pelo atlas v2; AINDA NÃO IMPLEMENTADO)
- **Slug:** `eras/act_03_ash_and_steel/`. **Regiões (region_id, propostas):** `no_mans_land` (Centro, início: Trincheira Setor 4, Ponte Ferroviária Quebrada, Cratera do Sino) · `eisenbruck_works` (Oeste: Fábricas de Aço, Entroncamento Ferroviário, Ponte Metálica) · `eastern_snowwoods` (Leste: Acampamento Partisan, Passo dos Pinheiros, Estação de Rádio Oculta) · `nordhaven_bay` (Norte, opcional: Porto de Nordhaven, Casamatas Costeiras, Farol de Ferro) · `southern_citadel` (Sul, clímax: Bunker Supremo, Bateria de Holofotes, Sala de Criptografia).
- **Facções (`fac_*`, dados):** `fac_steel_directorate` (Marechal Von Krell) · `fac_sabotage_network` (Agente "Corvo", Clara) · `fac_truce_radio` (Dr. Julian & Voz da Névoa) · `fac_night_witches` (Comandante Nadya; mítica — proteger vilas civis e Apoio alto no Leste) · `fac_smugglers` (O Comerciante de Nordhaven).
- **Encontros:** Patrulha de Choque (noite, Terra de Ninguém) · Comboio Ferroviário Blindado (patrulha nos trilhos Eisenbruck → Cidadela; corta o suprimento do chefe) · Recrutas Jovens Perdidos na Névoa (`low_level_trap`) · Equipe de Guerra Química (raro, Eisenbruck) · Espectro da Névoa (secreto, meia-noite, Ponte Quebrada).
- **Derrota Falsa:** clarão/explosão soterra o posto de comando na Cidadela do Sul; jornal abafa como "acidente de munição".
- **Pendente de decisão (atlas v1 → v2):** o atlas v2 não traz dilemas; os 5 do v1 (`act3_winter_truce_honored`, `act3_brevilles_civilians_warned`, `act3_eisenwerk_viaduct_spared`, `act3_chemical_depot_sealed`, `act3_final_radio_truth_aired`) citam lugares que sumiram (Brevilles, Estação X, Stahlstadt). Ids `station_x_balanced_war_cipher` e `act3_stahlstadt_classified_armistice` idem. Atlas v1 em `docs/diffs/Atlas_Ato_III_v1_SUPERADO.md`.
- **Anomalias (aeon_resistance_flags):** `pengming_fixed_stars` (I) · `montsegur_archon_codex` (II) · (III a definir). **Derrotas falsas (`EssenceState.false_defeats`):** `act1_tiandu_eclipse` · `act2_montsegur_pyre` · (III a definir).
- **Colisão de nomes:** "Clara" (Agente Corvo, III) × Clara Mendes (Rede Cívica Agora, IV).
- **Motor previsto (nomes reservados em SCHEMA_CANON §8):** `enable_supply_lines`, `enable_fog_of_intel`, `era_meters` (supply/intel/artillery/radio), `SupplyGraphSystem`, `OffmapStrikeManager`, status `SUPPRESSED`.

## Roteiro Mestre (linhas gerais, NÃO definitivo — `docs/Lore_Aeons_Verdade/Roteiro_Mestre_5_Atos.md`)
- **Protagonistas (nomes reservados):** I Shen Yue · II Aimeric de Val-Clair (o roteiro antigo dizia Guilhem de Razès; substituído pelo doc completo do Ato II) · III Tenente Arthur Vance · IV Lucas Vermeer · V Sujeito-0.
- **Conflitos em aberto (decidir antes de escrever cenas):** Ato I cena 1 tem Mestre Shen em Linhai (no jogo: velha Qiu) · Astrônomo Cego resolvido: Arquivista Xu no Observatório; Zhuo passa a ser o abade do Templo · antagonista do Ato IV "Nexus Aeterna" (roteiro) × "Consórcio Meridian" (atlas).

## Ato IV — Nova Vespera · Tecnocracia Nascente (catálogo canônico; AINDA NÃO IMPLEMENTADO)
- **Slug:** `eras/act_04_modern/` · `reality_layer = "RESOURCE_NETWORK"` · `interlude_style = "clandestine_physical"` (batalhas por sinal/recursos; interlúdios físicos reais: lanchonete sob chuva, esconderijo, metrô de madrugada).
- **Distritos (region_id):** Bairro de Santa Clara (NO, início) · Entroncamento Central (O, mobilidade) · Morro das Antenas (N, narrativa) · Porto & Subestação Leste (SE, energia) · Distrito Financeiro (Centro, clímax — Torre Meridian) · Subsolo de Fibra / Anel Zero (oculto, secreto).
- **Facções (dados):** Consórcio Meridian (Helena Vance) · Rede Cívica Agora/OSINT (Clara Mendes) · Coletivo Ruptura-Zero ("Kaelen") · Aparato Estatal Legado (Comissário Rocha) · Correios Analógicos (Sr. Takahashi) · Anomalias de Sinal.
- **Encontros/dilemas:** Vazamento do Hospital Sul · Enxame de Drones de Triagem · O Dossiê do Jornalista · Apagão do Porto Leste · O Sinal-Fantasma no Anel Zero (secreto).

## Facções canônicas dos Atos I–II (nomes reservados; não reutilizar com outro papel)
- **Ato I:** Regência do Selo de Ferro (Chanceler Gao Shen) · Feudo dos Três Rios (General Wei Bo) · Irmandade do Lótus de Cinza (Mestra Lin) · Liga dos Youxia e Moístas (Mestre Shen) · Clãs de Beisha (Khan Batu-Ordo) · Círculo Fangshi de Pengming (Arquivista Xu). Regiões: Nanlu, Dongwan, Hanmen, Beisha, Pengming, Zhonghe/Tiandu.
- **Ato II:** Barões da Cruzada do Norte (Barão Guy de Montclair) · Legado Papal & Inquisição (Abade Arnaut) · Faydits (Pierre-Roger de Rochefort) · Bons Hommes (Diaconisa Esclarmonde) · Coroa de Aragão · Routiers (Capitão Loup-Noir).

## Regra de sigilo narrativo (inviolável)
- **PROIBIDO** mencionar "Aeons", "simulação", "simulacro", "matriz", "camada concêntrica" ou "mesma alma" em diálogos, UI ou textos visíveis dos Atos I–IV, ou sugerir que os 5 protagonistas são a mesma pessoa.
- **Fio filosófico permitido (vocabulário da época):** I — estrelas fixas sobre Tianxu, Huang-Lao × Legalismo · II — o mundo material como obra de um Arconte ciumento (dualismo cátaro) · III — "mão invisível nas cifras", "guerra desenhada para moer gerações" · IV — anomalias de registro civil e dados idênticos a arquivos antigos, tratados como "ruído de algoritmo" ou conspiração corporativa.
- **Derrota Falsa:** ao vencer o poder central de cada ato (I–IV), uma cena de colapso/apagamento trágico encerra a crônica local antes do ato seguinte.
- **Ato III, adicional:** proibido "vida passada", "China", "Carcassonne" (nomes de outros atos); teste `EXTRA_FORBIDDEN` em `tests/test_interlude.gd`. "matriz" é barrado em todo texto jogável (`eras/`, `core/`) pelo `PLAYER_FORBIDDEN`.
- Diálogos dos Atos I–IV: usar **apenas** `docs/Lore_Simulacros/`. `docs/Lore_Aeons_Verdade/` só para `EssenceState` e Ato V.
- Guarda automático: teste `lore_secrecy_acts_1_to_4` (varre eras/, core/ e docs/Lore_Simulacros/).
- Nenhum LLM em tempo real no jogo: diálogos são estáticos no Dialogic 2. Uso offline permitido: rascunhos de vozes a partir de `docs/Lore_Simulacros/`, com este ledger no contexto.

## Decisões e bloqueios conhecidos
- Diff × implementação: `archetype` segue enum inteiro e ações seguem `ActionSkillData` (não StringName); `philosophical_echoes` segue `Array[String]` (contrato do ARCHITECTURE §5).
- `UnitClassData.promotes_to/promotion_good/promotion_evil` tipados como Resource (auto-referência vaza na saída no Godot 4.7).
- Sons de digitação de exemplo do Dialogic desligados (vazavam AudioStreamWAV ao fechar no meio de uma fala).
- Ação `dialogic_default_action` declarada à mão no `project.godot`; o editor reescreve o autoload do Dialogic como `uid://`.
- Spec mítica × schema: arquétipos MYTHIC_* viram `MYTHIC`/`HEALER_MORAL` + `traits`; "80% de resistência física" = recebe 20%; CONFUSE é determinístico (alvo mais lento); Xian usa `morale_drain_immune` (não `morale_immune`) para a vitória por Moral contra o chefe ser possível; Fangshi foi criado (não existia).
- Pendentes do atlas: "confiscar dobra a marcha", "distribuir atrai Youxia", áudio "reduzido a cordas" no Ato V; dilemas do Ato II.
