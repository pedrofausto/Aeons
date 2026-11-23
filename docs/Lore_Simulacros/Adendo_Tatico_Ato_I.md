> Versão SEM SPOILERS para gerar diálogos dos Atos I–IV. 0 linha(s)/célula(s) que revelavam o segredo foram omitidas;
> a íntegra está na pasta restrita de verdade em docs/ (proibido usá-la ao escrever diálogos dos Atos I–IV).

Adendo Tático do Ato I — Fichas de Classes e Inimigos Aleatórios (Tianxu)

# Adendo Tático do Ato I: fichas de classes e inimigos aleatórios de Tianxu

Complemento direto (diff) ao Atlas da China Imperial — trazendo exclusivamente o que faltava para equiparar o Ato I ao Ato II: especificações completas de combate 3×2 para todas as classes chinesas (base, promoções por alinhamento e míticas) e a tabela de patrulhas aleatórias nas seis províncias.
   Seis silhuetas-chave do Ato I: do Youxia e do Alabardeiro de Ji até o Fangshi e o Imortal Xian

*[Imagem: Vitrine em pixel art 32-bit de seis classes chinesas do Ato I em um terraço de templo ao crepúsculo: Youxia, Alabardeiro de Ji, Besteiro Nubing, Assassino Cike, Fangshi taoísta e Imortal Xian flutuando sobre névoa]*

 Da esquerda para a direita: Youxia (espadachim errante), Alabardeiro de Ji, Besteiro Nubing, Assassino Cike, Mestre Fangshi e Imortal Xian · Referência visual direta para os sprites do Ato I.

Cada ficha abaixo já nasce no formato da grade 3×2: mudar uma unidade da frente para trás muda o que ela faz em batalha.

Para evitar repetir províncias e facções já descritas no Atlas do Ato I, este documento concentra apenas os dados de combate e encontro que entram direto no Godot 4. Os atributos seguem a escala relativa de **1 a 5 (★)** ou notas S / A / B / C / D para facilitar o balanceamento inicial no arquivo UnitClassData.tres.

O **Alinhamento (ALI)** varia de 0 (implacável) a 100 (honrado), e cada classe reforça naturalmente a **Linha Pacifista** (quebra de moral, cura, defesa) ou a **Linha Revolucionária** (dano explosivo, penetração e velocidade de conquista).

## Fichas das classes marciais: linha de frente, ruptura e precisão

Três linhagens militares inspiradas na organização da China Imperial Han/Qin, com bifurcações claras entre virtude popular e brutalidade mercenária.

| Classe (Linhagem) | Promoção (Nv / ALI) | Perfil de Atributos | Ação na Frente (3×2) | Ação Atrás (3×2) | Terreno & Doutrina |
|---|---|---|---|---|---|
| Fubing / Bubing — Soldado · Base | — Base (Nv 1) — Qualquer ALI | — HP B · ATQ B · DEF B — INT C · AGI B | **2× Corte de Espada** (alvo frontal) | **1× Lançar Dardo** (baixo dano) | Estradas e aldeias · Equilibrado |
| Youxia — Soldado · Bem | — Nv 8+ · ALI 65–100 — Carisma alto | — HP A · ATQ A · DEF A — INT B · AGI S | **3× Espada Justa** (bônus contra unidades de ALI baixo) | **1× Brado de Honra** (restaura Moral do esquadrão + escudo) | Bambu e vilas · **Pacifista / Honra** |
| Buqu Sombrio — Soldado · Mal | — Nv 8+ · ALI 0–35 — Clã mercenário | — HP S · ATQ S · DEF B — INT D · AGI B | **3× Golpe Brutal** (ignora parte da defesa; drena moral inimiga) | **1× Intimidar** (reduz defesa física inimiga) | Cercos e estradas · **Revolucionária** |
| Alabardeiro de Ji — Lanceiro · Base | — Base (Nv 1) — Qualquer ALI | — HP A · ATQ B · DEF A — INT D · AGI C | **2× Estocada de Ji** (bônus contra cavalaria) | **1× Finco de Alabarda** (alcance médio) | Desfiladeiros (Hanmen) · Defesa |
| Catafractário — Lanceiro · Bem | — Nv 10+ · ALI 60–100 — Requer Montaria | — HP S · ATQ A · DEF S — INT C · AGI B | **3× Carga Blindada** (alta resistência física e quebra de postura) | **1× Proteger Flanco** (absorve dano de aliado ferido) | Planícies (Zhonghe) · **Muro Tático** |
| Saqueador das Estepes — Lanceiro · Mal | — Nv 10+ · ALI 0–40 — Pacto de Beisha | — HP A · ATQ S · DEF C — INT D · AGI S | **3× Lança Incendiária** (dano alto + saqueia ouro extra) | **2× Flecha de Ferro** (ataca enquanto recua) | Estepes (Beisha) · **Revolucionária** |
| Besteiro Nubing — Arqueiro · Base | — Base (Nv 1) — Qualquer ALI | — HP C · ATQ B · DEF C — INT C · AGI B | **1× Coronhada** (vulnerável na frente) | **2× Disparo de Besta** (perfura armadura leve) | Muralhas e colinas · Retaguarda |
| Arqueiro Montado — Arqueiro · Bem | — Nv 9+ · ALI 55–100 — Fronteira | — HP B · ATQ A · DEF C — INT B · AGI S | **2× Tiro à Queima-Roupa** (alta esquiva) | **3× Saraivada Precisa** (mira em unidades feridas ou aéreas) | Estepes e estradas · Alta mobilidade |
| Assassino Cike — Arqueiro · Mal | — Nv 9+ · ALI 0–35 — Adaga Oculta | — HP C · ATQ S · DEF D — INT B · AGI S+ | **3× Adagas Gêmeas** (alta chance de crítico) | **2× Lâmina Envenenada** (ataca diretamente o **líder** na fila de trás) | Noite e cidades · **Revolucionária** |

