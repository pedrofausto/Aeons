# ARCHITECTURE.md — Projeto "Os Cinco Simulacros" (Godot 4.7.2 / GDScript)

> **Instrução para o Agente de IA Autônomo:** Este arquivo é a fonte única de verdade técnica do projeto. Leia a seção **STATE LEDGER** no início de cada sessão, respeite rigorosamente os limites de arquitetura e atualize o ledger ao concluir cada marco.

---

## 1. STATE LEDGER (Atualizar no topo a cada sessão)

> O livro-razão detalhado vive em **[`STATE_LEDGER.md`](STATE_LEDGER.md)** (raiz, < 120 linhas), conforme `ARCHITECTURE_DIFF.md` §6.
> **Nomes e tipos de schema:** **[`SCHEMA_CANON.md`](SCHEMA_CANON.md)** é a referência obrigatória; nomes divergentes em documentos de design são traduzidos pela tabela de aliases dele.
> Diffs: [`ARCHITECTURE_DIFF.md`](ARCHITECTURE_DIFF.md) · [`ARCHITECTURE_DIFF_ATO3.md`](ARCHITECTURE_DIFF_ATO3.md) (extensões planejadas do Ato III).
> As expansões aprovadas depois deste documento estão em **[`ARCHITECTURE_DIFF.md`](ARCHITECTURE_DIFF.md)**.

```yaml
projeto: "Os Cinco Simulacros"
engine: "Godot 4.7.2 (Standard / GDScript puro — sem C#)"
renderizador_obrigatorio: "gl_compatibility (--rendering-driver opengl3)"
alvo_exportacao: ["Desktop (macOS/Win/Linux)", "Web HTML5 (single-threaded)", "Android"]
fase_atual: "Vertical Slice do Ato I jogável (Sprints 1–3 + Diff §1–6). Próximo: Sprint 4 (arte e áudio)."
regras_de_sigilo_narrativo:
  - "PROIBIDO mencionar 'Aeons', 'simulação', 'simulacro' ou 'mesma alma' em qualquer diálogo, UI ou comentário visível nos Atos I a IV."
  - "Cada ato deve parecer um jogo/crônica independente até a revelação final no Ato V."
```

---

## 2. Regras Invioláveis de Engenharia (Vibecoding Seguro)

1. **Dados separados de código:** Nunca *hardcode* nomes de cidades, atributos de classes, facções ou diálogos em scripts `.gd`. Tudo deve ser carregado de recursos `.tres` ou arquivos `.json` dentro de `res://eras/act_XX/`.
2. **Scripts curtos e desacoplados:** Máximo recomendado de **250 linhas por arquivo `.gd`**. Comunicação entre sistemas sempre via **Signals** ou Autoloads (`EventBus.gd`, `WorldState.gd`).
3. **Renderização compatível (SotN 2D Depth em OpenGL 3.3):** Usar exclusivamente `CanvasItem`, `Sprite2D` + `CanvasTexture` (com *normal maps* gerados no Laigter), `Parallax2D` e `PointLight2D` sob o renderizador `gl_compatibility`.
4. **Verificação real obrigatória:** Todo marco deve rodar em janela real via `~/bin/godot-opengl3 --path . --quit-after 60` e emitir um marcador explícito `TEST_PASS|<nome_do_teste>` sem `SCRIPT ERROR` ou `ERROR:`.

---

## 3. Arquitetura de 3 Camadas Fixas (Reaproveitada nos 5 Atos)

O motor nunca é reescrito entre as épocas. Apenas o recurso `EraConfig.tres` ativo troca a pele visual, o vocabulário da UI, as unidades e os modificadores de regra:

| Camada | Cena-Base (`res://core/`) | Atos I–III (Guerra Física) | Ato IV (Recursos / Rede) | Ato V (Virtual / Cognitiva) |
|---|---|---|---|---|
| **1. Mapa Estratégico** | `OverworldMap.tscn` | Províncias, cidades, fortalezas e estradas | Distritos urbanos, data centers, mídia e energia | Topologia da matriz, cofres de memória e núcleos dos Aeons |
| **2. Combate 3×2** | `BattleArena.tscn` | Esquadrões físicos (HP = vida, Moral = coragem) | Células operacionais (HP = sigilo, Moral = credibilidade) | Processos/avatares (HP = sinal, Moral = lucidez) |
| **3. Interlúdio de Presença** | `InterludeRoom.tscn` | Acampamentos, salões de chá, abadias, trincheiras | Cafés chuvosos, bunkers urbanos e encontros clandestinos | Espaços liminares efêmeros com shader de dissolução |

