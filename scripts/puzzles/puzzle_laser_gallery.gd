class_name PuzzleLaserGallery
extends Node3D

signal puzzle_solved()
signal alarm_triggered()

const InteractableScript = preload("res://scripts/interactable.gd")
const LaserBeamScript = preload("res://scripts/puzzles/laser_beam.gd")

@export var is_solved: bool = false
@export var checkpoint_pos: Vector3 = Vector3(0, 0, -10.0)

var _switch_a: Node3D = null # Cipher hold switch
var _switch_b: Node3D = null # Spark hold switch
var _keycard_pedestal: Node3D = null
var _keycard_terminal: Node3D = null
var _vault_doorway: Node3D = null

var _lasers_group_a: Array[Node3D] = []
var _lasers_group_b: Array[Node3D] = []

var _has_keycard_been_collected: bool = false
var _keycard_inserted: bool = false
var _players_in_exit_zone: Array[Node3D] = []

var _audio_mgr: Node = null

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_build_gallery()

func _build_gallery() -> void:
	# 1. Switch A (Cipher hold switch at start of hallway, left side)
	_switch_a = _create_bypass_switch(
		Vector3(-3.2, 0, -11.0),
		1, # Cipher
		"Hold Laser Override A",
		Color(0.2, 0.6, 1.0)
	)
	var inter_a: Area3D = _switch_a.get_meta("interactable")
	inter_a.hold_started.connect(func(_p): _on_switch_a_hold(true))
	inter_a.hold_ended.connect(func(_p): _on_switch_a_hold(false))
	add_child(_switch_a)
	
	# 2. Laser Group A (between Z = -13.0 and -18.0)
	var z_coords_a := [-13.5, -15.5, -17.5]
	for i in range(z_coords_a.size()):
		var laser := LaserBeamScript.new()
		laser.position = Vector3(0, 0.7 + (i * 0.4), z_coords_a[i])
		laser.beam_width = 7.0
		laser.moves_vertically = (i % 2 == 1)
		laser.moves_horizontally = (i % 2 == 0)
		laser.move_speed = 1.8 + (i * 0.4)
		laser.player_hit.connect(_on_laser_hit)
		add_child(laser)
		_lasers_group_a.append(laser)
	
	# 3. Keycard Pedestal in central safe pocket (Z = -20.5)
	_keycard_pedestal = _create_keycard_pedestal(Vector3(0, 0, -20.5))
	add_child(_keycard_pedestal)
	
	# 4. Laser Group B (between Z = -23.0 and -28.0)
	var z_coords_b := [-23.5, -25.5, -27.5]
	for i in range(z_coords_b.size()):
		var laser := LaserBeamScript.new()
		laser.position = Vector3(0, 0.8 + (i * 0.35), z_coords_b[i])
		laser.beam_width = 7.0
		laser.moves_vertically = (i % 2 == 0)
		laser.moves_horizontally = (i % 2 == 1)
		laser.move_speed = 2.2 + (i * 0.3)
		laser.player_hit.connect(_on_laser_hit)
		add_child(laser)
		_lasers_group_b.append(laser)
	
	# 5. Switch B (Spark hold switch at far end of hallway, right side, Z = -29.5)
	_switch_b = _create_bypass_switch(
		Vector3(3.2, 0, -29.5),
		2, # Spark
		"Hold Laser Override B",
		Color(1.0, 0.6, 0.1)
	)
	var inter_b: Area3D = _switch_b.get_meta("interactable")
	inter_b.hold_started.connect(func(_p): _on_switch_b_hold(true))
	inter_b.hold_ended.connect(func(_p): _on_switch_b_hold(false))
	add_child(_switch_b)
	
	# 6. Keycard Reader Terminal & Vault Doorway (Z = -32.0)
	_build_exit_barrier()

