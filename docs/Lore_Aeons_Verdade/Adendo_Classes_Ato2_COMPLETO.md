# Adendo de Fichas de Classes — Ato II (Terras d'Oc · Carcassonne e Cátaros)

> **Uso deste documento:** Referência de design e especificação técnica pronta para o cofre do [Obsidian](https://obsidian.md/) (`Lore_Simulacros/Ato_02_Occitania/`) e para agentes de *vibecoding* gerarem recursos `UnitClassData.tres` diretamente no [Godot 4](https://godotengine.org/). Todas as classes seguem a grade tática **3×2** inspirada em [Ogre Battle: March of the Black Queen](https://ogrebattlesaga.fandom.com/wiki/Alignment), integrando os três eixos do projeto: **Alinhamento (0–100)**, **Apoio Popular** e **Doutrina (Pacifista ↔ Revolucionária)**.

---

## 1. Contrato de Dados (`UnitClassData.gd` / `.tres`)

Cada ficha abaixo mapeia 1-para-1 para o recurso base do motor no Godot 4:

- `class_id`: identificador único (`act2_faydit`, `act2_parfait`, etc.)
- `archetype`: `VANGUARD` | `SHOCK` | `RANGED_STEALTH` | `ARCANE_TECH` | `HEALER_MORAL` | `BARD_INFLUENCE` | `MYTHIC`
- `slots_occupied`: `1` (padrão) ou `2` (unidades colossais como a *Tarasque*)
- `min_alignment` / `max_alignment`: faixa de `0` a `100` exigida para promoção
- `doctrine_affinity`: `PACIFISTA`, `REVOLUCIONARIA` ou `NEUTRA`
- `front_action` / `back_action`: comportamento automático conforme a fileira na grade 3×2
- `terrain_bonus`: terreno onde a unidade ganha bônus de marcha e esquiva no mapa

---

## 2. Linhagens Marciais (Frente, Choque e Precisão)

### Linhagem A — Soldado / Infantaria (`VANGUARD`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| **Sergent d'Armes** *(Base)* | Tier 1 | Qualquer (`0–100`) · Neutra | **2× Golpe de Espada** (físico) | **1× Estocada** (físico) | HP Médio, DEF Média · Estradas |
| [**Faydit**](https://fr.wikipedia.org/wiki/Faydit_(croisade)) *(Promoção Bem / Revolucionária)* | Tier 2 | `60–100` · Revolucionária | **3× Corte de Guerrilha** (ignora parte da DEF) | **1× Grito d'Oc** (+ATQ ao esquadrão) | AGI Alta, ATQ Alto · **Pireneus / Rochas** |
| **Cavaleiro Hospitalário** *(Promoção Bem / Pacifista)* | Tier 2 | `70–100` · Pacifista | **2× Escudo Consagrado** (dano + reduz dano recebido) | **1× Proteção de Voto** (cura leve + escudo em aliado) | HP Alto, DEF Muito Alta · Cidades / Planícies |
| **Routier / Cruzado Implacável** *(Promoção Mal)* | Tier 2 | `0–38` · Revolucionária | **3× Golpe Brutal** (alto dano + bônus contra feridos) | **1× Saque Incendiário** (dano + gera ouro extra) | ATQ Muito Alto, Carisma Baixo · Estradas *(reduz Apoio Popular ao conquistar cidades)* |

### Linhagem B — Lanceiro / Cavalaria / Cerco (`SHOCK`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| **Lanceiro / Escudeiro** *(Base)* | Tier 1 | Qualquer (`0–100`) · Neutra | **2× Lança Longa** (perfurante) | **1× Arremesso de Dardo** | HP Médio, ATQ Médio · Planícies |
| **Chevalier de Languedoc** *(Promoção Bem)* | Tier 2 | `65–100` · Neutra/Revolucionária | **3× Carga Montada** (alto dano + quebra defesa) | **1× Investida de Lança** (atinge fileira traseira) | ATQ Alto, Velocidade de Marcha Alta · **Vinhedos / Planícies de Toulouse** |
| **Quebra-Muralhas de Cerco** *(Promoção Mal / Choque)* | Tier 2 | `0–45` · Revolucionária | **2× Ariete / Martelo de Ferro** (dano dobrado em guarnições de *castrum*) | **1× Disparo de Mangonel** (dano físico em área) | HP Muito Alto, Marcha Lenta · Cercos / Fortalezas |

### Linhagem C — Arqueiro / Batedor / Assassino (`RANGED_STEALTH`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| **Arbalétrier** *(Besteiro de Muralha · Base)* | Tier 1 | Qualquer (`0–100`) · Neutra | **1× Adaga Curta** | **2× Virote de Besta** (ignora parte da armadura) | Precisão Alta, HP Baixo · Muralhas |
| **Batedor dos Pireneus** *(Promoção Bem)* | Tier 2 | `55–100` · Neutra/Pacifista | **2× Golpe Ágil** (alta esquiva) | **2× Tiro de Precisão** (foca unidades aéreas ou fracas) | AGI Muito Alta · **Montanhas / Montagne Noire** |
| **Sicário Inquisitorial** *(Promoção Mal)* | Tier 2 | `0–35` · Revolucionária | **3× Lâmina Oculta** (chance de veneno) | **2× Virote Envenenado** (prioriza o **líder** inimigo) | Crítico Alto, Furtividade · Noite / Cidades |

---

## 3. Linhagens de Suporte, Conhecimento e Influência Moral

### Linhagem D — Erudito / Alquimia (`ARCANE_TECH`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| **Boticário / Erudito** *(Base)* | Tier 1 | Qualquer (`0–100`) · Neutra | **1× Cajado** | **1× Frasco Alquímico** (dano elemental em 1 alvo) | INT Média, DEF Baixa · Cidades |
| **Alquimista Hermético** *(Promoção Bem)* | Tier 2 | `60–100` · Neutra/Pacifista | **1× Símbolo de Luz** (dano mágico) | **2× Chama Solar / Éter** (dano mágico em **todos** os inimigos) | INT Muito Alta, RES Mágica Alta · Neutro |
| **Engenheiro de Fogo & Cerco** *(Promoção Mal)* | Tier 2 | `0–40` · Revolucionária | **1× Tocha de Nafta** | **2× Fogo Grego** (dano incendiário em área + queima Moral inimiga) | INT Alta, Dano Contínuo · Cercos / Noite |

### Linhagem E — Clérigo / Curandeiro / Autoridade Moral (`HEALER_MORAL`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| **Irmão/Irmã de Caridade** *(Base)* | Tier 1 | `45–100` · Pacifista | **1× Cajado de Viagem** | **2× Curativo / Prece** (cura aliado com menos HP) | RES Mágica Alta · Cidades / Abadias |
| [**Parfait / Parfaite Cátaro**](https://en.wikipedia.org/wiki/Catharism) *(Promoção Bem / Pacifista)* | Tier 2 | `75–100` · **Pacifista** | **1× Escudo de Compaixão** *(não causa dano letal; reduz ATQ inimigo)* | **2× Paz dos Bons Homens** (cura todo o esquadrão + drena **Moral** inimiga para rendição) | INT/Carisma Muito Altos · **Eleva Apoio Popular ao libertar vilas** |
| [**Inquisidor Dominicano**](https://en.wikipedia.org/wiki/Albigensian_Crusade) *(Promoção Mal)* | Tier 2 | `0–35` · Controle/Sombria | **1× Bastão de Ferro** | **2× Anátema / Interrogatório** (dano sombrio + chance de paralisar e derrubar Moral pelo medo) | INT Alta, RES Mágica Alta · Abadias *(derruba Apoio Popular civil)* |

### Linhagem F — Bardo / Influência Popular (`BARD_INFLUENCE`)

| Classe | Tier | Alinhamento & Doutrina | Fileira Frontal (3×2) | Fileira Traseira (3×2) | Atributos-Chave & Terreno |
|---|---|---|---|---|---|
| [**Trovador Occitano (Trobador)**](https://en.wikipedia.org/wiki/Troubadour) *(Base)* | Tier 1 | Qualquer (`0–100`) · Neutra | **1× Rapieira Cortês** | **1× Canção d'Oc** (+Moral e +AGI ao esquadrão) | Carisma Alto · Estradas / Cortes |
| **Menestrel da Resistência** *(Promoção Bem)* | Tier 2 | `65–100` · Pacifista/Honrada | **2× Florete Ágil** | **1× Sirventes da Liberdade** (concede **+1 ação extra** a um aliado ou induz deserção inimiga) | Carisma Muito Alto · **Bônus máximo de Apoio Popular** |
| **Arauto da Cruzada** *(Promoção Mal)* | Tier 2 | `0–40` · Revolucionária/Fanática | **2× Espada Jurada** | **1× Pregação de Guerra** (+35% ATQ físico do esquadrão, mas reduz DEF e Apoio Popular) | ATQ/Carisma Altos · Campos de Batalha |

---

## 4. Classes Míticas, Folclóricas e Secretas (`MYTHIC`)

| Classe Secreta | Espaços (3×2) | Condição de Desbloqueio / Recrutamento | Fileira Frontal | Fileira Traseira | Papel Único no Ato II |
|---|---|---|---|---|---|
| **Portador do Consolamentum** *(Luz Cátara)* | `1` | Promover *Parfait* (Nível 15+, Alinhamento `90–100`) com a relíquia **Códice de Sabarthès** (Grutas dos Pireneus). | **2× Clarão Puro** (dano massivo em espectros/mortos-vivos) | **2× Consolamentum** (cura total em área + revive 1 aliado caído) | Ápice da **Linha Pacifista**; único counter absoluto contra *Ecos de Béziers*. |
| [**Tarasca do Rhône (Tarasque)**](https://en.wikipedia.org/wiki/Tarasque) | **`2`** *(Colossal)* | Encontro secreto nos **Pântanos de Tarascon**. Recrutável se derrotada por **Moral** por um esquadrão contendo uma *Parfaite* (Alinhamento `85+`), ecoando a lenda provençal. | **3× Mandíbula Blindada** (físico pesado + armadura altíssima) | **2× Hálito do Rhône** (dano venenoso em **todos** os inimigos) | Equivalente direto aos dragões de *Ogre Battle*; tanque colossal de pântanos e rios. |
| **Eco de Béziers** *(Cavaleiro Espectral)* | `1` | Recrutável nas **Ruínas de Béziers** à noite se o jogador tiver Alinhamento `≤ 25` e o item **Sino de Cinza**. | **2× Lâmina de Cinza** (drena HP) | **2× Lamento da Fogueira** (dano sombrio + reduz Moral inimiga) | **Imune a 75% do dano físico comum**; vulnerável a luz e *Parfaits*. |

---

## 5. Molde Pronto para Vibecoding no Godot 4 (`.tres`)

Entregue este molde ao seu agente de código (`Cline` / `Antigravity CLI`) para gerar todas as fichas acima dentro de `res://eras/act_02_occitania/classes/`:

```gdscript
# Exemplo: res://eras/act_02_occitania/classes/act2_parfait.tres
[gd_resource type="Resource" script_class="UnitClassData" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/data/unit_class_data.gd" id="1_cls"]

[resource]
script = ExtResource("1_cls")
class_id = "act2_parfait"
display_name = "Parfait Cátaro"
era_id = "act_02_occitania"
archetype = "HEALER_MORAL"
tier = 2
slots_occupied = 1
min_alignment = 75
max_alignment = 100
doctrine_affinity = "PACIFISTA"
is_non_lethal = true
base_hp = 85
base_atk = 12
base_def = 28
base_int = 54
base_agi = 30
base_cha = 65
front_action_id = "escudo_compaixao"
front_action_count = 1
back_action_id = "paz_bons_homens"
back_action_count = 2
terrain_bonus = PackedStringArray("village", "mountain", "abbey")
liberation_reputation_bonus = 12
promotion_targets = PackedStringArray("act2_portador_consolamentum")
```
