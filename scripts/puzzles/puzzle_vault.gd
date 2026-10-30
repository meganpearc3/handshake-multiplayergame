class_name PuzzleVault
extends Node3D

signal vault_unlocked()
signal diamond_stolen(carrier: Node3D)
signal alarm_triggered()
signal plaque_inspected(title: String, digit: int, text: String)
signal code_progress(entered: Array[int], is_latched: bool, is_open: bool)

const InteractableScript = preload("res://scripts/interactable.gd")

@export var is_power_latched: bool = false
@export var is_vault_open: bool = false
@export var is_diamond_collected: bool = false

var _plate_1: Node3D = null
var _plate_2: Node3D = null
var _plate_1_active: bool = false
var _plate_2_active: bool = false

var _vault_console: Node3D = null
var _vault_door: Node3D = null
var _diamond_pedestal: Node3D = null
var _audio_mgr: Node = null
var _conduit_materials: Array[StandardMaterial3D] = []
var _gem_sparkles: Array[Node3D] = []

# 3-digit vault code
const VAULT_CODE := [7, 4, 2]
var _entered_code: Array[int] = []
var _code_display_label: Label3D = null

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_build_vault_chamber()

func _build_vault_chamber() -> void:
	# 1. Dual Pressure Plates (Z = -37.0)
	_plate_1 = _create_pressure_plate(Vector3(-4.0, 0, -37.0), 1)
	_plate_2 = _create_pressure_plate(Vector3(4.0, 0, -37.0), 2)
	add_child(_plate_1)
	add_child(_plate_2)
	
	# Illuminated Floor Power Conduits leading from plates to central console
	_create_power_conduit(Vector3(-4.0, 0.015, -37.0), Vector3(0.0, 0.015, -39.0))
	_create_power_conduit(Vector3(4.0, 0.015, -37.0), Vector3(0.0, 0.015, -39.0))
	
	# 2. Vault Security Console in Center (Z = -39.0)
	_vault_console = _create_vault_console(Vector3(0, 0, -39.0))
	add_child(_vault_console)
	
	# 3. Museum Clue Plaques on the walls
	_create_clue_plaque(Vector3(-6.2, 1.8, -35.5), Vector3(0, PI * 0.5, 0), "VAULT ARCHIVE DIGIT 1:\n[ 7 ]", "VAULT ARCHIVE DIGIT 1", 7)
	_create_clue_plaque(Vector3(6.2, 1.8, -35.5), Vector3(0, -PI * 0.5, 0), "VAULT ARCHIVE DIGIT 2:\n[ 4 ]", "VAULT ARCHIVE DIGIT 2", 4)
	_create_clue_plaque(Vector3(-6.2, 1.8, -39.0), Vector3(0, PI * 0.5, 0), "VAULT ARCHIVE DIGIT 3:\n[ 2 ]", "VAULT ARCHIVE DIGIT 3", 2)
	
	# 4. Giant 3D Circular Vault Door (Z = -42.0)
	_build_vault_door(Vector3(0, 0, -42.0))
	
	# 5. Inner Vault & Midnight Diamond (Z = -47.0)
	_build_midnight_diamond(Vector3(0, 0, -47.0))

func _create_power_conduit(start_pos: Vector3, end_pos: Vector3) -> void:
	var diff := end_pos - start_pos
	var length := diff.length()
	var mid := (start_pos + end_pos) * 0.5
	
	# Conduit steel casing
	var case_mesh := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.3, 0.02, length)
	case_mesh.mesh = cbox
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.12, 0.14, 0.18)
	cmat.metallic = 0.8
	case_mesh.material_override = cmat
	case_mesh.position = mid
	case_mesh.look_at_from_position(mid, end_pos, Vector3.UP)
	add_child(case_mesh)
	
	# Luminous conduit core
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.028, length)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.2, 0.2)
	mat.emission_energy_multiplier = 0.8
	mesh.material_override = mat
	mesh.position = mid
	mesh.look_at_from_position(mid, end_pos, Vector3.UP)
	add_child(mesh)
	_conduit_materials.append(mat)

