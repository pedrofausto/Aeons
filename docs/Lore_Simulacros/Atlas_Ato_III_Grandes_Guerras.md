> Versão SEM SPOILERS para gerar diálogos dos Atos I–IV. 4 linha(s)/célula(s) que revelavam o segredo foram omitidas;
> a íntegra está na pasta restrita de verdade em docs/ (proibido usá-la ao escrever diálogos dos Atos I–IV).

Atlas do Ato III — A Frente de Cinza (Era das Grandes Guerras)

# A Frente de Cinza: atlas industrial, frentes de guerra e resistência do Ato III


*[Imagem: Mapa-múndi tático em pixel art 32-bit das frentes do Ato III mostrando porto naval ao norte, terra de ninguém com trincheiras e ferrovia no centro, polo industrial a oeste, florestas nevadas de partisans a leste e cidadela de comando de concreto ao sul]*

  Ferrovias, portos navais, trincheiras e florestas nevadas transformam o mapa em um quebra-cabeça de logística e desgaste Conceito cartográfico do Ato III · Norte (Porto Naval), Oeste (Polo Industrial), Centro (Terra de Ninguém), Leste (Florestas Partisans) e Sul (Cidadela de Concreto)

No Ato III, o inimigo já não tem rosto de imperador ou inquisidor: ele é uma máquina industrial que tritura soldados em escala.

Depois da queda trágica de Montségur no Ato II, o jogador abre os olhos em um abrigo de lama sob chuva de artilharia — acreditando que controla um jovem tenente de infantaria em uma guerra continental entre dois blocos industriais. O salto tecnológico muda imediatamente a sensação do jogo: **a logística vira a arma principal**.

No mapa, capturar estações ferroviárias e pontes mantém o suprimento dos seus pelotões; perder uma linha de trem deixa os esquadrões sem munição de artilharia. E a guerra deixa de ser só sobre vencer batalhas — ela passa a ser sobre **quebrar a máquina de propaganda** que convence milhões de jovens a marcharem para o moedor de carne.

## Os cinco setores da frente: logística, artilharia e combate de desgaste

Cada região do teatro de operações acima introduz uma mecânica de guerra moderna sobre o mesmo núcleo de Ogre Battle em Godot 4.

| Setor (Posição) | Pontos-Chave (MapNode) | Terreno & Regra Tática | Interlúdios de Presença | Papel na Campanha |
|---|---|---|---|---|
| Terra de Ninguém — Centro · Início | **Trincheira Setor 4**, Ponte Ferroviária Quebrada, Cratera do Sino | Lama, arame farpado e fogo cruzado: exige sapadores/pioneiros ou Stoßtruppen para abrir brechas sem dizimar o pelotão. | Abrigos subterrâneos, enfermaria de campanha e vigília no parapeito. | Abertura do ato: sobreviver à carnificina inicial e formar uma companhia autônoma. |
| Polo Industrial de Eisenbruck — Oeste · Suprimentos | **Fábricas de Aço**, Entroncamento Ferroviário, Ponte Metálica | Ruas urbanas e trilhos: controlar as fábricas multiplica a receita diária de munição e libera blindados leves. | Porões operários, galpões bombardeados e rádio clandestina. | Coração logístico da frente; sabotar ou capturar decide o ritmo da guerra. |
| Florestas Nevadas do Leste — Leste · Resistência | **Acampamento Partisan**, Passo dos Pinheiros, Estação de Rádio Oculta | Neve densa e mata fechada: inutiliza tanques pesados e dá vantagem total a franco-atiradores, Partisans e emboscadas. | Cabanas de madeira camufladas, fogueiras sem fumaça e hospitais secretos. | Base dos movimentos de resistência civil e ponto de recrutamento das unidades clandestinas. |
| Baía Naval de Nordhaven — Norte · Bloqueio | **Porto de Nordhaven**, Casamatas Costeiras, Farol de Ferro | Bunkers de concreto e bombardeio naval de apoio; controlar o farol e o porto abre rotas de suprimento externo. | Docas sob neblina, convés de navio-hospital e torre de sinais. | Frente estratégica opcional que pode encurtar o cerco final se tomada a tempo. |
| Cidadela de Comando do Sul — Sul · Clímax | **Bunker Supremo**, Bateria de Holofotes, Sala de Criptografia | Fortaleza de concreto armado sob barragens constantes; exige artilharia coordenada, sabotagem ou motim interno. | Túneis de concreto, salas de mapa de guerra e transmissores de rádio. |  [omitido] |

  Holofotes, pontes ferroviárias destruídas e biplanos silenciosos definem a atmosfera visual do Ato III

*[Imagem: Trincheira de madeira e sacos de areia ao crepúsculo diante de uma ponte ferroviária de pedra destruída, com dois holofotes brancos cortando o céu escuro e a silhueta de um biplano planando silenciosamente]*

 Referência de iluminação 2D para o Ato III · Feixes de holofote em shader 2D, clarões de artilharia ao fundo e luz quente de bunker em PointLight2D.

## Facções e poderes em guerra: estados-maiores, Partisans, espiões e desertores

Neste ato, os dois grandes impérios que se enfrentam são igualmente desumanos — obrigando o jogador a decidir se obedece à máquina, se se junta à sabotagem revolucionária ou se organiza uma rede humanitária de tréguas e deserção.