---

## 4. Estrutura de Pastas do Projeto (`res://`)

```text
res://
├── ARCHITECTURE.md                  # Este documento + State Ledger
├── project.godot                    # gl_compatibility, Autoloads registrados
├── core/                            # MOTOR FIXO (nunca contém conteúdo específico de uma era)
│   ├── autoloads/
│   │   ├── EventBus.gd              # Sinais globais (node_captured, battle_ended, era_transition)
│   │   ├── WorldState.gd            # Estado visível do ato atual (Alinhamento, Apoio, Doutrina)
│   │   └── EssenceState.gd          # Memória OCULTA dos Aeons persistida entre os 5 atos
│   ├── data/                        # Classes Resource (.gd) usadas por todas as eras
│   │   ├── EraConfig.gd             # Tema UI, paleta, regras extras, lista de nós/unidades
│   │   ├── UnitClassData.gd         # 6 arquétipos + Mítico, faixas de alinhamento, ações frente/trás
│   │   ├── UnitInstance.gd          # Estado individual (HP, Moral, XP, Alinhamento, Classe)
│   │   ├── SquadData.gd             # Grade 3x2 (slots 0..2 frente, 3..5 trás), líder, fadiga
│   │   └── MapNodeData.gd           # ID, tipo (City/Fortress/Resource/Server), facção, ouro/tick
│   ├── overworld/
│   │   ├── OverworldMap.tscn        # Mapa em tempo real com pausa tática (Space)
│   │   ├── MapNode.gd               # Nó capturável com indicador visual e gatilho de evento
│   │   └── SquadToken.gd            # Token que marcha entre nós via caminho/grafo
│   ├── combat/
│   │   ├── BattleArena.tscn         # Cena isolada 3x2 recebendo (ally_squad, enemy_squad)
│   │   ├── CombatResolver.gd        # Lógica pura de turnos automáticos (HP e Moral)
│   │   └── TacticalOrder.gd         # Ordens rápidas (Focar Líder, Focar Fraco, Poupar/Render)
│   └── interlude/
│       ├── InterludeRoom.tscn       # Cena 2D em paralaxe + PointLight2D + gatilho Dialogic 2
│       └── InterludeController.gd
├── eras/                            # CONTEÚDO ISOLADO POR ÉPOCA
│   ├── act_01_tianxu/               # China Imperial (Vertical Slice inicial)
│   │   ├── EraConfig_Act01.tres
│   │   ├── classes/                 # Fubing, Youxia, Buqu, Ji, Nubing, Cike, Fangshi, Daoshi...
│   │   ├── map/                     # Vales de Nanlu (Linhai, 2 aldeias, 1 forte da Regência)
│   │   ├── dialogues/               # Timelines Dialogic 2 (apenas lore público do Ato I)
│   │   └── assets/                  # Sprites, normal maps (_n.png), trilhas .ogg
│   ├── act_02_occitania/            # Carcassonne & Cátaros (futuro)
│   ├── act_03_great_wars/           # I e II Guerras Mundiais (futuro)
│   ├── act_04_modern/               # Era Moderna / Recursos (futuro)
│   └── act_05_technocracy/          # Tecnocracia Cibernética (futuro)
└── tests/
    ├── test_combat_3x2.gd           # Teste automatizado de combate HP vs. Moral
    └── test_world_state.gd          # Teste de Alinhamento, Doutrina e EssenceState
```

---

## 5. Contrato dos Autoloads Críticos

### `WorldState.gd` (Estado Visível do Ato Atual)
```gdscript
extends Node

var current_act: int = 1
var alignment: int = 50          # 0 (Brutal/Mal) .. 100 (Honrado/Bem)
var popular_support: int = 50    # 0 .. 100 (Chaos Frame / Mandato do Céu)
var doctrine: int = 0            # -100 (Pacifista) .. +100 (Revolucionária)
var resources: int = 500         # Ouro (Atos I-III), Capital/Dados (Ato IV), Energia/Sinal (Ato V)
var is_paused: bool = true
var captured_nodes: Dictionary = {} # node_id -> faction_id
```

