---
id: ato_02_terras_doc
titulo: "Ato II — Terras d'Oc: Carcassonne, Montségur e a Resistência Cátara"
periodo_inspiracao: "Século XIII (1209–1244) — Cruzada Albigense e Occitânia"
engine_alvo: "Godot 4.7.2 + Dialogic 2 + Obsidian"
---

# Ato II — Terras d'Oc: Atlas Completo, Facções, Encontros e Roteiro de Diálogos


---

## 1. Contexto Cultural e Fratura Política

Antes da invasão, as Terras d'Oc (*Languedoc*, sul da atual França) formavam uma sociedade urbana, musical e relativamente tolerante, distinta do feudalismo rígido do norte. A [Cruzada Albigense (1209–1229)](https://en.wikipedia.org/wiki/Albigensian_Crusade) rompeu esse equilíbrio ao unir interesse religioso (erradicar o catarismo) e ambição territorial (anexar os viscondados do sul).

### Pilares Culturais do Ato II
- **Língua d'Oc e Cortes de *Fin'Amor*:** os [trovadores occitanos (*trobadors*)](https://en.wikipedia.org/wiki/Troubadour) compunham *sirventes* (canções políticas) que moldavam a opinião pública nas praças — funcionando mecanicamente como amplificadores de **Apoio Popular**.
- **Os *Bons Hommes* e *Bonnes Femmes*:** os [cátaros](https://en.wikipedia.org/wiki/Catharism) rejeitavam a violência, o acúmulo de riquezas, os juramentos feudais e o consumo de carne, praticando um único sacramento: o *Consolamentum*. Mulheres (*Bonnes Femmes* / *Parfaites*) exerciam liderança espiritual plena.
- **Guerra de *Castra* (Cercos):** diferentemente das grandes marchas campais do Ato I, o conflito na Occitânia gira em torno de [cercos a *castra*](https://deremilitari.org/2018/04/the-albigensian-crusade-a-comparative-military-study-1209-1218/) (vilas fortificadas sobre rochedos), corte de suprimento de água, *trébuchets* e guerrilha nas montanhas.
- **Fratura Interna do Sul:** nobres católicos (como a [Casa de Trencavel](https://en.wikipedia.org/wiki/Raymond_Roger_Trencavel)), cavaleiros desapossados ([*Faydits*](https://fr.wikipedia.org/wiki/Faydit_(croisade))) e ascetas cátaros pacifistas lutam pelo mesmo território, mas divergem radicalmente quanto ao **método** — alimentando o eixo `WorldState.doctrine` (**Pacifista vs. Revolucionária**).

---

## 2. Atlas das 6 Regiões do Mapa (`CityData.tres`)

| ID Região | Nome & Posição | Cidades / *Castra* | Terreno & Modificador Tático | Interlúdios de Presença | Papel na Campanha |
|---|---|---|---|---|---|
| `act2_carcassonne` | **Cidadela de Carcassonne** *(Centro)* | Cité de Carcassonne, Burgo de São Vicente, Pontes do Rio Aude | Muralha dupla; controle de água/cisternas decide cercos prolongados ([Cerco de 1209](https://en.wikipedia.org/wiki/Siege_of_Carcassonne)). | Salão do Visconde, cisternas subterrâneas, adro da basílica. | Ponto inicial da crise e grande meta de reconquista no meio do ato. |
| `act2_toulouse` | **Vinhedos de Toulouse** *(Oeste)* | Toulouse, Muret, Castelnaudary | Planícies abertas e estradas largas: bônus para cavalaria pesada e batalhas campais. | Cortes de trovadores, cais do rio Garona, conselhos de nobres. | Centro diplomático para negociar com condes locais e Aragão. |
| `act2_albi` | **Montagne Noire & Albi** *(Norte)* | Albi, Abadia de Cîteaux-Sul, Castelo de Cabaret | Florestas densas e colinas nevoentas; bases cruzadas e emboscadas. | Mosteiros fortificados, tribunais inquisitoriais, clareiras ocultas. | Frente norte dos invasores; cortar comboios aqui enfraquece cercos no sul. |
| `act2_montsegur` | **Pireneus & Montségur** *(Sul)* | Castrum de Montségur, Quéribus, Grutas de Sabarthès | Escarpa rochosa e neve; bloqueia cavalaria pesada e favorece besteiros e *Faydits*. | Aldeia de pedra no penhasco, vigílias noturnas, grutas. | Último refúgio cátaro ([1243–1244](https://en.wikipedia.org/wiki/Siege_of_Monts%C3%A9gur)) e palco do clímax. |
| `act2_beziers` | **Costa de Béziers & Narbonne** *(Sudeste)* | Ruínas de Béziers, Porto de Narbonne, Minervois | Estradas romanas e portos; gera ouro diário via comércio com Barcelona. | Igreja queimada de Madalena, docas de refugiados, mercados. | Zona traumatizada pelo massacre; reconstruir ou saquear altera fortemente o Alinhamento. |
| `act2_tarascon` | **Pântanos de Tarascon** *(Leste · Secreto)* | Tarascon, Ruínas do Rhône, Ilha dos Herboristas | Brejos lentos e névoa espessa; exige unidades leves/aéreas. | Cabana do alquimista, margens do Rhône sob neblina. | Região secreta da lenda da [*Tarasque*](https://en.wikipedia.org/wiki/Tarasque) e manuscritos proibidos. |

---

## 3. Divisão Política e Facções

| ID Facção | Nome | Papel | Liderança | Composição Militar | Relação com os 3 Eixos |
|---|---|---|---|---|---|
| `fac_crusaders` | **Barões da Cruzada do Norte** | Antagonista Militar | Barão Guy de Montclair *(inspirado em Simon de Montfort)* | Cavalaria pesada, lanceiros de choque, *trébuchets*. | Inimigo principal; perde fôlego quando acaba o serviço feudal de 40 dias. |
| `fac_inquisition` | **Legado Papal & Inquisição** | Antagonista Ideológico | Abade Arnaut & Irmão Guillaume | Inquisidores (debuffs de medo/heresia), guardas e espiões. | Derruba o **Apoio Popular** nas vilas ocupadas; persegue *Parfaits*. |
| `fac_faydits` | **Irmandade dos *Faydits*** | Aliado Revolucionário | Pierre-Roger de Rochefort | Cavaleiros leves, besteiros de montanha, emboscadores. | Fortalece-se com `doctrine > +20` (**Linha Revolucionária**). |
| `fac_cathars` | **Igreja dos *Bons Hommes*** | Aliado Pacifista | Diaconisa Esclarmonde | *Parfaits* curandeiros, auras de moral (rendição sem sangue). | Fortalece-se com `doctrine < -20` (**Linha Pacifista**) e `alignment >= 60`. |
| `fac_aragon` | **Coroa de Aragão** | Aliado Externo Volátil | Emissário de Barcelona *(ecoando [Pedro II em Muret](https://fr.wikipedia.org/wiki/Bataille_de_Muret))* | Infantaria leve ágil (*Almogàvers*) e cavalaria real. | Envia reforços se o jogador mantiver **Apoio Popular** e legitimidade política. |
| `fac_routiers` | **Companhias de *Routiers*** | Mercenários Neutros | Capitão Loup-Noir | Infantaria brutal, saqueadores e incendiários. | Contratáveis por prata (reduz Alinhamento e Apoio Popular) ou caçados nas estradas. |

---

## 4. Tabela de Inimigos Aleatórios e Encontros de Mapa

| Encontro | Zona & Horário | Esquadrão (Grade 3×2) | Regra Tática e Impacto Moral |
|---|---|---|---|
| **Bando de *Routiers*** | Estradas de Toulouse e Béziers *(Dia/Noite)* | Frente: 2 Homens de Armas, 1 Saqueador · Trás: 2 Besteiros | Atacam comboios civis; derrotá-los rende ouro e protege a economia local. |
| **Escolta da Inquisição** | Rotas entre Albi e Carcassonne *(Dia)* | Frente: 2 Guardas Cruzados · Trás: 1 Inquisidor, 1 Espião | Conduzem prisioneiros; interceptar e libertar eleva **Alinhamento** e **Apoio Popular**. |
| **Desertores Famintos** | Florestas da Montagne Noire *(Dia/Noite)* | Frente: 3 Lanceiros desgastados · Trás: 1 Arqueiro | Nível inferior ao jogador: **massacrar derruba Alinhamento**; vencer por **Moral** permite poupar ou recrutar. |
| **Feras dos Pireneus** | Trilhas de Montségur *(Noite)* | Matilha de lobos gigantes e ursos de montanha | Combate natural sem impacto moral; ideal para treino seguro de unidades. |
| **Ecos de Béziers** | Ruínas de Béziers e cemitérios *(Noite · Raro)* | Cavaleiros espectrais e penitentes de cinza | Imunes a dano físico comum (exigem *Parfaits*, clérigos ou alquimistas); concedem relíquias de promoção. |
| **A Tarasca do Rhône** | Pântanos de Tarascon *(Névoa · Secreto)* | [*Tarasque*](https://en.wikipedia.org/wiki/Tarasque) colossal (ocupa 2 espaços na grade 3×2) | Pode ser abatida (item raro) ou acalmada por uma *Parfaite* de alto alinhamento para entrar no exército. |

---

## 5. Princípio Filosófico do Ato II (Sem Quebrar o Disfarce Histórico)

- **Na superfície histórica:** o protagonista (um jovem cavaleiro menor de Carcassonne chamado **Aimeric de Val-Clair**) acredita estar vivendo apenas a tragédia de sua terra sob cerco.
- **O fio filosófico invisível:** no Ato I, o debate era se o *Mandato do Céu* era ordem natural ou um "céu de bronze" fechado. No Ato II, o mesmo questionamento ressurge através do dualismo cátaro: *se o poder que governa o mundo precisa de fogueiras, fome e medo para existir, então a própria ordem material é uma jaula — e vencer o tirano com os métodos do tirano apenas troca o carcereiro*.

---

## 6. Diálogos Exatos (Formato Pronto para Dialogic 2 / Obsidian)

### Cena 2.1 — Interlúdio nas Muralhas de Carcassonne (Definição da Doutrina)
- **Local:** `InterludeRoom_Carcassonne_Wall.tscn` (Crepúsculo, sinos ao longe, fumaça no horizonte de Béziers)
- **Personagens:** **Aimeric** (Protagonista), **Pierre-Roger** (*Faydit* Revolucionário), **Trovador Guillem** (Cronista/Bardo)
- **Gatilho:** Logo após a chegada dos primeiros refugiados de Béziers.

```text
[CENÁRIO: Muralha leste de Carcassonne. Lanternas oscilam ao vento quente de agosto. Ao fundo, a coluna de poeira do exército cruzado avança pela estrada romana.]

GUILLEM (Trovador):
"Cantei ontem na praça que o rio Aude não seca nem sob o sol de julho. Hoje o povo já conta os baldes nas cisternas. Em Béziers não perguntaram quem rezava em latim e quem rezava em silêncio — queimaram a igreja inteira com todos dentro."

PIERRE-ROGER (Faydit):
"E é por isso que poemas não seguram portões, Guillem. Montclair traz ferro do norte e a bênção de Roma para repartir nossas terras como despojo. Se esperarmos que os barões se compadeçam, morreremos de sede atrás destas pedras."

PIERRE-ROGER (vira-se para Aimeric):
"Aimeric, os homens das vigias ainda escutam a tua voz. Os cavaleiros sem terra se reúnem nas trilhas de Cabaret esta noite. Dize-me: vamos descer ao vale e incendiar os carros de trigo e os trabucos deles antes que cerquem o rio — ou vamos cruzar os braços como os Bons Hommes e chamar a própria ruína de virtude?"

GUILLEM (baixo, olhando o horizonte):
"Cuidado com o que acendes no vale, Pierre. Há camponeses recrutados à força naquele acampamento — homens que nem sabem o nome das nossas cidades. Se respondermos ao fogo com fogo, quem restará para lembrar o que Carcassonne era antes da cinza?"

[ESCOLHA DO JOGADOR — Define a tendência inicial de WorldState.doctrine]

> OPÇÃO A (Linha Revolucionária): "O tirano só entende a linguagem do ferro. Atacaremos os comboios esta noite."
  [EFEITO: WorldState.doctrine += 15 | WorldState.alignment -= 5 | fac_faydits.trust += 10]
  PIERRE-ROGER:
  "Enfim alguém com sangue nas veias. Afia tua lança, Aimeric. Se esta terra tiver de cair, que caia levando metade do norte consigo."
  GUILLEM (suspira, afinando o alaúde):
  "Que Deus me perdoe, então — porque amanhã terei de cantar sobre mais viúvas dos dois lados."

> OPÇÃO B (Linha Pacifista / Estratégica): "Não venceremos nos tornando iguais a eles. Protegeremos a água e abriremos passagem aos refugiados."
  [EFEITO: WorldState.doctrine -= 15 | WorldState.alignment += 10 | WorldState.popular_support += 10 | fac_cathars.trust += 10]
  PIERRE-ROGER (com amargura):
  "Nobreza demais para um cerco sem misericórdia, rapaz. Guarda essas palavras para quando a água acabar."
  GUILLEM (sorri de leve):
  "Os barões temem uma cidade em armas, Aimeric — mas temem ainda mais um povo que eles não conseguem ensinar a odiar."
```

---

### Cena 2.2 — Interlúdio Secreto: A Vigília da Diaconisa Esclarmonde (O Coração Filosófico)
- **Local:** `InterludeRoom_Montsegur_Chapel.tscn` (Sala de pedra nua sem ornamentos, apenas uma lamparina e uma janela estreita para o céu estrelado dos Pireneus)
- **Personagens:** **Aimeric** e **Diaconisa Esclarmonde** (*Parfaite* Cátara)
- **Gatilho:** Após o jogador visitar Montségur pela primeira vez ou libertar uma escolta inquisitorial.

```text
[CENÁRIO: Silêncio quase total. Sem música de percussão — apenas uma nota longa de violoncelo e o vento nas fendas da rocha.]

ESCLARMONDE:
"Entra, Aimeric. Não há ouro aqui, nem estandartes. Apenas pedra, pão e a noite. Dizem nas estradas que o teu nome já pesa nos conselhos de Montclair."

AIMERIC:
"Eles cercam nossas cidades, queimam nossas colheitas e nos chamam de hereges porque não nos ajoelhamos. Dize-me a verdade, Diaconisa: por que os teus irmãos recusam até mesmo erguer uma espada para defender a própria vida?"

ESCLARMONDE (aproxima-se da janela estreita, olhando as estrelas fixas sobre os Pireneus):
"Porque já vimos este cerco antes, Aimeric — não apenas nesta montanha, mas em cada império que jamais se ergueu sobre a terra. Olha para o modo como o mundo funciona: um senhor cai, outro sobe em seu lugar; uma lei se quebra, outra mais pesada é escrita com o sangue da anterior."

ESCLARMONDE (vira-se para Aimeric, olhar sereno e penetrante):
"Os sábios do norte dizem que esta prisão de pedra e ferro foi feita por um Deus bom. Nós sabemos que não. O mundo visível é uma muralha construída por um Arconte ciumento para manter a centelha humana girando em círculos — ora como escravo, ora como conquistador, sempre preso ao mesmo tabuleiro."

AIMERIC (estranhamente perturbado, como se reconhecesse uma memória sem rosto):
"...'Girando em círculos'? Por um instante... tive a impressão de já ter olhado para um céu que não se movia. Como se as estrelas fossem pregos numa abóbada fechada."

ESCLARMONDE (silêncio breve; ela observa o rosto de Aimeric com assombro contido):
"Raros são os que sentem as grades antes de morrer, filho. Escuta-me bem: se lutares apenas para trocar quem segura o chicote, o Arconte vencerá mesmo que venças todas as batalhas. A única derrota que o carcereiro não suporta é quando o prisioneiro deixa de acreditar que a cela é tudo o que existe."

[ESCOLHA DO JOGADOR — Grava flag filosófica oculta em EssenceState.gd]

> OPÇÃO A (Eco de Ruptura): "Se este mundo é uma cela, então não basta recusá-la — é preciso derrubar suas muralhas."
  [EFEITO: WorldState.doctrine += 10 | EssenceState.record_echo("act2_philosophy", "shatter_walls")]
  ESCLARMONDE:
  "Tua chama é indomável, Aimeric. Temo apenas que, ao derrubar uma muralha, descubras que outra maior te espera do lado de fora."

> OPÇÃO B (Eco de Despertar): "Então a verdadeira vitória não é tomar o castelo deles... é libertar quem ainda dorme lá dentro."
  [EFEITO: WorldState.doctrine -= 10 | WorldState.alignment += 10 | EssenceState.record_echo("act2_philosophy", "awaken_within")]
  ESCLARMONDE:
  "Guarda essa lucidez quando a fumaça subir sobre Montségur. Nenhum fogo pode queimar aquilo que finalmente acordou."
```

---

### Cena 2.3 — Clímax e “Derrota Falsa”: A Queda do Rochedo de Montségur (Fim do Ato II)
- **Local:** `InterludeRoom_Montsegur_Precipice.tscn` (Madrugada gelada de 16 de março; tochas do exército real cobrem todo o vale abaixo; neve fina misturada a cinzas)
- **Contexto:** Mesmo após o jogador derrotar o comando de Montclair no mapa, um exército esmagador (a Coroa + a Inquisição) fecha o cerco final sobre o rochedo — espelhando o episódio real de [março de 1244](https://fr.wikipedia.org/wiki/Si%C3%A8ge_de_Monts%C3%A9gur), quando quatro *Bons Hommes* desceram o penhasco à noite levando um tesouro/manuscrito oculto.

```text
[CENÁRIO: Beira do precipício sul de Montségur. Quatro figuras encapuzadas descem silenciosamente por cordas na neblina, carregando um pequeno estojo de couro selado. Os portões da barbacã acima começam a ceder sob os trabucos.]

PIERRE-ROGER (ferido, apoiado na espada):
"Os quatro já alcançaram a mata do Sabarthès. O que quer que estivesse naqueles pergaminhos saiu da montanha. Agora só restamos nós — e a fogueira lá embaixo."

ESCLARMONDE (caminhando serenamente na direção da claridade das tochas):
"Não tenham medo do que se apaga. Quando a porta se fechar, lembrem-se apenas de que não pertencemos às pedras que desabam."

[VARIAÇÃO AUTOMÁTICA CONFORME WorldState.doctrine]

[SE WorldState.doctrine >= 0 — Linha Revolucionária]
AIMERIC (erguendo a lâmina diante da brecha em chamas):
"Então que os senhores do norte paguem por cada palmo desta rocha. Se a história deles vai apagar o nosso nome, que jamais esqueçam o preço da nossa recusa!"

[SE WorldState.doctrine < 0 — Linha Pacifista]
AIMERIC (baixando a espada e colocando-se entre os soldados que avançam e os civis desarmados):
"Nenhuma lâmina a mais esta noite. Podem tomar o rochedo, podem levantar suas fogueiras — mas não levarão a nossa obediência."

[EFEITO VISUAL EM GODOT 4: A tela não corta para sangue. O clarão alaranjado das chamas e da neblina se expande lentamente até virar um branco geométrico frio por 0,3 segundos — imperceptível como "glitch", parecendo apenas ofuscamento — enquanto o som dos sinos medievais se distorce suavemente até virar o zumbido grave de artilharia distante.]

NARRADOR DA CRÔNICA (texto em pergaminho escurecido):
"Em dezesseis de março, o último rochedo das Terras d'Oc silenciou. Os cronistas do norte escreveram que a rebelião fora extinta e que o nome de Aimeric de Val-Clair se perdeu entre as cinzas de Montségur."

[TELA DE TRANSIÇÃO — DERROTA FALSA]
"FIM DA CRÔNICA II — A RESISTÊNCIA CAIU."
(Após 4 segundos de silêncio, o pergaminho desaparece. Som de chuva pesada em aço e apito de trincheira. O menu muda totalmente para estética de papel-jornal e metal oxidado: ATO III.)
```

