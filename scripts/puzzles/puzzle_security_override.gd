class_name PuzzleSecurityOverride
extends Node3D

signal puzzle_solved()
signal alarm_triggered()
signal sequence_updated(seq: Array)

const InteractableScript = preload("res://scripts/interactable.gd")

@export var is_solved: bool = false
var target_sequence: Array[int] = [1, 3, 2, 4]
var current_input: Array[int] = []

var _cipher_console: Node3D = null
var _cipher_interactable: Area3D = null
var _cipher_display_label: Label3D = null

var _spark_buttons: Array[Node3D] = []
var _bulkhead_door: Node3D = null

var _audio_mgr: Node = null

# Colors and names for buttons
const BUTTON_NAMES = ["SQUARE [RED]", "CIRCLE [BLUE]", "TRIANGLE [GREEN]", "STAR [GOLD]"]
const BUTTON_COLORS = [
	Color(0.95, 0.2, 0.2), # 1
	Color(0.2, 0.5, 1.0), # 2
	Color(0.2, 0.9, 0.3), # 3
	Color(1.0, 0.85, 0.1)  # 4
]

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_generate_random_sequence()
	_build_room_nodes()

func _generate_random_sequence() -> void:
	target_sequence.clear()
	var pool: Array[int] = [1, 2, 3, 4]
	pool.shuffle()
	target_sequence = pool
	current_input.clear()

func _build_room_nodes() -> void:
	# 1. Cipher Console (at left of room)
	_cipher_console = Node3D.new()
	_cipher_console.position = Vector3(-6.0, 0.0, 0.0)
	add_child(_cipher_console)
	
	# Console table mesh
	var desk := MeshInstance3D.new()
	var desk_box := BoxMesh.new()
	desk_box.size = Vector3(1.6, 1.0, 1.0)
	desk.mesh = desk_box
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.15, 0.18, 0.24)
	desk_mat.roughness = 0.5
	desk.material_override = desk_mat
	desk.position = Vector3(0, 0.5, 0)
	_cipher_console.add_child(desk)
	
	# Console screen
	var screen := MeshInstance3D.new()
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(1.2, 0.8, 0.1)
	screen.mesh = screen_box
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.1, 0.2)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.4, 0.8)
	screen_mat.emission_energy_multiplier = 0.6
	screen.material_override = screen_mat
	screen.position = Vector3(0, 1.35, -0.3)
	screen.rotation.x = -0.2
	_cipher_console.add_child(screen)
	
	# Cipher Screen 3D text
	_cipher_display_label = Label3D.new()
	_cipher_display_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_cipher_display_label.pixel_size = 0.004
	_cipher_display_label.font_size = 32
	_cipher_display_label.outline_size = 6
	_cipher_display_label.outline_modulate = Color(0, 0, 0)
	_cipher_display_label.modulate = Color(0.4, 0.9, 1.0)
	_cipher_display_label.position = Vector3(0, 1.36, -0.24)
	_cipher_display_label.rotation.x = -0.2
	_cipher_display_label.text = "[E] HACK CONSOLE\nTO REVEAL CODE"
	_cipher_console.add_child(_cipher_display_label)
	
	# Cipher Interactable Area
	var c_inter := InteractableScript.new()
	c_inter.prompt_text = "Hack Console"
	c_inter.allowed_player_id = 1 # Cipher only!
	var c_col := CollisionShape3D.new()
	var c_box := BoxShape3D.new()
	c_box.size = Vector3(2.2, 2.0, 2.2)
	c_col.shape = c_box
	c_col.position = Vector3(0, 1.0, 0)
	c_inter.add_child(c_col)
	c_inter.interacted.connect(_on_cipher_interacted)
	_cipher_console.add_child(c_inter)
	_cipher_interactable = c_inter
	
	# 2. Spark Terminals (4 pedestals on right side of room)
	var button_spacing := 2.2
	var start_z := -3.3
	for i in range(4):
		var btn_num := i + 1
		var btn_node := Node3D.new()
		btn_node.position = Vector3(6.0, 0.0, start_z + (i * button_spacing))
		add_child(btn_node)
		_spark_buttons.append(btn_node)
		
		# Pedestal
		var ped := MeshInstance3D.new()
		var ped_cyl := CylinderMesh.new()
		ped_cyl.top_radius = 0.45
		ped_cyl.bottom_radius = 0.55
		ped_cyl.height = 0.9
		ped.mesh = ped_cyl
		var ped_mat := StandardMaterial3D.new()
		ped_mat.albedo_color = Color(0.2, 0.22, 0.26)
		ped.material_override = ped_mat
		ped.position = Vector3(0, 0.45, 0)
		btn_node.add_child(ped)
		
		# Button top
		var btn_cap := MeshInstance3D.new()
		var cap_cyl := CylinderMesh.new()
		cap_cyl.top_radius = 0.35
		cap_cyl.bottom_radius = 0.35
		cap_cyl.height = 0.15
		btn_cap.mesh = cap_cyl
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = BUTTON_COLORS[i]
		cap_mat.emission_enabled = true
		cap_mat.emission = BUTTON_COLORS[i]
		cap_mat.emission_energy_multiplier = 0.8
		btn_cap.material_override = cap_mat
		btn_cap.position = Vector3(0, 0.95, 0)
		btn_node.add_child(btn_cap)
		btn_node.set_meta("cap_mesh", btn_cap)
		btn_node.set_meta("cap_mat", cap_mat)
		
		# 3D Label on button
		var lbl := Label3D.new()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.pixel_size = 0.005
		lbl.font_size = 34
		lbl.outline_size = 6
		lbl.modulate = BUTTON_COLORS[i]
		lbl.position = Vector3(0, 1.45, 0)
		lbl.text = "BUTTON %d\n%s" % [btn_num, BUTTON_NAMES[i]]
		btn_node.add_child(lbl)
		
		# Interactable for Spark
		var b_inter := InteractableScript.new()
		b_inter.prompt_text = "Press Button %d" % btn_num
		b_inter.allowed_player_id = 2 # Spark only!
		var b_col := CollisionShape3D.new()
		var b_box := BoxShape3D.new()
		b_box.size = Vector3(1.8, 2.0, 1.8)
		b_col.shape = b_box
		b_col.position = Vector3(0, 1.0, 0)
		b_inter.add_child(b_col)
		b_inter.interacted.connect(func(_p): _on_spark_button_pressed(btn_num, btn_node))
		btn_node.add_child(b_inter)
	
	# 3. Security Bulkhead Gate at North exit (Z = -6.5)
	_build_bulkhead_gate()