## Fichas das classes místicas, de suporte e míticas (folclore chinês)

Aqui entram os Fangshi, o taoismo Han, os xamãs Wu e as classes secretas que dão o toque lendário ao Ato I — todas projetadas para operar com força máxima na fileira traseira.

| Classe (Linhagem) | Promoção / Acesso | Perfil de Atributos | Ação na Frente (3×2) | Ação Atrás (3×2) | Função Estratégica |
|---|---|---|---|---|---|
| Fangshi — Mago · Base | — Base (Nv 1) — Qualquer ALI | — HP D · ATQ D · DEF D — INT A · AGI B | **1× Talismã de Choque** (curto alcance) | **2× Fogo dos Cinco Elementos** (alvo único ou fila) | Dano mágico contra armaduras pesadas |
| Daoshi (Mestre do Dao) — Mago · Bem | — Nv 10+ · ALI 60–100 — Pergaminho Dao | — HP C · ATQ D · DEF C — INT S · AGI A | **1× Selo de Contenção** (reduz ataque inimigo) | **2× Tempestade de Vento/Fogo** (atinge **todo** o esquadrão inimigo) | Controle de campo e limpeza de hordas |
| Alquimista Sombrio — Mago · Mal | — Nv 10+ · ALI 0–35 — Cinábrio Puro | — HP C · ATQ D · DEF D — INT S+ · AGI B | **1× Vapor Tóxico** (envenena frente) | **2× Elixir Explosivo** (dano altíssimo em área + reduz moral) | Poder bruto com custo de alinhamento |
| Médico Imperial — Clérigo · Base | — Base (Nv 1) — ALI 40–100 | — HP C · ATQ D · DEF C — INT B · AGI B | **1× Bastão de Ervas** | **2× Acupuntura / Cura** (recupera HP do aliado mais ferido) | Sustentação em marchas longas |
| Sacerdote Taoísta — Clérigo · Bem | — Nv 9+ · ALI 70–100 — Mestres Celestiais | — HP B · ATQ D · DEF B — INT S · AGI B | **1× Purificação** (dano alto em mortos-vivos/espíritos) | **2× Cura em Área + Calma** (cura todos + sobe Moral) | Pilar absoluto da **Linha Pacifista** |
| Xamã Wu — Clérigo · Mal | — Nv 9+ · ALI 0–40 — Tambor Ritual | — HP C · ATQ C · DEF C — INT S · AGI A | **2× Dança do Transe** (drena energia) | **2× Maldição dos Ancestrais** (petrifica ou paralisa alvo) | Neutraliza tanques e chefes perigosos |
| Conselheiro Yuefu — Bardo · Base | — Base (Nv 1) — Qualquer ALI | — HP C · ATQ D · DEF C — INT A · AGI B | **1× Leque de Ferro** | **1× Melodia de Guqin** (aumenta precisão e moral aliada) | Eleva Apoio Popular ao libertar cidades |
| Estrategista Junshi — Bardo · Bem | — Nv 11+ · ALI 60–100 — Tratado Militar | — HP B · ATQ C · DEF B — INT S+ · AGI A | **2× Contra-Formação** | **1× Ordem de Mestre** (concede **+1 ação extra** ao esquadrão se for o líder) | Equivalente à Princess de Ogre Battle |
| Intrigante Legalista — Bardo · Mal | — Nv 11+ · ALI 0–35 — Selo da Corte | — HP C · ATQ C · DEF C — INT S · AGI A | **1× Decreto Severo** | **2× Semear Discórdia** (derruba drasticamente a Moral inimiga) | Força rendições ou pânico em massa |
| Imortal Xian — Mítica · Secreta | — Item: Elixir de Pengming — ALI 85–100 | — HP A · ATQ A · DEF A — INT S+ · AGI S+ | **3× Espada de Nuvem** (ignora terreno no mapa — **voo**) | **2× Luz do Dao** (dano espiritual em todos + remove debuffs) | Classe lendária da Ilha de Pengming |
| Espírito Huli Jing — Mítica · Secreta | — Encontro Secreto — ALI 0–30 | — HP C · ATQ B · DEF C — INT S+ · AGI S+ | **2× Garras Ilusórias** | **2× Encanto das Nove Caudas** (enfeitiça inimigos para atacarem aliados) | Sabotagem mental pura na retaguarda |
| Jiangshi das Tumbas — Mítica · Morto-Vivo | — Item: Talismã Quebrado — ALI 0–20 | — HP S+ · ATQ A · DEF S — INT D · AGI D | **2× Garra de Qi Drenado** (imune a golpes físicos comuns) | **1× Sopro Gélido** | Tanque imortal (só cai para fogo/taoístas) |

