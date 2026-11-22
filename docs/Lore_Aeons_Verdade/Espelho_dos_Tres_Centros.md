> Convertido do documento original de world building (HTML) para Markdown. Imagens omitidas.

O Espelho dos Três Centros — Sistema de Escolhas, Questionário e Equilíbrio

# O jogo não premia o bem nem o mal — ele testa se você consegue enxergar o próprio automatismo

Arquitetura psicológica e mecânica do sistema de escolhas dos Cinco Simulacros: criação de personagem sem rótulos, questionário inicial dos Três Centros (Racional, Passional e Impulsivo/Ativo) e dilemas cinzentos que penalizam o reforço cego do próprio perfil.

Os Aeons não precisam corromper você para mantê-lo preso — basta deixar você repetir quem você já é.

Na maioria dos RPGs, o jogador escolhe uma persona no minuto 1 (“vou jogar de frio/racional” ou “vou jogar de herói emotivo”) e clica automaticamente na mesma resposta por 40 horas. O seu sistema inverte essa lógica: **a rota macro dos cinco atos é quase idêntica nos dois extremos** — você sempre desafia o poder local e sempre é manipulado pelos Aeons —, mas o seu destino final depende de **autoconhecimento**.

O questionário inicial identifica qual dos três centros governa o jogador por padrão: **Racional**, **Passional/Emotivo** ou **Impulsivo/Ativo** (ou uma mistura). A partir daí, o jogo age como um espelho incômodo: ele oferece escolhas cinzentas, sem certo ou errado óbvio, onde **repetir o seu próprio padrão dominante aprofunda a captura pelos Aeons**, enquanto arriscar respostas dos centros opostos constrói o equilíbrio necessário para romper a prisão no Ato V.

    Somente quem converge para o centro escapa dos Aeons; qualquer extremo cristalizado transforma o jogador no próximo carcereiro
  Geometria interna de EssenceState.gd · O jogador nasce deslocado em direção ao seu perfil inicial no questionário; cada escolha o puxa para um vértice (reforço de padrão) ou em direção ao centro (integração dos três centros).

## Criação do personagem: identidade misteriosa e o eco visual oculto

Na abertura do Ato I, a criação do personagem deve ser limpa, tátil e quase silenciosa — inspirada na leitura inicial de Ogre Battle, mas sem caixas de texto explicando mecânicas. A aparência escolhida aqui é a primeira semente do segredo dos cinco atos.

### 1. Silhueta sem Rótulo

Em vez de botões escritos “Masculino / Feminino / Não-binário”, apresente **três silhuetas visuais** (uma de traços masculinos, uma de traços femininos e uma **figura andrógina/indefinida**). Os diálogos tratam a terceira figura com naturalidade e mistério — cronistas e inimigos nunca conseguem definir quem ela realmente é.

### 2. Customização Expressiva

Permita escolher **Rosto** (4–6 opções), **Cabelo** (6–8 cortes + cor), **Cor dos Olhos** e **Postura de Vitória** (ex.: espada cravada em silêncio, mão erguida ao céu, olhar para trás sobre o ombro, reverência serena). Tudo montado por camadas modulares de sprite no Godot 4.

### 3. O Truque nos Atos II–V

Nos Atos II, III, IV e V, o jogador **não recria o personagem** — cada novo protagonista parece outra pessoa, de outro tempo e até aparência diferente. Mas dois detalhes escolhidos no Ato I **sobrevivem em segredo** em todos os cinco: a exata **cor dos olhos** (visível nos retratos) e a **postura de vitória** após batalhas decisivas.

## O Questionário Inicial: sete cenas alegóricas para ler a essência do jogador

Apresentado antes do Ato I como uma conversa onírica ou teste de vigília sob um céu estrelado (sem explicar quem pergunta — na verdade, é a calibração inicial dos Aeons). Nenhuma resposta exibe pontuação; o sistema soma pontos ocultos no vetor (R, P, I) para detectar se o jogador é **Racional**, **Passional**, **Impulsivo** ou **Misto**.

