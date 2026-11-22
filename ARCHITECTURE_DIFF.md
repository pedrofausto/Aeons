# ARCHITECTURE_DIFF.md — Expansão Incremental da Arquitetura Base (Os Cinco Simulacros)

> **Escopo deste diff:** Expande a arquitetura base definida em `arquitetura-rpg-5-simulacros.html` incorporando apenas as adições e refinamentos aprovados depois dela (Doutrina Pacifista/Revolucionária, Matriz de Classes, Guerra Virtual nos Atos IV–V, Interlúdios de Presença, Patrulhas Aleatórias, Compatibilidade Mac mini 2011/OCLP e Disciplina de `STATE_LEDGER.md`). Tudo o que já estava definido no núcleo base permanece válido.

---

## 1. `[~ EXPANDIR]` Estado Global (`WorldState.gd` e `EssenceState.gd`)

Adicionar o eixo de **Doutrina** ao lado de Alinhamento e Apoio Popular, mantendo separação estrita entre o estado visível do ato atual e a memória secreta dos Aeons.

```diff
 # res://core/WorldState.gd (reiniciado a cada ato na "Derrota Falsa")
 var act_id: int = 1
 var alignment: int = 50         # 0 (Mal/Brutal) .. 100 (Bem/Honra)
 var popular_support: int = 50   # 0 .. 100 (Chaos Frame local)
+var doctrine: int = 0           # -100 (Pacifista) .. +100 (Revolucionária)
+var time_of_day: String = "day" # "day" | "night" (afeta patrulhas e encontros)
+var completed_interludes: Array[String] = []
```

```diff
 # res://core/EssenceState.gd (persiste em segredo nos 5 atos até o clímax do Ato V)
 var philosophical_echoes: Dictionary = {}
 var aeon_resistance_flags: Array[String] = []
+var doctrine_history: Dictionary = {}   # { 1: -40, 2: +65, ... }
+var alignment_history: Dictionary = {}  # { 1: 82, 2: 74, ... }
+var ephemeral_meetings_seen: Array[String] = [] # Encontros únicos do Ato V
```

---

## 2. `[~ EXPANDIR]` Abstração de Camada de Realidade (`EraConfig.tres`)

Permitir que o mesmo grafo de mapa (`MapNode`) e o mesmo combate 3×2 funcionem sem reescrita em guerra física (Atos I–III), guerra informacional/recursos (Ato IV) e guerra virtual/cognitiva (Ato V).

```diff
 # res://core/resources/EraConfig.gd (Resource)
 @export var era_id: int
 @export var ui_theme: Theme
 @export var palette_shader: ShaderMaterial
+@export_enum("PHYSICAL_WAR", "RESOURCE_NETWORK", "VIRTUAL_COGNITIVE")
+var reality_layer: String = "PHYSICAL_WAR"
+@export var hp_label: String = "HP"            # Ato IV: "Sigilo" | Ato V: "Sinal"
+@export var morale_label: String = "Moral"     # Ato IV: "Credibilidade" | Ato V: "Lucidez"
+@export var resource_label: String = "Ouro"    # Ato IV: "Fundos/Dados" | Ato V: "Largura de Banda"
+@export var interlude_style: String = "camp"   # "camp" | "clandestine_physical" | "ephemeral_metaphysical"
```

---

## 3. `[+ ADICIONAR]` Esquema Unificado de Classes (`UnitClassData.tres`)

Substituir definições soltas de unidades por 1 recurso padronizado que cobre os **6 arquétipos + Mítico** nas 5 épocas, incluindo unidades colossais (como a *Tarasque* no Ato II).

```gdscript
# res://core/resources/UnitClassData.gd
class_name UnitClassData
extends Resource

@export var class_id: StringName
@export var era_id: int = 1
@export_enum("VANGUARD", "SHOCK", "RANGED_STEALTH", "ARCANE_TECH", "HEALER_MORAL", "BARD_INFLUENCE", "MYTHIC")
var archetype: String = "VANGUARD"

@export var grid_slots: int = 1                # 1 padrão; 2 para unidades colossais (ex.: Tarasque)
@export var min_alignment: int = 0
@export var max_alignment: int = 100
@export var preferred_doctrine: String = "any" # "pacifist" | "revolutionary" | "any"

@export var front_action_id: StringName        # Golpe/ação quando posicionado na linha frontal (3x2)
@export var back_action_id: StringName         # Habilidade/suporte quando posicionado na retaguarda (3x2)
@export var promotion_good: Resource           # Próxima UnitClassData (Alto Alinhamento)
@export var promotion_evil: Resource           # Próxima UnitClassData (Baixo Alinhamento)
```

