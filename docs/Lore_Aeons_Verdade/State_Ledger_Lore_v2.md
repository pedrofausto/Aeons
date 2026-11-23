# STATE_LEDGER.md — Livro-Razão Explícito de Projeto & Lore

> **Regra de Vibecoding:** Cole ou referencie este arquivo no início de cada sessão com seu agente de código (Cline / Antigravity CLI) ou roteirista LLM. Nunca confie na memória de longo prazo da IA para variáveis de estado, nomes canônicos ou segredos de enredo.

---

## 1. Regras Imutáveis do Motor (Godot 4.7.2 · GDScript · Compatibility)

- **Renderizador obrigatório:** `gl_compatibility` (`--rendering-driver opengl3` no Mac mini Mid 2011 / OCLP).
- **3 Camadas Fixas em Todos os Atos:**
  1. `OverworldMap` (grafo de nós `MapNode` — cidades físicas nos Atos I–III; infraestrutura/recursos no Ato IV; clusters neurais no Ato V).
  2. `CombatScene` (grade 3×2 automática estilo *Ogre Battle*, posição Frente/Trás define a ação; vitória por Zerar HP ou Zerar Moral).
  3. `InterludeRoom` (cenas 2D presenciais com diálogo via **Dialogic 2** / **Ink**).
- **Separação Estrita:**
  - `WorldState.gd`: estado **visível** do ato atual (`act_id`, `alignment: 0..100`, `popular_support: 0..100`, `doctrine: -100..+100` [Pacifista..Revolucionária], `gold_or_resources`, `captured_nodes`).
  - `EssenceState.gd` *(Autoload Oculto)*: registra silenciosamente ecos filosóficos (`philosophical_echoes`), padrões de doutrina (`doctrine_history`) e flags dos Aeons (`aeon_resistance_flags`) através dos 5 atos.

---

## 2. Trava Anti-Vazamento (Sigilo dos Aeons)

- **PROIBIDO nos Atos I, II, III e IV:** mencionar os termos `"Aeons"`, `"simulação"`, `"simulacro"`, `"matriz"`, `"camada concêntrica"` ou sugerir explicitamente que os 5 protagonistas são a mesma pessoa.
- **PERMITIDO nos Atos I–IV:** apenas o **fio filosófico** expresso no vocabulário da própria época:
  - *Ato I:* astrônomos *Fangshi* notam que as estrelas sobre Tianxu nunca se deslocam; debate *Huang-Lao* vs. Legalismo.
  - *Ato II:* *Bons Hommes* cátaros ensinam que o mundo material é obra de um Arconte ciumento (fiel ao dualismo histórico).
  - *Ato IV:* anomalias de registro civil e padrões de dados idênticos aos de arquivos históricos antigos, tratados como "ruído de algoritmo" ou conspiração corporativa.
- **Regra da Derrota Falsa:** ao vencer o poder central de cada ato (I–IV), disparar uma cena de colapso/apagamento trágico que encerra a crônica local antes de iniciar o ato seguinte.

---

## 3. Registro Canônico dos Atos Definidos

### Ato I — China Antiga Imperial (*Império de Tianxu*)
- **Regiões (6):** Vales de Nanlu (SO, início), Delta de Dongwan (SE, portos), Desfiladeiro de Hanmen (O), Estepes de Beisha (N), Arquipélago de Pengming (L, secreto), Planície de Zhonghe / Capital Tiandu (Centro).
- **Facções:** Regência do Selo de Ferro (Chanceler Gao Shen), Feudo dos Três Rios (General Wei Bo), Irmandade do Lótus de Cinza (Mestra Lin), Liga dos *Youxia* e Moístas (Mestre Shen), Clãs de Beisha (Khan Batu-Ordo), Círculo *Fangshi* de Pengming (Arquivista Xu).
- **Classes:** *Fubing/Bubing* → *Youxia* / *Buqu*; Alabardeiro → Catafractário / Saqueador; *Nubing* → Arqueiro Montado / *Cike*; *Fangshi* → *Daoshi* / Alquimista Sombrio; Médico → Monge / Xamã *Wu*; Conselheiro → *Junshi* / Legalista. Míticas: *Xian*, *Jiangshi/Huli Jing*.

### Ato II — Europa Medieval (*Terras d'Oc · Carcassonne*)
- **Regiões (6):** Cidadela de Carcassonne (Centro), Vinhedos de Toulouse (O), Montagne Noire & Albi (N), Pireneus & Montségur (S, clímax), Costa de Béziers & Narbonne (SE), Pântanos de Tarascon (L, secreto).
- **Facções:** Barões da Cruzada do Norte (Barão Guy de Montclair), Legado Papal & Inquisição (Abade Arnaut), Irmandade dos *Faydits* (Pierre-Roger de Rochefort), Igreja dos *Bons Hommes* (Diaconisa Esclarmonde), Coroa de Aragão, Companhias de *Routiers* (Capitão Loup-Noir).
- **Classes:** *Sergent d'Armes* → *Faydit* / *Routier*; Lanceiro → *Chevalier* / Quebra-Muralhas; *Arbalétrier* → Batedor / Sicário; Erudito → Alquimista Hermético / Ocultista; Irmão de Caridade → *Parfait* / Inquisidor; *Trobador* → Menestrel / Arauto. Míticas: Portador do *Consolamentum*, Domador da *Tarasque*.

### Ato III — I e II Guerras Mundiais *(Pendente de Atlas detalhado)*
- **Status:** Classes definidas (Fuzileiro, *Stoßtruppen/Arditi*, Sapador, Criptógrafo, Médico de Combate, Rádio Clandestina, *Nachthexen*); mapa e facções a detalhar.

### Ato IV — Era Moderna (*Metrópole de Nova Vespera · Tecnocracia Nascente*)
- **Regiões (6):** Distrito Financeiro Central (Centro), Porto de Contêineres & Subestação Leste (SE), Distrito das Torres de Mídia (N), Entroncamento Metroviário (O), Subúrbios Residenciais (NO), Subsolo de Cabos & Abrigos (Camada Física).
- **Natureza das Batalhas:** Virtuais e de disputa de recursos/sinal (servidores, energia, crédito, opinião pública), contrabalanceadas por **Interlúdios de Presença** físicos reais (lanchonete sob chuva, esconderijo, metrô de madrugada).
- **Facções:** Consórcio Meridian (Tecnocracia nascente), Rede Cívica OSINT / Denunciantes, Aparato Estatal Legado, Sindicato *Black-Hat*, Correios Analógicos (resistência física), Anomalias de Sinal.

### Ato V — Tecnocracia Cibernética *(Clímax)*
- **Status:** Guerra 100% virtual e cognitiva; encontros presenciais efêmeros/metafísicos em brechas de latência; convergência de `EssenceState.gd` e revelação das 5 camadas concêntricas.
