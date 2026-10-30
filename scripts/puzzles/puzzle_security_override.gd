class_name PuzzleSecurityOverride
extends Node3D

signal puzzle_solved()
signal alarm_triggered()
signal sequence_updated(seq: Array)
signal button_pressed(btn_name: String, is_correct: bool, current_count: int, total_count: int)

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
const BUTTON_NAMES: Array[String] = ["SQUARE [RED]", "CIRCLE [BLUE]", "TRIANGLE [GREEN]", "STAR [GOLD]"]
const BUTTON_COLORS: Array[Color] = [
	Color(0.95, 0.2, 0.2), # 1
	Color(0.2, 0.5, 1.0), # 2
	Color(0.2, 0.9, 0.3), # 3
	Color(1.0, 0.85, 0.1)  # 4
]

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_generate_random_sequence()
	_build_room_nodes()

func _process(delta: float) -> void:
	for btn in _spark_buttons:
		if is_instance_valid(btn):
			var holo: MeshInstance3D = btn.get_meta("holo_mesh")
			if holo:
				holo.rotation.y += delta * 2.0
				holo.position.y = 1.85 + sin(Time.get_ticks_msec() * 0.004) * 0.05

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
	desk_box.size = Vector3(2.2, 1.0, 1.2)
	desk.mesh = desk_box
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.12, 0.15, 0.20)
	desk_mat.roughness = 0.4
	desk.material_override = desk_mat
	desk.position = Vector3(0, 0.5, 0)
	_cipher_console.add_child(desk)
	
	# Main Center Console screen
	var screen := MeshInstance3D.new()
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(1.4, 0.9, 0.1)
	screen.mesh = screen_box
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.04, 0.08, 0.16)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.45, 0.9)
	screen_mat.emission_energy_multiplier = 0.8
	screen.material_override = screen_mat
	screen.position = Vector3(0, 1.40, -0.35)
	screen.rotation.x = -0.2
	_cipher_console.add_child(screen)
	
	# Angled Left & Right Auxiliary Wing Screens
	for side in [-1, 1]:
		var wing := MeshInstance3D.new()
		var wbox := BoxMesh.new()
		wbox.size = Vector3(0.65, 0.7, 0.08)
		wing.mesh = wbox
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.03, 0.06, 0.12)
		wmat.emission_enabled = true
		wmat.emission = Color(0.08, 0.6, 0.7)
		wmat.emission_energy_multiplier = 0.6
		wing.material_override = wmat
		wing.position = Vector3(side * 0.95, 1.35, -0.28)
		wing.rotation.y = -side * 0.35
		wing.rotation.x = -0.15
		_cipher_console.add_child(wing)
	
	# Server Mainframe Rack beside the desk
	var rack := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(0.9, 2.6, 0.9)
	rack.mesh = rbox
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.08, 0.10, 0.13)
	rmat.roughness = 0.5
	rack.material_override = rmat
	rack.position = Vector3(-1.4, 1.3, -0.2)
	_cipher_console.add_child(rack)
	
	# Blinking Server LED Indicators on Rack
	for r_row in range(5):
		for r_col in range(3):
			var led := MeshInstance3D.new()
			var lbox := BoxMesh.new()
			lbox.size = Vector3(0.06, 0.06, 0.02)
			led.mesh = lbox
			var lmat := StandardMaterial3D.new()
			var led_col: Color = BUTTON_COLORS[(r_row + r_col) % 4]
			lmat.albedo_color = led_col
			lmat.emission_enabled = true
			lmat.emission = led_col
			lmat.emission_energy_multiplier = 1.8
			led.material_override = lmat
			led.position = Vector3(-1.65 + (r_col * 0.18), 0.6 + (r_row * 0.38), 0.26)
			_cipher_console.add_child(led)
	
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
		
		# Pedestal Collar & Base Trim
		var trim := MeshInstance3D.new()
		var tmesh := TorusMesh.new()
		tmesh.inner_radius = 0.44
		tmesh.outer_radius = 0.52
		trim.mesh = tmesh
		var trim_mat := StandardMaterial3D.new()
		trim_mat.albedo_color = Color(0.9, 0.75, 0.25)
		trim_mat.metallic = 0.95
		trim.material_override = trim_mat
		trim.position = Vector3(0, 0.90, 0)
		btn_node.add_child(trim)
		
		# Button Dome Cap (Heavy Arcade Style)
		var btn_cap := MeshInstance3D.new()
		var cap_cyl := CylinderMesh.new()
		cap_cyl.top_radius = 0.35
		cap_cyl.bottom_radius = 0.35
		cap_cyl.height = 0.16
		btn_cap.mesh = cap_cyl
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = BUTTON_COLORS[i]
		cap_mat.emission_enabled = true
		cap_mat.emission = BUTTON_COLORS[i]
		cap_mat.emission_energy_multiplier = 1.4
		btn_cap.material_override = cap_mat
		btn_cap.position = Vector3(0, 0.96, 0)
		btn_node.add_child(btn_cap)
		btn_node.set_meta("cap_mesh", btn_cap)
		btn_node.set_meta("cap_mat", cap_mat)
		
		# Floating 3D Holographic Symbol
		var holo := MeshInstance3D.new()
		if i == 0:
			var sbox := BoxMesh.new()
			sbox.size = Vector3(0.25, 0.25, 0.25)
			holo.mesh = sbox
		elif i == 1:
			var scyl := CylinderMesh.new()
			scyl.top_radius = 0.16
			scyl.bottom_radius = 0.16
			scyl.height = 0.08
			holo.mesh = scyl
			holo.rotation.x = PI * 0.5
		elif i == 2:
			var sprism := PrismMesh.new()
			sprism.size = Vector3(0.28, 0.28, 0.14)
			holo.mesh = sprism
		else:
			var sstar := PrismMesh.new()
			sstar.size = Vector3(0.32, 0.32, 0.12)
			holo.mesh = sstar
		holo.material_override = cap_mat
		holo.position = Vector3(0, 1.85, 0)
		btn_node.add_child(holo)
		btn_node.set_meta("holo_mesh", holo)
		
		# 3D Label on button
		var lbl := Label3D.new()
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.pixel_size = 0.005
		lbl.font_size = 32
		lbl.outline_size = 8
		lbl.outline_modulate = Color(0, 0, 0, 0.95)
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
		button_pressed.emit(BUTTON_NAMES[btn_num - 1], false, 0, target_sequence.size())
		alarm_triggered.emit()
		current_input.clear()
		_cipher_display_label.text = "ERROR: CODE MISMATCH!\nRE-HACK CONSOLE"
		_cipher_display_label.modulate = Color(1.0, 0.3, 0.3)
		return
	
	button_pressed.emit(BUTTON_NAMES[btn_num - 1], true, current_input.size(), target_sequence.size())
	
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
