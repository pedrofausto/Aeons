# Especificação Técnica e de Game Design — Classes e Especializações do Ato II (Terras d'Oc)

> **Escopo:** Árvore completa de classes, atributos, regras de promoção por **Alinhamento (`ALI`)**, **Doutrina (`DOC`)** e **Carisma (`CHA`)**, ações por fileira na grade **3×2** (*Ogre Battle*) e schema `UnitClassData.gd` pronto para geração de arquivos `.tres` no **Godot 4.7.2** via *vibecoding*.

---

## 1. Convenções Numéricas do Motor (Ato II)

- **Alinhamento (`ALI`):** `0` (Brutalidade/Mal) a `100` (Honra/Bem).
- **Doutrina (`DOC`):** `-100` (Pacifista / Contenção & Moral) a `+100` (Revolucionária / Choque & Ruptura).
- **Carisma (`CHA`):** `0` a `100` (necessário para liderar esquadrões e desbloquear promoções de elite).
- **Grade de Combate:** `3 colunas × 2 fileiras` (**Frente** e **Trás**). Unidades padrão ocupam `1 slot`; unidades colossais (como a *Tarasque*) ocupam `2 slots`.
- **Tipos de Dano / Efeito:**
  - `FIS` (Físico / Corte), `PERF` (Perfurante / Bestas & Lanças), `CERCO` (Quebra-Muralhas / Ignora 50% de defesa), `LUZ` (Espiritual / Purificação), `FOGO` (Alquimia / Queimadura), `MORAL` (Drena Moral inimiga sem matar — chave da **Linha Pacifista**), `CURA` / `BUFF`.
- **Perfis de Movimento no Mapa:** `Infantaria`, `Cavalaria` (rápida em estradas/planícies de Toulouse, lenta nos Pireneus), `Montanha` (ignora penalidade nos Pireneus), `Pântano` (ignora penalidade em Tarascon), `Etéreo` (ignora terreno físico).

---

## 2. Linhagens Marciais (Frente, Choque e Furtividade)

