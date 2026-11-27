class_name SquadHudPanel
extends PanelContainer
## Painel compacto estilo Ogre Battle para exibir um esquadrão 3x2 (HP e Moral) nos cantos.

signal unit_hovered(index: int)
signal unit_unhovered
signal unit_clicked(index: int)

var _squad: SquadData
var _is_enemy: bool = false
var _rows: Array[HBoxContainer] = []
var _hp_bars: Array[ProgressBar] = []
var _mor_bars: Array[ProgressBar] = []
var _names: Array[Label] = []


func setup(p_squad: SquadData, title_prefix: String, is_enemy: bool) -> void:
	_squad = p_squad
	_is_enemy = is_enemy
	for child: Node in get_children():
		child.queue_free()
	_rows.clear()
	_hp_bars.clear()
	_mor_bars.clear()
	_names.clear()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	var title := Label.new()
	title.text = "%s: %s" % [title_prefix, p_squad.display_name if p_squad else ""]
	title.add_theme_font_size_override("font_size", 8)
	vbox.add_child(title)
	if p_squad == null:
		return
	for i: int in p_squad.units.size():
		var u: UnitInstance = p_squad.units[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(72, 12)
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.text = "%s%s" % ["★" if u.is_leader else "", u.unit_name]
		row.add_child(lbl)
		var hp := _make_bar(Color(0.85, 0.22, 0.22), u.get_max_hp(), u.hp)
		var mor := _make_bar(Color(0.28, 0.55, 0.95), u.get_max_morale(), u.morale)
		row.add_child(hp)
		row.add_child(mor)
		if is_enemy:
			row.mouse_entered.connect(func() -> void: unit_hovered.emit(i))
			row.mouse_exited.connect(func() -> void: unit_unhovered.emit())
			row.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
					unit_clicked.emit(i))
		vbox.add_child(row)
		_rows.append(row)
		_names.append(lbl)
		_hp_bars.append(hp)
		_mor_bars.append(mor)


func _make_bar(col: Color, max_v: int, cur_v: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(36, 7)
	bar.show_percentage = false
	bar.max_value = maxf(float(max_v), 1.0)
	bar.value = clampf(float(cur_v), 0.0, bar.max_value)
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func sync(active_idx: int = -1, highlight_targets: bool = false) -> void:
	if _squad == null:
		return
	for i: int in mini(_squad.units.size(), _hp_bars.size()):
		var u: UnitInstance = _squad.units[i]
		_hp_bars[i].value = clampf(float(u.hp), 0.0, _hp_bars[i].max_value)
		_mor_bars[i].value = clampf(float(u.morale), 0.0, _mor_bars[i].max_value)
		var col := Color(0.5, 0.5, 0.5) if not u.is_alive() else (
			Color(1.0, 0.88, 0.3) if i == active_idx else (
			Color(1.0, 0.45, 0.4) if (highlight_targets and _is_enemy) else Color(0.92, 0.92, 0.9)))
		_names[i].add_theme_color_override("font_color", col)
