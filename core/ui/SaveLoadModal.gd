class_name SaveLoadModal
extends PanelContainer
## Painel multi-slot (Autosave + Slots 1..3) para Carregar ou Salvar campanhas.

signal closed
signal slot_loaded(slot: int)
signal slot_saved(slot: int)

var _mode: String = "load"
var _title_lbl: Label
var _list_box: VBoxContainer


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(380, 220)
	_build_shell()


func open(mode: String = "load") -> void:
	_mode = mode
	_title_lbl.text = "Salvar Campanha" if _mode == "save" else "Carregar Campanha"
	_rebuild_rows()
	visible = true


func _build_shell() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_title_lbl)

	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 5)
	_list_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_list_box)

	var close_btn := Button.new()
	close_btn.text = "Voltar"
	close_btn.custom_minimum_size = Vector2(90, 24)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	vbox.add_child(close_btn)


func _rebuild_rows() -> void:
	for child: Node in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	for meta: Dictionary in SaveSystem.list_slots():
		var slot: int = int(meta["slot"])
		var empty: bool = bool(meta.get("empty", true))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 8)
		var slot_title := "Autosave" if slot == 0 else "Slot %d" % slot
		if empty:
			lbl.text = "%s — (Vazio)" % slot_title
		else:
			lbl.text = "%s — Ato %d (%s) · Dia %d · %s · %s" % [
				slot_title, int(meta.get("act_number", 1)), String(meta.get("era_title", "")),
				int(meta.get("day_count", 1)), String(meta.get("leader_name", "")),
				String(meta.get("saved_at", ""))]
		row.add_child(lbl)

		if _mode == "save":
			if slot > 0:
				var save_btn := Button.new()
				save_btn.text = "Salvar"
				save_btn.custom_minimum_size = Vector2(64, 22)
				save_btn.pressed.connect(func() -> void:
					if SaveSystem.save_slot(slot):
						visible = false
						slot_saved.emit(slot))
				row.add_child(save_btn)
		else:
			var load_btn := Button.new()
			load_btn.text = "Carregar"
			load_btn.disabled = empty
			load_btn.custom_minimum_size = Vector2(68, 22)
			load_btn.pressed.connect(func() -> void:
				if SaveSystem.load_slot(slot):
					visible = false
					slot_loaded.emit(slot))
			row.add_child(load_btn)
			if not empty:
				var del_btn := Button.new()
				del_btn.text = "✕"
				del_btn.custom_minimum_size = Vector2(26, 22)
				del_btn.pressed.connect(func() -> void:
					SaveSystem.delete_slot(slot)
					_rebuild_rows())
				row.add_child(del_btn)
		_list_box.add_child(row)