func _build_bulkhead_gate() -> void:
	_bulkhead_door = Node3D.new()
	_bulkhead_door.position = Vector3(0.0, 0.0, -8.0)
	add_child(_bulkhead_door)
	
	# StaticBody3D collision wall
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 4.0, 0.6)
	col.shape = box
	col.position = Vector3(0, 2.0, 0)
	sb.add_child(col)
	_bulkhead_door.add_child(sb)
	_bulkhead_door.set_meta("collision", sb)
	
	# Left door leaf
	var leaf_l := MeshInstance3D.new()
	var leaf_box := BoxMesh.new()
	leaf_box.size = Vector3(2.9, 3.8, 0.4)
	leaf_l.mesh = leaf_box
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.18, 0.22, 0.28)
	door_mat.metallic = 0.8
	door_mat.roughness = 0.3
	leaf_l.material_override = door_mat
	leaf_l.position = Vector3(-1.45, 1.9, 0)
	_bulkhead_door.add_child(leaf_l)
	_bulkhead_door.set_meta("leaf_l", leaf_l)
	
	# Right door leaf
	var leaf_r := MeshInstance3D.new()
	leaf_r.mesh = leaf_box
	leaf_r.material_override = door_mat
	leaf_r.position = Vector3(1.45, 1.9, 0)
	_bulkhead_door.add_child(leaf_r)
	_bulkhead_door.set_meta("leaf_r", leaf_r)
	
	# Overhead status light
	var light := MeshInstance3D.new()
	var light_cyl := CylinderMesh.new()
	light_cyl.top_radius = 0.25
	light_cyl.bottom_radius = 0.25
	light_cyl.height = 0.15
	light.mesh = light_cyl
	var light_mat := StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.9, 0.1, 0.1)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.9, 0.1, 0.1)
	light_mat.emission_energy_multiplier = 1.5
	light.material_override = light_mat
	light.position = Vector3(0, 4.0, 0)
	_bulkhead_door.add_child(light)
	_bulkhead_door.set_meta("status_light_mat", light_mat)

func _on_cipher_interacted(_player: Node3D) -> void:
	if is_solved:
		return
	if _audio_mgr:
		_audio_mgr.play_beep(980.0, 0.08)
	
	var seq_str := ""
	for i in range(target_sequence.size()):
		var n: int = target_sequence[i]
		seq_str += "[%d:%s]\n" % [n, BUTTON_NAMES[n - 1]]
	
	_cipher_display_label.text = "OVERRIDE CODE:\n" + seq_str
	_cipher_display_label.modulate = Color(0.2, 1.0, 0.4)
	sequence_updated.emit(target_sequence)

func _on_spark_button_pressed(btn_num: int, btn_node: Node3D) -> void:
	if is_solved:
		return
	
	if _audio_mgr:
		_audio_mgr.play_beep(440.0 + (btn_num * 120.0), 0.1)
	
	current_input.append(btn_num)
	var expected_idx := current_input.size() - 1
	
	# Animate button press
	var cap: MeshInstance3D = btn_node.get_meta("cap_mesh")
	if cap:
		var tw := create_tween()
		tw.tween_property(cap, "position:y", 0.85, 0.08)
		tw.tween_property(cap, "position:y", 0.95, 0.1)
	
	# Verify current step
	if current_input[expected_idx] != target_sequence[expected_idx]:
		# Wrong button! Trigger alarm strike
		if _audio_mgr:
			_audio_mgr.play_buzzer()
		alarm_triggered.emit()
		current_input.clear()
		_cipher_display_label.text = "ERROR: CODE MISMATCH!\nRE-HACK CONSOLE"
		_cipher_display_label.modulate = Color(1.0, 0.3, 0.3)
		return
	
	# Check if sequence is complete
	if current_input.size() == target_sequence.size():
		is_solved = true
		if _audio_mgr:
			_audio_mgr.play_success()
		_open_bulkhead_door()
		_cipher_display_label.text = "SECURITY BYPASS ACCEPTED\nBULKHEAD OPEN"
		_cipher_display_label.modulate = Color(0.2, 1.0, 0.5)
		puzzle_solved.emit()

func _open_bulkhead_door() -> void:
	# Change status light to green
	var light_mat: StandardMaterial3D = _bulkhead_door.get_meta("status_light_mat")
	if light_mat:
		light_mat.albedo_color = Color(0.1, 0.9, 0.3)
		light_mat.emission = Color(0.1, 0.9, 0.3)
	
	# Disable collision
	var sb: StaticBody3D = _bulkhead_door.get_meta("collision")
	if sb:
		sb.collision_layer = 0
	
	# Slide doors open smoothly
	var leaf_l: MeshInstance3D = _bulkhead_door.get_meta("leaf_l")
	var leaf_r: MeshInstance3D = _bulkhead_door.get_meta("leaf_r")
	if leaf_l and leaf_r:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(leaf_l, "position:x", -3.8, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(leaf_r, "position:x", 3.8, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
