class_name HeistHUD
extends CanvasLayer

signal restart_requested()

const _phase_names: Array[String] = ["1. HACK OVERRIDE", "2. LASER GALLERY", "3. DIAMOND VAULT", "4. GETAWAY VAN"]

var _objective_label: Label = null
var _timer_label: Label = null
var _alarm_label: Label = null
var _escape_banner: PanelContainer = null
var _escape_timer_label: Label = null
var _radio_box: PanelContainer = null
var _radio_text: Label = null
var _p1_card_label: Label = null
var _p2_card_label: Label = null
var _phase_labels: Array[Label] = []

var _time_elapsed: float = 0.0
var _escape_time_left: float = 60.0
var _is_escape_active: bool = false
var _radio_timer: float = 0.0

func _ready() -> void:
	_build_hud_ui()

func _build_hud_ui() -> void:
	# Root container
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# Top bar for Objectives & Stats
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 82.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.92)
	sb.border_width_bottom = 2
	sb.border_color = Color(0.18, 0.5, 0.8, 0.8)
	sb.set_content_margin_all(8.0)
	top_bar.add_theme_stylebox_override("panel", sb)
	root.add_child(top_bar)
	
	var top_vbox := VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 4)
	top_bar.add_child(top_vbox)
	
	var h_box := HBoxContainer.new()
	h_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_vbox.add_child(h_box)
	
	# Objective text
	_objective_label = Label.new()
	_objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objective_label.text = "OBJECTIVE: Infiltrate Museum & Override Security Bulkhead"
	_objective_label.add_theme_font_size_override("font_size", 18)
	_objective_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	h_box.add_child(_objective_label)
	
	# Alarm counter
	_alarm_label = Label.new()
	_alarm_label.text = "ALARMS: 0"
	_alarm_label.add_theme_font_size_override("font_size", 17)
	_alarm_label.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))
	h_box.add_child(_alarm_label)
	
	var sep := VSeparator.new()
	sep.custom_minimum_size = Vector2(20, 0)
	h_box.add_child(sep)
	
	# Mission Timer
	_timer_label = Label.new()
	_timer_label.text = "TIME: 00:00"
	_timer_label.add_theme_font_size_override("font_size", 17)
	_timer_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	h_box.add_child(_timer_label)
	
	# Progress Phase Ribbon
	var steps_box := HBoxContainer.new()
	steps_box.alignment = BoxContainer.ALIGNMENT_CENTER
	steps_box.add_theme_constant_override("separation", 12)
	top_vbox.add_child(steps_box)
	
	for i in range(_phase_names.size()):
		if i > 0:
			var arrow := Label.new()
			arrow.text = "➔"
			arrow.add_theme_font_size_override("font_size", 11)
			arrow.add_theme_color_override("font_color", Color(0.35, 0.45, 0.55))
			steps_box.add_child(arrow)
		
		var pill := Label.new()
		pill.text = _phase_names[i]
		pill.add_theme_font_size_override("font_size", 12)
		pill.add_theme_color_override("font_color", Color(0.45, 0.55, 0.65))
		steps_box.add_child(pill)
		_phase_labels.append(pill)
	
	set_phase(1)
	
	# Escape Banner (Appears in center top when diamond stolen)
	_escape_banner = PanelContainer.new()
	_escape_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_escape_banner.offset_top = 92.0
	_escape_banner.offset_left = -220.0
	_escape_banner.offset_right = 220.0
	_escape_banner.offset_bottom = 152.0
	var esb := StyleBoxFlat.new()
	esb.bg_color = Color(0.7, 0.08, 0.08, 0.92)
	esb.border_width_left = 3
	esb.border_width_right = 3
	esb.border_width_top = 3
	esb.border_width_bottom = 3
	esb.border_color = Color(1.0, 0.8, 0.2)
	esb.corner_radius_top_left = 8
	esb.corner_radius_top_right = 8
	esb.corner_radius_bottom_left = 8
	esb.corner_radius_bottom_right = 8
	esb.set_content_margin_all(8.0)
	_escape_banner.add_theme_stylebox_override("panel", esb)
	_escape_banner.visible = false
	root.add_child(_escape_banner)
	
	_escape_timer_label = Label.new()
	_escape_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_escape_timer_label.text = "ESCAPE TO VAN: 60.0s"
	_escape_timer_label.add_theme_font_size_override("font_size", 24)
	_escape_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_escape_banner.add_child(_escape_timer_label)
	
	# Bottom Player Badges
	var bottom_box := HBoxContainer.new()
	bottom_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_box.offset_top = -60.0
	bottom_box.offset_left = 16.0
	bottom_box.offset_right = -16.0
	bottom_box.offset_bottom = -16.0
	root.add_child(bottom_box)
	
	# P1 Cipher Badge
	_p1_card_label = Label.new()
	_p1_card_label.text = "  CIPHER [P1]: WASD + [E]  "
	_p1_card_label.add_theme_font_size_override("font_size", 16)
	_p1_card_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	var p1_sb := StyleBoxFlat.new()
	p1_sb.bg_color = Color(0.05, 0.12, 0.22, 0.85)
	p1_sb.border_width_left = 2
	p1_sb.border_color = Color(0.2, 0.7, 1.0)
	p1_sb.set_content_margin_all(8.0)
	_p1_card_label.add_theme_stylebox_override("normal", p1_sb)
	bottom_box.add_child(_p1_card_label)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(spacer)
	
	# P2 Spark Badge
	_p2_card_label = Label.new()
	_p2_card_label.text = "  SPARK [P2]: Arrows + [Enter]  "
	_p2_card_label.add_theme_font_size_override("font_size", 16)
	_p2_card_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	var p2_sb := StyleBoxFlat.new()
	p2_sb.bg_color = Color(0.2, 0.1, 0.04, 0.85)
	p2_sb.border_width_right = 2
	p2_sb.border_color = Color(1.0, 0.6, 0.1)
	p2_sb.set_content_margin_all(8.0)
	_p2_card_label.add_theme_stylebox_override("normal", p2_sb)
	bottom_box.add_child(_p2_card_label)
	
	# Getaway Driver Radio Box (Bottom Center)
	_radio_box = PanelContainer.new()
	_radio_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_radio_box.offset_bottom = -75.0
	_radio_box.offset_left = -300.0
	_radio_box.offset_right = 300.0
	_radio_box.offset_top = -145.0
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	rsb.border_width_left = 3
	rsb.border_color = Color(0.9, 0.8, 0.2)
	rsb.corner_radius_top_left = 6
	rsb.corner_radius_top_right = 6
	rsb.corner_radius_bottom_left = 6
	rsb.corner_radius_bottom_right = 6
	rsb.set_content_margin_all(10.0)
	_radio_box.add_theme_stylebox_override("panel", rsb)
	_radio_box.visible = false
	root.add_child(_radio_box)
	
	_radio_text = Label.new()
	_radio_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio_text.text = "DRIVER: Let's get that diamond!"
	_radio_text.add_theme_font_size_override("font_size", 15)
	_radio_text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	_radio_box.add_child(_radio_text)