| Cena / Pergunta | Opção A | Opção B | Opção C |
|---|---|---|---|
| 1. A Ponte Quebrada — Diante de um rio em cheia e um vilarejo isolado na outra margem… | “Meço a correnteza e procuro o ponto mais estreito rio acima antes de mover qualquer homem.” — +2 Racional | “Escuto os sobreviventes na margem para saber quem ficou preso lá antes de decidir.” — +2 Passional | “Amarro a primeira corda na minha cintura e atravesso agora — esperar é condenar quem está lá.” — +2 Impulsivo |
| 2. O Traidor Confesso — Um aliado vendeu sua posição para salvar a própria filha doente… | “Analiso se a informação dele ainda serve como isca contra o inimigo antes de julgá-lo.” — +2 Racional | “Sento diante dele em silêncio; preciso entender o tamanho do desespero que o quebrou.” — +2 Passional | “Afaste-o do comando imediatamente. Compaixão tardia não ressuscita os mortos.” — +2 Impulsivo |
| 3. O Livro em Chamas — Uma biblioteca antiga arde enquanto soldados saqueiam o pátio… | “Salvo os mapas e registros de leis: sem memória, venceremos hoje para repetir o erro amanhã.” — +2 Racional | “Salvo as cartas e poemas das famílias — o que mantém um povo vivo é o que ele ama.” — +2 Passional | “Deixo o papel queimar e avanço direto contra quem ateou o fogo.” — +2 Impulsivo |
| 4. O Silêncio Antes da Batalha — Na véspera de um cerco desigual, o que ocupa sua mente? | “As três falhas no flanco inimigo que ninguém percebeu ainda.” — +2 Racional | “O rosto de cada pessoa que confiou sua vida à minha bandeira.” — +2 Passional | “A impaciência de ouvir a trombeta e quebrar a espera de uma vez.” — +2 Impulsivo |
| 5. A Mentira Piedosa — Você descobre que a vitória só é possível ocultando uma perda terrível da tropa… | “Omito o fato até depois da batalha; a matemática da moral decide o campo.” — +2 Racional | “Não consigo mentir para quem sangra ao meu lado; divido a dor e escolho com eles.” — +2 Passional | “Não há tempo para discursos — lidero a carga na frente para que ninguém olhe para trás.” — +2 Impulsivo |
| 6. A Jaula Dourada — Um tirano oferece paz e fartura perpétua ao seu povo em troca de obediência absoluta… | “Estudo os termos: se a paz é real, talvez seja possível corroer a tirania por dentro com o tempo.” — +1 Racional · +1 Passional | “Uma paz que mata a alma do povo não é paz; prefiro o luto livre ao conforto submisso.” — +2 Passional | “Rasgo o tratado na frente dos emissários. Toda jaula só entende uma linguagem.” — +2 Impulsivo |
| 7. O Espelho Sem Rosto — Se você pudesse apagar uma única fraqueza humana do mundo, qual seria? | “A ignorância que faz os homens agirem sem medir consequências.” — +2 Racional | “A indiferença que impede os homens de sentirem a dor do outro.” — +2 Passional | “A covardia que paralisa os homens quando é hora de agir.” — +2 Impulsivo |

## Como o jogo pune o reforço do próprio viés (e como programar no Godot 4)

Ao final das 7 perguntas, o vetor inicial (R, P, I) define o **Perfil Dominante** do jogador (se um centro ficar ≥ 3 pontos acima dos outros, é perfil puro; se dois empatarem ou ficarem próximos, é perfil misto). A partir daí, toda escolha cinzenta nos 5 atos aplica a regra do **Contrapeso**:

### Regra da Penalidade por Viés

Se o jogador tem perfil dominante **Racional** e continua escolhendo saídas friamente calculadas, o centro R cresce ainda mais e aumenta o **Desequilíbrio (imbalance)**. Narrativamente, seus aliados começam a enxergá-lo como frio e distante, e os Aeons ganham controle silencioso (aeon_grip += 2).

Quando esse mesmo jogador escolhe uma saída **Passional** ou **Impulsiva** corajosa — saindo da sua zona de conforto — o vetor se aproxima do centro, o imbalance cai e a **Lucidez** sobe.

### E se o jogador começou Misto?

Para jogadores que terminam o questionário equilibrados, o jogo monitora o **centro que mais crescer durante os atos**. Assim que o jogador criar uma “muleta” recorrente (ex.: resolver 3 dilemas seguidos na impulsividade), o sistema identifica esse novo viés ativo e passa a gerar dilemas feitos para desafiá-lo.

 # Trecho de referência para EssenceState.gd (Godot 4) var center_r: float = 0.0 # Racional var center_p: float = 0.0 # Passional / Emotivo var center_i: float = 0.0 # Impulsivo / Ativo var aeon_grip: float = 50.0 # 0 = Libertação total | 100 = Novo mecanismo dos Aeons func register_choice(dr: float, dp: float, di: float) -> void: var dominant := get_dominant_center() # "R", "P", "I" ou "BALANCED" center_r += dr center_p += dp center_i += di # Se reforçou o próprio centro dominante, os Aeons apertam o controle if (dominant == "R" and dr > dp and dr > di) \ or (dominant == "P" and dp > dr and dp > di) \ or (dominant == "I" and di > dr and di > dp): aeon_grip = clamp(aeon_grip + 6.0, 0.0, 100.0) else: # Escolher fora do automatismo reduz o desequilíbrio e enfraquece a prisão var spread := max(center_r, max(center_p, center_i)) - min(center_r, min(center_p, center_i)) if spread <= 6.0: aeon_grip = clamp(aeon_grip - 7.0, 0.0, 100.0) else: aeon_grip = clamp(aeon_grip - 3.5, 0.0, 100.0)

