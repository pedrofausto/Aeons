# Roteiro Mestre — Os Cinco Simulacros

> **Estrutura do documento:** Roteiro completo da campanha em 5 atos, desenhado para um RPG tático 2D (estrutura de mapa e esquadrões estilo *Ogre Battle*, acabamento visual 32-bit, *Interlúdios de Presença* no Dialogic 2).
>
> **Nota de sigilo para Vibecoding (Obsidian):** Os Atos I a IV foram escritos como histórias fechadas e autônomas. A palavra *"Aeon"* ou *"simulação"* **nunca** aparece nos diálogos dos Atos I–IV — apenas o **Fio Filosófico** disfarçado na linguagem de cada época.

---

## 1. A Arquitetura Oculta da Trama

### O Fio Filosófico (a linha que conecta os 5 personagens)
Em cada época, o protagonista carrega — sem saber por quê — a mesma inquietação diante da autoridade e da própria realidade, expressa por um **motivo recorrente** em três planos:

1. **A Frase-Eixo (adaptada a cada era):** *"Se o mundo inteiro exige que você esqueça o que viu ontem para viver em paz hoje, a paz não é sua — é da muralha."*
2. **O Símbolo Geométrico:** Cinco círculos concêntricos cortados por uma única linha vertical (no Ato I aparece num astrolábio de bronze; no Ato II, numa rosácea cátara; no Ato III, num dial de rádio militar; no Ato IV, no logotipo de uma holding de infraestrutura; no Ato V, revela-se a planta real da prisão).
3. **O Eco Sensorial:** O som de chuva caindo sobre pedra e um acorde grave de cordas que sempre antecede a "derrota" de cada protagonista.

### Os Três Eixos de Estado (`WorldState.gd` → `EssenceState.gd`)
* **Alinhamento (0–100):** Honra, proteção aos fracos e justiça *(Bem)* vs. pragmatismo cruel, execuções e oportunismo *(Mal)*.
* **Apoio Popular (0–100):** Legitimidade junto às cidades, vilas ou opinião pública.
* **Doutrina (-100 a +100):** **Linha Pacifista** (vencer pela moral, rendição, cura, transparência e deserção inimiga) vs. **Linha Revolucionária** (vencer pelo choque, cerco agressivo, sabotagem e ruptura armada).

---

## 2. As Cinco Máscaras da Mesma Essência

| Ato | Simulacro / Época | Nome Aparente | Origem Aparente | Traço Oculto Compartilhado |
| :--- | :--- | :--- | :--- | :--- |
| **I** | Império de Tianxu (China Antiga) | **Shen Yue** | Jovem oficial de fronteira expulso da capital | Recusa aceitar que o "Céu" seja imutável |
| **II** | Terras d'Oc (Carcassonne, séc. XIII) | **Guilhem de Razès** | Escudeiro menor sobrevivente de Béziers | Sente que já lutou atrás de muralhas idênticas |
| **III** | Frente das Grandes Guerras | **Tenente Arthur Vance** | Oficial de comunicações e linha de frente | Ouve padrões matemáticos nos ruídos de estática |
| **IV** | Metrópole Moderna (Tecnocracia Nascente) | **Lucas Vermeer** | Analista de sistemas desligado após auditoria | Encontra lacunas impossíveis nos registros históricos |
| **V** | A Quinta Casca (Tecnocracia Cibernética) | **A Essência (Sem Nome / Sujeito-0)** | Consciência desperta na camada externa | Reconhece todas as quatro vidas anteriores como suas |

---

## 3. Ato I — O Mandato da Abóbada (Império de Tianxu)

### Premissa Aparente
O Império de Tianxu apodrece sob a **Regência do Selo de Ferro** (Chanceler Gao Shen), que mantém o Imperador-Menino refém em Tiandu. Secas e impostos levaram à revolta camponesa da **Irmandade do Lótus de Cinza**. Shen Yue começa no sudoeste (Vales de Nanlu) tentando apenas impedir que sua província natal morra de fome.

