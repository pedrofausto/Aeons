extends Node
## Executa as suítes de teste e imprime marcadores explícitos:
##   TEST_PASS|<nome>  /  TEST_FAIL|<nome>|<detalhe>  /  TEST_SUMMARY|pass=N|fail=M
## Sai com código 1 se qualquer teste falhar (o script shell ainda verifica ERROR no log).

const SUITES: Array[String] = [
	"res://tests/test_combat_3x2.gd",
	"res://tests/test_world_state.gd",
	"res://tests/test_overworld.gd",
	"res://tests/test_interlude.gd",
	"res://tests/test_mythic.gd",
	"res://tests/test_act1_fixes.gd",
	"res://tests/test_act2.gd",
]

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	for path: String in SUITES:
		if not ResourceLoader.exists(path):
			continue
		var suite: Object = (load(path) as GDScript).new()
		await suite.call("run", self)
	print("TEST_SUMMARY|pass=%d|fail=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 or passed == 0 else 0)


func check(test_name: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed += 1
		print("TEST_PASS|%s" % test_name)
	else:
		failed += 1
		print("TEST_FAIL|%s|%s" % [test_name, detail])
