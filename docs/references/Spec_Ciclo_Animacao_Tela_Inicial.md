# INSTRUÇÃO DE IMPLEMENTAÇÃO — CICLO DE ANIMAÇÃO DA TELA INICIAL (GODOT 4)

> **Reconciliação Canônica (Projeto Aeon):**
> - **Caminhos reais no repositório:** `res://core/ui/TitleScreen.tscn`, `res://core/ui/TitleScreen.gd`, `res://core/ui/StormBackdrop.gd`, `res://core/ui/ProtagonistSelect.tscn`, `res://core/autoloads/SaveSystem.gd`.
> - **Título e Entrada Imediata:** O título exibido na tela inicial é **"AEONS"**, aparecendo imediatamente no boot com *fade-in* de **`3.0s`**.
> - **Tempestade + 7 Silhuetas:** Nos primeiros **`49.0s`** na tela inicial, ocorrem apenas relâmpagos, chuva e nuvens. Após **`49.0s`**, cada relâmpago (`8.5s–15.5s` entre tempestades; pulso duplo `0.06s` → `0.08s` → `0.12s` → `0.95s` decaimento) revela as 7 figuras em **ordem numérica estrita (`01` → `07`)** (`01_athoth.jpg`..`07_sabbede.jpg`), reiniciando o ciclo em `01` e **sumindo completamente (`visible = false`, alpha `0.0`)** ao término de cada flash.
> - **Sigilo narrativo:** os textos visíveis e epígrafes de `AttractOverlay` usam exclusivamente vocabulário da era ativa (sem mencionar termos proibidos de `SCHEMA_CANON.md`).

---

## 1. Objetivo e Restrições Técnicas
Implemente a cena `res://core/ui/TitleScreen.tscn` e o script `res://core/ui/TitleScreen.gd` em **GDScript** para **Godot 4.7+**, compatível com o renderizador **Compatibility (OpenGL 3.3 / WebGL 2.0)**.

- **Regra de performance (Mac mini 2011 / Web / Mobile):** Use exclusivamente `CPUParticles2D` (nunca `GPUParticles2D`), `Tween` (`create_tween()`), `CanvasModulate` e no máximo 2 `PointLight2D`.
- **Modularidade sem spoilers:** A cena deve carregar visuais, fontes, partículas, música e frases a partir de um recurso/configuração da era (por padrão, o **Ato I — Império de Tianxu**). Não inclua nenhuma referência visual ou textual aos outros atos no Ato I.
- **Resolução base:** 640×360 (pixel art 32-bit, `canvas_items` / `integer` scaling, filtro `Nearest`).

---

## 2. Hierarquia de Nós (`TitleScreen.tscn`)
1. `TitleScreen` (`Control`, script `TitleScreen.gd`)
2. `StormBackdrop` (`Control` / `Node2D`, script `StormBackdrop.gd` — céu noturno, nuvens contínuas, 7 silhuetas com `storm_silhouette.gdshader`, chuva e relâmpagos)
3. `UILayer` (`CanvasLayer` / controles sobrepostos):
   - `BlackCurtain` (`ColorRect` preto cobrindo a tela inteira, `mouse_filter = IGNORE`)
   - `TitleLabel` + `SubtitleLabel` (terço superior, `modulate.a = 0.0` no boot)
   - `PressStartLabel` (`Label` — *"Pressione qualquer tecla"*, `modulate.a = 0.0`)
   - `MenuBox` (`VBoxContainer` — *Continuar*, *Novo Jogo*, *Carregar Jogo*, *Opções*, *Sair*, `visible = false`)
   - `AttractOverlay` (`Control` — vinheta de inatividade com epígrafe filosófica da era, `modulate.a = 0.0`)
   - `OptionsPanel` e `SaveLoadModal`

---

## 3. Máquina de Estados e Linha do Tempo Exata

`enum State { BOOT_SILENCE, INTRO_REVEAL, IDLE_PRESS_START, ATTRACT_MODE, MENU_ACTIVE, TRANSITION_OUT }`

### Fase 0 — `BOOT_SILENCE` (`0.0s` a `1.2s`)
- Tela 100% preta (`BlackCurtain.modulate.a = 1.0`).
- Em `0.4s`: inicia `BGMPlayer` (quando presente) com volume em `-24 dB` fazendo *fade-in* suave até `0 dB` ao longo de `3.0s`.
- Em `1.2s`: avança automaticamente para `INTRO_REVEAL`.

