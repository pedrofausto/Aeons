> Versão SEM SPOILERS para gerar diálogos dos Atos I–IV. 1 linha(s)/célula(s) que revelavam o segredo foram omitidas;
> a íntegra está na pasta restrita de verdade em docs/ (proibido usá-la ao escrever diálogos dos Atos I–IV).

# Dilemas Morais e Táticos — Ato II (Terras d'Oc / Carcassonne)


---

## Tabela-Resumo de Impacto no Motor (`WorldState.gd`)

| # | Dilema | Região | Eixos Principais | Desbloqueio / Consequência-Chave |
|---|---|---|---|---|
| 1 | **A Água de Carcassonne** | Cidadela de Carcassonne | Alinhamento · Apoio Popular · Doutrina | Acesso a cisternas/rendição limpa vs. quebra rápida do cerco |
| 2 | **O Conselho de Toulouse e Aragão** | Vinhedos de Toulouse | Legitimidade · Doutrina | Reforços de Aragão vs. autonomia dos *Faydits* |
| 3 | **As Estradas da Montagne Noire** | Montagne Noire & Albi | Alinhamento · Doutrina | Recrutamento de *Parfaits* vs. queda da logística cruzada |
| 4 | **As Cinzas de Béziers** | Costa de Béziers & Narbonne | Apoio Popular · Ouro | Renda portuária estável vs. mercenários *Routiers* |
| 5 | **A Fera e o Pergaminho do Rhône** | Pântanos de Tarascon | Alinhamento · Secreto | Recrutamento da *Tarasque* e flag oculta em `EssenceState.gd` |
| 6 | **A Vigília dos Quatro em Montségur** | Pireneus & Montségur | Doutrina · Clímax | Desfecho da “Derrota Falsa” e eco gravado para o Ato V |

---