func set_objective(text: String) -> void:
	if _objective_label:
		_objective_label.text = "OBJECTIVE: " + text
	
	if text.findn("Override") != -1 or text.findn("Infiltrate") != -1:
		set_phase(1)
	elif text.findn("Laser") != -1 or text.findn("Keycard") != -1:
		set_phase(2)
	elif text.findn("Vault") != -1 or text.findn("Pressure") != -1:
		set_phase(3)
	elif text.findn("ESCAPE") != -1 or text.findn("Van") != -1:
		set_phase(4)

func set_phase(phase_num: int) -> void:
	for i in range(_phase_labels.size()):
		var lbl: Label = _phase_labels[i]
		var step_idx := i + 1
		if step_idx < phase_num:
			lbl.text = "✔ " + _phase_names[i]
			lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
		elif step_idx == phase_num:
			lbl.text = "▶ " + _phase_names[i]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lbl.text = "   " + _phase_names[i]
			lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.65))

func update_alarms(count: int) -> void:
	if _alarm_label:
		_alarm_label.text = "ALARMS: %d" % count

func show_driver_radio(message: String, duration: float = 4.5) -> void:
	if _radio_box and _radio_text:
		_radio_text.text = "📻 DRIVER 'WHEELS': \"" + message + "\""
		_radio_box.visible = true
		_radio_timer = duration

func start_escape_countdown(seconds: float = 60.0) -> void:
	_is_escape_active = true
	_escape_time_left = seconds
	if _escape_banner:
		_escape_banner.visible = true

func _process(delta: float) -> void:
	_time_elapsed += delta
	var mins := int(_time_elapsed) / 60
	var secs := int(_time_elapsed) % 60
	if _timer_label:
		_timer_label.text = "TIME: %02d:%02d" % [mins, secs]
	
	if _is_escape_active:
		_escape_time_left = maxf(_escape_time_left - delta, 0.0)
		if _escape_timer_label:
			_escape_timer_label.text = "ESCAPE TO VAN: %.1fs" % _escape_time_left
			# Pulse scale/color
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.01)
			_escape_timer_label.modulate = Color(1.0, 0.8 + 0.2 * pulse, 0.8 + 0.2 * pulse)
	
	if _radio_timer > 0.0:
		_radio_timer -= delta
		if _radio_timer <= 0.0 and _radio_box:
			_radio_box.visible = false