| Facção | Papel na Guerra | Liderança / Núcleo | Perfil Militar | Relação com o Jogador |
|---|---|---|---|---|
| Alto Comando do Diretório de Aço — Antagonista Central | Estado-maior tecnocrático embrionário que trata vidas como estatística de desgaste. | **Marechal Von Krell** Cidadela de Comando do Sul | Artilharia pesada, blindados, comissários disciplinares e armas químicas experimentais. |  [omitido] |
| Rede de Sabotagem Irregular — Aliado Revolucionário | Células de sabotadores e espiões inspiradas na SOE / Resistência. | **Agente “Corvo” (Clara)** Florestas Nevadas do Leste | Explosivos, franco-atiradores, corte de ferrovias e tropas de infiltração rápida. | Fortalece a **Linha Revolucionária**, permitindo explodir pontes e depósitos antes das batalhas. |
| Corpo Humanitário & Rádio da Trégua — Aliado Pacifista | Médicos, capelães, fotógrafos do Signal Corps e operadores de rádio clandestina. | **Dr. Julian & Voz da Névoa** Hospitais de campanha e rádio | Cura pesada, transmissões que zeram a Moral inimiga e provocam tréguas/deserções em massa. | Coração da **Linha Pacifista**: transforma pelotões inimigos exaustos em aliados civis. |
| Esquadrilha das Bruxas da Noite — Aliado Mítico / Secreto | Pilotos voluntárias em biplanos silenciosos inspiradas no 588º Regimento (Nachthexen). | **Comandante Nadya** Pista oculta no Leste | Unidade aérea rara que ignora trincheiras/terreno e bombardeia holofotes à noite. | Desbloqueada ao proteger vilas civis e manter alto Apoio Popular no setor leste. |
| Sindicato de Contrabandistas de Guerra — Neutro / Mercenário | Atravessadores de morfina, combustível, peças de rádio e armas entre as linhas. | **O Comerciante de Nordhaven** Porto e fábricas | Mercenários armados com equipamento misto e caminhões de carga. | Vendem melhorias raras em troca de fundos ou favores moralmente duvidosos. |

## Inimigos aleatórios, patrulhas de frente e encontros raros

| Tipo de Encontro | Onde Aparece | Composição do Pelotão | Dinâmica Tática e Moral |
|---|---|---|---|
| **Patrulha de Choque (Arditi / Stoßtruppen)** — Frequente · Noite | Terra de Ninguém e trincheiras centrais | 2 Tropas de Assalto + 1 Lança-Chamas + 1 Sapador | Altíssimo dano frontal; exige contenção à distância ou quebra de flanco. |
| **Comboio Ferroviário Blindado** — Dinâmico · Trilhos | Linha entre Eisenbruck e a Cidadela do Sul | Vagão-metralhadora + Observador de Artilharia | Percorre o mapa em tempo real; interceptá-lo corta suprimentos do chefe do ato. |
| **Recrutas Jovens Perdidos na Névoa** — Ocasional · Chuva/Névoa | Crateras e estradas vicinais | 4 Fuzileiros de nível baixo com Moral abalada | **Teste moral:** aniquilá-los despenca Alinhamento; usar Rádio/Capelão permite rendição pacífica e ganho de Apoio Popular. |
| **Equipe de Guerra Química** — Raro · Setor Industrial | Arredores das fábricas de Eisenbruck | 2 Guardas de Máscara + 2 Químicos de Guerra | Aplica dano contínuo em área; derrotá-los rende máscaras e equipamentos raros. |
| **O Espectro da Névoa (Lenda de Trincheira)** — Secreto · Meia-Noite | Ponte Quebrada sob neblina fechada | Pelotão silencioso sem insígnia com uniformes anacrônicos |  [omitido] |

“Os criptógrafos captam uma transmissão que não pertence a nenhum dos dois exércitos: um pulso matemático frio, idêntico em ambos os lados da fronteira, calculando exatamente quantos homens precisam morrer para manter o medo aceso.”

**O fio filosófico no Ato III:** enquanto no Ato I o controle era o *Mandato do Céu* e no Ato II era o *Dogma da Fogueira*, aqui ele se revela como **a Burocracia da Guerra Perpétua**. Pela primeira vez, o protagonista suspeita que os generais de ambos os lados obedecem à mesma lógica oculta — preparando psicologicamente o salto para a vigilância silenciosa do Ato IV.

**A “Derrota Falsa” na Cidadela do Sul:** ao invadir a sala de criptografia ou provocar um grande motim de paz que interrompe a frente inteira, os transmissores disparam um clarão eletromagnético/explosão de bunker que soterra o posto de comando. O jornal da manhã anuncia que o incidente foi abafado como “acidente de munição” e a guerra prossegue. A tela apaga — e o jogador acorda diante das telas azuis e da chuva de neon da metrópole do **Ato IV**, convencido de que a resistência da geração anterior também fracassou.

## Referências Históricas

- Wikipedia — Stormtroopers / Stoßtruppen (táticas de infiltração na I Guerra Mundial)
- Wikipedia — Arditi (tropas de assalto de trincheira na I Guerra Mundial)
- Wikipedia — Special Operations Executive (sabotagem e resistência atrás das linhas na II Guerra)
- Holocaust Encyclopedia — U.S. Army Signal Corps (comunicações e documentação fotográfica de guerra)
- The National WWII Museum — Night Witches (588º Regimento de Bombardeio Noturno / Nachthexen)