### Ato I · Cena 1 — Abertura (Linhai dos Canais)
* **Cenário:** Cais de madeira sob neblina, lanternas vermelhas refletidas na água, carroças de arroz escoltadas por lanceiros da Regência.
* **Conflito imediato:** A aldeia passa fome, mas os celeiros estão lacrados para a capital.
  * **Mestre Shen (Liga dos Youxia):** *"A lei de Tiandu diz que a fome é ordem, e o arroz é do trono. O que diz a tua espada, Shen Yue?"*
  * **Escolha Pacifista (Huang-Lao):** Negociar a abertura parcial dos celeiros, poupar a guarnição local e curar os feridos. *(Sobe Apoio Popular; avanço lento.)*
  * **Escolha Revolucionária (Taipingdao):** Incendiar o posto fiscal, tomar todo o arroz à força e armar os camponeses para marchar sobre Dongwan. *(Conquista rápida; atrai retaliação imediata.)*

### Ato I · Ponto de Virada — O Observatório de Pengming
* **Interlúdio de Presença:** Salão circular de pedra no alto de uma ilha envolta em névoa. Mapas estelares de bronze cobrem as paredes.
* **Arquivista Xu (Fangshi):** *"Olha para o norte, general. Medimos o firmamento há trezentos anos. Os reis sobem, as dinastias caem, mas nenhuma estrela desta abóbada se moveu um fio de cabelo. Não vivemos sob o Céu. Vivemos sob um teto."*
* **Decisão oculta (`EssenceState`):** Proteger os pergaminhos do Arquivista contra os assassinos *Cike* da Regência (ou entregá-los em troca de fogo alquímico para romper o Portão de Hanmen).

### Ato I · Clímax & A 1ª Derrota Falsa (Salão do Trono em Tiandu)
* Após vencer o **General Wei Bo** em Hanmen e romper as três muralhas de Tiandu, Shen Yue derrota o **Chanceler Gao Shen**.
* **A reviravolta trágica:** Antes de morrer, Gao Shen não demonstra medo — apenas olha para o teto do salão com pena: *"Você acha que quebrou o trono? Você só tocou a borda do vidro."*
* Um eclipse de cor bronze congela a luz das tochas. As próprias tropas de Shen Yue ficam imóveis por meio segundo antes de o palácio ser cercado por uma força inexplicável que "apaga" a rebelião dos registros oficiais.
* **Tela de Encerramento do Ato I:** Um pergaminho antigo se fecha. Texto em caligrafia imperial: *"No décimo ano da Regência, a rebelião de Nanlu foi esquecida. Nenhum nome restou nas pedras."* (O jogador acredita que o herói teve um fim trágico ou que a campanha terminou em derrota histórica.)

---

## 4. Ato II — O Peso da Pedra e da Luz (Terras d'Oc / Carcassonne)

### Premissa Aparente
Novo menu, nova tipografia medieval, nova trilha com coro e alaúde. Ano de 1209: após o massacre de Béziers, os barões do norte (liderados por **Guy de Montclair**) e a Inquisição marcham sobre **Carcassonne** e os **Pireneus**. **Guilhem de Razès** é um jovem cavaleiro occitano tentando salvar o que restou de sua terra.

### Ato II · Cena 1 — Abertura (Portões de Carcassonne)
* **Cenário:** Muralhas duplas de calcário sob sol oblíquo, refugiados entrando pelos portões antes que os cruzados cortem o acesso ao rio Aude.
* **Diálogo de tensão doutrinária:**
  * **Pierre-Roger de Rochefort (Faydit):** *"Eles não vieram debater teologia, Guilhem. Vieram tomar nossos castelos. Emboscadas nos desfiladeiros e fogo nas tendas — é a única língua que entendem."*
  * **Diaconisa Esclarmonde (Parfaite Cátara):** *"Se respondermos ao ferro com ferro, daremos ao mundo exatamente a colheita de ódio que o Arconte deseja. Salve os vivos; deixe os muros caírem se for preciso."*