func _create_bypass_switch(pos: Vector3, player_id: int, label_text: String, col: Color) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	
	# Stand
	var stand := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.4
	cyl.height = 1.0
	stand.mesh = cyl
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.18, 0.2, 0.24)
	stand.material_override = smat
	stand.position = Vector3(0, 0.5, 0)
	root.add_child(stand)
	
	# Lever / Switch Mesh
	var lever := MeshInstance3D.new()
	var lmesh := BoxMesh.new()
	lmesh.size = Vector3(0.2, 0.4, 0.2)
	lever.mesh = lmesh
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = col
	lmat.emission_enabled = true
	lmat.emission = col
	lmat.emission_energy_multiplier = 1.2
	lever.material_override = lmat
	lever.position = Vector3(0, 1.1, 0)
	root.add_child(lever)
	root.set_meta("lever_mesh", lever)
	
	# Overhead label
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.005
	lbl.font_size = 32
	lbl.outline_size = 6
	lbl.modulate = col
	lbl.position = Vector3(0, 1.6, 0)
	lbl.text = label_text
	root.add_child(lbl)
	
	# Interactable hold area
	var inter := InteractableScript.new()
	inter.prompt_text = label_text
	inter.allowed_player_id = player_id
	inter.is_hold_switch = true
	var ccol := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(2.2, 2.0, 2.2)
	ccol.shape = cbox
	ccol.position = Vector3(0, 1.0, 0)
	inter.add_child(ccol)
	root.add_child(inter)
	root.set_meta("interactable", inter)
	
	return root

func _create_keycard_pedestal(pos: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	
	# Ornate museum pedestal
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	ped.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.8, 0.75, 0.65) # Marble
	pmat.roughness = 0.3
	ped.material_override = pmat
	ped.position = Vector3(0, 0.5, 0)
	root.add_child(ped)
	
	# Keycard floating mesh
	var card := MeshInstance3D.new()
	var cmesh := BoxMesh.new()
	cmesh.size = Vector3(0.24, 0.36, 0.04)
	card.mesh = cmesh
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(1.0, 0.85, 0.1) # Gold keycard
	cmat.emission_enabled = true
	cmat.emission = Color(1.0, 0.85, 0.1)
	cmat.emission_energy_multiplier = 2.0
	cmat.metallic = 0.9
	card.material_override = cmat
	card.position = Vector3(0, 1.25, 0)
	card.rotation.x = 0.3
	root.add_child(card)
	root.set_meta("card_mesh", card)
	
	# Interactable to collect
	var inter := InteractableScript.new()
	inter.prompt_text = "Collect Gold Keycard"
	inter.allowed_player_id = 0 # Either player can grab
	var ccol := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(1.8, 2.0, 1.8)
	ccol.shape = cbox
	ccol.position = Vector3(0, 1.0, 0)
	inter.add_child(ccol)
	inter.interacted.connect(_on_keycard_collected)
	root.add_child(inter)
	root.set_meta("interactable", inter)
	
	return root

func _build_exit_barrier() -> void:
	_vault_doorway = Node3D.new()
	_vault_doorway.position = Vector3(0, 0, -32.0)
	add_child(_vault_doorway)
	
	# Barrier door StaticBody3D
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.5, 4.0, 0.6)
	col.shape = box
	col.position = Vector3(0, 2.0, 0)
	sb.add_child(col)
	_vault_doorway.add_child(sb)
	_vault_doorway.set_meta("collision", sb)
	
	# Door Mesh
	var door := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(6.0, 3.8, 0.4)
	door.mesh = dbox
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.22, 0.25, 0.32)
	dmat.metallic = 0.8
	door.material_override = dmat
	door.position = Vector3(0, 1.9, 0)
	_vault_doorway.add_child(door)
	_vault_doorway.set_meta("door_mesh", door)
	
	# Keycard terminal pedestal on the wall
	_keycard_terminal = Node3D.new()
	_keycard_terminal.position = Vector3(-3.2, 0, -31.2)
	var term_ped := MeshInstance3D.new()
	var tcyl := CylinderMesh.new()
	tcyl.top_radius = 0.3
	tcyl.bottom_radius = 0.35
	tcyl.height = 1.0
	term_ped.mesh = tcyl
	var tpmat := StandardMaterial3D.new()
	tpmat.albedo_color = Color(0.2, 0.22, 0.25)
	term_ped.material_override = tpmat
	term_ped.position = Vector3(0, 0.5, 0)
	_keycard_terminal.add_child(term_ped)
	
	var term_slot := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.4, 0.3, 0.2)
	term_slot.mesh = sbox
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.9, 0.2, 0.2)
	smat.emission_enabled = true
	smat.emission = Color(0.9, 0.2, 0.2)
	smat.emission_energy_multiplier = 1.5
	term_slot.material_override = smat
	term_slot.position = Vector3(0, 1.1, 0)
	_keycard_terminal.add_child(term_slot)
	_keycard_terminal.set_meta("slot_mat", smat)
	
	var tlbl := Label3D.new()
	tlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tlbl.pixel_size = 0.005
	tlbl.font_size = 32
	tlbl.outline_size = 6
	tlbl.position = Vector3(0, 1.5, 0)
	tlbl.text = "KEYCARD SLOT"
	_keycard_terminal.add_child(tlbl)
	_keycard_terminal.set_meta("label", tlbl)
	
	var t_inter := InteractableScript.new()
	t_inter.prompt_text = "Insert Keycard"
	var tcol := CollisionShape3D.new()
	var tbox := BoxShape3D.new()
	tbox.size = Vector3(2.0, 2.0, 2.0)
	tcol.shape = tbox
	tcol.position = Vector3(0, 1.0, 0)
	t_inter.add_child(tcol)
	t_inter.interacted.connect(_on_keycard_inserted)
	_keycard_terminal.add_child(t_inter)
	_keycard_terminal.set_meta("interactable", t_inter)
	add_child(_keycard_terminal)

