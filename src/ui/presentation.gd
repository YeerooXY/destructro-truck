extends CanvasLayer
## Views render supplied copies. Signals carry intentions, never changed game state.
signal intent(action: String, value: Variant)

const Game = preload("res://src/core/contracts/game_contracts.gd")
const INK := Color("101d29")
const PAPER := Color("eef4ed")
const MUTED := Color("99aea9")
const ACCENT := Color("d4ef76")
const BLUE := Color("84cad1")
var root: Control
var overlay: Control
var hud: Control
var score_label: Label
var detail_label: Label
var energy_bar: ProgressBar
var launch_bar: ProgressBar
var launch_panel: PanelContainer
var hint_label: Label
var feedback_label: Label
var gamepad := false
var screen := "menu"
var feedback_ttl := 0.0


func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hud()


func _label(text: String, size: int = 20, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _button(text: String, action: String, value: Variant = null, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = tr(text)
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _style(ACCENT if primary else Color("263b45")))
	button.add_theme_stylebox_override("hover", _style(BLUE))
	button.add_theme_stylebox_override("pressed", _style(Color("b2cf59")))
	button.add_theme_stylebox_override("focus", _style(Color(0.5, 0.8, 0.8, 0.35), ACCENT))
	button.pressed.connect(func(): intent.emit(action, value))
	return button


func _bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style


func _new_overlay(width: float = 460) -> VBoxContainer:
	_clear_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.055, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", _style(Color("142630"), Color("344c55")))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


func _clear_overlay() -> void:
	if not is_instance_valid(overlay):
		overlay = null
		return
	var previous := overlay
	overlay = null
	if previous.get_parent() == root:
		root.remove_child(previous)
	previous.queue_free()


func show_menu() -> void:
	screen = "menu"
	hud.hide()
	var box := _new_overlay(500)
	box.add_child(_label("FIRST PLAYABLE  /  TEST YARD", 14, BLUE))
	box.add_child(_label("DESTRUCTRO\nTRUCK", 54))
	box.add_child(_label("Spend momentum. Make a mess. Go again.", 19, MUTED))
	var line := HSeparator.new()
	box.add_child(line)
	var survival := _button("Survival — keep moving", "start", "survival", true)
	box.add_child(survival)
	box.add_child(_button("Timed Efficiency — 60 seconds", "start", "timed_efficiency"))
	box.add_child(_button("Controls", "controls"))
	box.add_child(_button("Exit", "exit"))
	box.add_child(_label("A physics prototype. Progress is not saved yet.", 14, MUTED))
	survival.grab_focus()


func show_controls() -> void:
	screen = "controls"
	var box := _new_overlay(590)
	box.add_child(_label("MAKE MOMENTUM COUNT", 28))
	box.add_child(_label("Space / gamepad A     Launch on the center mark\nA · D / left stick         Rotate in the air\nArrow keys / right stick  Nudge (uses energy)\nR / gamepad Y             Restart\nEsc / Start                  Pause", 20))
	box.add_child(_label("Buildings cost speed. Balloons restore it.\nLevel landings preserve your forward motion.\nTap nudge for a correction; hold for a stronger push.", 18, MUTED))
	var back := _button("Back", "menu", null, true)
	box.add_child(back)
	back.grab_focus()


func show_gameplay() -> void:
	screen = "gameplay"
	_clear_overlay()
	hud.show()
	launch_panel.show()
	feedback_label.text = ""
	get_viewport().gui_release_focus()


func show_pause() -> void:
	screen = "pause"
	var box := _new_overlay()
	box.add_child(_label("TAKE A BREATHER", 30))
	box.add_child(_label("Your run is paused.", 18, MUTED))
	var resume_button := _button("Resume", "resume", null, true)
	box.add_child(resume_button)
	box.add_child(_button("Restart run", "restart"))
	box.add_child(_button("Main menu", "menu"))
	resume_button.grab_focus()


func show_results(result: Dictionary) -> void:
	screen = "results"
	launch_panel.hide()
	var box := _new_overlay(510)
	box.add_child(_label("RUN COMPLETE", 14, BLUE))
	box.add_child(_label("%s POINTS" % _number(int(result.get("score_total", 0))), 40))
	box.add_child(_label(tr("%d buildings  ·  %.0f m  ·  %.1f seconds") % [int(result.get("destroyed_count", 0)), float(result.get("distance_px", 0.0)) / Game.PIXELS_PER_METRE, float(result.get("elapsed_s", 0.0))], 18, MUTED))
	var breakdown: Dictionary = result.get("score_breakdown", {})
	for key in breakdown:
		var row := HBoxContainer.new()
		var left := _label(str(key).capitalize(), 17, MUTED)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		row.add_child(_label(_number(int(breakdown[key])), 17))
		box.add_child(row)
	box.add_child(_label("$%s earned this run · prototype only" % int(result.get("money_earned", 0)), 16, BLUE))
	var retry := _button("One more run", "restart", null, true)
	box.add_child(retry)
	box.add_child(_button("Main menu", "menu"))
	retry.grab_focus()


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	top.offset_bottom = 112
	top.add_theme_stylebox_override("panel", _style(Color(0.06, 0.12, 0.16, 0.94)))
	hud.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	top.add_child(row)
	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_child(_label("DESTRUCTRO TRUCK", 18, BLUE))
	detail_label = _label("TEST YARD", 17, MUTED)
	name_box.add_child(detail_label)
	row.add_child(name_box)
	score_label = _label("0", 32)
	row.add_child(score_label)
	var energy_box := VBoxContainer.new()
	energy_box.custom_minimum_size.x = 180
	energy_box.add_child(_label("NUDGE ENERGY", 13, BLUE))
	energy_bar = ProgressBar.new()
	energy_bar.custom_minimum_size = Vector2(180, 18)
	energy_bar.show_percentage = false
	energy_bar.add_theme_stylebox_override("background", _bar(Color("284049")))
	energy_bar.add_theme_stylebox_override("fill", _bar(ACCENT))
	energy_box.add_child(energy_bar)
	row.add_child(energy_box)
	row.add_child(_button("Pause", "pause"))
	launch_panel = PanelContainer.new()
	launch_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	launch_panel.position = Vector2(-235, -174)
	launch_panel.size = Vector2(470, 128)
	launch_panel.add_theme_stylebox_override("panel", _style(Color("142630")))
	hud.add_child(launch_panel)
	var launch_box := VBoxContainer.new()
	launch_panel.add_child(launch_box)
	launch_box.add_child(_label("LAUNCH ON THE CENTER MARK", 19))
	launch_bar = ProgressBar.new()
	launch_bar.custom_minimum_size = Vector2(400, 18)
	launch_bar.max_value = 1.0
	launch_bar.show_percentage = false
	launch_bar.add_theme_stylebox_override("background", _bar(Color("284049")))
	launch_bar.add_theme_stylebox_override("fill", _bar(BLUE))
	launch_box.add_child(launch_bar)
	var marker := _label("                         ▲                         ", 16, ACCENT)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	launch_box.add_child(marker)
	launch_box.add_child(_label("Space / A to launch", 15, MUTED))
	hint_label = _label("", 17, PAPER)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.position = Vector2(28, -38)
	hud.add_child(hint_label)
	feedback_label = _label("", 24, ACCENT)
	feedback_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	feedback_label.position = Vector2(-220, 132)
	feedback_label.size = Vector2(440, 42)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(feedback_label)
	hud.hide()


func render_hud(model: Dictionary) -> void:
	if model.is_empty():
		return
	var run: Dictionary = model.run
	score_label.text = _number(int(run.score_total))
	var time_text := tr("SURVIVAL")
	if run.time_remaining_s != null:
		time_text = tr("TIME LEFT  %.1f s") % float(run.time_remaining_s)
	detail_label.text = tr("%s   /   %.0f m   /   %.0f km/h   /   CHAIN %d") % [time_text, float(run.distance_px) / Game.PIXELS_PER_METRE, float(model.truck.momentum) / Game.PIXELS_PER_METRE * 3.6, int(run.combo)]
	energy_bar.max_value = float(model.resources.nudge_capacity)
	energy_bar.value = float(model.truck.nudge_energy)
	launch_bar.value = float(model.launch.phase)
	launch_panel.visible = bool(model.launch.ready) and screen == "gameplay"
	hint_label.text = tr("Left stick: rotate  ·  Right stick: nudge  ·  Y: retry") if gamepad else tr("A / D: rotate  ·  Arrow keys: nudge  ·  R: retry")


func feedback(text: String) -> void:
	feedback_label.text = tr(text)
	feedback_ttl = 1.6


func show_error(message: String) -> void:
	screen = "error"
	hud.hide()
	var box := _new_overlay(620)
	box.add_child(_label("COULD NOT OPEN THE TEST YARD", 24))
	var message_label := _label(message, 16, MUTED)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message_label)
	box.add_child(_button("Exit", "exit", null, true))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if screen in ["controls", "results"]:
			intent.emit("menu", null)
			get_viewport().set_input_as_handled()
		elif screen == "pause":
			intent.emit("resume", null)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	feedback_ttl = maxf(0.0, feedback_ttl - delta)
	if feedback_ttl <= 0.0:
		feedback_label.text = ""


func _number(value: int) -> String:
	var raw := str(value)
	var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length() - i) % 3 == 0:
			result += " "
		result += raw[i]
	return result
