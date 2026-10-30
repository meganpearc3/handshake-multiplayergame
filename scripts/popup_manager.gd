class_name PopupManager
extends CanvasLayer

signal popup_closed()

var _active_card: PanelContainer = null
var _audio_mgr: Node = null
var _backdrop: ColorRect = null

func _ready() -> void:
	layer = 100 # On top of game and HUD
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_build_base()

func _build_base() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.04, 0.08, 0.7)
	_backdrop.visible = false
	_backdrop.gui_input.connect(_on_backdrop_input)
	add_child(_backdrop)

func _unhandled_input(event: InputEvent) -> void:
	if is_popup_open():
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_interact") or event.is_action_pressed("p2_interact"):
			close_current()
			get_viewport().set_input_as_handled()

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_current()

func is_popup_open() -> bool:
	return _active_card != null and _active_card.visible

func close_current() -> void:
	if _active_card:
		_active_card.queue_free()
		_active_card = null
	if _backdrop:
		_backdrop.visible = false
	if _audio_mgr:
		_audio_mgr.play_click()
	popup_closed.emit()

func _create_card_container(width: float = 620.0, height: float = 420.0, border_col: Color = Color(0.2, 0.8, 1.0)) -> VBoxContainer:
	if _active_card:
		_active_card.queue_free()
		_active_card = null
	
	_backdrop.visible = true
	
	_active_card = PanelContainer.new()
	_active_card.set_anchors_preset(Control.PRESET_CENTER)
	_active_card.offset_left = -width * 0.5
	_active_card.offset_right = width * 0.5
	_active_card.offset_top = -height * 0.5
	_active_card.offset_bottom = height * 0.5
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.16, 0.96)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = border_col
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.set_content_margin_all(20.0)
	_active_card.add_theme_stylebox_override("panel", sb)
	add_child(_active_card)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_active_card.add_child(vbox)
	
	return vbox

func _add_header(vbox: VBoxContainer, title: String, subtitle: String, header_col: Color = Color(1.0, 0.85, 0.2)) -> void:
	var head_hbox := HBoxContainer.new()
	vbox.add_child(head_hbox)
	
	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_hbox.add_child(title_vbox)
	
	var t_lbl := Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 22)
	t_lbl.add_theme_color_override("font_color", header_col)
	title_vbox.add_child(t_lbl)
	
	if subtitle != "":
		var s_lbl := Label.new()
		s_lbl.text = subtitle
		s_lbl.add_theme_font_size_override("font_size", 14)
		s_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
		title_vbox.add_child(s_lbl)
	
	var close_btn := Button.new()
	close_btn.text = " [X] CLOSE "
	close_btn.custom_minimum_size = Vector2(90, 32)
	close_btn.pressed.connect(close_current)
	head_hbox.add_child(close_btn)
	
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(sep)

# ==========================================================
# 1. PUZZLE 1: CIPHER SECURITY OVERRIDE HACKING POP-UP
# ==========================================================
func show_security_override(target_seq: Array[int], _player_id: int = 1) -> void:
	var vbox := _create_card_container(660.0, 440.0, Color(0.2, 0.85, 1.0))
	_add_header(vbox, "⚡ MERIDIAN MAINFRAME: SECURITY OVERRIDE", "OPERATIVE: CIPHER // HACKING TERMINAL ACTIVE", Color(0.3, 0.9, 1.0))
	
	var info := Label.new()
	info.text = "SECURITY BULKHEAD LOCK ACTIVE. DECRYPTED SEQUENCE IDENTIFIED:\nCOMMUNICATE THESE SYMBOLS TO SPARK AT THE PEDESTALS IN EXACT ORDER:"
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)
	
	# Sequence display cards
	var seq_hbox := HBoxContainer.new()
	seq_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	seq_hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(seq_hbox)
	
	const symbol_names := {
		1: "SQUARE",
		2: "CIRCLE",
		3: "TRIANGLE",
		4: "STAR"
	}
	const symbol_icons := {
		1: "■",
		2: "●",
		3: "▲",
		4: "★"
	}
	const symbol_colors := {
		1: Color(1.0, 0.25, 0.25),
		2: Color(0.25, 0.65, 1.0),
		3: Color(0.2, 0.95, 0.35),
		4: Color(1.0, 0.88, 0.1)
	}
	
	for i in range(target_seq.size()):
		var sym_id: int = target_seq[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(120, 140)
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.05, 0.08, 0.14, 0.95)
		csb.border_width_left = 3
		csb.border_width_right = 3
		csb.border_width_top = 3
		csb.border_width_bottom = 3
		csb.border_color = symbol_colors.get(sym_id, Color.WHITE)
		csb.corner_radius_top_left = 8
		csb.corner_radius_top_right = 8
		csb.corner_radius_bottom_left = 8
		csb.corner_radius_bottom_right = 8
		csb.set_content_margin_all(8.0)
		card.add_theme_stylebox_override("panel", csb)
		
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var step_lbl := Label.new()
		step_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_lbl.text = "STEP %d" % (i + 1)
		step_lbl.add_theme_font_size_override("font_size", 13)
		step_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		cv.add_child(step_lbl)
		
		var icon_lbl := Label.new()
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.text = symbol_icons.get(sym_id, "?")
		icon_lbl.add_theme_font_size_override("font_size", 42)
		icon_lbl.add_theme_color_override("font_color", symbol_colors.get(sym_id, Color.WHITE))
		cv.add_child(icon_lbl)
		
		var name_lbl := Label.new()
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.text = symbol_names.get(sym_id, "???")
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", symbol_colors.get(sym_id, Color.WHITE))
		cv.add_child(name_lbl)
		
		card.add_child(cv)
		seq_hbox.add_child(card)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Label.new()
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "[ PRESS E OR ESC TO CLOSE TERMINAL ]"
	foot.add_theme_font_size_override("font_size", 14)
	foot.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(foot)
	
	if _audio_mgr:
		if _audio_mgr.has_method("play_terminal_hack"):
			_audio_mgr.play_terminal_hack()
		elif _audio_mgr.has_method("play_beep"):
			_audio_mgr.play_beep(880.0, 0.12)

