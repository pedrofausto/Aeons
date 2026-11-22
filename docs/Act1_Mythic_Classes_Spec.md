# Especificação para Agente Autônomo: Classes Míticas e Encontros Faltantes do Ato I

> **Instrução para o Agente de IA:** Antes de criar os arquivos, inspecione o schema real do recurso de classe já existente no projeto (ex.: `UnitClassData.gd` / `*.tres`) e a tabela de encontros do spawner. Adapte os nomes de campos abaixo para corresponder exatamente às propriedades já definidas no código do repositório — **não** quebre o schema existente.

---

## 1. Novas Classes do Ato I (`res://eras/act_01_china/classes/`)

### A. `jiangshi` — Jiangshi (Cadáver Rígido)
- **Papel tático:** Tanque físico noturno (análogo aos mortos-vivos clássicos de *Ogre Battle*). Exige *Daoshi*, fogo ou ataques espirituais para ser abatido com eficiência.
- **Arquétipo:** `MYTHIC_UNDEAD`
- **Alinhamento (ALI):** `0–35`
- **Slots na grade 3×2:** `1`
- **Movimento no mapa:** Terrestre lento (bônus à noite)
- **Atributos base sugeridos (escala relativa 1–10):**
  - HP: `8` | ATK: `6` | DEF Física: `9` | DEF Mágica/Espiritual: `2` | AGI: `3` | Moral: `Imune a queda de moral (ou 100 fixo)`
- **Resistências / Fraquezas:** `80%` resistência a dano físico comum; `150%` dano recebido de `SPIRITUAL`, `PURIFY` e `FIRE`.
- **Ação na Fileira Frontal:** `2x Dreno Vital` (dano físico-sombrio; cura `30%` do dano causado).
- **Ação na Fileira Traseira:** `1x Sopro de Miasma` (dano baixo em 1 alvo + `-12` Moral no alvo).

### B. `wu_sombrio` — Xamã Wu (Líder do Cortejo)
- **Papel tático:** Suporte sombrio de retaguarda que comanda e fortalece unidades `jiangshi`.
- **Arquétipo:** `HEALER_MORAL_EVIL`
- **Alinhamento (ALI):** `0–35`
- **Slots na grade 3×2:** `1`
- **Atributos base sugeridos:**
  - HP: `4` | ATK: `3` | INT/MAG: `8` | DEF Física: `3` | DEF Mágica: `7` | AGI: `5`
- **Ação na Fileira Frontal:** `1x Golpe de Talismã` (dano baixo).
- **Ação na Fileira Traseira:** `1x Sino dos Mortos` (dano sombrio leve em área + concede `+20%` ataque aos `jiangshi` aliados na mesma batalha).

### C. `huli_jing` — Espírito Raposa (Ilusionista Noturna)
- **Papel tático:** Sabotadora mágica de alta esquiva focada em drenar Moral e desestabilizar formações.
- **Arquétipo:** `MYTHIC_TRICKSTER`
- **Alinhamento (ALI):** `15–55`
- **Slots na grade 3×2:** `1`
- **Atributos base sugeridos:**
  - HP: `4` | ATK: `5` | INT/MAG: `8` | DEF Física: `3` | DEF Mágica: `8` | AGI: `9`
- **Ação na Fileira Frontal:** `2x Garra Espectral` (dano mágico rápido; ignora metade da armadura física).
- **Ação na Fileira Traseira:** `1x Encanto da Névoa` (dano mágico em 1 alvo + `-20` Moral e chance de status `CONFUSE` por 1 rodada).

### D. `xian` — Xian (Imortal das Montanhas de Pengming)
- **Papel tático:** Classe mítica celeste de alto alinhamento; ignora terreno no mapa e atua tanto como purificador contra mortos-vivos quanto como pilar da Doutrina Pacifista.
- **Arquétipo:** `MYTHIC_CELESTIAL`
- **Alinhamento (ALI):** `75–100`
- **Slots na grade 3×2:** `1`
- **Movimento no mapa:** `FLYING` (ignora rios, montanhas e mar até Pengming)
- **Atributos base sugeridos:**
  - HP: `7` | ATK: `7` | INT/MAG: `9` | DEF Física: `6` | DEF Mágica: `9` | AGI: `8`
- **Resistências:** Imune a `POISON`, `CONFUSE` e drenagem de Moral.
- **Ação na Fileira Frontal:** `2x Espada de Jade Celeste` (dano `SPIRITUAL` puro — atravessa resistência física de `jiangshi`).
- **Ação na Fileira Traseira:** `1x Harmonia dos Nove Céus` (cura aliados em área + restaura `+15` Moral; se todos os aliados estiverem com HP > 80%, dispara dano `SPIRITUAL` em área contra inimigos).

---

## 2. Definições de Encontros para o Spawner do Ato I

### Encontro Noturno 1: `cortejo_de_jiangshi`
- **Tipo de spawn:** `NIGHT_ENCOUNTER`
- **Regiões válidas:** `vales_nanlu` (estradas/ruínas), `desfiladeiro_hanmen` (trilhas noturnas)
- **Formação 3×2:**
  - **Frente:** `[jiangshi, jiangshi, jiangshi]`
  - **Trás:** `[wu_sombrio (líder), huli_jing]`
- **Regras pós-batalha:**
  - Não reduz Alinhamento por diferença de nível (unidade sobrenatural).
  - Vitória concede `+5` de **Apoio Popular** na província atual.
  - Drop raro (`25%`): `talisma_de_cinabrio` (item de promoção/selo para classes místicas).

### Encontro Chefe Mítico: `guardiao_xian_pengming`
- **Tipo de spawn:** `MYTHIC_BOSS` (encontro único ou reativável até ser vencido)
- **Região válida:** `arquipelago_pengming` (Observatório dos Nove Céus)
- **Formação 3×2:**
  - **Frente:** `[xian (líder), jiangshi_ou_guarda_imperial]` *(preferir um guardião de elite existente no Ato I, como `youxia` ou `alabardeiro_ji`)*
  - **Trás:** `[fangshi, xian]` *(usar a classe `fangshi` já existente no Ato I)*
- **Resolução por Doutrina (Pacifista vs. Revolucionária):**
  - **Vitória por Moral** (ou vitória com Alinhamento do esquadrão ≥ `70` e flag do Astrônomo Cego ativa): desbloqueia o recrutamento da classe `xian` e grava a flag `pengming_xian_ally = true` em `WorldState.gd`.
  - **Vitória por HP (aniquilação):** concede o item único `bussola_dos_nove_ceus` (`+20%` velocidade de marcha no mapa e visão de encontros noturnos).

---

## 3. Checklist de Validação para o Agente

1. Criar os 4 arquivos de classe (`jiangshi`, `wu_sombrio`, `huli_jing`, `xian`) seguindo o formato `.tres` / registro do projeto (usando sprites placeholder coloridos distintos caso a arte final ainda não exista).
2. Registrar `cortejo_de_jiangshi` (`NIGHT_ENCOUNTER`) e `guardiao_xian_pengming` (`MYTHIC_BOSS`) no spawner do Ato I.
3. Rodar teste automatizado verificando:
   - Todos os IDs de classe referenciados no spawner resolvem sem `null` ou erro de carregamento.
   - Em batalha simulada, um ataque físico comum contra `jiangshi` aplica a redução de dano (`80%`), enquanto `Espada de Jade Celeste` do `xian` aplica dano espiritual pleno (`150%`).
   - Emitir `ACT1_MYTHIC_CLASSES_PASS` no log ao concluir.
