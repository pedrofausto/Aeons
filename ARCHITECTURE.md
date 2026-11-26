# ARCHITECTURE.md — Projeto "Aeon" (Godot 4.7.2 / GDScript)

> **Instrução para o Agente de IA Autônomo:** Este arquivo é a fonte única de verdade técnica do projeto. Leia [`STATE_LEDGER.md`](STATE_LEDGER.md) e [`SCHEMA_CANON.md`](SCHEMA_CANON.md) no início de cada sessão, respeite rigorosamente os limites de arquitetura e atualize o ledger ao concluir cada marco.

---

## 1. STATE LEDGER & Documentos Relacionados

> - **Livro-razão detalhado:** [`STATE_LEDGER.md`](STATE_LEDGER.md) (raiz, < 120 linhas).
> - **Nomes e tipos canônicos:** [`SCHEMA_CANON.md`](SCHEMA_CANON.md) é a referência obrigatória; nomes divergentes em documentos de design são traduzidos pela Tabela de Aliases (§7).
> - **Referências e Diffs:** [`ARCHITECTURE_DIFF.md`](ARCHITECTURE_DIFF.md) · [`ARCHITECTURE_DIFF_ATO3.md`](ARCHITECTURE_DIFF_ATO3.md) (extensões planejadas do Ato III) · [`docs/references/Guia_Arquitetura_Tecnica_Game_Design.md`](docs/references/Guia_Arquitetura_Tecnica_Game_Design.md) · Mockup aprovado: [`docs/references/arena_25d_plana_mockup_v3.jpg`](docs/references/arena_25d_plana_mockup_v3.jpg) · `docs/Lore_Aeons_Verdade/ARCHITECTURE_v4_referencia.md`.

```yaml
projeto: "Aeon"
engine: "Godot 4.7.2 (Standard / GDScript puro — sem C#)"
renderizador_obrigatorio: "gl_compatibility (--rendering-driver opengl3)"
alvo_exportacao: ["Desktop (macOS/Win/Linux)", "Web HTML5 (single-threaded + OGG Vorbis)", "Android"]
fase_atual: "Atos I e II jogáveis + sprites 4x4/assets Ato I integrados. Próximo: Sprint 4 (áudio/normal maps/SaveSystem) e Ato III."
regras_de_sigilo_narrativo:
  - "PROIBIDO mencionar 'Aeons', 'simulação', 'simulacro' ou 'mesma alma' em qualquer diálogo, UI ou comentário visível nos Atos I a IV."
  - "Cada ato deve parecer um jogo/crônica independente até a revelação final no Ato V."
```

---

## 2. Regras Invioláveis de Engenharia (Vibecoding Seguro)

