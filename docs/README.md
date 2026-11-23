# docs/ — Lore e Referências

| Pasta | Uso | Regra |
|---|---|---|
| `Lore_Simulacros/` | Atlas dos Atos I–III e matriz de classes **sem spoilers** | Única fonte permitida ao escrever diálogos/UI dos Atos I–IV. |
| `Lore_Aeons_Verdade/` | Documentos completos, Espelho dos Três Centros, arquitetura de referência | Usar **apenas** ao programar `EssenceState.gd` e o Ato V. |

- Os `.md` foram convertidos dos HTML originais de world building (imagens omitidas).
- As versões de `Lore_Simulacros/` removem linhas com termos proibidos; o teste
  `lore_secrecy_acts_1_to_4` (tests/test_interlude.gd) falha se algum termo voltar a aparecer.
- `docs/.gdignore` impede o Godot de importar esta pasta.
- `Cloud_Agent_Bootstrap.md`: runbook original do agente na nuvem (aplicado parcialmente: CI e docs;
  o projeto continua na raiz do repositório, não em `game/`).
