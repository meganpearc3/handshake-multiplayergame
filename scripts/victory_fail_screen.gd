class_name VictoryFailScreen
extends CanvasLayer

signal play_again_pressed()
signal main_menu_pressed()

var _panel: PanelContainer = null
var _title_label: Label = null
var _sub_label: Label = null
var _rank_label: Label = null
var _stats_label: Label = null
var _retry_btn: Button = null
var _menu_btn: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	# Dim backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.08, 0.85)
	root.add_child(bg)
	
	# Modal card
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -280.0
	_panel.offset_right = 280.0
	_panel.offset_top = -240.0
	_panel.offset_bottom = 240.0
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.16, 0.98)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.3, 0.7, 1.0)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.set_content_margin_all(24.0)
	_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_panel)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)
	
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.text = "HEIST COMPLETE!"
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(_title_label)
	
	_sub_label = Label.new()
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.text = "The Midnight Diamond is secured in the van!"
	_sub_label.add_theme_font_size_override("font_size", 16)
	_sub_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(_sub_label)
	
	var sep1 := HSeparator.new()
	sep1.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(sep1)
	
	_rank_label = Label.new()
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.text = "RANK: S (MASTER THIEVES)"
	_rank_label.add_theme_font_size_override("font_size", 26)
	_rank_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	vbox.add_child(_rank_label)
	
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.text = "Time: 02:45 | Alarms: 0"
	_stats_label.add_theme_font_size_override("font_size", 18)
	_stats_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(_stats_label)
	
	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sep2)
	
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)
	
	_retry_btn = Button.new()
	_retry_btn.text = "  PLAY AGAIN  "
	_retry_btn.custom_minimum_size = Vector2(160, 48)
	_retry_btn.pressed.connect(func(): play_again_pressed.emit())
	btn_box.add_child(_retry_btn)
	
	var b_sep := Control.new()
	b_sep.custom_minimum_size = Vector2(20, 0)
	btn_box.add_child(b_sep)
	
	_menu_btn = Button.new()
	_menu_btn.text = "  MAIN MENU  "
	_menu_btn.custom_minimum_size = Vector2(160, 48)
	_menu_btn.pressed.connect(func(): main_menu_pressed.emit())
	btn_box.add_child(_menu_btn)

func show_victory(time_seconds: float, alarm_count: int) -> void:
	visible = true
	_title_label.text = "HEIST SUCCESSFUL!"
	_title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	_sub_label.text = "The Midnight Diamond is secured in the van!"
	
	var mins := int(time_seconds) / 60
	var secs := int(time_seconds) % 60
	
	# Determine Rank
	var rank := "B"
	var rank_desc := "HEIST AMATEURS"
	var rank_col := Color(0.8, 0.8, 0.4)
	if time_seconds <= 180.0 and alarm_count == 0:
		rank = "S"
		rank_desc = "LEGENDARY OPERATIVES"
		rank_col = Color(1.0, 0.85, 0.2)
	elif time_seconds <= 300.0 and alarm_count <= 2:
		rank = "A"
		rank_desc = "CLEAN GETAWAY"
		rank_col = Color(0.3, 0.9, 1.0)
	
	_rank_label.text = "HEIST RATING: RANK %s\n[%s]" % [rank, rank_desc]
	_rank_label.add_theme_color_override("font_color", rank_col)
	_stats_label.text = "Time: %02d:%02d  |  Alarms Triggered: %d" % [mins, secs, alarm_count]
	_retry_btn.text = "  PLAY AGAIN  "

func show_failure(reason: String) -> void:
	visible = true
	_title_label.text = "HEIST FAILED!"
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	_sub_label.text = reason
	_rank_label.text = "STATUS: BUSTED"
	_rank_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	_stats_label.text = "The museum security lockdown caught you!"
	_retry_btn.text = "  RETRY MISSION  "
