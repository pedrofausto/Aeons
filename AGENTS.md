# Regras do Projeto Aeon

## Execução de Testes no Godot
- **NUNCA** execute testes no Godot (`tests/run_tests.sh`, `tests/TestRunner.tscn`, `--quit-after` ou comandos equivalentes) sem autorização explícita do usuário.
- Esta regra tem precedência sobre a verificação automática de `ARCHITECTURE.md` e `SCHEMA_CANON.md`: após editar código ou recursos, aguarde o usuário autorizar antes de rodar testes ou boots do Godot.

## Convenções do Repositório (Aeon)
- **Nome do projeto:** `Aeon` (respeitando o sigilo narrativo nos Atos I–IV conforme `SCHEMA_CANON.md`).
- **Git & Testes:** `tests/` é mantida apenas localmente (listada no `.gitignore`); push direto na branch `main` é permitido.
- **Motor & Wrapper:** Godot 4.7.2 (`gl_compatibility`) via `~/bin/godot-opengl3`; manter scripts `.gd` com no máximo 250 linhas e estender `core/data/` apenas de forma aditiva seguindo `SCHEMA_CANON.md`.
- **Kit de personagens:** manter `.gdignore` dentro de `antigravity-character-kit/` para evitar colisão de `class_name`.
