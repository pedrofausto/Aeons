#!/usr/bin/env bash
# Roda a suíte automatizada em janela real (OpenGL 3.3) e valida o log.
# Uso: tests/run_tests.sh   (GODOT=/caminho/do/godot para sobrescrever o wrapper)
set -u
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT:-$HOME/bin/godot-opengl3}"
# Argumentos extras (ex.: CI usa GODOT_ARGS="--headless"). Sem aspas de propósito: lista de flags.
GODOT_ARGS="${GODOT_ARGS:-}"
LOG="$(mktemp)"
"$GODOT_BIN" $GODOT_ARGS --path . --import >/dev/null 2>&1
"$GODOT_BIN" $GODOT_ARGS --path . res://tests/TestRunner.tscn --quit-after 20000 2>&1 | tee "$LOG"
status=0
grep -q "TEST_PASS|" "$LOG" || { echo "FALHA: nenhum TEST_PASS emitido"; status=1; }
grep -q "TEST_FAIL|" "$LOG" && { echo "FALHA: há TEST_FAIL no log"; status=1; }
grep -E -q "SCRIPT ERROR|ERROR:" "$LOG" && { echo "FALHA: SCRIPT ERROR/ERROR: no log"; status=1; }
grep -q "TEST_SUMMARY|" "$LOG" || { echo "FALHA: suíte não terminou"; status=1; }
for marker in ACT1_MYTHIC_CLASSES_PASS ACT1_FIXES_SMOKE_PASS ACT1_ADENDO_PASS ACT2_CARCASSONNE_PASS; do
	grep -q "$marker" "$LOG" || { echo "FALHA: $marker ausente"; status=1; }
done
rm -f "$LOG"
[ $status -eq 0 ] && echo "OK: todos os testes passaram sem erros."
exit $status