## Inimigos aleatórios, patrulhas de mapa e encontros folclóricos de Tianxu

Espelhando a tabela do Ato II, cada província da China Imperial gera patrulhas vivas com comportamentos distintos de dia e de noite — incluindo armadilhas morais fiéis ao Chaos Frame de Ogre Battle.

| Tipo de Encontro | Província & Horário | Composição do Esquadrão | Dinâmica Tática e Moral |
|---|---|---|---|
| **Bandidos do Bambu** — Comum · Dia/Noite | Vales de Nanlu e estradas de Dongwan | 2 Soldados desertores + 2 Besteiros Nubing + 1 Saqueador | Emboscada rápida em terreno de bambu; bom encontro inicial para ganhar XP e proteger aldeias. |
| **Coletor da Regência** — Frequente · Dia | Rotas entre Zhonghe, Dongwan e Nanlu | 2 Alabardeiros de Ji + 1 Intrigante Legalista + 1 Besteiro | Transporta impostos confiscados de camponeses; interceptar e **devolver o grão/ouro** sobe Apoio Popular e Alinhamento; ficar com tudo financia seu exército mas baixa a reputação. |
| **Ala Radical do Lótus de Cinza** — Ocasional · Sul | Arredores de Linhai dos Canais | 3 Camponeses armados + 1 Xamã Wu | **Armadilha moral de Ogre Battle:** têm nível mais baixo; exterminá-los derruba o Alinhamento, mas vencê-los por **Moral (Linha Pacifista)** permite absorvê-los sem massacre. |
| **Batedores de Beisha** — Rápido · Dia | Estepes de Beisha e Muralha do Norte | 2 Saqueadores das Estepes + 2 Arqueiros Montados | Altíssima velocidade no mapa; fogem de combates desfavoráveis e atacam seus esquadrões sem proteção de alabardeiros. |
| **Tigres e Feras de Hanmen** — Noturno · Montanhas | Desfiladeiro de Hanmen e trilhas nevadas | Feras de montanha e javalis gigantes | Combate natural neutro (não afeta Alinhamento nem Apoio Popular); excelente para treinar unidades fracas sem penalidade. |
| **Cortejo de Jiangshi** — Raro · Noite / Névoa | Tumbas antigas de Hanmen e costa de Pengming | 2 Jiangshi na frente + 1 Xamã Wu ou Alquimista atrás | Imunes a dano físico comum; forçam o jogador a levar **Sacerdotes Taoístas** ou **Fangshi** no esquadrão. Dão o item Talismã Quebrado. |
| **Santuário da Raposa (Huli Jing)** — Secreto · Pengming | Ilha de Pengming (sob névoa noturna) | 1 Huli Jing + 2 Guardiões Ilusórios | Encontro folclórico raro: pode ser derrotada por um item mítico ou recrutada se o esquadrão tiver Alinhamento baixo e um Fangshi como líder. |

“Com estas três tabelas, o Ato I inteiro já tem dados suficientes para gerar todos os arquivos .tres de unidades e encontros no Godot 4.”

Ao passar este adendo para o agente de vibecoding, peça para ele criar dois tipos de Resource em GDScript: UnitClassData.tres (campos: class_id, min_level, ali_range, front_skill, back_skill, terrain_bonus) e EncounterTable.tres (campos: province_id, time_of_day, squad_composition, moral_event_id). Assim, o mesmo código que rodar os Bandidos do Bambu no Ato I vai rodar os Routiers no Ato II sem alterar uma linha do motor.

## Referências Históricas e de Mecânica

- Wikipedia — Military history of China before 1912 (Fubing, Buqu, bestas Nubing e táticas Han)
- World History Encyclopedia — Cavalry in Ancient Chinese Warfare (catafractários e arqueiros montados)
- Wikipedia — Youxia (ética moísta e cavaleiros errantes chineses)
- Wikipedia — Jing Ke (tradição dos assassinos Cike)
- Wikipedia — Fangshi (alquimistas, astrônomos e busca pelos imortais Xian)
- Wikipédia — Huang-Lao (taoismo político e filosófico na dinastia Han)
- Wikipedia — Wu (xamanismo antigo chinês)
- Ogre Battle Saga Wiki — Alignment & Promotion Mechanics
