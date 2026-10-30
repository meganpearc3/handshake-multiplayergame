class_name MainMenu
extends Control

var _how_to_play_modal: PanelContainer = null
var _audio_mgr: Node = null

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_build_ui()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background gradient/fill
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.1)
	add_child(bg)
	
	# Main layout vbox
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -400.0
	vbox.offset_right = 400.0
	vbox.offset_top = -280.0
	vbox.offset_bottom = 280.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# Title
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "THE GREAT GEM CAPER"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(title)
	
	# Subtitle
	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.text = "★ 3D TWO-PLAYER FIRST-PERSON CO-OP HEIST ★\nPress [V] anytime to toggle View Mode (Split FP / Full FP / Overhead)"
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vbox.add_child(sub)
	
	var sep1 := HSeparator.new()
	sep1.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(sep1)
	
	# Player cards hbox
	var cards_hbox := HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_hbox)
	
	# Cipher Card
	var c_card := PanelContainer.new()
	c_card.custom_minimum_size = Vector2(340, 140)
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.06, 0.14, 0.26, 0.9)
	csb.border_width_left = 3
	csb.border_color = Color(0.3, 0.75, 1.0)
	csb.corner_radius_top_left = 8
	csb.corner_radius_top_right = 8
	csb.corner_radius_bottom_left = 8
	csb.corner_radius_bottom_right = 8
	csb.set_content_margin_all(12.0)
	c_card.add_theme_stylebox_override("panel", csb)
	
	var c_vbox := VBoxContainer.new()
	var c_name := Label.new()
	c_name.text = "PLAYER 1: CIPHER"
	c_name.add_theme_font_size_override("font_size", 18)
	c_name.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	c_vbox.add_child(c_name)
	
	var c_info := Label.new()
	c_info.text = "Role: Hacker & Grid Controller\nControls: W/S (Forward/Back), A/D (Turn View)\nInteract: [ E ] | Shift+A/D: Strafe"
	c_info.add_theme_font_size_override("font_size", 14)
	c_info.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	c_vbox.add_child(c_info)
	c_card.add_child(c_vbox)
	cards_hbox.add_child(c_card)
	
	var c_sep := Control.new()
	c_sep.custom_minimum_size = Vector2(24, 0)
	cards_hbox.add_child(c_sep)
	
	# Spark Card
	var s_card := PanelContainer.new()
	s_card.custom_minimum_size = Vector2(340, 140)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.24, 0.12, 0.04, 0.9)
	ssb.border_width_right = 3
	ssb.border_color = Color(1.0, 0.6, 0.1)
	ssb.corner_radius_top_left = 8
	ssb.corner_radius_top_right = 8
	ssb.corner_radius_bottom_left = 8
	ssb.corner_radius_bottom_right = 8
	ssb.set_content_margin_all(12.0)
	s_card.add_theme_stylebox_override("panel", ssb)
	
	var s_vbox := VBoxContainer.new()
	var s_name := Label.new()
	s_name.text = "PLAYER 2: SPARK"
	s_name.add_theme_font_size_override("font_size", 18)
	s_name.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	s_vbox.add_child(s_name)
	
	var s_info := Label.new()
	s_info.text = "Role: Infiltrator & Lock Specialist\nControls: ↑/↓ (Forward/Back), ←/→ (Turn View)\nInteract: [ Enter ] | Shift+←/→: Strafe"
	s_info.add_theme_font_size_override("font_size", 14)
	s_info.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	s_vbox.add_child(s_info)
	s_card.add_child(s_vbox)
	cards_hbox.add_child(s_card)
	
	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(sep2)
	
	# Menu buttons
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)
	
	var start_btn := Button.new()
	start_btn.text = "  START CO-OP HEIST  "
	start_btn.custom_minimum_size = Vector2(200, 48)
	start_btn.pressed.connect(_on_start_pressed)
	btn_box.add_child(start_btn)
	
	var b_sep1 := Control.new()
	b_sep1.custom_minimum_size = Vector2(16, 0)
	btn_box.add_child(b_sep1)
	
	var how_btn := Button.new()
	how_btn.text = "  HOW TO PLAY  "
	how_btn.custom_minimum_size = Vector2(160, 48)
	how_btn.pressed.connect(_on_how_to_play_pressed)
	btn_box.add_child(how_btn)
	
	var b_sep2 := Control.new()
	b_sep2.custom_minimum_size = Vector2(16, 0)
	btn_box.add_child(b_sep2)
	
	var quit_btn := Button.new()
	quit_btn.text = "  QUIT  "
	quit_btn.custom_minimum_size = Vector2(120, 48)
	quit_btn.pressed.connect(func(): get_tree().quit())
	btn_box.add_child(quit_btn)
	
	# How to Play Modal (hidden by default)
	_build_how_to_play_modal()

func _build_how_to_play_modal() -> void:
	_how_to_play_modal = PanelContainer.new()
	_how_to_play_modal.set_anchors_preset(Control.PRESET_CENTER)
	_how_to_play_modal.offset_left = -320.0
	_how_to_play_modal.offset_right = 320.0
	_how_to_play_modal.offset_top = -220.0
	_how_to_play_modal.offset_bottom = 220.0
	
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.08, 0.1, 0.15, 0.98)
	msb.border_width_left = 3
	msb.border_width_right = 3
	msb.border_width_top = 3
	msb.border_width_bottom = 3
	msb.border_color = Color(1.0, 0.85, 0.2)
	msb.corner_radius_top_left = 10
	msb.corner_radius_top_right = 10
	msb.corner_radius_bottom_left = 10
	msb.corner_radius_bottom_right = 10
	msb.set_content_margin_all(20.0)
	_how_to_play_modal.add_theme_stylebox_override("panel", msb)
	_how_to_play_modal.visible = false
	add_child(_how_to_play_modal)
	
	var mvbox := VBoxContainer.new()
	mvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_how_to_play_modal.add_child(mvbox)
	
	var mtitle := Label.new()
	mtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mtitle.text = "HOW TO PLAY: HEIST RULES"
	mtitle.add_theme_font_size_override("font_size", 22)
	mtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	mvbox.add_child(mtitle)
	
	var mtext := Label.new()
	mtext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mtext.text = """1. PUZZLE 1: Cipher hacks the security terminal to read the 4-digit code. Spark presses the matching colored pedestals across the room in exact order!

2. PUZZLE 2: Moving laser tripwires block the corridor. Cipher holds Switch A so Spark can cross and grab the Gold Keycard. Spark then holds Switch B so Cipher can join him! Insert the keycard to unlock the vault.

3. PUZZLE 3: Both players must step on the dual pressure plates simultaneously to power up the vault lock. Read the 3-digit code from museum plaques and enter it into the console.

4. THE ESCAPE: Steal the Midnight Diamond! The alarms will blare with a 60-second timer. BOTH players must escape back to the getaway van outside!"""
	mtext.add_theme_font_size_override("font_size", 14)
	mvbox.add_child(mtext)
	
	var mclose := Button.new()
	mclose.text = "  GOT IT, LET'S HEIST!  "
	mclose.custom_minimum_size = Vector2(180, 40)
	mclose.pressed.connect(func(): _how_to_play_modal.visible = false)
	mvbox.add_child(mclose)

func _on_start_pressed() -> void:
	if _audio_mgr:
		_audio_mgr.play_click()
	get_tree().change_scene_to_file("res://scenes/heist_game.tscn")

func _on_how_to_play_pressed() -> void:
	if _audio_mgr:
		_audio_mgr.play_click()
	if _how_to_play_modal:
		_how_to_play_modal.visible = not _how_to_play_modal.visible