func _create_pressure_plate(pos: Vector3, plate_idx: int) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	
	# Base plate
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 0.12, 2.4)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.3, 0.38)
	mat.roughness = 0.4
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.06, 0)
	root.add_child(mesh)
	
	# Center glowing ring
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.6
	t.outer_radius = 0.8
	ring.mesh = t
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.9, 0.2, 0.2)
	rmat.emission_enabled = true
	rmat.emission = Color(0.9, 0.2, 0.2)
	rmat.emission_energy_multiplier = 1.0
	ring.material_override = rmat
	ring.position = Vector3(0, 0.13, 0)
	root.add_child(ring)
	root.set_meta("ring_mat", rmat)
	
	# Label
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.005
	lbl.font_size = 28
	lbl.position = Vector3(0, 1.2, 0)
	lbl.text = "PRESSURE PLATE %d\n[STEP HERE TOGETHER]" % plate_idx
	root.add_child(lbl)
	
	# Trigger Area3D
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2 # Players
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(2.2, 1.5, 2.2)
	col.shape = cbox
	col.position = Vector3(0, 0.75, 0)
	area.add_child(col)
	
	area.body_entered.connect(func(body): _on_plate_body_entered(plate_idx, body))
	area.body_exited.connect(func(body): _on_plate_body_exited(plate_idx, body))
	root.add_child(area)
	
	return root

func _create_clue_plaque(pos: Vector3, rot: Vector3, text: String, title: String = "VAULT ARCHIVE", digit: int = 0) -> void:
	var plaque := Node3D.new()
	plaque.position = pos
	plaque.rotation = rot
	
	# Frame
	var frame := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 1.2, 0.08)
	frame.mesh = box
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.7, 0.55, 0.2) # Gold brass
	fmat.metallic = 0.9
	fmat.roughness = 0.2
	frame.material_override = fmat
	plaque.add_child(frame)
	
	# Canvas
	var canvas := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(1.4, 1.0, 0.09)
	canvas.mesh = cbox
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.1, 0.12, 0.16)
	canvas.material_override = cmat
	plaque.add_child(canvas)
	
	# Text
	var lbl := Label3D.new()
	lbl.pixel_size = 0.005
	lbl.font_size = 32
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.9, 0.3)
	lbl.position = Vector3(0, 0, 0.06)
	lbl.text = text
	plaque.add_child(lbl)
	
	# Interactable inspect area
	var inter := InteractableScript.new()
	inter.prompt_text = "Inspect Plaque: " + title
	var col := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(2.4, 2.0, 2.0)
	col.shape = col_box
	col.position = Vector3(0, 0, 0.5)
	inter.add_child(col)
	inter.interacted.connect(func(_p): plaque_inspected.emit(title, digit, text))
	plaque.add_child(inter)
	
	add_child(plaque)

func _create_vault_console(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	
	# Terminal desk
	var desk := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(2.0, 1.0, 1.0)
	desk.mesh = dbox
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.18, 0.2, 0.24)
	desk.material_override = dmat
	desk.position = Vector3(0, 0.5, 0)
	root.add_child(desk)
	
	# Screen
	var screen := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(1.6, 0.9, 0.1)
	screen.mesh = sbox
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.08, 0.1, 0.15)
	smat.emission_enabled = true
	smat.emission = Color(0.8, 0.2, 0.2) # Red until powered
	smat.emission_energy_multiplier = 0.5
	screen.material_override = smat
	screen.position = Vector3(0, 1.4, -0.3)
	screen.rotation.x = -0.2
	root.add_child(screen)
	root.set_meta("screen_mat", smat)
	
	# Label
	_code_display_label = Label3D.new()
	_code_display_label.pixel_size = 0.004
	_code_display_label.font_size = 32
	_code_display_label.outline_size = 6
	_code_display_label.position = Vector3(0, 1.42, -0.24)
	_code_display_label.rotation.x = -0.2
	_code_display_label.text = "VAULT OFFLINE\nACTIVATE DUAL PLATES"
	_code_display_label.modulate = Color(0.9, 0.3, 0.3)
	root.add_child(_code_display_label)
	
	# Interactable to enter code
	var inter := InteractableScript.new()
	inter.prompt_text = "Enter Vault Code"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.0, 2.0)
	col.shape = box
	col.position = Vector3(0, 1.0, 0)
	inter.add_child(col)
	inter.interacted.connect(_on_console_interacted)
	root.add_child(inter)
	root.set_meta("interactable", inter)
	
	return root