### `EssenceState.gd` (Estado Oculto dos Aeons — Nunca Exibido na UI dos Atos I–IV)
```gdscript
extends Node

var completed_acts: Array[int] = []
var alignment_history: Dictionary = {}   # act_id -> final_alignment
var doctrine_history: Dictionary = {}    # act_id -> final_doctrine
var philosophical_echoes: Array[String] = [] # Ex: ["protected_pengming_charts", "spared_deserters"]

func archive_act_and_reset_visible(act_id: int) -> void:
	completed_acts.append(act_id)
	alignment_history[act_id] = WorldState.alignment
	doctrine_history[act_id] = WorldState.doctrine
	# Reseta WorldState para simular um "novo jogo/novo personagem" após a Derrota Falsa
	WorldState.current_act = act_id + 1
	WorldState.alignment = 50
	WorldState.popular_support = 50
	WorldState.doctrine = 0
	WorldState.captured_nodes.clear()
```

---

## 6. Regra Central de Combate (`CombatResolver.gd`)

Todo esquadrão usa uma grade **3×2** (3 espaços frontais `0..2`, 3 traseiros `3..5`). Cada classe em `UnitClassData.gd` define:
- `archetype`: `VANGUARD`, `SHOCK`, `RANGED_STEALTH`, `ARCANE_TECH`, `HEALER_MORAL`, `BARD_INFLUENCE` ou `MYTHIC`.
- `front_action` e `back_action`: o golpe muda conforme a fileira (ex.: *Youxia* na frente ataca corpo a corpo; atrás protege aliados).
- **Duas condições de vitória por batalha:**
  1. **Aniquilação (HP = 0):** mais rápida, favorecida pela **Linha Revolucionária**.
  2. **Rendição por Moral (Moral = 0):** favorecida pela **Linha Pacifista** (clérigos/bardos/defesa), reduz baixas e aumenta **Apoio Popular** + inclinação pacifista (`doctrine -= delta`).

---

## 7. Plano de Execução para o Agente (Vertical Slice — Vales de Nanlu, Ato I)

Execute um sprint por vez. Faça um commit Git limpo ao final de cada sprint validado:

1. **Sprint 1 — Núcleo de Dados e Combate 3×2 (Sem Arte Definitiva):**
   - Criar `EventBus.gd`, `WorldState.gd`, `EssenceState.gd` e os `Resource` em `res://core/data/`.
   - Criar 4 classes iniciais em `res://eras/act_01_tianxu/classes/`: `fubing.tres`, `ji_halberdier.tres`, `nubing_crossbow.tres`, `daoshi_healer.tres`.
   - Implementar `BattleArena.tscn` + `CombatResolver.gd` com retângulos coloridos (placeholders) validando vitória por **HP** e vitória por **Moral**.
2. **Sprint 2 — Mapa de Conquista com Pausa (Vales de Nanlu):**
   - Implementar `OverworldMap.tscn` com 4 nós conectados: *Linhai dos Canais* (base aliada), *Aldeia dos Terraços* (neutra/celeiro), *Templo do Bambu* (neutra) e *Forte da Regência* (inimiga).
   - Permitir pausar (`Space`), clicar em um esquadrão, enviar para um nó, disparar `BattleArena.tscn` ao colidir com inimigo e atualizar `WorldState.gd` ao capturar a cidade.
3. **Sprint 3 — Primeiro Dilema Moral e Interlúdio de Presença:**
   - Instalar plugin **Dialogic 2** e implementar `InterludeRoom.tscn`.
   - Implementar o evento **Os Celeiros de Linhai** (distribuir arroz → `+alignment`, `+popular_support`, `-doctrine`; confiscar → `+resources`, `-popular_support`, `+doctrine`).
4. **Sprint 4 — Camada Visual 32-bit (SotN Depth) e Transição de Era:**
   - Substituir placeholders por sprites do **Pixelorama** + *normal maps* do **Laigter** + `PointLight2D` + 1 faixa `.ogg` em loop.
   - Testar `EssenceState.archive_act_and_reset_visible(1)` comprovando que o estado visível reinicia limpo para o Ato II enquanto os ecos ocultos permanecem salvos.
