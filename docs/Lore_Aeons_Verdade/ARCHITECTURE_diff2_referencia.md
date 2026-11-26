# arch diff2 — Arquitetura Técnica do RPG Tático 2D (Referência)

> Documento de referência absorvido em `ARCHITECTURE.md`, `SCHEMA_CANON.md` (§7) e `STATE_LEDGER.md`.
> Nomes divergentes (ex.: `SaveSystem`, `EraManager`, `BattleResolver`, `ActionData`, `TacticOrders`, `army_doctrine`, `resource_pool`, `overworld_music`) são traduzidos pela Tabela de Aliases do `SCHEMA_CANON.md` §7.

## 1. Premissa Técnica e Restrições Inegociáveis

- **Engine e Linguagem:** Godot 4.7.2 · GDScript puro (zero C#).
- **Renderizador:** `gl_compatibility` (OpenGL 3.3 / WebGL 2.0) — compatível com Mac mini Mid 2011 (OCLP), Web e Android/iOS.
- **Exportação Web:** Single-threaded WebAssembly + OGG Vorbis.
- **Tamanho de Script:** Máximo de 250 linhas por arquivo `.gd`.
- **Segredo Narrativo:** Separação física entre `Lore_Simulacros/` e `Lore_Aeons_Verdade/` (proibido mencionar "Aeons", "simulação" ou "camadas concêntricas" nos Atos I–IV).

## 2. Princípio Central: Motor Neutro + 5 Perfis de Era + Estado Oculto

- **Superfície (`WorldState`):** estado visível do ato atual (`current_act`, `resources`, `popular_support`, `doctrine`, `faction_trust`, `captured_nodes`, `player_squads`, `completed_interludes`).
- **Bastidores (`EssenceState`):** memória oculta persistida através das 5 "derrotas falsas" (`completed_acts`, `alignment_history`, `doctrine_history`, `philosophical_echoes`, `aeon_resistance_flags`, `act_records`, `false_defeats`, e `remembered_captains` planejado para o Ato V).

## 3. Novos Recursos Mapeados para Roadmap Futuro (via `SCHEMA_CANON.md` §7)

- **`SaveSystem.gd`:** serialização JSON/Resource separando `WorldState` e `EssenceState` (Desktop `user://` e Web).
- **`AudioDirector.gd` + `EraConfig.overworld_music / battle_music / interlude_music`:** camadas sincronizadas em `.ogg` (`AudioStreamInteractive` / `AudioStreamSynchronized`).
- **`UnitClassData.sprite_frames / normal_map_texture`:** suporte a `SpriteFrames` (sheets 4×4) e *normal maps* do Laigter com `CanvasTexture` + `PointLight2D`.
- **`EssenceState.remembered_captains`:** snapshot mínimo (nome/classe/retrato) de protagonistas e aliados marcantes dos Atos I–IV para reaparecerem no Ato V.