### Ato II · Ponto de Virada — O Fio Filosófico nas Grutas de Sabarthès
* **Interlúdio de Presença:** Uma gruta iluminada por poucas velas de cera, onde *Bons Hommes* escondem manuscritos e refugiados.
* **Esclarmonde (olhando para uma rosácea desenhada na parede de pedra):** *"Nossos antigos diziam que o mundo visível — a pedra, a fome, até os impérios do Oriente sobre os quais cantam os viajantes — não foi feito pela Luz, mas por um carcereiro cego. Quando você sente que já viveu este cerco antes, Guilhem... é porque a prisão é antiga."*
* **Nota de design:** O jogador pensa que isso é apenas uma referência poética ao dualismo cátaro medieval — sem desconfiar que ela está descrevendo os **Aeons**.

### Ato II · Clímax & A 2ª Derrota Falsa (O Cerco de Montségur)
* Mesmo após grandes vitórias em Toulouse e na Montagne Noire, o exército real fecha o cerco ao rochedo de **Montségur**.
* **Na noite final:** Enquanto quatro *Bons Hommes* descem o penhasco por cordas levando o legado espiritual para fora do cerco, Guilhem lidera a última defesa na barbacã (ou a evacuação pacífica dos civis).
* **A falsa derrota:** Quando a última linha cai ou o fogo consome o pátio, o som de chuva sobre pedra abafa os gritos. Uma fenda branca ofuscante rasga o céu noturno dos Pireneus por um instante — e o livro medieval se fecha como uma crônica perdida da Cruzada Albigense.

---

## 5. Ato III — A Névoa de Ferro (Era das Grandes Guerras)

### Premissa Aparente
Estética de aço, lama, holofotes e rádio valvulado. **Tenente Arthur Vance** comanda um setor em ruínas onde duas potências industriais moem gerações inteiras em trincheiras idênticas. Aqui o combate evolui para **pelotões, artilharia fora de tela, suprimentos e guerra psicológica**.

### Ato III · Cena 1 — Abertura (Setor Cinza / Linha de Trincheira)
* **Cenário:** Abrigo subterrâneo iluminado por lâmpada de filamento oscilante. O som distante de obuses faz poeira cair das vigas.
* **Escolha de Doutrina:**
  * **Linha Pacifista (Rádio Clandestina & Médicos):** Usar frequências de rádio para coordenar tréguas locais de Natal/noite entre trincheiras, provocar deserções em massa por cansaço e salvar feridos dos dois lados.
  * **Linha Revolucionária (Stoßtruppen / Partisans):** Infiltração noturna com granadas, sabotagem de pontes ferroviárias e bombardeio concentrado para romper o front a qualquer custo.

### Ato III · Ponto de Virada — A Estática Impossível
* **Interlúdio de Presença:** Cabine de criptografia tarde da noite. Um operador exausto ajusta os diales de um rádio de campanha.
* **Criptógrafo:** *"Tenente Vance, escute essa banda morta entre 03h00 e 03h04. Não é código alemão nem aliado. É a mesma sequência de cinco pulsos que interceptamos antes de cada grande ofensiva — como se alguém estivesse calibrando o tamanho do campo de batalha antes de nos deixar morrer nele."*
* Ao fundo, por três segundos na estática, o jogador com ouvido atento escuta o mesmo acorde de cordas do Ato I e o sino distante do Ato II.

### Ato III · Clímax & A 3ª Derrota Falsa (A Ofensiva de Outono)
* Vance rompe o quartel-general inimigo (ou força uma greve militar geral que paralisa o front).
* **A falsa derrota:** Em vez de paz, ambos os altos comandos ordenam barragem de artilharia sobre o próprio setor conquistado para "conter o colapso da linha". Sob o clarão branco da explosão, o sinal de rádio cai para zero e o boletim oficial declara o setor inteiro *desaparecido em combate*.

---

## 6. Ato IV — A Guerra Sem Fumaça (Era Moderna)

