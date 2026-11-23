# STATE_LEDGER.md — Livro-Razão Canônico de Estado e Segredos

> **Regra para Agentes de IA (Vibecoding e Roteiro):** Leia este arquivo no início de toda sessão. Nunca confie na memória da conversa para rastrear variáveis de mundo, facções ou segredos. Mantenha a barreira de sigilo: **os Atos I–IV jamais podem mencionar "Aeons", "simulacro" ou "camadas concêntricas" nos diálogos visíveis ao jogador.**

---

## 1. Estado Base Consolidado (Core + Atos I e II)

### 1.1 Variáveis Globais por Ato (`WorldState.gd`)
- `current_act`: `int` (`1..5`)
- `alignment`: `int` (`0..100` — `0..30` Sombrio/Brutal, `31..69` Neutro, `70..100` Honrado/Bem)
- `popular_support`: `int` (`0..100` — equivale ao *Chaos Frame* de *Ogre Battle*)
- `doctrine`: `int` (`-100..+100` — `-100` Pacifista ↔ `+100` Revolucionária)
- `treasury`: `int` (Ouro nos Atos I–II)
- `day_cycle`: `enum { DAY, NIGHT }`

### 1.2 Memória Oculta dos Aeons (`EssenceState.gd` — Invisível ao Jogador até o Ato V)
- `essence_alignment_history`: `Array[int]` (registro do alinhamento final de cada ato)
- `essence_doctrine_history`: `Array[int]` (registro da doutrina Pacifista vs. Revolucionária)
- `aeon_anomalies_discovered`: `Array[String]`
  - Ato I: `"pengming_fixed_stars"` (Observatório dos Nove Céus — estrelas fixas)
  - Ato II: `"montsegur_archon_codex"` (Códice Cátaro — mundo material como prisão)
- `false_defeats_triggered`: `Array[String]` (`"act1_tiandu_eclipse"`, `"act2_montsegur_pyre"`)

### 1.3 Catálogo Canônico — Ato I (Império de Tianxu) & Ato II (Terras d'Oc)
- **Ato I:** 6 províncias (`Nanlu`, `Dongwan`, `Hanmen`, `Beisha`, `Pengming`, `Zhonghe/Tiandu`); facções: Regência do Selo de Ferro, Feudo dos Três Rios, Lótus de Cinza, Liga dos *Youxia*/Moístas, Clãs de Beisha, Círculo *Fangshi*.
- **Ato II:** 6 regiões (`Carcassonne`, `Toulouse`, `Montagne Noire/Albi`, `Pireneus/Montségur`, `Béziers/Narbonne`, `Pântanos de Tarascon`); facções: Barões da Cruzada do Norte, Legado Papal/Inquisição, *Faydits*, *Bons Hommes*, Coroa de Aragão, *Routiers*; chefe mítico: `Tarasque`.

---

## 2. DIFF — Atualizações Introduzidas pelo Ato III (A Frente de Cinza e Aço)

```diff
# ==============================================================================
# DIFF: STATE_LEDGER.md (Base Atos I-II -> Inclusão do Ato III)
# ==============================================================================

 ## 1.1 Variáveis Globais por Ato (WorldState.gd)
   treasury: int               # Ouro (Atos I-II)
+  supply_reserve: int         # [ATO III] Estoque logístico (munição/combustível) gerado por ferrovias e portos
+  intel_decryption_level: int # [ATO III] 0..100 — nível de quebra de cifras na Estação X (revela névoa/ordens)
+  offmap_artillery_charges: int # [ATO III] Cargas de barragem disponíveis via Observadores de Artilharia
+  radio_broadcast_reach: int  # [ATO III] 0..100 — alcance da Rádio Livre (buff de Apoio Popular e deserção inimiga)

 ## 1.2 Memória Oculta dos Aeons (EssenceState.gd)
   aeon_anomalies_discovered:
     - "pengming_fixed_stars"          # Ato I
     - "montsegur_archon_codex"        # Ato II
+    - "station_x_balanced_war_cipher" # [ATO III] Prova matemática de que ordens anônimas equilibram a guerra para nunca terminar

   false_defeats_triggered:
     - "act1_tiandu_eclipse"
     - "act2_montsegur_pyre"
+    - "act3_stahlstadt_classified_armistice" # [ATO III] Armistício de bastidores / clarão final -> jornal censurado

+  act3_dilemma_flags: Dictionary = {
+    "winter_truce_honored": false,        # Trégua de Inverno na Terra de Ninguém
+    "brevilles_civilians_warned": false,  # Segredo da Estação X vs. evacuação civil
+    "eisenwerk_viaduct_spared": false,    # Infiltração cirúrgica vs. demolição total
+    "chemical_depot_sealed": false,       # Sela gás (libera Bruxas da Noite) vs. apreende (Químico de Guerra)
+    "final_radio_truth_aired": false      # Transmissão pacifista de motim vs. golpe militar no QG
+  }

+## 1.4 Catálogo Canônico — Ato III (A Frente de Cinza e Aço)
+  Regiões (6):
+    - "no_mans_land"    (Centro — Trincheira Setor 7, Ponte do Rio Cinza)
+    - "grey_strait"     (Oeste — Porto de Brevilles, Muralha de Concreto)
+    - "maquis_woods"    (Sul — Planalto de Verneuil, Antena Clandestina)
+    - "eisenwerk_hub"   (Leste — Entroncamento Ferroviário, Depósito Químico)
+    - "alpine_pass"     (Norte — Estação X, Aeródromo Oculto)
+    - "stahlstadt_hq"   (Nordeste — Bastião de Aço, Torre de Transmissão)
+
+  Facções (5) + Secreto (1):
+    - "iron_directorate"   [Antagonista Militar]
+    - "censorship_bureau"  [Antagonista Ideológico]
+    - "maquis_saboteurs"   [Aliado Revolucionário]
+    - "field_medics_radio" [Aliado Pacifista]
+    - "station_x_analysts" [Aliado Técnico]
+    - "night_witches_588"  [Unidade Mítica Secreta — requer chemical_depot_sealed == true]
+
+  Regra de Sigilo do Ato III:
+    - PROIBIDO usar termos: "Aeons", "simulação", "matriz", "vida passada", "China", "Carcassonne".
+    - PERMITIDO usar linguagem da época: "mão invisível nas cifras", "guerra desenhada para moer gerações", "burocracia acima dos generais".
```