func _build_vault_door(pos: Vector3) -> void:
	_vault_door = Node3D.new()
	_vault_door.position = pos
	add_child(_vault_door)
	
	# Wall frame
	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(10.0, 6.0, 1.0)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.14, 0.18)
	fmat.metallic = 0.8
	frame.material_override = fmat
	frame.position = Vector3(0, 3.0, 0)
	_vault_door.add_child(frame)
	
	# Door collision
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(5.0, 5.0, 1.0)
	col.shape = cbox
	col.position = Vector3(0, 2.5, 0)
	sb.add_child(col)
	_vault_door.add_child(sb)
	_vault_door.set_meta("collision", sb)
	
	# Rotating Bank Vault Disc
	var door_disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.4
	cyl.height = 0.8
	door_disc.mesh = cyl
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.75, 0.65, 0.25) # Heavy brass/gold
	dmat.metallic = 0.95
	dmat.roughness = 0.2
	door_disc.material_override = dmat
	door_disc.position = Vector3(0, 2.5, 0)
	door_disc.rotation.x = PI * 0.5
	_vault_door.add_child(door_disc)
	_vault_door.set_meta("door_disc", door_disc)
	
	# Vault Lock Wheel
	var wheel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.5
	t.outer_radius = 0.7
	wheel.mesh = t
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.9, 0.9, 0.9) # Chrome
	wmat.metallic = 1.0
	wheel.material_override = wmat
	wheel.position = Vector3(0, 0.45, 0)
	door_disc.add_child(wheel)
	_vault_door.set_meta("wheel", wheel)

	# Vault Lock Wheel Spokes
	for i in range(4):
		var spoke := MeshInstance3D.new()
		var spbox := BoxMesh.new()
		spbox.size = Vector3(0.08, 0.08, 1.3)
		spoke.mesh = spbox
		spoke.material_override = wmat
		spoke.rotation.y = float(i) * (PI * 0.25)
		wheel.add_child(spoke)
	
	# Center dial hub
	var hub := MeshInstance3D.new()
	var hub_cyl := CylinderMesh.new()
	hub_cyl.top_radius = 0.22
	hub_cyl.bottom_radius = 0.22
	hub_cyl.height = 0.16
	hub.mesh = hub_cyl
	hub.material_override = wmat
	hub.position = Vector3(0, 0.05, 0)
	door_disc.add_child(hub)

	# 8 Heavy locking lugs radiating along outer circumference
	for i in range(8):
		var angle := float(i) * (PI * 0.25)
		var lug := MeshInstance3D.new()
		var lbox := BoxMesh.new()
		lbox.size = Vector3(0.3, 0.5, 0.3)
		lug.mesh = lbox
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(0.2, 0.24, 0.3)
		lmat.metallic = 0.95
		lug.material_override = lmat
		lug.position = Vector3(cos(angle) * 2.3, 0.0, sin(angle) * 2.3)
		lug.rotation.y = -angle
		door_disc.add_child(lug)