# ==========================================================
# 2. PUZZLE 1: SPARK BUTTON INPUT STATUS POP-UP
# ==========================================================
func show_pedestal_input(btn_name: String, is_correct: bool, current_count: int, total_count: int) -> void:
	var col := Color(0.2, 0.9, 0.4) if is_correct else Color(0.95, 0.25, 0.25)
	var vbox := _create_card_container(540.0, 300.0, col)
	
	var title := "INPUT ACCEPTED" if is_correct else "⚠️ ALARM STRIKE: MISMATCH!"
	_add_header(vbox, title, "PEDESTAL CONTROL PANEL // SPARK", col)
	
	var msg := Label.new()
	if is_correct:
		msg.text = "PEDESTAL ACTIVATED: [ %s ]\nPROGRESS: %d OF %d SYMBOLS VERIFIED!" % [btn_name, current_count, total_count]
		if current_count == total_count:
			msg.text += "\n\n★ SEQUENCE COMPLETE! BULKHEAD DOOR UNSEALED! ★"
	else:
		msg.text = "INCORRECT PEDESTAL PRESSED: [ %s ]\nSECURITY SYSTEM TRIGGERED ALARM STRIKE!\nSEQUENCE RESET - CIPHER MUST RE-VERIFY CODE." % btn_name
	
	msg.add_theme_font_size_override("font_size", 16)
	msg.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Label.new()
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "[ PRESS ENTER OR ESC TO CLOSE ]"
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(foot)

# ==========================================================
# 3. PUZZLE 2: LASER SCHEMATIC POP-UP
# ==========================================================
func show_laser_bypass(switch_name: String, is_held: bool) -> void:
	var vbox := _create_card_container(580.0, 340.0, Color(1.0, 0.3, 0.3))
	_add_header(vbox, "⚡ LASER CORRIDOR DEFENSE GRID", "BYPASS CONTROL SWITCH", Color(1.0, 0.4, 0.4))
	
	var text := Label.new()
	if is_held:
		text.text = "%s IS CURRENTLY ENGAGED!\n\nCORRESPONDING LASER TRIPWIRES TEMPORARILY DISABLED.\nPARTNER: SPRINT ACROSS THE CORRIDOR NOW!" % switch_name
	else:
		text.text = "%s RELEASED!\n\nLASER TRIPWIRES HAVE RE-ARMED. HOLD THIS SWITCH TO KEEP THE PATH CLEAR!" % switch_name
	
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Label.new()
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "[ HOLD INTERACT KEY TO MAINTAIN BYPASS ]"
	foot.add_theme_font_size_override("font_size", 14)
	foot.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(foot)

# ==========================================================
# 4. PUZZLE 3: CLUE PLAQUE POP-UP
# ==========================================================
func show_clue_plaque(plaque_title: String, digit: int, description: String) -> void:
	var vbox := _create_card_container(540.0, 360.0, Color(1.0, 0.85, 0.2))
	_add_header(vbox, "🏛 GRAND MERIDIAN ARCHIVES", plaque_title, Color(1.0, 0.85, 0.25))
	
	var body := Label.new()
	body.text = description
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)
	
	# Giant digit badge
	var d_card := PanelContainer.new()
	d_card.custom_minimum_size = Vector2(140, 100)
	d_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var dsb := StyleBoxFlat.new()
	dsb.bg_color = Color(0.12, 0.15, 0.22, 0.95)
	dsb.border_width_left = 3
	dsb.border_width_right = 3
	dsb.border_width_top = 3
	dsb.border_width_bottom = 3
	dsb.border_color = Color(1.0, 0.85, 0.2)
	dsb.corner_radius_top_left = 8
	dsb.corner_radius_top_right = 8
	dsb.corner_radius_bottom_left = 8
	dsb.corner_radius_bottom_right = 8
	d_card.add_theme_stylebox_override("panel", dsb)
	
	var d_lbl := Label.new()
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	d_lbl.text = "%d" % digit
	d_lbl.add_theme_font_size_override("font_size", 54)
	d_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	d_card.add_child(d_lbl)
	vbox.add_child(d_card)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Label.new()
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "[ PRESS E / ENTER / ESC TO CLOSE ]"
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	vbox.add_child(foot)
	
	if _audio_mgr:
		_audio_mgr.play_click()

