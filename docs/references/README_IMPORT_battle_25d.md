# Pacote 2.5D — Arena de Batalha 3×2 (Ato I: Tianxu)

Alinhado ao `SCHEMA_CANON.md` e pronto para **Godot 4.7 (`gl_compatibility` / OpenGL 3.3)**.

## Como importar
1. Extraia o conteúdo deste `.zip` diretamente na raiz do seu projeto Godot (`res://`).
2. Verifique em *Project Settings → Rendering → Textures → Default Texture Filter* = **Nearest**.
3. Use `UnitActor25D.tscn` + `BattleArena25DLayout.gd` dentro de `core/combat/BattleArena.tscn`.
4. Cada sprite possui sua versão `_n.png` em espaço tangente **X+Y+Z+** pronta para `CanvasTexture` (`160×128 px` por quadro, `480×128 px` por folha individual).
5. Os `.tres` em `eras/act_01_tianxu/classes/` usam exatamente os nomes de campos de `SCHEMA_CANON.md` (`UnitClassData` e `ActionSkillData`).
