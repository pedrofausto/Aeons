# ARCHITECTURE.md — Arquitetura Técnica em Godot 4 (Os Cinco Simulacros)

> **Alvo Técnico:** [Godot 4.7.2](https://godotengine.org/download/archive/) · **GDScript** · Renderizador **`gl_compatibility`** (OpenGL 3.3 / WebGL 2.0 — compatível com Mac mini 2011 OCLP, Desktop, Mobile e Web Browser).

---

## 1. Arquitetura Base Consolidada (Núcleo Fixo + Perfis de Era)

### 1.1 Estrutura de Pastas (`res://`)
```text
res://
├── core/
│   ├── autoload/
│   │   ├── WorldState.gd        # Estado visível do ato atual (alinhamento, apoio popular, doutrina)
│   │   ├── EssenceState.gd      # Memória oculta persistente dos Aeons (salva entre atos)
│   │   └── EraManager.gd        # Carrega EraConfig.tres, troca Theme de UI, shaders e áudio
│   ├── resources/
│   │   ├── EraConfig.gd         # Resource base de época
│   │   ├── UnitClassData.gd     # Arquétipos (Vanguard, Shock, Stealth, ArcaneTech, HealerMoral, Bard, Mythic)
│   │   ├── SquadData.gd         # Grade 3x2 (3 frente, 3 trás), líder, fadiga e moral
│   │   └── MapNodeData.gd       # Abstração de nó (Cidade física I-III | Infraestrutura IV | Servidor V)
│   ├── overworld/               # Mapa RTS com pausa, NavigationRegion2D, captura de nós e patrulhas
│   ├── combat/                  # Arena isolada 3x2 (HP + Moral; vitória por aniquilação ou rendição)
│   └── interlude/               # InterludeRoom.tscn (paralaxe 2D + PointLight2D + Dialogic 2)
└── eras/
    ├── act_01_tianxu/           # EraConfig.tres, sprites, normal maps (Laigter), cidades, diálogos
    ├── act_02_occitania/        # EraConfig.tres, cercos/água, Faydits, Parfaits, Tarasque
    └── ...
```

### 1.2 Contrato das 3 Camadas Fixas
1. **Camada Estratégica (`Overworld`):** grafo de `MapNode` conectado por rotas ponderadas por terreno; gera recursos por ciclo e dispara combates ao colidir esquadrões.
2. **Camada Tática (`CombatResolver`):** recebe dois `SquadData` (aliado e inimigo), executa ações conforme posição na grade 3×2 (Frente vs. Trás), atualiza `HP` e `Moral`, e emite sinal `battle_finished(result_dict)`.
3. **Camada de Presença (`InterludeRoom`):** cena 2D leve com diálogo condicional via **Dialogic 2** lendo `WorldState.gd`.

---

## 2. DIFF — Extensões Arquiteturais Introduzidas pelo Ato III (Guerra Industrial)

```diff
# ==============================================================================
# DIFF: ARCHITECTURE.md (Base Atos I-II -> Extensões Modulares do Ato III)
# ==============================================================================

 res://
 ├── core/
 │   ├── resources/
 │   │   ├── EraConfig.gd
+│   │   │   + @export var uses_supply_lines: bool = false        # true a partir do Ato III
+│   │   │   + @export var uses_offmap_support: bool = false      # artilharia (III), drones/hack (IV-V)
+│   │   │   + @export var uses_fog_of_intel: bool = false        # rádio/criptografia (III) e vigilância (IV-V)
 │   │   ├── MapNodeData.gd
+│   │   │   + @export var is_supply_source: bool = false         # Portos (Brevilles) e Ferrovias (Eisenwerk)
+│   │   │   + @export var connected_rail_ids: PackedStringArray  # Grafo ferroviário; cortar um nó corta o fluxo
+│   │   │   + @export var has_artillery_battery: bool = false    # Alcance de suporte em nós adjacentes
+│   │   │   + @export var artillery_radius_px: float = 0.0
 │   │   └── SquadData.gd
+│   │       + @export var supply_level: int = 100                # Cai fora de linha de suprimento; 0 reduz dano e moral
+│   │       + @export var is_stealth_air: bool = false           # Permite voar sobre trincheiras (Bruxas da Noite)
 │   ├── overworld/
+│   │   ├── SupplyGraphSystem.gd     # [NOVO] BFS a partir de nós com is_supply_source para marcar nós abastecidos
+│   │   └── OffmapStrikeManager.gd   # [NOVO] Dispara aviso visual + barragem de artilharia/rádio no mapa
 │   ├── combat/
 │   │   └── CombatResolver.gd
+│   │       + Suporte a "Suppression" (debuff de iniciativa/ação de metralhadoras e artilharia)
+│   │       + Gancho pre_round_hook() para ataques fora de tela (artilharia III / ataques cibernéticos IV-V)
 │   └── shaders/
+│       ├── rain_overlay_2d.gdshader         # [NOVO] Chuva leve compatível com OpenGL 3.3 (gl_compatibility)
+│       └── searchlight_cone.gdshader        # [NOVO] Feixe de holofote 2D de baixo custo (sem Vulkan/Forward+)
 └── eras/
     ├── act_01_tianxu/
     ├── act_02_occitania/
+    └── act_03_ash_and_steel/               # [NOVO] Módulo isolado do Ato III
+        ├── EraConfig_Act03.tres            # uses_supply_lines=true, uses_offmap_support=true, uses_fog_of_intel=true
+        ├── ui/Theme_Act03_Industrial.tres  # Interface estilo mapa militar/telégrafo (troca total de pele)
+        ├── classes/                        # Fuzileiro, Stoßtruppen, Sapador, Criptógrafo, Médico, Bruxa da Noite
+        ├── maps/Theater_Continental.tscn   # 6 setores + grafo ferroviário + bunkers costeiros
+        └── audio/                          # Camadas sincronizadas (BBC SO Discover / MuseSounds) + ruído de rádio
```

### Notas de Engenharia para o Agente de Vibecoding (Reaproveitamento nos Atos IV e V)
- **`SupplyGraphSystem.gd` não é descartável:** no **Ato III** ele rastreia **ferrovias e munição**; no **Ato IV** o mesmo algoritmo BFS rastreia **energia e largura de banda**; no **Ato V** rastreia **conexões de consenso neural na Matriz**.
- **`OffmapStrikeManager.gd` não é descartável:** no **Ato III** dispara **barragens de artilharia e transmissões da Rádio Livre**; no **Ato IV** dispara **enxames de drones e vazamentos na mídia**; no **Ato V** dispara **sobrecargas de protocolo e purgas neurais**.
- **Orçamento de Performance (Mac mini 2011 / WebGL 2.0):** manter `rain_overlay_2d.gdshader` e `searchlight_cone.gdshader` em fragment shaders simples (`canvas_item`) sem *screen-reading* pesado, preservando 60 FPS no modo `gl_compatibility`.