## 1. A Água de Carcassonne
- **Região:** Cidadela de Carcassonne (Centro)
- **Referência histórica:** No [Cerco de Carcassonne (agosto de 1209)](https://en.wikipedia.org/wiki/Siege_of_Carcassonne), a cidadela era quase inexpugnável pelas muralhas duplas, mas caiu em duas semanas quando os cruzados cortaram o acesso dos defensores à água do rio Aude.
- **Situação no mapa:** A cidadela está tomada por uma guarnição cruzada cercada pelo exército do jogador — mas abriga centenas de artesãos e famílias occitanas presas lá dentro. Um engenheiro *Faydit* descobre o duto que abastece as cisternas internas.

### Escolhas
1. **Rota Pacifista / Honrada — “Poupar as Cisternas e Negociar Salvo-Conduto”**
   - Mantém a água correndo e envia trovadores e *Parfaits* para pregar sob as muralhas, pressionando a moral dos soldados contratados por 40 dias.
   - **Impacto:** `alignment +15`, `popular_support +20`, `doctrine -20` (Pacifista). O cerco exige 2 batalhas defensivas extras, mas a cidade se rende intacta e gera **+30% de ouro diário** e voluntários locais.
2. **Rota Revolucionária / Honrada — “Assalto Noturno às Portas do Burgo”**
   - Recusa punir os civis pela sede, mas lidera um ataque arriscado diretamente sobre a ponte do Aude para romper a guarnição pela força.
   - **Impacto:** `alignment +10`, `popular_support +10`, `doctrine +20` (Revolucionária). Batalha difícil contra cavalaria pesada, mas eleva o prestígio junto aos *Faydits*.
3. **Rota Implacável — “Cortar a Água do Aude”**
   - Desvia o canal e envenena o poço externo com cal, forçando a rendição imediata por sede.
   - **Impacto:** `alignment -25`, `popular_support -20`, `doctrine +15`. A guarnição inimiga cai com **-50% de HP** na batalha final, mas os *Bons Hommes* recusam entrar nos seus esquadrões na região.

- **Interlúdio de Presença:** Nas cisternas subterrâneas de Carcassonne, uma velha tecelã pergunta se *“quem usa a mesma arma do invasor não acaba construindo a mesma muralha”*.

---

## 2. O Conselho de Toulouse e a Balança de Aragão
- **Região:** Vinhedos de Toulouse (Oeste)
- **Referência histórica:** Antes da [Batalha de Muret (1213)](https://fr.wikipedia.org/wiki/Bataille_de_Muret), o rei Pedro II de Aragão hesitou entre proteger seus vassalos occitanos e não romper com o Papa Inocêncio III, exigindo contenção política dos senhores do sul.
- **Situação no mapa:** Emissários da Coroa de Aragão oferecem infantaria leve (*Almogàvers*) e cavalaria real para enfrentar os barões do norte — mas exigem que o protagonista **expulse os pregadores cátaros mais visíveis de Toulouse** para não provocar Roma.

### Escolhas
1. **Rota Diplomática / Pragmática — “Aceitar as Condições de Barcelona”**
   - Esconde os *Parfaits* fora das muralhas e assina o pacto feudal com Aragão.
   - **Impacto:** `alignment -5`, `popular_support -10`, `doctrine -10`. Desbloqueia **2 esquadrões de elite aragoneses** imediatamente para as batalhas campais do oeste.
2. **Rota Pacifista / Firme — “Recusar a Expulsão e Apelar aos Trovadores”**
   - Recusa trair os *Bons Hommes* e usa os [trovadores occitanos](https://en.wikipedia.org/wiki/Troubadour) para mobilizar a burguesia urbana de Toulouse em defesa da cidade.
   - **Impacto:** `alignment +15`, `popular_support +20`, `doctrine -15`. Sem reforços aragoneses, mas libera a classe **Menestrel da Resistência** e defesa reforçada em todas as cidades do oeste.
3. **Rota Revolucionária — “Quebrar os Selos Feudais”**
   - Declara que nenhum rei estrangeiro nem bispo do norte mandará no Languedoc, convocando os *Faydits* para confiscar armas dos nobres hesitantes.
   - **Impacto:** `alignment -10`, `popular_support +5`, `doctrine +25`. Desbloqueia recrutamento acelerado de *Faydits* e bônus de ataque em campo aberto, mas fecha a diplomacia com Aragão.

---

## 3. As Estradas da Montagne Noire
- **Região:** Montagne Noire & Albi (Norte)
- **Referência histórica:** A [Cruzada Albigense](https://en.wikipedia.org/wiki/Albigensian_Crusade) institucionalizou a Ordem Dominicana e a Inquisição Medieval no norte do Languedoc para investigar e reprimir a heresia em vilas e abadias.
- **Situação no mapa:** Seus batedores localizam dois alvos simultâneos nas florestas ao norte: um **comboio inquisitorial** levando 14 camponeses e duas *Bonnes Femmes* para Albi, e o **acampamento de suprimentos e *trébuchets*** dos barões do norte (que partirá ao amanhecer para bombardear o sul). Só há tempo de interceptar um antes do nascer do sol.

### Escolhas
1. **Rota Pacifista / Honrada — “Libertar os Prisioneiros da Inquisição”**
   - Intercepta a escolta e escolta os civis de volta às clareiras seguras.
   - **Impacto:** `alignment +20`, `popular_support +20`, `doctrine -15`. Libera a promoção para **Parfait Cátaro (*Perfectus*)**; em troca, os *trébuchets* inimigos chegam intactos ao próximo cerco.
2. **Rota Revolucionária — “Incendiar os *Trébuchets* e os Paióis do Norte”**
   - Ataca o acampamento militar sob neblina e destrói as máquinas de cerco cruzadas, deixando o comboio civil seguir até Albi.
   - **Impacto:** `alignment -15`, `popular_support -15`, `doctrine +25`. Reduz permanentemente o poder de cerco dos Barões do Norte pelo resto do Ato II.
3. **Rota Implacável — “Capturar o Inquisidor como Refém Político”**
   - Ignora os *trébuchets* e faz uma emboscada brutal na escolta para capturar o legado e exigir resgate em prata e informação militar.
   - **Impacto:** `alignment -20`, `popular_support -5`, `doctrine +15`. Revela todas as patrulhas escondidas na Montagne Noire e rende ouro alto, mas atrai esquadrões de caçadores de hereges implacáveis.

---

## 4. As Cinzas de Béziers
- **Região:** Costa de Béziers & Narbonne (Sudeste)
- **Referência histórica:** O saque e massacre de Béziers (julho de 1209) traumatizou todo o sul da França, deixando sobreviventes sem teto e estradas infestadas por companhias de mercenários (*Routiers*).
- **Situação no mapa:** Ao chegar às ruínas de Béziers e ao porto de Narbonne, o protagonista encontra o capitão mercenário **Loup-Noir** controlando os armazéns portuários e cobrando taxas abusivas de refugiados. Ele propõe um acordo: se o jogador ignorar seus saques, sua companhia de *Routiers* luta de graça na linha de frente contra os cruzados.

### Escolhas
1. **Rota Honrada / Pacifista — “Expulsar os *Routiers* e Reabrir o Porto aos Refugiados”**
   - Enfrenta a companhia mercenária, devolve os armazéns à cidade e financia a reconstrução de abrigos em Béziers.
   - **Impacto:** `alignment +20`, `popular_support +25`, `doctrine -10`. Custa ouro imediato, mas estabiliza a renda comercial de Narbonne e eleva a moral em todas as batalhas do sudeste.
2. **Rota Pragmática / Sombria — “Contratar a Companhia de Loup-Noir”**
   - Sela pacto com os mercenários para usar tropas brutais como bucha de canhão contra os barões do norte.
   - **Impacto:** `alignment -25`, `popular_support -25`, `doctrine +20`. Adiciona 2 esquadrões de **Routiers** de alto dano imediato e desbloqueia a promoção sombria de infantaria.

- **Interlúdio de Presença:** Na nave queimada da igreja de Madalena em Béziers, um sobrevivente entrega um medalhão de prata derretido com um **símbolo concêntrico** quase apagado — eco visual silencioso do Ato I.

---

## 5. A Fera e o Pergaminho do Rhône
- **Região:** Pântanos de Tarascon (Leste — Zona Secreta)
- **Referência histórica e folclórica:** A lenda da [Tarasca (*Tarasque*)](https://en.wikipedia.org/wiki/Tarasque) — dragão anfíbio dos pântanos do Rhône acalmado por Santa Marta com água benta e coragem serena na *Legenda Áurea* (séc. XIII) — fundida aos manuscritos proibidos contrabandeados por herboristas.
- **Situação no mapa:** No coração enevoado do delta, uma criatura colossal bloqueia as ruínas de um antigo claustro submerso onde um alquimista guarda um códice apócrifo sobre *“os sete círculos do mundo-prisão”*.

### Escolhas
1. **Rota Pacifista / Alto Alinhamento (Exige *Parfait* no esquadrão) — “Acalmar a Tarasca”**
   - Usa o rito de serenidade dos *Bons Hommes* (sem golpes letais) até zerar a fúria da fera, repetindo o mito de Tarascon.
   - **Impacto:** `alignment +20`, `doctrine -20`. **Recruta a Tarasca** (unidade mítica de 2 espaços na grade 3×2!) e recupera o códice intacto → grava `essence_flag: "act2_codex_preserved"` em `EssenceState.gd`.
2. **Rota Marcial / Revolucionária — “Abater a Fera e Tomar o Claustro”**
   - Enfrenta o chefe secreto em combate direto de alta dificuldade.
   - **Impacto:** `alignment +0`, `doctrine +15`. Rende armadura/relíquia única de promoção e permite ler o códice → grava `essence_flag: "act2_codex_preserved"`.
3. **Rota Sombria — “Queimar o Claustro para Negociar Trégua com o Legado”**
   - Entrega o códice proibido aos agentes inquisitoriais em troca de passagem livre pelo leste.
   - **Impacto:** `alignment -20`, `popular_support -10`. Grava `essence_flag: "act2_codex_burned"` (ecoará em um diálogo efêmero do Ato V).

---

## 6. A Vigília dos Quatro em Montségur (Clímax e “Derrota Falsa”)
- **Região:** Pireneus & *Castrum* de Montségur (Sul)
- **Referência histórica:** Na véspera da queda do [Cerco de Montségur (março de 1244)](https://fr.wikipedia.org/wiki/Si%C3%A8ge_de_Monts%C3%A9gur), quatro *Bons Hommes* desceram secretamente o abismo rochoso à noite levando o misterioso “tesouro” dos cátaros antes que mais de 200 defensores recusassem abjurar sua fé.
- **Situação no mapa:** Mesmo após vitórias brilhantes, exércitos reais cercam completamente o rochedo. Na última noite, a Diaconisa Esclarmonde confia ao protagonista a decisão final da resistência: **escoltar a descida silenciosa dos quatro mensageiros pelo abismo** (salvando a memória e os livros) ou **liderar uma carga desesperada contra os *trébuchets* no vale** para tentar quebrar o cerco à força.

### Escolhas
1. **Rota Pacifista — “Guardar a Descida pelo Abismo”**
   - Segura a brecha da muralha apenas o tempo suficiente para os quatro *Bons Hommes* desaparecerem na névoa com os textos.
   - **Impacto:** `doctrine -25`, grava `essence_flag: "act2_montsegur_witness"` em `EssenceState.gd`.
2. **Rota Revolucionária — “Carga Final contra o Acampamento Real”**
   - Abre os portões ao amanhecer em um contra-ataque feroz para destruir o comando inimigo.
   - **Impacto:** `doctrine +25`, grava `essence_flag: "act2_montsegur_defiance"` em `EssenceState.gd`.

### Disparo da “Derrota Falsa” (Transição para o Ato III)
Em **ambos** os caminhos, quando o protagonista vence a última onda inimiga e parece prestes a romper o destino imposto ao Languedoc, um clarão branco-dourado engole a névoa dos Pireneus; o som das trombetas de cerco se distorce gradualmente até virar o apito metálico de uma granada de artilharia. A crônica medieval fecha como uma tragédia perdida na história — e o jogador desperta na lama do **Ato III**, convencido de que falhou mais uma vez.