| Parâmetro | Decisão Obrigatória | Motivo Técnico |
|---|---|---|
| **Engine e Linguagem** | Godot 4.7.2 · **GDScript puro** (zero C#) | Cenas (`.tscn`) e dados (`.tres`) em texto puro; exportação nativa Web, Desktop e Mobile. |
| **Renderizador** | **`gl_compatibility`** (OpenGL 3.3 / WebGL 2.0) | Compatível com GPU *non-Metal* (Mac mini Mid 2011 / OCLP), Web e Mobile, cobrindo o mapa 2D (`CanvasItem`, `Parallax2D`, `PointLight2D`) e a Arena 2.5D Plana (`Node3D`, `Camera3D`, `Sprite3D` *billboard* sobre piso plano). |
| **Exportação Web** | *Single-threaded* WebAssembly + OGG Vorbis | Evita restrições de `SharedArrayBuffer` (COOP/COEP) no GitHub Pages / itch.io. |
| **Tamanho de Script** | Máximo de **250 linhas** por arquivo `.gd` | Reduz regressões e mantém separação limpa por responsabilidade. |
| **Dados vs. Código** | Nunca *hardcode* nomes, atributos ou diálogos em `.gd` | Tudo carregado de `.tres`, `.dtl` ou `.json` em `res://eras/act_XX/`. |
| **Comunicação** | Signals ou Autoloads (`EventBus.gd`, `WorldState.gd`) | Evita referências circulares entre cenas. |
| **Sigilo Narrativo** | Separação física `Lore_Simulacros/` vs `Lore_Aeons_Verdade/` | Diálogos dos Atos I–IV leem apenas `Lore_Simulacros/`. |
| **Execução de Testes** | Regra em [`AGENTS.md`](AGENTS.md): **aguardar autorização explícita** | Só rodar `tests/run_tests.sh` ou `~/bin/godot-opengl3 --path . --quit-after 60` quando autorizado pelo usuário. |

---

## 3. Princípio Central: 3 Camadas Fixas + 5 Perfis de Era + Estado Oculto

Em vez de programar cinco jogos separados, o projeto implementa **um único motor tático neutro** (`res://core/`) revestido por **cinco perfis modulares de época** (`res://eras/act_0X_*/EraConfig_Act0X.tres`).

| Camada | Cena-Base (`res://core/`) | Atos I–III (Guerra Física) | Ato IV (Rede & Recursos) | Ato V (Virtual & Cognitiva) |
|---|---|---|---|---|
| **1. Mapa Estratégico** | `OverworldMap.tscn` | Províncias, cidades, fortalezas, estradas e rios | Distritos urbanos, data centers, mídia e energia | Topologia da rede, cofres de memória e núcleos |
| **2. Esquadrões & Combate 3×2** | `BattleArena.tscn` | Companhias/pelotões físicos (`HP` = vida, `Moral` = coragem) | Células operacionais (`HP` = sigilo, `Moral` = credibilidade) | Processos/avatares (`HP` = sinal, `Moral` = lucidez) |
| **3. Interlúdio & Locais** | `InterludeRoom.tscn` · `LocationRoom.tscn` | Salões de chá, acampamentos, abadias, trincheiras | Locais físicos clandestinos (lanchonete, metrô, esconderijo) | Brechas efêmeras de uso único (`ephemeral_fade.gdshader`) |

---

## 4. Estrutura de Pastas do Projeto (`res://`)

```text
res://
├── ARCHITECTURE.md                  # Este documento
├── SCHEMA_CANON.md                  # Schemas canônicos e Tabela de Aliases (§7)
├── STATE_LEDGER.md                  # Livro-razão curto (< 120 linhas)
├── AGENTS.md                        # Travas operacionais e convenções
├── project.godot                    # gl_compatibility, Autoloads registrados
├── core/                            # MOTOR FIXO (nunca contém conteúdo específico de uma era)
│   ├── autoloads/
│   │   ├── EventBus.gd              # Sinais globais desacoplados
│   │   ├── WorldState.gd            # Estado visível do ato atual
│   │   ├── EssenceState.gd          # Memória OCULTA persistida entre os 5 atos
│   │   ├── AudioDirector.gd         # [Planejado] Camadas sincronizadas (.ogg)
│   │   └── SaveSystem.gd            # [Planejado] Serialização separando WorldState e EssenceState
│   ├── data/                        # Classes Resource (.gd) usadas por todas as eras
│   │   ├── EraConfig.gd             # Tema UI, paleta, regras extras, trilhas [Planejado], nós/unidades
│   │   ├── UnitClassData.gd         # 6 arquétipos + Mítico, ações frente/trás, promoções, sprite_frames [Planejado]
│   │   ├── UnitInstance.gd          # Estado individual (HP, Moral, XP, Alinhamento, Classe, Equipamentos)
│   │   ├── SquadData.gd             # Grade 3x2 (slots 0..2 frente, 3..5 trás), líder, fadiga
│   │   ├── MapNodeData.gd           # ID, tipo, facção, ouro/tick, vizinhos, artes do local
│   │   ├── ActionSkillData.gd       # Golpe/efeito, alvo, elemento, status
│   │   ├── ItemData.gd              # Itens de campanha, equipamentos e relíquias de promoção
│   │   └── PromotionRules.gd        # Requisitos de promoção + consumo de item
│   ├── overworld/                   # OverworldMap.tscn, MapNode, SquadToken, LocationRoom.tscn, HUD
│   ├── combat/                      # BattleArena.tscn, CombatResolver, TurnBattleSession, SkillMath
│   ├── interlude/                   # InterludeRoom.tscn, InterludeController, InterludeManager, shaders/
│   └── ui/                          # CharacterCreationTest.tscn
├── eras/                            # CONTEÚDO ISOLADO POR ÉPOCA
│   ├── act_01_tianxu/               # China Imperial (completo + assets 4x4/battle/portraits/tokens)
│   ├── act_02_occitania/            # Occitânia & Carcassonne (completo + sheet_faydit_4x4)
│   ├── act_03_ash_and_steel/        # Grandes Guerras (arte inicial staged; motor Ato III planejado)
│   ├── act_04_modern/               # Era Moderna / Recursos (arte inicial staged)
│   └── act_05_technocracy/          # Tecnocracia Cibernética (arte inicial staged)
└── tests/                           # Suíte local (no .gitignore): TestRunner.tscn + test_*.gd
```

---

## 5. Contrato dos Autoloads e Resources Críticos

### `WorldState.gd` (Estado Visível do Ato Atual)
Reiniciado na "Derrota Falsa" via `reset_visible()`: `current_act`, `alignment` (0..100), `popular_support` (0..100), `doctrine` (-100 Pacifista .. +100 Revolucionária), `resources`, `is_paused`, `captured_nodes`, `liberation_methods`, `faction_trust`, `day_count`, `time_of_day`, `player_squads`, `inventory`, `completed_interludes`.

### `EssenceState.gd` (Estado Oculto — Nunca Exibido na UI dos Atos I–IV)
Persiste nos 5 atos até o clímax do Ato V: `completed_acts`, `alignment_history`, `doctrine_history`, `philosophical_echoes`, `aeon_resistance_flags`, `ephemeral_meetings_seen`, `decisions`, `echo_values`, `act_records`, `false_defeats` e `[Planejado]` `remembered_captains: Array[Dictionary]` (snapshot mínimo de nome/classe/retrato dos protagonistas e aliados marcantes dos Atos I–IV).

### Extensões Planejadas em `EraConfig` e `UnitClassData`
- `EraConfig`: `[Planejado]` `overworld_music: AudioStream`, `battle_music: AudioStream`, `interlude_music: AudioStream`.
- `UnitClassData`: `[Planejado]` `sprite_frames: SpriteFrames` (sheets 4×4 animados), `normal_map_texture: Texture2D` (Laigter).

---

## 6. Combate 3×2 (`CombatResolver.gd` e `TurnBattleSession.gd`)

Todo esquadrão usa uma grade **3×2** (3 espaços frontais `0..2`, 3 traseiros `3..5`). Unidades colossais (`grid_slots = 2`, ex.: *Tarasca*) ocupam a coluna inteira.
- **Execução por fileira e turnos:** ordem determinada por `agility` (desempate determinístico por slot/lado). `CombatResolver` executa batalhas automáticas determinísticas; `TurnBattleSession` permite controle interativo turno a turno (escolher golpe frontal/traseiro, Poupar, Defender e alvo inimigo por clique/toque).
- **Duas condições de vitória por batalha:**
  1. **Aniquilação (HP = 0):** favorecida pela **Linha Revolucionária** (`doctrine > 0`); reduz `alignment` se o inimigo tiver nível muito inferior.
  2. **Rendição por Moral (Moral = 0):** favorecida pela **Linha Pacifista** (`doctrine < 0`), poupa vidas e eleva `popular_support`.

### Apresentação da Arena (2.5D Plana Rotacionável — Estilo *Ogre Battle* HD-2D)
- **Piso 3D plano e livre de obstáculos:** a luta ocorre sobre um diorama 3D isométrico rotacionável (`Q / E`), com piso central 100% plano (`y = 0`) — **sem degraus, paredes ou obstáculos internos** para os personagens subirem ou descerem; lanternas e elementos do cenário ficam apenas nas bordas e entorno.
- **Disposição 3×2 diagonal e animações 2.5D:** os dois esquadrões ficam frente a frente nas âncoras **3×2** sobre o piso plano com sprites 2D realistas (7,5–8 cabeças) em *Cylindrical Billboarding* (`Sprite3D`) e sombras projetadas no chão; avanços diagonais de golpe, arcos de corte, projéteis, recuo, *Hitstop*, *Screen Shake* e *Combat Forecast* determinístico operam em 2.5D.
- **Referência visual aprovada:** [`docs/references/arena_25d_plana_mockup_v3.jpg`](docs/references/arena_25d_plana_mockup_v3.jpg) e [`docs/references/Guia_Arquitetura_Tecnica_Game_Design.md`](docs/references/Guia_Arquitetura_Tecnica_Game_Design.md).

---

## 7. Protocolo da "Derrota Falsa" e Transição entre Eras

Gerenciado por `FalseDefeat.gd` + `EssenceState.archive_act_and_reset_visible()` + `WorldState.load_era()`:
1. Ao vencer o poder central do ato, tocam as `climax_timelines` da era e `EssenceState` registra silenciosamente o ato (`record_act`).
2. Exibe-se o desfecho trágico/apagamento daquela crônica (`false_defeat_id` / `chronicle_end_text`).
3. Ao avançar para `next_era_config`, `WorldState.reset_visible(next_act)` limpa os dados visíveis, aplica o novo `Theme`, paleta e vocabulário, iniciando o ato seguinte como uma nova história independente.

---

## 8. Pipeline Visual 2D / 2.5D (32-bit), Áudio e Narrativa

- **Pixel Art Realista com Profundidade:** proporções anatômicas realistas (7,5–8 cabeças, sem *chibi*), sprites e tilesets produzidos no **Pixelorama**, processados no **Laigter** para *normal maps* (`*_n.png`) via `CanvasTexture` / `Sprite3D`, iluminados no mapa 2D (`CanvasModulate` + `PointLight2D` + `Parallax2D`) e na Arena 2.5D Plana (`Node3D` + iluminação dinâmica + sombras no solo em `gl_compatibility`).
- **Áudio Orquestral Adaptativo `[Planejado]`:** composições no **MuseScore Studio + MuseSounds** / **Waveform Free + BBC Symphony Orchestra Discover**, exportadas em `.ogg` (OGG Vorbis) com loop para troca limpa via `AudioStreamInteractive` / `AudioStreamSynchronized` no `AudioDirector.gd`.
- **Narrativa Offline:** rascunho de lore em `docs/Lore_Simulacros/` e implementação estática determinística no **Dialogic 2** (`.dtl`). Nenhum LLM roda em tempo real dentro do jogo.
