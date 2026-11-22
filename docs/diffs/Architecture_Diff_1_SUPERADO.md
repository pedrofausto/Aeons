# ARCHITECTURE_DIFF.md — Diff Incremental para Atualizar o `ARCHITECTURE.md` Existente

> **Uso:** Aplicar apenas as alterações abaixo sobre o `ARCHITECTURE.md` já existente no projeto (sem reescrever o documento inteiro).

---

## 1. `[~ ATUALIZAR]` Estrutura de Pastas (`res://`)

```diff
 res://
 ├── ARCHITECTURE.md
+├── STATE_LEDGER.md                  # Livro-razão canônico (leitura obrigatória por sessão)
 ├── project.godot                    # gl_compatibility, Autoloads registrados
 ├── core/
 │   ├── state/
 │   │   ├── WorldState.gd            # Autoload: estado visível do ato atual
 │   │   └── EssenceState.gd          # Autoload: memória oculta entre os 5 atos (Aeons)
 │   ├── resources/
 │   │   ├── EraConfig.gd             # Resource: tema, shader, camada de realidade e labels
 │   │   ├── UnitClassData.gd         # Resource: ficha unificada de classe (Bem/Mal, 3x2)
+│   │   ├── SquadData.gd             # Resource: esquadrão 3x2 (até 6 slots)
+│   │   └── MapNodeData.gd           # Resource: cidade, fortaleza, servidor ou nó neural
 │   ├── overworld/
 │   │   ├── OverworldMap.tscn
 │   │   ├── MapNode.tscn
+│   │   ├── SquadToken.tscn
+│   │   └── RoamingSquadSpawner.gd   # Patrulhas dinâmicas por região e horário
 │   ├── combat/
 │   │   ├── CombatArena.tscn         # Diorama 2D lateral 3x2 + PointLight2D + paralaxe
 │   │   └── CombatResolver.gd        # Vitória dupla: HP = 0 ou Moral = 0
 │   └── interlude/
-│       └── InterludeRoom.tscn
+│       ├── InterludeRoom.tscn       # Camada 3: encontros presenciais / liminares + Dialogic 2
+│       └── shaders/
+│           └── ephemeral_fade.gdshader # Dissolução sutil para os encontros únicos do Ato V
+└── tests/
+    └── smoke_test.gd                # Validação automatizada (SMOKE_TEST_PASS)
```

---

## 2. `[~ ATUALIZAR]` Estado Global (`WorldState.gd` e `EssenceState.gd`)

```diff
 # res://core/state/WorldState.gd (reiniciado a cada ato na "Derrota Falsa")
-var act_id: int = 1
+var current_act: int = 1
 var alignment: int = 50         # 0 (Brutal/Mal) .. 100 (Honrado/Bem)
 var popular_support: int = 50   # 0 (Odiado) .. 100 (Aclamado / Chaos Frame)
+var doctrine: int = 0           # -100 (Pacifista) .. +100 (Revolucionária)
+var resources: int = 500        # Ouro (I-III), Fundos/Dados (IV), Largura de Banda (V)
+var captured_nodes: Dictionary = {}
+var time_of_day: String = "day" # "day" | "night"
```

```diff
 # res://core/state/EssenceState.gd (persiste em segredo nos 5 atos até o Ato V)
+var act_summaries: Dictionary = {}            # { act_id: { alignment, support, doctrine, key_choices } }
 var philosophical_echoes: Array[String] = []
+var aeon_resistance_score: int = 0
+var false_defeats_triggered: Array[int] = []
+var ephemeral_meetings_seen: Array[String] = [] # Encontros únicos do Ato V
```

---

## 3. `[+ ADICIONAR]` Abstração de Camada de Realidade (`EraConfig.gd` e `MapNodeData.gd`)

```diff
 # res://core/resources/EraConfig.gd
 @export var era_id: int = 1
 @export var ui_theme: Theme
 @export var palette_shader: ShaderMaterial
+@export_enum("PHYSICAL_WAR", "RESOURCE_NETWORK", "VIRTUAL_COGNITIVE")
+var reality_layer: String = "PHYSICAL_WAR"
+@export var hp_label: String = "HP"          # Ato IV: "Sigilo" | Ato V: "Sinal"
+@export var morale_label: String = "Moral"   # Ato IV: "Credibilidade" | Ato V: "Lucidez"
+@export var resource_label: String = "Ouro"  # Ato IV: "Fundos/Dados" | Ato V: "Largura de Banda"
+@export var interlude_style: String = "camp" # "camp" | "clandestine_physical" | "ephemeral_metaphysical"
```

```diff
 # res://core/resources/MapNodeData.gd
+@export var node_id: StringName
+@export var display_name: String
+@export_enum("CITY", "FORTRESS", "PORT", "INFRASTRUCTURE", "NEURAL_NODE")
+var node_type: String = "CITY"
+@export var owner_faction: StringName
+@export var resource_per_tick: int = 10
+@export var local_support: int = 50
+@export var connected_nodes: Array[StringName] = []
```

---

## 4. `[+ ADICIONAR]` Esquema de Classes (`UnitClassData.gd`) e Dupla Vitória (`CombatResolver.gd`)

```diff
 # res://core/resources/UnitClassData.gd
+@export var class_id: StringName
+@export var era_id: int = 1
+@export_enum("VANGUARD", "SHOCK", "RANGED_STEALTH", "ARCANE_TECH", "HEALER_MORAL", "BARD_INFLUENCE", "MYTHIC")
+var archetype: String = "VANGUARD"
+@export var grid_slots: int = 1                # 1 padrão; 2 para colossais (ex.: Tarasque)
+@export var min_alignment: int = 0
+@export var max_alignment: int = 100
+@export var front_action_id: StringName
+@export var back_action_id: StringName
+@export var promotion_good: Resource           # Alto Alinhamento
+@export var promotion_evil: Resource           # Baixo Alinhamento
```

- **Dupla condição de vitória no `CombatResolver.gd`:**
  - `HP = 0`: vitória por aniquilação (linha **Revolucionária**; reduz `alignment` contra inimigos de nível inferior).
  - `Moral = 0`: vitória por rendição/conversão (linha **Pacifista**; preserva vidas, eleva `alignment` e `popular_support` e reduz `doctrine`).

---

## 5. `[~ ATUALIZAR]` Critério de Fechamento do Sprint 1 (Vales de Nanlu, Ato I)

```diff
 # Escopo do Vertical Slice (não iniciar Atos II-V antes de validar)
-1. Protótipo genérico de combate
+1. Mapa mínimo com 3 nós em eras/act_01_tianxu/nodes/: Linhai dos Canais, Aldeia dos Terraços e Posto da Regência.
+2. 4 classes .tres: Bubing, Nubing, Daoshi e Youxia.
+3. 1 dilema moral: Os Celeiros de Linhai (impactando alignment, popular_support, doctrine e resources).
+4. 1 InterludeRoom.tscn em Linhai reagindo ao dilema via Dialogic 2.
+5. Smoke-test via godot-mcp (gl_compatibility + opengl3) provando captura de nó, vitória por HP e vitória por Moral sem SCRIPT ERROR.
```
