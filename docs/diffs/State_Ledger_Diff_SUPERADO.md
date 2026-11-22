# STATE_LEDGER_DIFF.md — Diff Incremental para Atualizar o `STATE_LEDGER.md` Anterior

> **Uso:** Aplicar apenas as alterações abaixo sobre o `STATE_LEDGER.md` anterior (mantendo o arquivo final abaixo de 120 linhas para leitura rápida pelos agentes no início de cada sessão).

---

## 1. `[~ ATUALIZAR]` Estado Atual e Protocolo de Sessão

```diff
 ## 1. Estado Atual do Desenvolvimento
 
-- **Fase Atual:** Sprint 0 (Validação de Ambiente no Mac mini Mid 2011 / OCLP) → Próximo: Sprint 1 (Vertical Slice — Vales de Nanlu, Ato I).
+- **Fase Atual:** Sprint 0 (Validação OpenGL 3 / `godot-mcp` via `AGENT_SETUP_AND_TEST.md`) → Próximo: Sprint 1 (Vertical Slice — Vales de Nanlu, Ato I).
 - **Engine Alvo:** Godot 4.7.2+ (Standard / GDScript), renderizador `gl_compatibility`, wrapper `~/bin/godot-opengl3`.
-- **Sistemas Implementados:** Nenhum código de produção ainda (aguardando conclusão do `AGENT_SETUP_AND_TEST.md`).
-- **Sistemas Pendentes no Sprint 1:** `WorldState.gd`, `EssenceState.gd`, `UnitClassData.gd`, `CombatResolver.gd` (HP + Moral 3×2), `OverworldMap.tscn` (3 nós em Nanlu), `InterludeRoom.tscn`.
+- **Documentos Canônicos Ativos:** `ARCHITECTURE.md` (+ `ARCHITECTURE_DIFF.md`), `AGENT_SETUP_AND_TEST.md`, `atlas-ato1-china-imperial.html`, `atlas-ato2-occitania-carcassonne.html`, `atlas-ato3-grandes-guerras.html`.
+- **Sistemas Pendentes no Sprint 1:** `WorldState.gd`, `EssenceState.gd`, `EraConfig.gd`, `MapNodeData.gd`, `UnitClassData.gd`, `CombatResolver.gd` (HP + Moral 3×2), `OverworldMap.tscn` (3 nós em Nanlu), `InterludeRoom.tscn`.
```

---

## 2. `[~ ATUALIZAR]` Status dos Atos no Cânone Consolidado

```diff
-### Atos III–V (Escopo Definido — Atlas Pendentes)
-- **Ato III:** Era das Grandes Guerras (guerra física de trincheiras, artilharia, *Stoßtruppen*, *Partisans*, *Nachthexen*).
-- **Ato IV:** Era Moderna (mapa de infraestrutura/recursos/mídia + interlúdios físicos clandestinos).
-- **Ato V:** Tecnocracia Cibernética (mapa virtual/cognitivo + interlúdios liminares efêmeros + revelação dos Aeons).
+### Ato III — Era das Grandes Guerras (Atlas Gerado)
+- **Referência:** `atlas-ato3-grandes-guerras.html` (guerra de trincheiras, artilharia, *Stoßtruppen*, *Partisans*, *Nachthexen*, logística e propaganda).
+
+### Atos IV–V (Escopo Definido — Atlas Pendentes)
+- **Ato IV (Era Moderna):** mapa de infraestrutura/recursos/mídia (`RESOURCE_NETWORK`) + interlúdios físicos clandestinos (`clandestine_physical`).
+- **Ato V (Tecnocracia Cibernética):** mapa virtual/cognitivo (`VIRTUAL_COGNITIVE`) + interlúdios liminares efêmeros (`ephemeral_metaphysical`) + revelação dos Aeons.
```

---

## 3. `[~ ATUALIZAR]` Variáveis Oficiais de Estado (Sincronizado com `ARCHITECTURE.md`)

```diff
 ## 4. Variáveis Oficiais de Estado (Não Renomear)
 
+- `WorldState.current_act` (`int`, `1..5`)
 - `WorldState.alignment` (`0..100`)
 - `WorldState.popular_support` (`0..100`)
 - `WorldState.doctrine` (`-100..+100`, negativo = Pacifista, positivo = Revolucionária)
 - `WorldState.resources` (`int`)
+- `WorldState.captured_nodes` (`Dictionary`)
+- `EssenceState.act_summaries` (`Dictionary`)
 - `EssenceState.philosophical_echoes` (`Array[String]`)
 - `EssenceState.aeon_resistance_score` (`int`)
+- `EssenceState.false_defeats_triggered` (`Array[int]`)
```

---

## 4. `[+ ADICIONAR]` Regra de Autoria Offline (Sem LLM em Tempo Real)

```diff
+## 5. Regra de Uso de IA na Narrativa
+- **Proibido LLM em runtime:** todos os diálogos são estáticos no Dialogic 2 / GodotInk.
+- **Uso offline permitido:** gerar rascunhos de vozes distintas a partir de `Lore_Simulacros/` (Obsidian) mantendo este ledger no topo do contexto para não vazar o segredo dos Aeons antes do Ato V.
```