# ==========================================================
# 5. PUZZLE 3: VAULT CONSOLE KEYPAD POP-UP
# ==========================================================
func show_vault_keypad(entered: Array[int], is_latched: bool, is_unlocked: bool) -> void:
	var border_col := Color(0.2, 0.9, 0.4) if is_unlocked else (Color(0.2, 0.8, 1.0) if is_latched else Color(0.9, 0.2, 0.2))
	var vbox := _create_card_container(620.0, 420.0, border_col)
	
	_add_header(vbox, "🔒 MERIDIAN MASTER VAULT ACCESS", "HIGH-SECURITY DUAL-CIRCUIT LOCK", border_col)
	
	var status_lbl := Label.new()
	if not is_latched:
		status_lbl.text = "CIRCUIT OFFLINE: AUXILIARY POWER REQUIRED!\nBOTH OPERATIVES MUST STEP ON THE DUAL PRESSURE PLATES SIMULTANEOUSLY!"
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	elif is_unlocked:
		status_lbl.text = "★ MASTER AUTHORIZATION ACCEPTED! ★\nROTARY LOCK MECHANISM DISENGAGED - VAULT IS OPEN!"
		status_lbl.add_theme_color_override("font_color", Color(0.25, 1.0, 0.45))
	else:
		status_lbl.text = "CIRCUIT LATCHED: ONLINE!\nENTER 3-DIGIT ARCHIVE COMBINATION IN PROGRESS:"
		status_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	
	status_lbl.add_theme_font_size_override("font_size", 16)
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(status_lbl)
	
	# Display Code Box
	var code_card := PanelContainer.new()
	code_card.custom_minimum_size = Vector2(300, 80)
	code_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.04, 0.06, 0.1, 0.95)
	csb.border_width_left = 2
	csb.border_width_right = 2
	csb.border_width_top = 2
	csb.border_width_bottom = 2
	csb.border_color = border_col
	csb.corner_radius_top_left = 8
	csb.corner_radius_top_right = 8
	csb.corner_radius_bottom_left = 8
	csb.corner_radius_bottom_right = 8
	code_card.add_theme_stylebox_override("panel", csb)
	
	var code_str := ""
	for i in range(3):
		if i < entered.size():
			code_str += " %d " % entered[i]
		else:
			code_str += " _ "
	
	var code_lbl := Label.new()
	code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_lbl.text = "[ %s ]" % code_str.strip_edges()
	code_lbl.add_theme_font_size_override("font_size", 42)
	code_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2) if is_latched else Color(0.7, 0.2, 0.2))
	code_card.add_child(code_lbl)
	vbox.add_child(code_card)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Label.new()
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "[ PRESS E OR ENTER TO ADVANCE CODE // ESC TO CLOSE ]"
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	vbox.add_child(foot)

# ==========================================================
# 6. MIDNIGHT DIAMOND ACQUIRED POP-UP
# ==========================================================
func show_diamond_acquired() -> void:
	var vbox := _create_card_container(640.0, 420.0, Color(0.2, 0.95, 1.0))
	_add_header(vbox, "💎 THE MIDNIGHT DIAMOND ACQUIRED! 💎", "HEIST TARGET SECURED // VALUE: $50,000,000", Color(0.3, 0.95, 1.0))
	
	var body := Label.new()
	body.text = """THE MIDNIGHT DIAMOND IS IN YOUR HANDS!

⚠️ EMERGENCY ALARM PROTOCOL ACTIVATED:
SIRENS ARE WAILING AND POLICE HAVE BEEN NOTIFIED!
THE GETAWAY VAN IS WAITING OUTSIDE IN FRONT OF THE MUSEUM.

BOTH CIPHER AND SPARK MUST REACH THE ESCAPE VAN IN 60 SECONDS!"""
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var foot := Button.new()
	foot.text = "  RUN FOR THE GETAWAY VAN!  "
	foot.custom_minimum_size = Vector2(260, 44)
	foot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	foot.pressed.connect(close_current)
	vbox.add_child(foot)