### 2.1 Linhagem do Soldado (`Sergent d'Armes`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Sergent d'Armes** *(Homem de Armas)* | Base | — | 1 / Infantaria | `2× Golpe de Espada` (`FIS`) | `1× Estocada` (`FIS`) | 95 / 18 / 16 / 12 / 8 | Linha de frente inicial equilibrada em Carcassonne. |
| **Faydit** *(Cavaleiro Desapossado)* | Elite | `Nv 10+`, `ALI ≥ 60`, `DOC ≥ +20`, `CHA ≥ 55` | 1 / Montanha | `3× Investida Occitana` (`FIS`, +25% em montanha) | `1× Grito de Guerrilha` (`BUFF`: +ATK ao esquadrão) | 145 / 32 / 24 / 22 / 14 | **Bem + Revolucionária:** quebra cercos e lidera emboscadas nos Pireneus ([Faydits](https://fr.wikipedia.org/wiki/Faydit_(croisade))). |
| **Defensor do Burgo** *(Hospitalário)* | Elite | `Nv 10+`, `ALI ≥ 70`, `DOC ≤ -10`, `CHA ≥ 60` | 1 / Infantaria | `2× Escudo Juramentado` (`FIS` + reduz dano recebido pelo esquadrão) | `1× Prece de Proteção` (`CURA` moderada em 1 aliado) | 165 / 22 / 34 / 12 / 18 | **Bem + Pacifista:** tanque puro que segura a linha enquanto *Parfaits* vencem por Moral. |
| **Routier / Cruzado Implacável** | Sombria | `Nv 9+`, `ALI ≤ 35` | 1 / Infantaria | `3× Golpe Brutal` (`FIS` + reduz Moral inimiga por terror) | `1× Saque Incendiário` (`FOGO` em 1 alvo + gera ouro) | 150 / 35 / 22 / 16 / 10 | **Mal (Baixo ALI):** altíssimo dano precoce e ouro extra, mas derruba Apoio Popular ao libertar cidades. |

### 2.2 Linhagem do Lanceiro / Cavalaria (`Escudeiro`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Escudeiro / Lanceiro** | Base | — | 1 / Infantaria | `2× Lança Longa` (`PERF`) | `1× Arremesso de Dardo` (`PERF`) | 90 / 20 / 14 / 14 / 8 | Anti-cavalaria básica. |
| **Chevalier de Languedoc** | Elite | `Nv 11+`, `ALI ≥ 60`, `CHA ≥ 60` | 1 / Cavalaria | `2× Carga de Lança` (`PERF`, alto impacto, ignora parte da DEF) | `1× Flanco Montado` (`PERF` no alvo mais fraco) | 155 / 34 / 26 / 24 / 12 | **Bem:** velocidade máxima nas estradas e vinhedos de Toulouse. |
| **Quebra-Muralhas** *(Engenheiro de Cerco)* | Sombria / Tática | `Nv 11+`, `ALI ≤ 45`, `DOC ≥ +30` | 1 / Infantaria | `2× Martelo de Brecha` (`CERCO`) | `1× Disparo de Trébuchet` (`CERCO` em área, bônus contra *castra*) | 140 / 36 / 28 / 9 / 16 | **Revolucionária / Cerco:** especialista em derrubar fortalezas cruzadas ([guerra de castra](https://deremilitari.org/2018/04/the-albigensian-crusade-a-comparative-military-study-1209-1218/)). |

### 2.3 Linhagem do Arqueiro / Batedor (`Arbalétrier`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Arbalétrier** *(Besteiro)* | Base | — | 1 / Infantaria | `1× Adaga de Defesa` (`FIS`) | `2× Virote de Besta` (`PERF`) | 75 / 19 / 11 / 16 / 10 | Dano perfurante confiável da retaguarda. |
| **Batedor dos Pireneus** *(Almogàver)* | Elite | `Nv 10+`, `ALI ≥ 55` | 1 / Montanha | `2× Contra-Ataque Ágil` (`FIS` + alta esquiva) | `2× Tiro de Precisão` (`PERF`, bônus contra alvos em cobertura) | 115 / 29 / 17 / 30 / 14 | **Bem:** batedor rápido em montanha e floresta, excelente para interceptar patrulhas. |
| **Sicário da Inquisição** | Sombria | `Nv 10+`, `ALI ≤ 30` | 1 / Infantaria | `2× Lâmina Envenenada` (`FIS` + dano contínuo) | `2× Virote Silencioso` (`PERF`, mira automaticamente o líder inimigo) | 105 / 31 / 14 / 32 / 16 | **Mal:** elimina curandeiros e líderes na retaguarda antes que ajam. |

---

## 3. Linhagens de Suporte, Alquimia, Fé e Influência

### 3.1 Linhagem do Erudito / Mago (`Boticário`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Erudito / Boticário** | Base | — | 1 / Infantaria | `1× Cajado` (`FIS`) | `1× Frasco Alquímico` (`FOGO` em 1 fileira) | 70 / 9 / 10 / 13 / 22 | Suporte técnico inicial com dano elemental. |
| **Alquimista Hermético** | Elite | `Nv 11+`, `ALI ≥ 55` | 1 / Infantaria | `1× Selo de Contenção` (`LUZ` + reduz ATK inimigo) | `2× Tempestade Astral` (`LUZ` em área, bônus contra espectros) | 105 / 12 / 16 / 18 / 36 | **Bem:** dano em área limpo e indispensável contra *Ecos de Béziers*. |
| **Piromante de Cerco** | Sombria | `Nv 10+`, `ALI ≤ 40` | 1 / Infantaria | `1× Bomba de Nafta` (`FOGO`) | `2× Fogo Grego` (`FOGO` em todos os inimigos + queimadura) | 100 / 14 / 14 / 17 / 38 | **Mal:** maior dano mágico em área do Ato II, porém causa medo em vilas civis. |

### 3.2 Linhagem do Clérigo / Moral (`Irmão de Caridade`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Irmão/Irmã de Caridade** | Base | — | 1 / Infantaria | `1× Bênção Menor` (`CURA` em si) | `2× Cura de Campo` (`CURA` no aliado mais ferido) | 75 / 8 / 12 / 12 / 20 | Curandeiro inicial do esquadrão. |
| **Parfait / Parfaite Cátaro** *(Bon Homme)* | Elite | `Nv 10+`, `ALI ≥ 70`, `DOC ≤ -20` | 1 / Infantaria | `1× Escudo de Luz` (`BUFF` de defesa espiritual) | `2× Consolamentum` (`CURA` em grupo + `MORAL` drena vontade de lutar do inimigo) | 115 / 6 / 18 / 16 / 36 | **Bem + Pacifista:** pilar da vitória sem sangue; eleva drasticamente o Apoio Popular ao libertar cidades ([Catharism](https://en.wikipedia.org/wiki/Catharism)). |
| **Inquisidor Dominicano** | Sombria | `Nv 10+`, `ALI ≤ 30` | 1 / Infantaria | `1× Sentença de Ferro` (`FIS` + debuff de DEF) | `2× Anátema` (`MORAL` por pânico + reduz cura inimiga em 50%) | 120 / 18 / 20 / 14 / 34 | **Mal:** controle brutal de campo de batalha, mas reduz Apoio Popular por onde passa. |

### 3.3 Linhagem do Bardo / Influência (`Trovador Occitano`)

| Classe | Tier | Requisitos de Promoção | Slots / Mov. | Ação na Frente (por rodada) | Ação Atrás (por rodada) | Atributos Base (HP / ATK / DEF / AGI / INT) | Papel Tático & Doutrina |
|---|---|---|---|---|---|---|---|
| **Trovador Occitano** *(Trobador)* | Base | — | 1 / Infantaria | `1× Florete Cortês` (`FIS`) | `1× Canção de Coragem` (`BUFF`: +Moral e +AGI aliados) | 80 / 13 / 11 / 18 / 18 | Aumenta moral do esquadrão e gera bônus de diálogo em vilas ([Troubadour](https://en.wikipedia.org/wiki/Troubadour)). |
| **Menestrel da Resistência** | Elite | `Nv 12+`, `ALI ≥ 65`, `CHA ≥ 70` | 1 / Infantaria | `2× Dança de Lâminas` (`FIS`) | `1× Sirventes da Liberdade` (`BUFF`: concede +1 ação extra a 1 aliado e reduz Moral inimiga) | 115 / 19 / 16 / 26 / 30 | **Bem:** inspirado na *Princess/Muse* de *Ogre Battle*; multiplica o poder de esquadrões de elite. |
| **Arauto da Cruzada** | Sombria | `Nv 12+`, `ALI ≤ 35`, `CHA ≥ 60` | 1 / Infantaria | `2× Estandarte de Ferro` (`FIS`) | `1× Trombeta do Cerco` (`BUFF`: +30% ATK a todo o esquadrão, -10% DEF) | 125 / 24 / 18 / 20 / 24 | **Mal:** transforma esquadrões ofensivos em máquinas de choque implacáveis. |

---

## 4. Classes Míticas e Secretas do Ato II

| Classe Secreta | Como Desbloquear / Recrutar | Slots / Mov. | Ação na Frente | Ação Atrás | Diferencial Único |
|---|---|---|---|---|---|
| **Portador do Consolamentum** *(Luz Cátara)* | Promover um *Parfait* `Nv 15+` com `ALI ≥ 90`, `DOC ≤ -60` + item *Manuscrito de Montségur* | 1 / Etéreo | `2× Raio de Lucidez` (`LUZ` + `MORAL`) | `2× Graça Pura` (`CURA` total + revive 1 aliado caído por batalha) | Imune a debuffs inquisitoriais; ao entrar em combate, exibe um brilho geométrico sutil (eco oculto dos Aeons). |
| **Tarasca do Rhône** *(Tarasque)* | Evento nos Pântanos de Tarascon: acalmá-la usando uma *Parfaite* (`ALI ≥ 80`) ou vencê-la em duelo ([Tarasque](https://en.wikipedia.org/wiki/Tarasque)) | **2 / Pântano** | `3× Esmagamento de Carapaça` (`FIS` massivo) | `2× Sopro Miasmático` (`FOGO`/veneno em todos os inimigos) | HP altíssimo (`290`), blindagem natural; ocupa 2 slots da grade 3×2 como os dragões de *Ogre Battle*. |
| **Espectro de Béziers** | Recrutável nas Ruínas de Béziers à noite com `ALI ≤ 20` + item *Sino Partido* | 1 / Etéreo | `2× Toque de Cinzas` (`FIS` + dreno de HP) | `2× Lamento de 1209` (`MORAL` em área + paralisa) | Imune a dano `FIS` comum; vulnerável a `LUZ` e purificação. |

---

## 5. Schema Pronto para Godot 4 (`res://core/data/UnitClassData.gd`)

Copie este `Resource` para a pasta `res://core/data/` e peça ao seu agente de *vibecoding* para gerar os arquivos `.tres` em `res://eras/act_02_occitania/classes/` usando as tabelas acima como fonte única da verdade:

```gdscript
class_name UnitClassData
extends Resource

enum Archetype { VANGUARD, SHOCK, STEALTH, ARCANE_TECH, HEALER_MORAL, BARD_INFLUENCE, MYTHIC }
enum MovementType { INFANTRY, CAVALRY, MOUNTAIN, SWAMP, ETHEREAL }
enum DamageType { PHYSICAL, PIERCE, SIEGE, LIGHT, FIRE, MORALE, HEAL, BUFF }

@export var class_id: StringName
@export var display_name: String
@export var era_id: StringName = &"act_02_occitania"
@export var archetype: Archetype = Archetype.VANGUARD
@export var tier: int = 1 # 1 = Base, 2 = Elite/Sombria, 3 = Mítica/Secreta
@export var grid_slots: int = 1 # 2 para unidades colossais (ex.: Tarasque)
@export var movement_type: MovementType = MovementType.INFANTRY

@export_group("Requisitos de Promoção")
@export var promotes_from: StringName = &""
@export var min_level: int = 1
@export var min_alignment: int = 0
@export var max_alignment: int = 100
@export var min_doctrine: int = -100 # -100 Pacifista .. +100 Revolucionária
@export var max_doctrine: int = 100
@export var min_charisma: int = 0
@export var required_item_id: StringName = &""

@export_group("Atributos Base")
@export var base_hp: int = 100
@export var base_atk: int = 15
@export var base_def: int = 15
@export var base_agi: int = 15
@export var base_int: int = 15

@export_group("Ações na Grade 3x2")
@export var front_action_name: String
@export var front_hits: int = 2
@export var front_damage_type: DamageType = DamageType.PHYSICAL
@export var front_is_aoe: bool = false

@export var back_action_name: String
@export var back_hits: int = 1
@export var back_damage_type: DamageType = DamageType.PHYSICAL
@export var back_is_aoe: bool = false

@export_group("Impacto no Mapa")
@export var liberation_reputation_bonus: int = 0 # Positivo para Parfait/Defensor; negativo para Routier/Inquisidor
@export var sprite_sheet: Texture2D
@export var normal_map: Texture2D
```