## Três exemplos de dilemas cinzentos calibrados para cada perfil

Repare que em nenhum dos exemplos abaixo existe uma opção “boa” ou “má” óbvia. Cada alternativa tem uma justificativa moral real — mas exige que o jogador perceba quando está apenas obedecendo ao seu próprio hábito mental.

| Perfil Testado | Dilema no Jogo | A Armadilha (Reforça o Viés) | O Caminho do Equilíbrio (Desafio) |
|---|---|---|---|
| Jogador Racional — Confrontado com a Empatia | **Ato I · A Aldeia Contaminada:** uma peste atinge uma vila aliada perto da fronteira. Isolar e queimar a ponte salva três cidades vizinhas com 99% de certeza; enviar seus curandeiros Daoshi arrisca atrasar a campanha inteira. | **Decreto frio de quarentena total:** numericamente impecável, vence o mapa mais fácil — mas transforma você em uma cópia do Chanceler Legalista (aeon_grip +6). | **Entrar na vila com seus médicos** ou **negociar evacuação arriscada**: custa tempo e recursos, mas quebra a frieza calculista e revela uma aliada-chave. |
| Jogador Passional — Confrontado com a Clareza | **Ato II · O Refém em Carcassonne:** um trovador querido pelo seu esquadrão foi capturado pela Inquisição e usado como isca em uma emboscada óbvia que pode destruir metade do seu exército. | **Atacar de frente pelo desespero afetivo:** parece leal e heróico, mas cai exatamente na manipulação emocional do inimigo e sacrifica dezenas de outros aliados (aeon_grip +6). | **Recuar, mapear a emboscada com frieza** e trocar um prisioneiro estratégico — aceitando a dor de não reagir pelo impulso do coração. |
| Jogador Impulsivo — Confrontado com a Contenção | **Ato IV · O Vazamento Prematuro:** você encontra provas parciais de um crime da tecnocracia. Publicar tudo agora gera choque imediato e fúria nas ruas, mas permite que a mídia corporativa desacredite a fonte em 24 horas. | **Vazar imediatamente e convocar ruptura:** dá sensação de ação rápida e coragem, mas fortalece a vigilância e legitima a repressão (aeon_grip +6). | **Esperar em silêncio, cruzar dados com calma** e ouvir as testemunhas protegidas antes de agir — dominando a urgência de bater primeiro. |

## Os dois desfechos do Ato V: romper a prisão ou tornar-se a engrenagem dela

“Você achou que lutava contra nós em cinco épocas diferentes. Mas cada vez que obedeceu cegamente à sua frieza, à sua dor ou à sua fúria, foi você quem reconstruiu os muros da camada seguinte.”

**Desfecho 1 — A Libertação (Baixo aeon_grip · Centros Integrados):** ao longo das cinco existências, o jogador aprendeu a desconfiar dos próprios automatismos — o racional aprendeu a sentir, o passional aprendeu a discernir, o impulsivo aprendeu a esperar. No confronto metafísico final do Ato V, as cinco identidades se fundem sem conflito, os Aeons perdem a alavanca psicológica sobre a consciência humana e a prisão concêntrica se desfaz.

**Desfecho 2 — O Mecanismo Aprofundado (Alto aeon_grip · Extremo Cristalizado):** mesmo tendo “vencido” militarmente todos os chefes dos cinco atos, o jogador nunca quebrou o próprio padrão. Se venceu pela frieza racional absoluta, torna-se o Arquiteto da nova ordem perfeita; se pela paixão fanática, o Profeta de uma nova ortodoxia; se pela fúria impulsiva, o Tirano da ruptura eterna. Sem perceber, **ele mesmo vira o novo motor de aprisionamento dos Aeons** — e a tela final mostra a primeira centelha de uma sexta camada nascendo.
