class_name OptionsPanel
extends PanelContainer
## Painel reutilizável de Opções (Tela Cheia, Volumes, Velocidade de Batalha, Reduzir Clarões).

signal closed

var _fullscreen_cb: CheckButton
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _speed_opt: OptionButton
var _flash_cb: CheckButton


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(310, 210)
	_build_ui()


func open() -> void:
	_sync_from_settings()
	visible = true


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Opções"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	_fullscreen_cb = _add_check_row(vbox, "Tela Cheia", func(on: bool) -> void:
		SaveSystem.settings["fullscreen"] = on
		SaveSystem.save_settings())
	_fullscreen_cb.disabled = OS.has_feature("web")

	_master_slider = _add_slider_row(vbox, "Volume Geral", func(v: float) -> void:
		SaveSystem.settings["master_volume"] = v
		SaveSystem.save_settings())
	_music_slider = _add_slider_row(vbox, "Música", func(v: float) -> void:
		SaveSystem.settings["music_volume"] = v
		SaveSystem.save_settings())
	_sfx_slider = _add_slider_row(vbox, "Efeitos (SFX)", func(v: float) -> void:
		SaveSystem.settings["sfx_volume"] = v
		SaveSystem.save_settings())

	var speed_row := HBoxContainer.new()
	var speed_lbl := Label.new()
	speed_lbl.text = "Velocidade da Batalha"
	speed_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed_lbl.add_theme_font_size_override("font_size", 9)
	speed_row.add_child(speed_lbl)
	_speed_opt = OptionButton.new()
	_speed_opt.add_item("Normal", 0)
	_speed_opt.add_item("Rápida", 1)
	_speed_opt.item_selected.connect(func(idx: int) -> void:
		SaveSystem.settings["battle_speed"] = "fast" if idx == 1 else "normal"
		SaveSystem.save_settings())
	speed_row.add_child(_speed_opt)
	vbox.add_child(speed_row)

	_flash_cb = _add_check_row(vbox, "Reduzir Clarões", func(on: bool) -> void:
		SaveSystem.settings["reduce_flashes"] = on
		SaveSystem.save_settings())

	var close_btn := Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(90, 24)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	vbox.add_child(close_btn)


func _add_check_row(parent: VBoxContainer, label_text: String, cb: Callable) -> CheckButton:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 9)
	row.add_child(lbl)
	var btn := CheckButton.new()
	btn.toggled.connect(cb)
	row.add_child(btn)
	parent.add_child(row)
	return btn


func _add_slider_row(parent: VBoxContainer, label_text: String, cb: Callable) -> HSlider:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(110, 0)
	lbl.add_theme_font_size_override("font_size", 9)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(cb)
	row.add_child(slider)
	parent.add_child(row)
	return slider


func _sync_from_settings() -> void:
	_fullscreen_cb.set_pressed_no_signal(bool(SaveSystem.settings.get("fullscreen", false)))
	_master_slider.set_value_no_signal(float(SaveSystem.settings.get("master_volume", 1.0)))
	_music_slider.set_value_no_signal(float(SaveSystem.settings.get("music_volume", 0.85)))
	_sfx_slider.set_value_no_signal(float(SaveSystem.settings.get("sfx_volume", 0.90)))
	_speed_opt.select(1 if String(SaveSystem.settings.get("battle_speed", "normal")) == "fast" else 0)
	_flash_cb.set_pressed_no_signal(bool(SaveSystem.settings.get("reduce_flashes", false)))