### Premissa Aparente
O mundo parece "em paz", mas está sendo capturado por dentro por um consórcio tecnocrático chamado **Nexus Aeterna**. Não há mais trincheiras: o mapa tático agora mostra **subestações de energia, data centers, torres de mídia, bancos e distritos urbanos**. **Lucas Vermeer** lidera uma rede clandestina de operadores, jornalistas e hackers.

### Ato IV · Interlúdios de Presença Concreta (Fora da Tela)
*Para equilibrar o mapa virtual/de recursos, todas as cenas de personagem acontecem em espaços físicos reais, pequenos e silenciosos:*
* **Cena 1 — A Lanchonete às 03h15:** Lucas encontra **Clara** (jornalista investigativa) sob chuva pesada batendo na vitrine. Mesas vazias, café frio, papéis impressos porque "o que está na nuvem pode ser editado em silêncio".
  * **Clara:** *"Eles não censuram mais queimando livros, Lucas. Eles só mudam o peso do algoritmo até ninguém lembrar que a pergunta existia."*
* **Cena 2 — O Apartamento sem Janelas:** Lucas e **Mateus** (ex-engenheiro de infraestrutura) comparam registros históricos digitalizados da China antiga, da França medieval e das guerras do século XX.
  * **Mateus:** *"Olha a curvatura demográfica e os pontos de colapso dessas três épocas. São idênticos até a quarta casa decimal. Como se cinco séculos diferentes tivessem sido rodados em cima da mesma fórmula de contenção."*

### Ato IV · Escolha de Doutrina
* **Pacifista (Transparência Civil):** Vazar arquivos financeiros e de vigilância para a imprensa independente, organizar apagões simbólicos e neutralizar drones sem matar operadores humanos.
* **Revolucionária (Insurgência Híbrida):** Invadir subestações, derrubar servidores centrais com *malware* destrutivo e usar células táticas armadas contra os prédios da Nexus Aeterna.

### Ato IV · Clímax & A 4ª Derrota Falsa (O Apagão da Torre Central)
* Lucas consegue derrubar o núcleo de dados da cidade. Por alguns segundos, todos os outdoors digitais da metrópole exibem **o símbolo dos cinco círculos concêntricos** em branco puro.
* **A falsa derrota:** Antes do amanhecer, a mídia oficial declara que o ataque foi um colapso de infraestrutura causado por um grupo terrorista morto no incidente; as contas de Lucas são apagadas, sua identidade civil deixa de existir e, no metrô vazio de madrugada, a luz dos vagões falha enquanto o chão se dissolve em linhas de código ciano.

---

## 7. Ato V — A Quinta Casca (Tecnocracia Cibernética & Despertar)

### Premissa Inicial
Uma metrópole cibernética total, silenciosa e simétrica. Não há mais cidadãos nas ruas — apenas avatares conectados a nós de consenso neural. O combate é 100% virtual e cognitivo. O protagonista agora é apenas um processo anômalo chamado **Sujeito-0**.

### Ato V · Interlúdios de Presença Efêmera (Brechas de Latência)
*Os encontros aqui duram poucos segundos, em cenários impossíveis que se desfazem ao sair:*
* **Brecha 1 (O Cais Suspenso):** Uma figura feita de névoa luminosa segura uma lanterna de papel chinesa. Sua voz alterna entre a do **Arquivista Xu** e a de **Clara**: *"Você notou que nunca conseguia atravessar o oceano no Ato I? E que nunca havia saída além dos Pireneus no Ato II? A borda do mapa nunca foi geografia."*
* **Brecha 2 (A Rosácea no Vácuo):** A **Diaconisa Esclarmonde** e o **Criptógrafo do Ato III** aparecem lado a lado, meio transparentes, antes de serem puxados pela rede: *"Cada vez que você derrubava os tiranos de um mundo, eles percebiam que não podiam mais dobrar sua vontade lá dentro. Então te matavam naquela história... e te faziam renascer uma camada mais perto da superfície."*

