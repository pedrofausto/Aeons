# ARCHITECTURE.md — Os Cinco Simulacros (Godot 4.7.2 / GDScript)

> **Documento-mestre de arquitetura para agentes de vibecoding (Cline / Antigravity CLI + `godot-mcp`).**
> Leia este arquivo inteiro antes de criar ou editar qualquer cena ou script.

---

## 1. Premissa Técnica e Restrições de Hardware

- **Engine:** [Godot 4.7.2 (Standard / GDScript — sem C#/.NET)](https://godotengine.org/download/archive/).
- **Renderizador obrigatório:** `gl_compatibility` (OpenGL 3.3 / WebGL 2.0) + exportação Web *single-threaded*.
  - **Motivo duplo:** (1) compatibilidade total com o Mac mini Mid 2011 (OCLP *non-Metal*) usando o wrapper `~/bin/godot-opengl3`; (2) exportação nativa para **Windows, Linux, macOS, Android, iOS e Web Browser (HTML5)** sem reescrever shaders.
- **Estilo Visual:** Pixel art 32-bit de alta riqueza (referência de qualidade técnica: *Castlevania: Symphony of the Night*, **sem** temática gótica fixa). Profundidade obtida por `Parallax2D`, `PointLight2D`, `CanvasModulate` e *normal maps* gerados no [Laigter](https://github.com/azagaya/laigter).
- **Regra de Ouro do Vibecoding:**
  - Scripts curtos (< 250 linhas), responsabilidade única, tipagem estática obrigatória em GDScript (`var hp: int = 100`).
  - **Nunca** misturar dados de época (nomes de unidades, mapas, diálogos) na lógica do motor em `res://core/`.
  - **Nunca** vazar o conceito de "Aeons", "simulacro" ou "5 camadas concêntricas" em diálogos, comentários visíveis ou UI dos Atos I–IV.

---

## 2. As Três Camadas Fixas do Jogo (Presentes em Todos os 5 Atos)

Todo ato roda exatamente o mesmo ciclo de três camadas, apenas trocando o perfil `EraConfig.tres`:

1. **Camada Estratégica (`OverworldMap.tscn`):**
   - Grafo de nós (`MapNode`) conectados por rotas ponderadas por terreno.
   - Marcha em tempo real com **pausa tática** (estilo *Ogre Battle: March of the Black Queen*).
   - **Abstração multi-era:** nos Atos I–III, `MapNode` representa cidades, fortalezas e trincheiras; no Ato IV representa data centers, emissoras e distritos urbanos; no Ato V representa nós de consenso neural e núcleos dos Aeons.
2. **Camada Tática (`CombatArena.tscn`):**
   - Cena isolada que recebe dois `SquadData` (aliado e inimigo) organizados em grade **3×2** (3 espaços na linha frontal, 3 na retaguarda; unidades colossais como a *Tarasque* ocupam 2 espaços).
   - Combate automático em rodadas onde a **fileira (Frente vs. Trás)** define a ação da classe, com intervenção do jogador por ordens táticas (Focar Líder, Focar Mais Fraco, Defender, Pressão Moral) e cartas/habilidades especiais da era.
   - **Dupla condição de vitória:** zerar **HP** (aniquilação — favorece Doutrina Revolucionária) ou zerar **Moral** (rendição/deserção — favorece Doutrina Pacifista).
3. **Camada de Interlúdio (`InterludeRoom.tscn`):**
   - Cenas 2D curtas de presença humana com paralaxe, `PointLight2D` e diálogos via [Dialogic 2](https://github.com/dialogic-godot/dialogic).
   - Atos I–III: acampamentos, cidades, mosteiros e abrigos.
   - Ato IV: espaços físicos íntimos e clandestinos (café sob chuva, esconderijo urbano) em contraste com o mapa virtual/informacional.
   - Ato V: espaços liminares efêmeros com shader de dissolução sutil e trilha mínima.

---

## 3. Estrutura de Pastas do Projeto Godot

```text
res://
├── core/
│   ├── autoloads/
│   │   ├── WorldState.gd          # Estado visível do ato atual (resetado na "derrota falsa")
│   │   ├── EssenceState.gd        # Autoload OCULTO que persiste entre os 5 atos (Aeons)
│   │   ├── EraManager.gd          # Carrega EraConfig.tres, temas de UI e transição de atos
│   │   └── AudioDirector.gd       # AudioStreamSynchronized (mapa, combate, tensão moral)
│   ├── resources/
│   │   ├── EraConfig.gd           # Resource: tema UI, regras extras, paleta, trilhas, nome dos recursos
│   │   ├── UnitClassData.gd       # Resource: arquétipo, faixa de alinhamento, golpes frente/trás
│   │   ├── UnitInstance.gd        # Resource: nível, HP, moral, alinhamento individual (0..100)
│   │   ├── SquadData.gd           # Resource: grade 3x2, líder, posição no mapa, fadiga
│   │   └── MapNodeData.gd         # Resource: tipo de nó, facção dona, ouro/recurso por dia, evento Dialogic
│   ├── overworld/
│   │   ├── OverworldMap.tscn
│   │   ├── OverworldController.gd
│   │   └── SquadToken.tscn
│   ├── combat/
│   │   ├── CombatArena.tscn
│   │   ├── CombatResolver.gd      # Lógica pura determinística (testável sem UI!)
│   │   └── CombatUnitView.tscn
│   └── interlude/
│       ├── InterludeRoom.tscn
│       └── InterludeController.gd
├── eras/
│   ├── act_01_tianxu/             # China Imperial (Vertical Slice inicial: Vales de Nanlu)
│   │   ├── era_config.tres
│   │   ├── classes/               # fubing.tres, youxia.tres, fangshi.tres, cike.tres...
│   │   ├── maps/                  # nanlu_vertical_slice.tscn
│   │   ├── dialogs/               # Timelines Dialogic 2 (sem citar Aeons!)
│   │   └── assets/                # Sprites, normal maps, tilesets, áudio OGG
│   ├── act_02_occitania/          # Carcassonne & Cátaros (estrutura reservada)
│   ├── act_03_great_wars/         # I e II Guerras Mundiais (estrutura reservada)
│   ├── act_04_modern/             # Alvorecer da Tecnocracia (estrutura reservada)
│   └── act_05_technocracy/        # Tecnocracia Cibernética + Convergência Final
├── docs/
│   ├── STATE_LEDGER.md            # Livro-razão explícito atualizado a cada marco (anti-amnésia)
│   └── lore_public/               # Cópias em Markdown dos atlas dos Atos I-IV
└── tests/
    └── smoke_combat_test.gd       # Teste determinístico automatizado com sentinela PASS/FAIL
```

---

## 4. Os Três Eixos de Estado (`WorldState.gd`) + Memória Oculta (`EssenceState.gd`)

### `WorldState.gd` (Visível no Ato Atual)
```gdscript
# Autoload: WorldState
extends Node

var current_act: int = 1
var alignment: int = 50            # 0 (Brutal/Sombrio) .. 100 (Honrado/Luz)
var popular_support: int = 50      # 0 (Temido/Odiado) .. 100 (Aclamado - Chaos Frame)
var doctrine: int = 0              # -100 (Pacifista) .. +100 (Revolucionária)
var treasury: int = 500            # Ouro (Atos I-III), Recursos/Fundos (Ato IV), Largura de Banda (Ato V)
var day_count: int = 1
var liberated_nodes: Dictionary = {} # node_id -> { "owner": String, "method": String }
```

### `EssenceState.gd` (Persistente e Oculto entre os 5 Simulacros)
```gdscript
# Autoload: EssenceState (NUNCA expor nomes de variáveis ou valores na UI dos Atos I-IV)
extends Node

var completed_acts: Array[int] = []
var act_echoes: Dictionary = {}    # act_id -> { "final_alignment": int, "final_doctrine": int, "support": int }
var philosophical_flags: Array[String] = [] # Ex: "pengming_astronomer_saved", "montsegur_codex_kept"
var aeon_containment_level: int = 1

func record_false_defeat(act_id: int, ws: Node) -> void:
	completed_acts.append(act_id)
	act_echoes[act_id] = {
		"final_alignment": ws.alignment,
		"final_doctrine": ws.doctrine,
		"support": ws.popular_support
	}
	aeon_containment_level += 1
```

---

## 5. Regra Anti-Amnésia para Agentes (`docs/STATE_LEDGER.md`)

LLMs degradam rastreamento de estado conforme a conversa cresce. Por isso, **ao final de cada tarefa concluída**, o agente deve atualizar `docs/STATE_LEDGER.md` com:
1. Arquivos criados/alterados e seus caminhos exatos (`res://...`).
2. Quais cenas e scripts passaram no teste automatizado com sentinela `SMOKE_TEST_PASS`.
3. Nomes canônicos já implementados (cidades, facções, classes) para evitar duplicação ou renomeação acidental.
4. Próxima micro-tarefa (máximo 1 funcionalidade por ciclo + commit Git).

---

## 6. Ordem de Construção do Corte Vertical (Ato I — Vales de Nanlu)

**Não implemente os Atos II–V antes de o Corte Vertical do Ato I estar 100% jogável e testado:**

1. **Marco 1 — Esqueleto e Autoloads:** Criar `project.godot` (`gl_compatibility`), pastas `res://core/` e `res://eras/act_01_tianxu/`, `WorldState.gd`, `EssenceState.gd` e os 5 arquivos `Resource` (`EraConfig.gd`, `UnitClassData.gd`, `UnitInstance.gd`, `SquadData.gd`, `MapNodeData.gd`).
2. **Marco 2 — Motor de Combate 3×2 (`CombatResolver.gd`):** Implementar resolução determinística de rodadas (frente vs. trás, dano HP vs. dano Moral, rendição por Moral = 0) com 4 classes do Ato I (`fubing`, `youxia`, `nubing`, `fangshi`) e validar via `tests/smoke_combat_test.gd`.
3. **Marco 3 — Mapa dos Vales de Nanlu (`OverworldMap.tscn`):** Criar 4 nós conectados (*Linhai dos Canais*, *Aldeia dos Terraços*, *Templo do Bambu Cinzento* e *Posto da Regência*), movimentação com pausa tática, captura de nó alterando `WorldState` e disparo automático do `CombatArena.tscn`.
4. **Marco 4 — Interlúdio + Transição de Era:** Adicionar `InterludeRoom.tscn` com o dilema *Os Celeiros de Linhai* (alterando `alignment`, `popular_support` e `doctrine`) e um botão/gatilho de teste da **Derrota Falsa** chamando `EssenceState.record_false_defeat(1, WorldState)` e trocando o `Theme` de UI para o molde do Ato II.
