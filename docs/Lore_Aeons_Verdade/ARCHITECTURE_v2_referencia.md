# ARCHITECTURE.md — Projeto: Os Cinco Simulacros (Godot 4.7.2 · GDScript)

> **Guia Técnico para Agentes de Vibecoding (Cline / Antigravity CLI + `godot-mcp`)**
> Este documento define a arquitetura fixa, os contratos de dados e os limites de escopo do projeto. **Nunca** misture dados de uma época específica dentro da pasta `res://core/`.

---

## 1. Parâmetros Obrigatórios da Engine e Compatibilidade

- **Engine:** Godot 4.7.2 (Standard / **GDScript** — não usar C#/.NET para preservar exportação Web).
- **Renderizador obrigatório:** `gl_compatibility` (OpenGL 3.3 / WebGL 2.0) — garante execução no Mac mini Mid 2011 (OCLP non-Metal via `--rendering-driver opengl3`), Web Browser (itch.io / GitHub Pages) e Mobile (Android/iOS).
- **Resolução lógica base:** `640×360` (escala inteira limpa para `1280×720` e `1920×1080`, `stretch/mode = "canvas_items"`, `stretch/aspect = "keep"`, textura `Nearest` para pixel art 32-bit nítido).
- **Plugins gratuitos:** [Dialogic 2](https://github.com/dialogic-godot/dialogic) para interlúdios e eventos de mapa.

---

## 2. Estrutura de Pastas (Separação Estrita Motor vs. Épocas)

```text
res://
├── core/                          # MOTOR FIXO (nunca contém nomes de cidades ou facções)
│   ├── autoload/
│   │   ├── WorldState.gd          # Estado visível do ato atual (resetado na Derrota Falsa)
│   │   ├── EssenceState.gd        # Estado OCULTO dos Aeons (persiste nos 5 atos)
│   │   └── AudioManager.gd        # Música orquestral adaptativa (AudioStreamSynchronized)
│   ├── resources/
│   │   ├── EraConfig.gd           # Resource (.tres) que define a "pele" e regras extras do ato
│   │   ├── UnitClassData.gd       # Resource (.tres) de classe (6 arquétipos + Mítico)
│   │   ├── UnitInstance.gd        # Instância de soldado (HP, XP, Alignment, ClassData)
│   │   ├── SquadData.gd           # Grade 3x2 (3 frente, 3 trás) + líder + moral + fadiga
│   │   └── MapNodeData.gd         # Nó genérico (Cidade física, Data Center ou Nó Virtual)
│   ├── overworld/
│   │   ├── OverworldMap.tscn      # Mapa RTS com pausa tática, captura de nós e patrulhas
│   │   ├── MapNode.gd             # Interação de captura/libertação/dilema
│   │   └── SquadToken.gd          # Movimentação via NavigationRegion2D + custo de terreno
│   ├── combat/
│   │   ├── BattleArena.tscn       # Cena isolada de combate 3x2 (recebe 2 SquadData)
│   │   └── CombatResolver.gd      # Turnos automáticos: vitória por HP OU por Moral (Pacifista)
│   └── interlude/
│       └── InterludeRoom.tscn     # Cena 2D atmosférica (paralaxe + PointLight2D + Dialogic 2)
│
├── eras/                          # CONTEÚDO ISOLADO POR SIMULACRO
│   ├── act_01_tianxu/             # Ato I: China Imperial (FOCO DO VERTICAL SLICE)
│   │   ├── EraConfig_Act01.tres
│   │   ├── classes/               # bubing.tres, youxia.tres, fangshi.tres, daoshi.tres...
│   │   ├── nodes/                 # linhai_canais.tres, aldeia_terracos.tres...
│   │   ├── maps/                  # nanlu_vertical_slice.tscn
│   │   └── dialogues/             # Timelines do Dialogic 2 (sem spoiler dos Aeons!)
│   ├── act_02_occitania/          # Ato II: Carcassonne & Cátaros
│   ├── act_03_great_wars/         # Ato III: Grandes Guerras
│   ├── act_04_modern/             # Ato IV: Guerra de Recursos & Interlúdios Físicos
│   └── act_05_technocracy/        # Ato V: Guerra Virtual & Interlúdios Metafísicos
│
└── docs/
    └── STATE_LEDGER.md            # Livro-razão curto mantido atualizado para sessões de IA
```

---

## 3. Contratos dos Autoloads Críticos

### 3.1 `WorldState.gd` (Estado Visível do Ato Atual)
Reiniciado visualmente a cada transição de “Derrota Falsa” entre atos:
- `current_act: int` (`1` a `5`)
- `gold_or_resource: int` (Ouro nos Atos I–II, Suprimentos no Ato III, Capital/Dados no Ato IV, Banda/Energia no Ato V)
- `popular_support: int` (`0` a `100` — equivalente ao *Chaos Frame* de *Ogre Battle*)
- `doctrine: int` (`-100` Pacifista a `+100` Revolucionária)
- `captured_nodes: Dictionary` (`node_id -> faction_id`)
- `active_squads: Array[SquadData]`
- **Sinais obrigatórios:** `popular_support_changed(new_val)`, `doctrine_changed(new_val)`, `node_captured(node_id, by_faction)`.

### 3.2 `EssenceState.gd` (Memória Oculta dos Aeons)
**Nunca exibido na UI nos Atos I–IV.** Persiste no arquivo de save criptografado/separado durante toda a campanha:
- `act_records: Dictionary` (`act_id -> { final_alignment, final_support, final_doctrine, key_dilemmas: Array[String] }`)
- `philosophical_echoes: Array[String]` (ex.: `"pengming_star_map_saved"`, `"montsegur_manuscript_escaped"`, `"krovna_radio_pulse_logged"`)
- `aeon_alert_level: int` (aumenta quando o jogador demonstra autonomia extrema, seja pacifista ou revolucionária).

---

## 4. Regras de Ouro do Combate 3×2 (`CombatResolver.gd`)

1. **Grade 3×2:** cada `SquadData` possui `front_row: Array[UnitInstance]` (3 slots) e `back_row: Array[UnitInstance]` (3 slots).
2. **Ação por fileira:** toda `UnitClassData` define `front_action` e `back_action` (ex.: *Youxia* ataca corpo a corpo na frente e protege/inspira atrás; *Fangshi* lança área atrás e sofre dano alto se ficar na frente).
3. **Dupla condição de vitória (Doutrina Pacifista vs. Revolucionária):**
   - **Aniquilação (HP = 0):** derrota padrão; tende a mover `doctrine` para o lado **Revolucionário** (e reduz `alignment` se o inimigo for de nível muito inferior).
   - **Ruptura de Moral (Moral = 0):** causada por bardos, *Daoshi*, *Parfaits*, médicos e táticas defensivas; o esquadrão inimigo **se rende ou recua sem mortes**, movendo `doctrine` para o lado **Pacifista** e elevando `popular_support`.
4. **Abstração de Época:** a UI de combate lê os rótulos do `EraConfig.tres` ativo:
   - Atos I–III: `HP / Moral / Ouro`
   - Ato IV: `Integridade / Credibilidade / Recursos`
   - Ato V: `Sinal / Lucidez / Energia`

---

## 5. Especificação do Vertical Slice (Fase 1 — Vales de Nanlu, Ato I)

**Escopo fechado para a primeira entrega jogável (não adicionar nada fora desta lista):**
1. **1 Mapa (`nanlu_vertical_slice.tscn`):** 3 nós conectáveis — *Aldeia dos Terraços* (base aliada), *Celeiro de Linhai* (neutro/dilema moral) e *Posto da Regência* (base inimiga).
2. **4 Classes jogáveis (`.tres`):** `bubing.tres` (Soldado base), `youxia.tres` (Vanguarda Honrada), `nubing.tres` (Besteiro) e `daoshi.tres` (Suporte/Cura Pacifista).
3. **2 Esquadrões no mapa:** 1 aliado (controlável por clique com pausa na barra de espaço) e 1 patrulha inimiga da Regência.
4. **1 Combate 3×2 funcional:** dispara quando os tokens colidem, executa 1 rodada automática com opção de ordem tática (*Focar Líder* / *Quebrar Moral*) e retorna ao mapa atualizando HP, Moral e Alinhamento.
5. **1 Interlúdio de Presença (`InterludeRoom.tscn`):** dispara ao conquistar o *Celeiro de Linhai*, abrindo o dilema moral (distribuir arroz aos camponeses vs. confiscar para o exército) e atualizando `WorldState` + `EssenceState`.

---

## 6. Protocolo Anti-Alucinação para Sessões de Vibecoding

1. **Commits curtos:** fazer commit no Git após cada sub-tarefa testada com sucesso via `godot-mcp`.
2. **Scripts enxutos:** manter cada arquivo `.gd` abaixo de **250 linhas** com responsabilidade única.
3. **Validação real:** após editar qualquer cena ou script, o agente deve rodar o projeto via `godot-mcp` (usando o wrapper `godot-opengl3`), inspecionar `get_debug_output` e confirmar ausência de `SCRIPT ERROR` antes de declarar concluído.
4. **Segredo narrativo:** ao gerar textos/diálogos para os Atos I–IV, o agente deve ler **apenas** a pasta `Lore_Simulacros/` — nunca mencionar "Aeons" ou "simulação" nos diálogos iniciais.
