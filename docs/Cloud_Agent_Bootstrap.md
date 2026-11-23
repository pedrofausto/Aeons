# Runbook de Agente Autônomo na Nuvem — Bootstrap, Teste e Upload no GitHub

> **Instrução para o Agente de IA Autônomo (GitHub Codespaces / Sandbox Linux na Nuvem):**
> Execute todas as fases abaixo diretamente no ambiente Linux em nuvem — **sem exigir instalação local no PC do usuário**. Ao final, valide o projeto com Godot 4.7.2 *headless*, configure o CI no GitHub Actions e faça `git push` para o repositório remoto configurado.

---

## Pré-requisito de Execução (100% Gratuito na Nuvem)

- **Ambiente recomendado:** [GitHub Codespaces](https://github.com/features/codespaces) (plano pessoal gratuito oferece 120 core-hours/mês = 60h em máquina de 2 núcleos e 15 GB-mês de armazenamento) ou qualquer agente autônomo em nuvem conectado ao repositório GitHub do projeto.
- **Importante após o `git push`:** se estiver usando Codespaces gratuito, lembre o usuário de **deletar** o Codespace após o upload (Codespaces apenas "parados" continuam consumindo a cota mensal de 15 GB).

---

## Fase 1 — Instalar Godot 4.7.2 (Linux x86_64) em `/tmp` (Sem Commitar Binários)

```bash
set -euo pipefail

mkdir -p /tmp/godot-cli
cd /tmp/godot-cli

if [ ! -x "/tmp/godot-cli/godot" ]; then
  curl -fL "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip" -o godot.zip
  unzip -o godot.zip
  mv Godot_v4.7.2-stable_linux.x86_64 /tmp/godot-cli/godot
  chmod +x /tmp/godot-cli/godot
  rm -f godot.zip
fi

/tmp/godot-cli/godot --version
```

- **Critério de aprovação:** imprime `4.7.2.stable.official...`.

---

## Fase 2 — Criar Estrutura do Repositório, Arquitetura e Livro-Razão de Estado

Volte para a raiz do repositório (`cd "$GITHUB_WORKSPACE"` ou `cd "$(git rev-parse --show-toplevel)"`) e crie a estrutura completa abaixo:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

mkdir -p \
  game/core/resources \
  game/core/combat \
  game/core/overworld \
  game/scenes \
  game/eras/act_01_tianxu/classes \
  game/eras/act_01_tianxu/nodes \
  docs/Lore_Simulacros/Ato_01_Tianxu \
  docs/Lore_Aeons_Verdade \
  .github/workflows
```

### 2.1 `.gitignore`
```bash
cat << 'EOF' > .gitignore
# Godot 4
game/.godot/
game/.import/
*.translation
export_presets.cfg
builds/

# OS / Temp
.DS_Store
*.log
/tmp/
EOF
```

### 2.2 `ARCHITECTURE.md` e `STATE_LEDGER.md`
```bash
cat << 'EOF' > ARCHITECTURE.md
# Arquitetura — Os Cinco Simulacros (Godot 4.7.2 / GDScript)

## Regras Invioláveis
1. **Engine & Renderizador:** Godot 4.7.2 (GDScript puro, sem C#) usando `gl_compatibility` para suportar Desktop (inclusive Macs antigos via OpenGL 3.3), Web (HTML5/WebGL 2.0) e Mobile.
2. **Três Camadas Fixas em Todos os Atos:**
   - **Mapa de Conquista (`MapNodeData`):** Cidades/Fortalezas (Atos I–III) -> Infraestrutura/Recursos (Ato IV) -> Nodos da Matriz (Ato V).
   - **Combate 3x2 (`CombatResolver`):** Grade frontal/traseira com vitória por HP ou por Moral.
   - **Interlúdios de Presença:** Cenas 2D curtas (Dialogic 2) — físicas nos Atos I–IV e efêmeras/metafísicas no Ato V.
3. **Dois Níveis de Memória:**
   - `WorldState.gd`: Estado visível do ato atual (`alignment`, `popular_support`, `doctrine`, `gold`).
   - `EssenceState.gd`: Estado oculto que persiste através das 5 "derrotas falsas" até o clímax do Ato V.
4. **Segredo Narrativo no Vibecoding:** Ao gerar diálogos dos Atos I–IV, leia APENAS `docs/Lore_Simulacros/`. Nunca leia `docs/Lore_Aeons_Verdade/` durante tarefas dos atos iniciais.
EOF

cat << 'EOF' > STATE_LEDGER.md
# Livro-Razão Explícito de Estado (Atualizar a cada milestone)

- **Ato em desenvolvimento:** Ato I — Império de Tianxu (Vales de Nanlu)
- **Versão Godot:** 4.7.2-stable (GL Compatibility)
- **Autoloads ativos:** `WorldState`, `EssenceState`
- **Eixos ativos:**
  - `alignment` (0..100: Brutalidade <-> Honra)
  - `popular_support` (0..100: Apoio Popular / Mandato)
  - `doctrine` (-100..+100: Pacifista <-> Revolucionária)
- **Segredo protegido (NÃO citar em diálogos dos Atos I–IV):** Aeons, simulações concêntricas e identidade única dos 5 protagonistas.
EOF
```

---

## Fase 3 — Gerar Projeto Godot 4 (`gl_compatibility`) e Scripts-Núcleo

### 3.1 `game/project.godot`
```bash
cat << 'EOF' > game/project.godot
config_version=5

[application]
config/name="OsCincoSimulacros"
run/main_scene="res://scenes/smoke_test.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[autoload]
WorldState="*res://core/WorldState.gd"
EssenceState="*res://core/EssenceState.gd"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
EOF
```

### 3.2 `game/core/WorldState.gd` e `game/core/EssenceState.gd`
```bash
cat << 'EOF' > game/core/WorldState.gd
extends Node

signal state_changed(metric: String, new_value: int)

var current_act: int = 1
var alignment: int = 50        # 0 (Mal/Brutal) .. 100 (Bem/Honrado)
var popular_support: int = 50  # 0 .. 100 (Chaos Frame / Apoio Popular)
var doctrine: int = 0          # -100 (Pacifista) .. +100 (Revolucionária)
var gold: int = 500
var controlled_nodes: Dictionary = {}

func modify_alignment(delta: int) -> void:
	alignment = clampi(alignment + delta, 0, 100)
	state_changed.emit("alignment", alignment)

func modify_popular_support(delta: int) -> void:
	popular_support = clampi(popular_support + delta, 0, 100)
	state_changed.emit("popular_support", popular_support)

func modify_doctrine(delta: int) -> void:
	doctrine = clampi(doctrine + delta, -100, 100)
	state_changed.emit("doctrine", doctrine)

func capture_node(node_id: String, method: String) -> void:
	controlled_nodes[node_id] = method
	match method:
		"liberate_pacifist":
			modify_alignment(8)
			modify_popular_support(10)
			modify_doctrine(-10)
		"liberate_revolutionary":
			modify_alignment(4)
			modify_popular_support(6)
			modify_doctrine(12)
		"sack_brutal":
			modify_alignment(-15)
			modify_popular_support(-15)
			modify_doctrine(10)
			gold += 250

func reset_for_new_act(next_act: int) -> void:
	current_act = next_act
	alignment = 50
	popular_support = 50
	doctrine = 0
	gold = 500
	controlled_nodes.clear()
EOF

cat << 'EOF' > game/core/EssenceState.gd
extends Node

# Memória oculta dos Aeons — persiste através das "derrotas falsas" entre os 5 atos.
var act_summaries: Dictionary = {}
var philosophical_echoes: Array[String] = []
var aeon_resistance_score: int = 0

func record_act_completion(act_number: int, final_alignment: int, final_support: int, final_doctrine: int) -> void:
	act_summaries[act_number] = {
		"alignment": final_alignment,
		"popular_support": final_support,
		"doctrine": final_doctrine
	}
	aeon_resistance_score += 1

func add_echo(flag_name: String) -> void:
	if not philosophical_echoes.has(flag_name):
		philosophical_echoes.append(flag_name)
EOF
```

### 3.3 Recursos Modulares (`UnitClassData.gd` e `MapNodeData.gd`)
```bash
cat << 'EOF' > game/core/resources/UnitClassData.gd
class_name UnitClassData
extends Resource

enum Archetype { VANGUARD, SHOCK, RANGED_STEALTH, ARCANE_TECH, HEALER_MORAL, BARD_INFLUENCE, MYTHIC }

@export var class_id: String = ""
@export var display_name: String = ""
@export var era_id: int = 1
@export var archetype: Archetype = Archetype.VANGUARD
@export var min_alignment: int = 0
@export var max_alignment: int = 100
@export var front_action: String = "strike"
@export var back_action: String = "guard"
@export var promotes_good_id: String = ""
@export var promotes_evil_id: String = ""

func can_promote_with_alignment(unit_alignment: int) -> bool:
	return unit_alignment >= min_alignment and unit_alignment <= max_alignment
EOF

cat << 'EOF' > game/core/resources/MapNodeData.gd
class_name MapNodeData
extends Resource

enum LayerType { PHYSICAL_SETTLEMENT, INFRASTRUCTURE_RESOURCE, VIRTUAL_MATRIX_NODE }

@export var node_id: String = ""
@export var display_name: String = ""
@export var era_id: int = 1
@export var layer_type: LayerType = LayerType.PHYSICAL_SETTLEMENT
@export var daily_resource_yield: int = 100
@export var terrain_tag: String = "plains"
EOF
```

### 3.4 Smoke-Test Automatizado (`game/scenes/smoke_test.gd` e `.tscn`)
```bash
cat << 'EOF' > game/scenes/smoke_test.gd
extends Node

func _ready() -> void:
	# 1. Valida Autoloads e captura de cidade no Ato I (Vales de Nanlu)
	WorldState.capture_node("linhai_dos_canais", "liberate_pacifist")
	assert(WorldState.alignment == 58, "Alignment esperado: 58")
	assert(WorldState.popular_support == 60, "Popular support esperado: 60")
	assert(WorldState.doctrine == -10, "Doctrine esperada: -10")

	# 2. Valida persistência oculta dos Aeons entre atos
	EssenceState.add_echo("pengming_fixed_sky")
	EssenceState.record_act_completion(1, WorldState.alignment, WorldState.popular_support, WorldState.doctrine)
	WorldState.reset_for_new_act(2)
	assert(WorldState.current_act == 2 and EssenceState.aeon_resistance_score == 1, "Falha na persistência de EssenceState")

	# 3. Valida recursos modulares de classe e nó de mapa
	var youxia := UnitClassData.new()
	youxia.class_id = "act1_youxia"
	youxia.display_name = "Youxia"
	youxia.min_alignment = 65
	youxia.max_alignment = 100
	assert(youxia.can_promote_with_alignment(75), "Promoção de Youxia falhou")

	var node := MapNodeData.new()
	node.node_id = "linhai_dos_canais"
	node.display_name = "Linhai dos Canais"
	node.layer_type = MapNodeData.LayerType.PHYSICAL_SETTLEMENT
	assert(node.daily_resource_yield == 100, "MapNodeData falhou")

	print("SMOKE_TEST_PASS|act1_core=OK|essence_persistence=OK|resources=OK")
	get_tree().quit(0)
EOF

cat << 'EOF' > game/scenes/smoke_test.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/smoke_test.gd" id="1_smoke"]

[node name="SmokeTest" type="Node"]
script = ExtResource("1_smoke")
EOF
```

---

## Fase 4 — Criar GitHub Actions CI Automático (`.github/workflows/godot-ci.yml`)

Assim, toda alteração futura feita na nuvem (ou no seu Mac mini) será testada automaticamente pelo GitHub:

```bash
cat << 'EOF' > .github/workflows/godot-ci.yml
name: Godot 4.7.2 Headless Smoke Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  smoke-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Instalar Godot 4.7.2 (Linux x86_64)
        run: |
          curl -fL "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip" -o /tmp/godot.zip
          unzip -o /tmp/godot.zip -d /tmp/godot
          chmod +x /tmp/godot/Godot_v4.7.2-stable_linux.x86_64

      - name: Importar projeto e executar Smoke Test
        run: |
          GODOT="/tmp/godot/Godot_v4.7.2-stable_linux.x86_64"
          "$GODOT" --headless --path game --import --quit
          "$GODOT" --headless --path game res://scenes/smoke_test.tscn 2>&1 | tee /tmp/smoke.log
          grep -q "SMOKE_TEST_PASS" /tmp/smoke.log
          ! grep -q "SCRIPT ERROR" /tmp/smoke.log
EOF
```

---

## Fase 5 — Validar na Nuvem e Fazer Upload (`git push`)

```bash
/tmp/godot-cli/godot --headless --path game --import --quit
/tmp/godot-cli/godot --headless --path game res://scenes/smoke_test.tscn 2>&1 | tee /tmp/cloud_smoke.log

grep -q "SMOKE_TEST_PASS" /tmp/cloud_smoke.log
! grep -q "SCRIPT ERROR" /tmp/cloud_smoke.log

git add .
git commit -m "feat: bootstrap Godot 4.7.2 core (WorldState, EssenceState, resources, CI)"
git push -u origin main
```

### Relatório obrigatório do agente ao usuário
```text
STATUS GERAL: [PASS | FAIL]
- Godot 4.7.2 (Cloud Linux Headless): [PASS | FAIL]
- Smoke-Test Core (WorldState + EssenceState + Resources): [PASS | FAIL]
- GitHub Actions CI (.github/workflows/godot-ci.yml): [CRIADO | ERRO]
- Upload no Repositório (git push): [PASS | FAIL] (<hash do commit>)
```