### `[~ EXPANDIR]` Condição Dupla de Vitória no `CombatResolver.gd`
- **Vitória por Aniquilação (HP = 0):** mais rápida na linha **Revolucionária**; pode reduzir `alignment` se o esquadrão inimigo tiver nível muito inferior (regra clássica de *Ogre Battle*).
- **Vitória por Quebra de Moral (Moral = 0):** foco da linha **Pacifista** (clérigos, *Parfaits*, bardos, trovadores, médicos, transmissores); inimigos se rendem sem massacre, elevando `popular_support` e permitindo recrutamento ou liberação.

---

## 4. `[+ ADICIONAR]` 3ª Camada Fixa — Interlúdios de Presença (`InterludeRoom.tscn`)

Adicionar a camada narrativa íntima entre conquistas no mapa, desacoplada da guerra tática:

```text
res://core/interlude/
├── InterludeRoom.tscn        # Cena-base 2D (paralaxe + 2–3 NPCs + PointLight2D + gatilho Dialogic 2)
├── InterludeManager.gd       # Lê WorldState + EssenceState para escolher falas e encontros elegíveis
└── shaders/
    └── ephemeral_fade.gdshader # Usado no Ato V (dissolução/desfoque sutil + áudio reduzido a cordas)
```

- **Atos I–III:** locais físicos de campanha (salões de chá em Nanlu, cisternas de Carcassonne, abrigos de trincheira).
- **Ato IV (Era Moderna):** espaços físicos reais e clandestinos (cafeteria na chuva, esconderijo urbano) contrastando com o mapa virtual de recursos.
- **Ato V (Tecnocracia):** espaços liminares efêmeros; flags em `ephemeral_meetings_seen` garantem encontros únicos que se desfazem ao sair.

---

## 5. `[+ ADICIONAR]` Mapa Vivo e Inimigos Aleatórios (`RoamingSquadSpawner.gd`)

Para evitar mapas vazios nos Atos I–III (e patrulhas de vigilância/firewalls móveis nos Atos IV–V):

```text
res://core/overworld/
├── RoamingSquadSpawner.gd    # Gera patrulhas por região, time_of_day e nível do jogador
└── EncounterTable.gd         # Resource por província (comum, noturno, escolta moral, chefe secreto)
```

- **Tags de encontro:** `bandit_loot` (ouro), `moral_escort` (libertar civis/prisioneiros sobe Alinhamento e Apoio Popular), `low_level_trap` (desertores fracos — testar disciplina moral), `natural_wildlife` (treino neutro sem alterar Alinhamento) e `mythic_boss` (ex.: *Tarasque* nos pântanos de Tarascon ou *Xian* em Pengming).

---

## 6. `[! RESTRIÇÃO]` Hardware, Exportação e Fluxo de Vibecoding

Consolidar as travas técnicas descobertas para o **Mac mini Mid 2011 (OCLP non-Metal)** e para a qualidade do código gerado por IA:

- **Linguagem e Renderizador obrigatórios:** 100% **GDScript** + renderizador **`gl_compatibility`** (OpenGL 3.3 / WebGL 2.0) — garante execução no Mac mini 2011 (`~/bin/godot-opengl3`), exportação **Web/HTML5 single-threaded** e **Mobile (Android/iOS)**.
- **Livro-razão explícito (`STATE_LEDGER.md`):** manter na raiz do repositório um arquivo curto (< 120 linhas) atualizado após cada tarefa do agente, listando: variáveis ativas de `WorldState`/`EssenceState`, cenas existentes, nomes canônicos do ato atual e a regra de **proibição de vazar o segredo dos Aeons** nos Atos I–IV.
- **Autonomia de roteiro offline:** usar o LLM apenas na fase de autoria (lendo `Lore_Simulacros/` do Obsidian) para gerar vozes distintas e gravar diálogos estáticos no **Dialogic 2** — jamais embutir chamadas de LLM em tempo real dentro do jogo.