### Fase 1 — `INTRO_REVEAL` (`1.2s` a `7.2s`)
Execute em sequência controlada por `Tween` (`TRANS_SINE`, `EASE_OUT`):
1. **`1.2s` → `3.8s` (`2.6s` de duração):** `BlackCurtain.modulate.a` vai de `1.0` para `0.0`.
2. **`3.2s` → `5.2s` (`2.0s` de duração):** iluminação/partículas entram suavemente.
3. **`4.6s` → `6.4s` (`1.8s` de duração):** `TitleLabel` faz *fade-in* (`alpha 0.0 → 1.0`) deslizando `10px` para cima (`TRANS_CUBIC`, `EASE_OUT`).
4. **`6.0s` → `7.0s` (`1.0s` de duração):** `SubtitleLabel` faz *fade-in* (`alpha 0.0 → 0.85`).
5. **`7.2s`:** Entra no estado `IDLE_PRESS_START`, exibe `PressStartLabel` e inicia o temporizador de inatividade (`30.0s`).

---

## 4. Loops Contínuos em Paralelo (Durante `IDLE_PRESS_START` e `MENU_ACTIVE`)
Todos os ciclos usam intervalos dessincronizados:

| Elemento | Intervalo / Velocidade | Comportamento do Loop |
|---|---|---|
| **Névoa / Nuvens (`StormBackdrop`)** | `42.0s` por ciclo completo | Rolagem horizontal contínua (`-6.0 px/s`). |
| **Relâmpagos + 7 Silhuetas** | `8.5s – 15.5s` (irregular) | Pulso duplo realista (`0.06s` clarão → `0.08s` micro-apagão → `0.12s` pico → `0.95s` decaimento). |
| **Logo (`TitleLabel`)** | `6.0s` por ciclo (`3.0s` sobe / `3.0s` desce) | Flutuação vertical sutil de `±2px` (`TRANS_SINE`, `EASE_IN_OUT`). |
| **"Pressione qualquer tecla"** | `2.4s` por ciclo (`1.2s` / `1.2s`) | Pulso suave de opacidade entre `0.35` e `1.0` (`TRANS_SINE`). |
| **Brilho Celeste Sutil** | A cada `19.0s` | Sobe opacidade de `0.0` → `0.14` em `3.0s`, mantém `1.0s`, volta a `0.0` em `3.0s`. |

---

## 5. Ciclo de Inatividade (`ATTRACT_MODE`)
Se o jogador ficar **`30.0s` sem pressionar nenhuma tecla ou clique** no estado `IDLE_PRESS_START`:
1. **`0.0s` → `1.5s`:** `TitleLabel`, `SubtitleLabel` e `PressStartLabel` fazem *fade-out* para `0.0`; fundo escurece `25%`.
2. **`1.5s` → `9.5s` (`8.0s` em tela):** `AttractOverlay` faz *fade-in* (`1.2s`), permanece `5.6s` legível e faz *fade-out* (`1.2s`).
3. **`9.5s` → `11.0s` (`1.5s`):** Restaura a iluminação, retorna o logo e o `PressStartLabel`, zera o contador e volta ao estado `IDLE_PRESS_START`.
4. Esse ciclo (`30.0s` idle → `11.0s` attract) se repete alternando entre 3 epígrafes da era ativa.

---

## 6. Regras de Input e Transições
`_unhandled_input(event)` aceita `InputEventKey`, `InputEventJoypadButton`, `InputEventMouseButton` e `InputEventScreenTouch` (`pressed == true`):
- **Durante `BOOT_SILENCE` ou `INTRO_REVEAL`:** Cancela os `Tweens` da introdução (`kill()`), aplica os valores finais de `7.2s` e entra em `IDLE_PRESS_START`.
- **Durante `ATTRACT_MODE`:** Interrompe imediatamente o `AttractOverlay` (`0.3s` *fade-out*) e retorna para `IDLE_PRESS_START` zerando o timer de `30.0s`.
- **Durante `IDLE_PRESS_START`:** `PressStartLabel` desaparece em `0.25s`, entra em `MENU_ACTIVE` e cada botão de `MenuBox` entra com *fade-in* + deslocamento horizontal de `8px` em cascata (`0.08s` de atraso entre cada botão).
- **Ao selecionar *Novo Jogo*, *Continuar* ou carregar slot (`TRANSITION_OUT`):** Bloqueia inputs, `BlackCurtain.modulate.a` vai de `0.0` → `1.0` em `1.2s` e troca para a cena de destino.

---

## 7. Critérios de Validação
1. Nenhum `Tween` órfão ou erro ao apertar teclas repetidamente durante a introdução ou ao sair do `ATTRACT_MODE`.
2. O ciclo `IDLE_PRESS_START` → `ATTRACT_MODE` → `IDLE_PRESS_START` roda sem acúmulo de memória.
3. Funciona em teclado/mouse e toque (Mobile/Web) a 60 FPS no renderizador `gl_compatibility`.