func _build_midnight_diamond(pos: Vector3) -> void:
	_diamond_pedestal = Node3D.new()
	_diamond_pedestal.position = pos
	add_child(_diamond_pedestal)
	
	# Black marble pedestal
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.75
	cyl.height = 1.1
	ped.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.08, 0.08, 0.1)
	pmat.roughness = 0.15
	ped.material_override = pmat
	ped.position = Vector3(0, 0.55, 0)
	_diamond_pedestal.add_child(ped)
	
	# Velvet cushion
	var cush := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(0.7, 0.15, 0.7)
	cush.mesh = cbox
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.6, 0.05, 0.1) # Royal red
	cush.material_override = cmat
	cush.position = Vector3(0, 1.15, 0)
	_diamond_pedestal.add_child(cush)
	
	# Midnight Diamond Mesh (Faceted Prism/Diamond)
	var gem_root := Node3D.new()
	gem_root.position = Vector3(0, 1.55, 0)
	_diamond_pedestal.add_child(gem_root)
	_diamond_pedestal.set_meta("gem_root", gem_root)
	
	var gem_top := MeshInstance3D.new()
	var top_cyl := CylinderMesh.new()
	top_cyl.top_radius = 0.35
	top_cyl.bottom_radius = 0.0
	top_cyl.height = 0.45
	gem_top.mesh = top_cyl
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.1, 0.85, 1.0, 0.95) # Cyan diamond
	gmat.emission_enabled = true
	gmat.emission = Color(0.2, 0.9, 1.0)
	gmat.emission_energy_multiplier = 3.0
	gmat.roughness = 0.05
	gem_top.material_override = gmat
	gem_top.position = Vector3(0, -0.15, 0)
	gem_root.add_child(gem_top)
	
	var gem_bottom := MeshInstance3D.new()
	var bot_cyl := CylinderMesh.new()
	bot_cyl.top_radius = 0.0
	bot_cyl.bottom_radius = 0.35
	bot_cyl.height = 0.25
	gem_bottom.mesh = bot_cyl
	gem_bottom.material_override = gmat
	gem_bottom.position = Vector3(0, 0.15, 0)
	gem_root.add_child(gem_bottom)
	
	# Orbiting sparkle motes
	for i in range(4):
		var spark := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.08, 0.08, 0.08)
		spark.mesh = sbox
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(0.7, 0.95, 1.0)
		smat.emission_enabled = true
		smat.emission = Color(0.6, 0.95, 1.0)
		smat.emission_energy_multiplier = 4.0
		spark.material_override = smat
		gem_root.add_child(spark)
		_gem_sparkles.append(spark)
	
	# Spotlight focused on diamond
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 4.5, 0)
	spot.rotation.x = -PI * 0.5
	spot.light_color = Color(0.7, 0.95, 1.0)
	spot.light_energy = 5.0
	spot.spot_range = 8.0
	spot.spot_angle = 25.0
	_diamond_pedestal.add_child(spot)
	
	# Interactable to grab diamond
	var inter := InteractableScript.new()
	inter.prompt_text = "STEAL THE MIDNIGHT DIAMOND"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.5)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	inter.add_child(col)
	inter.interacted.connect(_on_diamond_grabbed)
	_diamond_pedestal.add_child(inter)
	_diamond_pedestal.set_meta("interactable", inter)

func _process(delta: float) -> void:
	# Spin and float the Midnight Diamond
	if not is_diamond_collected and _diamond_pedestal:
		var gem: Node3D = _diamond_pedestal.get_meta("gem_root")
		if gem:
			gem.rotation.y += delta * 1.5
			gem.position.y = 1.55 + sin(Time.get_ticks_msec() * 0.003) * 0.1
			# Orbit sparkles around the diamond
			var time := Time.get_ticks_msec() * 0.003
			for i in range(_gem_sparkles.size()):
				var spark: Node3D = _gem_sparkles[i]
				if is_instance_valid(spark):
					var angle := time * 2.0 + float(i) * (PI * 0.5)
					var r := 0.6 + sin(time * 3.0 + i) * 0.15
					spark.position = Vector3(cos(angle) * r, sin(time * 2.5 + i) * 0.25, sin(angle) * r)
					spark.rotation.x += delta * 3.0
					spark.rotation.y += delta * 2.0

func _on_plate_body_entered(plate_idx: int, _body: Node3D) -> void:
	if plate_idx == 1:
		_plate_1_active = true
	else:
		_plate_2_active = true
	
	_update_plate_visuals()
	
	# Check dual simultaneous activation to latch circuit
	if _plate_1_active and _plate_2_active and not is_power_latched:
		is_power_latched = true
		if _audio_mgr:
			_audio_mgr.play_success()
		_power_up_console()