func _on_switch_a_hold(is_holding: bool) -> void:
	for laser in _lasers_group_a:
		if is_instance_valid(laser):
			laser.set_laser_active(not is_holding)
	if _audio_mgr:
		if is_holding:
			_audio_mgr.play_click()
		else:
			_audio_mgr.play_beep(350.0, 0.08)

func _on_switch_b_hold(is_holding: bool) -> void:
	for laser in _lasers_group_b:
		if is_instance_valid(laser):
			laser.set_laser_active(not is_holding)
	if _audio_mgr:
		if is_holding:
			_audio_mgr.play_click()
		else:
			_audio_mgr.play_beep(350.0, 0.08)

func _on_keycard_collected(player: Node3D) -> void:
	if _has_keycard_been_collected:
		return
	_has_keycard_been_collected = true
	if player.has_method("give_keycard"):
		player.give_keycard()
	if _audio_mgr:
		_audio_mgr.play_beep(1200.0, 0.15)
	
	# Hide pedestal keycard
	var card: MeshInstance3D = _keycard_pedestal.get_meta("card_mesh")
	if card:
		card.visible = false
	var inter: Area3D = _keycard_pedestal.get_meta("interactable")
	if inter and inter.has_method("set_enabled"):
		inter.set_enabled(false)

func _on_keycard_inserted(player: Node3D) -> void:
	if is_solved:
		return
	var has_card: bool = player.get("has_keycard") if player else false
	if not has_card:
		if _audio_mgr:
			_audio_mgr.play_buzzer()
		return
	
	_keycard_inserted = true
	if player.has_method("remove_keycard"):
		player.remove_keycard()
	
	# Terminal turns green
	var smat: StandardMaterial3D = _keycard_terminal.get_meta("slot_mat")
	if smat:
		smat.albedo_color = Color(0.2, 0.9, 0.3)
		smat.emission = Color(0.2, 0.9, 0.3)
	var tlbl: Label3D = _keycard_terminal.get_meta("label")
	if tlbl:
		tlbl.text = "KEYCARD ACCEPTED"
		tlbl.modulate = Color(0.2, 0.9, 0.3)
	
	is_solved = true
	if _audio_mgr:
		_audio_mgr.play_success()
	
	# Open door
	var sb: StaticBody3D = _vault_doorway.get_meta("collision")
	if sb:
		sb.collision_layer = 0
	var door: MeshInstance3D = _vault_doorway.get_meta("door_mesh")
	if door:
		var tw := create_tween()
		tw.tween_property(door, "position:y", 4.5, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	puzzle_solved.emit()

func _on_laser_hit(player: Node3D) -> void:
	if _audio_mgr:
		_audio_mgr.play_laser_zap()
	alarm_triggered.emit()
	if player.has_method("stun_player"):
		player.stun_player(checkpoint_pos)