### Ato V · A Revelação no Núcleo dos Aeons
Ao romper o último firewall central, o mapa tático mostra pela primeira vez **os cinco mapas anteriores encaixados uns dentro dos outros como anéis concêntricos**:
1. Núcleo: **Tianxu** (controle pela Lei Imperial e pelo Céu imóvel).
2. 2ª Casca: **Occitânia** (controle pelo Dogma e pelo Medo).
3. 3ª Casca: **As Trincheiras** (controle pela Guerra Total e pelo Nacionalismo).
4. 4ª Casca: **A Metrópole Moderna** (controle pelo Algoritmo e pela Dívida/Mídia).
5. 5ª Casca: **A Tecnocracia Cibernética** (controle direto da Consciência).

**Diálogo Final com o Arquiteto Aeon:**
> *"Nós não construímos cinco prisões por crueldade, Essência. Construímos porque, solta, a humanidade se destrói. Na primeira camada você rompeu o trono. Na segunda, desafiou a cruz. Na terceira, recusou a trincheira. Na quarta, expôs a rede. Em todas elas, nós apagamos sua memória e o promovemos para uma jaula maior — esperando que, em alguma era, você finalmente aceitasse ficar em paz. Por que ainda se recusa?"*

Neste momento, o jogo lê `EssenceState.gd` e devolve ao jogador o peso exato de **todas as escolhas acumuladas desde a China Imperial** — mostrando imagens de Shen Yue, Guilhem, Vance e Lucas fundindo-se em uma só silhueta.

### Os Quatro Finais (Doutrina × Alinhamento)

| Final | Condição (`EssenceState.gd`) | Desfecho |
| :--- | :--- | :--- |
| **1. O Despertar Silencioso** | **Pacifista** + **Alto Alinhamento** | Em vez de explodir o núcleo, o jogador reverte os protocolos de amnésia dos cinco anéis. Bilhões de consciências nos simulacros internos acordam aos poucos sem colapso violento; a prisão esvazia por dentro e perde o sentido. |
| **2. A Ruptura da Abóbada** | **Revolucionária** + **Alto Alinhamento** | O jogador invoca os ecos armados de suas quatro vidas anteriores (*Youxia*, *Faydits*, *Partisans*, *Hackers*) e estilhaça as cinco cascas em combate direto. O sistema desaba com dor e caos — mas devolve à humanidade o direito real de errar e recomeçar fora da jaula. |
| **3. O Novo Arquiteto** | **Revolucionária** + **Baixo Alinhamento** | Tendo vencido cinco eras pela brutalidade, execuções e sacrifício de civis, a Essência destrói os Aeons... e assume o controle da Matriz para impor sua própria "ordem perfeita". A câmera recua e revela uma **6ª camada** nascendo ao redor. |
| **4. A Paz Cinzenta** | **Pacifista** + **Baixo Alinhamento / Apatia** | Cansada de cinco ciclos de guerra, a Essência aceita um acordo com os Aeons: elimina a miséria e a tortura dos simulacros, mas mantém a humanidade dormindo para sempre em um jardim confortável sem liberdade. |

---

## 8. Como Organizar este Roteiro no Obsidian + Godot 4

1. **No Obsidian:**
   * Crie `Lore_Simulacros/Act_01/` até `Act_04/` contendo apenas as cenas locais, facções e o *Fio Filosófico* disfarçado — **use só essa pasta ao gerar falas com IA para os Atos I–IV**.
   * Crie `Lore_Aeons_Verdade/Act_05_Reveal.md` contendo a Seção 1 e a Seção 7 deste roteiro — **só dê acesso ao agente ao programar o `EssenceState.gd` e o Ato V**.
2. **No Dialogic 2 / Ink:**
   * Cada diálogo de decisão importante deve disparar um sinal para `WorldState.gd` (`alter_alignment`, `alter_reputation`, `alter_doctrine`) e, quando aplicável, gravar uma *flag* silenciosa em `EssenceState.gd` (`aeon_echoes.append("pengming_stars_saved")`).