func _on_plate_body_exited(plate_idx: int, _body: Node3D) -> void:
	if plate_idx == 1:
		_plate_1_active = false
	else:
		_plate_2_active = false
	_update_plate_visuals()

func _update_plate_visuals() -> void:
	var rmat1: StandardMaterial3D = _plate_1.get_meta("ring_mat")
	if rmat1:
		var c := Color(0.2, 0.9, 0.3) if (_plate_1_active or is_power_latched) else Color(0.9, 0.2, 0.2)
		rmat1.albedo_color = c
		rmat1.emission = c
	
	var rmat2: StandardMaterial3D = _plate_2.get_meta("ring_mat")
	if rmat2:
		var c := Color(0.2, 0.9, 0.3) if (_plate_2_active or is_power_latched) else Color(0.9, 0.2, 0.2)
		rmat2.albedo_color = c
		rmat2.emission = c

func _power_up_console() -> void:
	for cmat in _conduit_materials:
		cmat.albedo_color = Color(0.2, 0.9, 0.4)
		cmat.emission = Color(0.2, 0.9, 0.4)
		cmat.emission_energy_multiplier = 2.0
	var smat: StandardMaterial3D = _vault_console.get_meta("screen_mat")
	if smat:
		smat.emission = Color(0.2, 0.8, 1.0)
		smat.emission_energy_multiplier = 1.2
	_code_display_label.text = "CIRCUIT LATCHED: POWER ONLINE\nENTER 3-DIGIT CODE\nINPUT: [ _ _ _ ]"
	_code_display_label.modulate = Color(0.3, 0.9, 1.0)

func _on_console_interacted(player: Node3D) -> void:
	if not is_power_latched:
		if _audio_mgr:
			_audio_mgr.play_buzzer()
		code_progress.emit(_entered_code, false, false)
		return
	if is_vault_open:
		code_progress.emit(_entered_code, true, true)
		return
	
	# Prompt player to advance digit
	var next_expected_digit: int = VAULT_CODE[_entered_code.size()]
	_entered_code.append(next_expected_digit)
	
	if _audio_mgr:
		_audio_mgr.play_beep(600.0 + (_entered_code.size() * 200.0), 0.12)
	
	var code_str := ""
	for d in _entered_code:
		code_str += "%d " % d
	while code_str.length() < 6:
		code_str += "_ "
	
	_code_display_label.text = "CODE VERIFIED: [ %s ]" % code_str.strip_edges()
	code_progress.emit(_entered_code, true, _entered_code.size() == VAULT_CODE.size())
	
	if _entered_code.size() == VAULT_CODE.size():
		is_vault_open = true
		if _audio_mgr:
			_audio_mgr.play_vault_open()
		_open_vault_door()
		vault_unlocked.emit()

func _open_vault_door() -> void:
	# Disable collision
	var sb: StaticBody3D = _vault_door.get_meta("collision")
	if sb:
		sb.collision_layer = 0
	
	# Spin wheel, then swing disc open
	var wheel: MeshInstance3D = _vault_door.get_meta("wheel")
	var disc: MeshInstance3D = _vault_door.get_meta("door_disc")
	
	var tw := create_tween()
	if wheel:
		tw.tween_property(wheel, "rotation:y", PI * 4.0, 0.8)
	if disc:
		tw.tween_property(disc, "position:x", 4.2, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_diamond_grabbed(player: Node3D) -> void:
	if is_diamond_collected:
		return
	is_diamond_collected = true
	
	# Hide diamond on pedestal
	var gem: Node3D = _diamond_pedestal.get_meta("gem_root")
	if gem:
		gem.visible = false
	var inter: Area3D = _diamond_pedestal.get_meta("interactable")
	if inter and inter.has_method("set_enabled"):
		inter.set_enabled(false)
	
	if player.has_method("give_diamond"):
		player.give_diamond()
	if _audio_mgr:
		_audio_mgr.play_gem_pickup()
		_audio_mgr.start_alarm_siren()
	
	diamond_stolen.emit(player)
