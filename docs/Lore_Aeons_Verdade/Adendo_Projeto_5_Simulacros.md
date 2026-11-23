# Adendo de Arquitetura, Estado e Worldbuilding — Os Cinco Simulacros

> **Finalidade:** Este adendo consolida todas as evoluções de design definidas após o guia inicial e serve como referência direta para o seu cofre no [**Obsidian**](https://obsidian.md/) e para o agente de *vibecoding* no [**Godot 4**](https://godotengine.org/).

---

## 1. Livro-Razão Explícito para Vibecoding (`STATE_LEDGER.md`)

Modelos de linguagem não mantêm um livro-razão oculto confiável conforme o projeto cresce — variáveis, nomes de facções e segredos de roteiro se degradam ao longo de sessões longas ([Rukka Nova, Medium, 2026](https://carreira-mktp.medium.com/i-spent-a-year-engineering-ai-rpgs-heres-what-the-llm-actually-can-t-do-and-what-it-can-7280b62a007b)). Mantenha um arquivo curto `STATE_LEDGER.md` na raiz do repositório e instrua o agente a lê-lo no início de cada tarefa e atualizá-lo ao final:

```markdown
# STATE_LEDGER (Atualizar a cada commit)
- Engine: Godot 4.7.2 (GDScript, Renderer: gl_compatibility / OpenGL 3.3)
- Ato em construção: Ato I — Império de Tianxu (Vales de Nanlu)
- Autoloads ativos: WorldState.gd (estado do ato) | EssenceState.gd (estado oculto global)
- Eixos de estado: alignment (0..100), popular_support (0..100), doctrine (-100 Pacifista .. +100 Revolucionária)
- Regra de sigilo narrativo (Atos I–IV): PROIBIDO mencionar "Aeons", "simulação", "camadas concêntricas" ou "mesma consciência" em diálogos públicos. Usar apenas o fio filosófico nativo de cada era.
- Último marco testado (SMOKE_TEST_PASS): <data e cena validada>
```

---

## 2. Contrato de Estado com 3 Eixos (`WorldState.gd` e `EssenceState.gd`)

### `WorldState.gd` (Visível e reiniciado a cada Ato)
Controla o simulacro atual sem expor a persistência secreta entre as épocas:

- `alignment` (`0` a `100`): Honra/Compaixão vs. Brutalidade/Crueldade. Define promoções de classe (ex.: *Youxia* vs. *Buqu* brutal no Ato I; *Faydit* vs. *Routier* no Ato II).
- `popular_support` (`0` a `100`): Apoio Popular (*Chaos Frame*). Define recrutamento especial, preço em cidades e reações civis.
- `doctrine` (`-100` a `+100`): **Linha Pacifista** (`< 0`, contenção, cura, vitória por quebra de Moral e rendição) vs. **Linha Revolucionária** (`> 0`, insurgência, choque ofensivo e vitória por dano/ruptura).
- `combat_victory_mode`: toda unidade inimiga possui `hp` e `morale`. Zerar `hp` conquista pela força (empurra `doctrine` para o lado revolucionário); zerar `morale` força rendição ou deserção sem massacre (empurra `doctrine` para o lado pacifista e eleva `popular_support`).

### `EssenceState.gd` (Oculto — Memória dos Aeons)
Persiste silenciosamente no arquivo de save através das "derrotas falsas" dos Atos I–IV:

- `era_echoes`: dicionário gravando o perfil moral e doutrinário final de cada ato (`act_01` a `act_04`).
- `philosophical_flags`: marcos sutis de ruptura (ex.: proteger os mapas estelares em Pengming no Ato I; preservar os textos de Montségur no Ato II).
- `awakening_convergence`: lido apenas no clímax do Ato V para reconstruir as decisões das 4 encarnações anteriores e definir a reação dos Aeons (despertar pacífico de dentro vs. ruptura revolucionária da matriz).

---

## 3. Abstração das 3 Camadas Universais (Física → Rede → Virtual/Metafísica)

Para evitar reescrever o motor quando o jogo deixa campos de batalha físicos (Atos I–III) e entra em disputas de recursos/informação (Ato IV) e guerra virtual (Ato V), todos os atos usam exatamente os mesmos três módulos:

| Camada (Cena Godot) | Atos I–III (Guerra Física) | Ato IV (Recursos & Narrativa) | Ato V (Virtual & Metafísico) |
|---|---|---|---|
| **1. `StrategicMap.tscn`** (`MapNode`) | Províncias, estradas, portões e castelos. | Mapa metropolitano: data centers, emissoras, bancos, energia e distritos. | Topologia da Matriz: nós de consenso, cofres de memória e núcleos dos Aeons. |
| **2. `SquadBattle.tscn`** (Grade 3×2) | Tropas físicas (`HP` = vida, `Morale` = coragem). | Células operacionais (`HP` = sigilo/integridade, `Morale` = credibilidade). | Processos/avatares virtuais (`HP` = integridade de sinal, `Morale` = lucidez). |
| **3. `InterludeRoom.tscn`** ([Dialogic 2](https://github.com/dialogic-godot/dialogic)) | Acampamentos, cidades, templos e trincheiras. | **Encontros físicos clandestinos** (café na chuva, esconderijo, metrô vazio). | **Encontros efêmeros e metafísicos** em brechas de latência (shaders de dissolução e encontros únicos que se desfazem). |

---

## 4. Adendo ao Atlas do Ato I (Taoismo Han e Inimigos Aleatórios)

Para alinhar o **Ato I (Império de Tianxu)** ao nível de detalhamento do Ato II, incorpore estes dois blocos ao cofre `Lore_Simulacros/Ato_01_Tianxu/`:

### As três correntes taoistas da época (Base histórica da dinastia Han)
- **Via *Huang-Lao* (Pacifista / Corte):** baseada na filosofia política de não-intervenção (*wu wei*) que influenciou os primeiros imperadores Han ([Huang-Lao](https://pt.wikipedia.org/wiki/Huang-Lao)). Alimenta a **Linha Pacifista** do jogador.
- **Via dos Mestres Celestiais (*Tianshi Dao*):** inspirada no movimento fundado por [Zhang Daoling](https://en.wikipedia.org/wiki/Zhang_Daoling) em 142 d.C. ([Way of the Celestial Masters](https://en.wikipedia.org/wiki/Way_of_the_Celestial_Masters)), focada em cura comunitária, talismãs e autonomia moral fora da tirania imperial.
- **Via da Grande Paz (*Taipingdao*):** inspirada na [Rebelião dos Turbantes Amarelos (184 d.C.)](https://en.wikipedia.org/wiki/Yellow_Turban_Rebellion), unindo camponeses famintos sob o lema da queda do céu antigo. Alimenta a **Linha Revolucionária** — com o risco constante de radicalização e saques.

### Tabela de Inimigos Aleatórios do Ato I (Patrulhas Vivas no Mapa)

| Encontro | Região / Horário | Composição Tática | Dinâmica Moral & Recompensa |
|---|---|---|---|
| **Coletores da Regência** | Estradas de Nanlu e Dongwan (Dia) | 2 Alabardeiros *Fubing* + 2 Besteiros *Nubing* | Escoltam grãos confiscados; interceptá-los rende ouro/suprimentos (devolver às aldeias sobe Apoio Popular). |
| **Salteadores dos Canais** | Arrozais e pontes de Nanlu (Dia/Noite) | 3 Infantaria Leve + 1 Arqueiro | Bandidos oportunistas; eliminá-los protege rotas comerciais sem penalizar Alinhamento. |
| **Batedores da Estepe** | Fronteira de Beisha (Dia) | 3 Arqueiros Montados + 1 Lanceiro Nômade | Velocidade alta no mapa; derrotá-los em combate justo abre respeito diplomático com Khan Batu-Ordo. |
| **Radicais do Lótus de Cinza** | Arredores de vilas (Noite) | 2 Milicianos + 1 Xamã *Wu* + 1 Incendiário | **Dilema moral:** são camponeses desesperados de nível menor; vencê-los por **Moral** (sem massacre) preserva Alinhamento alto. |
| **Assassinos *Cike* da Corte** | Próximo a Hanmen e Tiandu (Noite) | 2 *Cike* + 1 Alquimista *Fangshi* Sombrio | Emboscam líderes de esquadrão à noite; derrubam itens raros de promoção. |
| **Guardião *Xian* / Espírito Raposa** | Ilha de Pengming (Névoa / Secreto) | Entidade mítica isolada com suporte espiritual | Encontro raro que desbloqueia as classes míticas do Ato I conforme o Alinhamento do esquadrão. |
