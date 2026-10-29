class_name Player
extends CharacterBody3D

const InteractableScript = preload("res://scripts/interactable.gd")

signal interacted_with(interactable: Node)
signal diamond_picked_up()

@export var player_id: int = 1 # 1 = Cipher, 2 = Spark
@export var character_name: String = "Cipher"
@export var base_speed: float = 6.0
@export var acceleration: float = 18.0

var is_stunned: bool = false
var has_diamond: bool = false
var has_keycard: bool = false
var current_checkpoint: Vector3 = Vector3.ZERO

# Input action strings
var act_up: String = "p1_up"
var act_down: String = "p1_down"
var act_left: String = "p1_left"
var act_right: String = "p1_right"
var act_interact: String = "p1_interact"

# Nodes
var _visuals: Node3D = null
var _torso: MeshInstance3D = null
var _head: MeshInstance3D = null
var _backpack: MeshInstance3D = null
var _diamond_prop: Node3D = null
var _keycard_prop: Node3D = null
var _overhead_label: Label3D = null
var _halo_ring: MeshInstance3D = null
var _interaction_detector: Area3D = null

# State tracking
var _nearby_interactables: Array = []
var _active_held_interactable = null
var _walk_time: float = 0.0
var _target_yaw: float = 0.0
var _is_interacting_held: bool = false

func _ready() -> void:
	collision_layer = 2 # Players layer
	collision_mask = 1 | 4 # World & Interactables
	
	_configure_inputs()
	_build_procedural_model()
	current_checkpoint = global_position
	
	_interaction_detector = Area3D.new()
	_interaction_detector.collision_layer = 0
	_interaction_detector.collision_mask = 4 # Detect Interactables
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	col.shape = sphere
	_interaction_detector.add_child(col)
	add_child(_interaction_detector)
	
	_interaction_detector.area_entered.connect(_on_interaction_area_entered)
	_interaction_detector.area_exited.connect(_on_interaction_area_exited)

func _configure_inputs() -> void:
	if player_id == 1:
		character_name = "Cipher"
		act_up = "p1_up"
		act_down = "p1_down"
		act_left = "p1_left"
		act_right = "p1_right"
		act_interact = "p1_interact"
	else:
		character_name = "Spark"
		act_up = "p2_up"
		act_down = "p2_down"
		act_left = "p2_left"
		act_right = "p2_right"
		act_interact = "p2_interact"

func _build_procedural_model() -> void:
	# Root visuals node for rotation and walk animations
	_visuals = Node3D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	
	# Determine team colors
	var main_color := Color(0.12, 0.45, 0.95) if player_id == 1 else Color(0.95, 0.45, 0.08)
	var accent_color := Color(0.2, 0.9, 1.0) if player_id == 1 else Color(1.0, 0.85, 0.2)
	var dark_gear := Color(0.12, 0.14, 0.18)
	
	var mat_main := StandardMaterial3D.new()
	mat_main.albedo_color = main_color
	mat_main.roughness = 0.4
	
	var mat_accent := StandardMaterial3D.new()
	mat_accent.albedo_color = accent_color
	mat_accent.emission_enabled = true
	mat_accent.emission = accent_color
	mat_accent.emission_energy_multiplier = 0.8
	
	var mat_gear := StandardMaterial3D.new()
	mat_gear.albedo_color = dark_gear
	mat_gear.roughness = 0.6
	
	# Torso / Jumpsuit
	_torso = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.32
	body_mesh.height = 0.9
	_torso.mesh = body_mesh
	_torso.material_override = mat_main
	_torso.position = Vector3(0, 0.65, 0)
	_visuals.add_child(_torso)
	
	# Belt / Gear strap
	var belt := MeshInstance3D.new()
	var belt_mesh := CylinderMesh.new()
	belt_mesh.top_radius = 0.34
	belt_mesh.bottom_radius = 0.34
	belt_mesh.height = 0.12
	belt.mesh = belt_mesh
	belt.material_override = mat_gear
	belt.position = Vector3(0, 0.45, 0)
	_visuals.add_child(belt)
	
	# Head
	_head = MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	_head.mesh = head_mesh
	_head.material_override = mat_gear
	_head.position = Vector3(0, 1.25, 0)
	_visuals.add_child(_head)
	
	# Visor / Goggles
	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.38, 0.12, 0.22)
	visor.mesh = visor_mesh
	visor.material_override = mat_accent
	visor.position = Vector3(0, 1.28, -0.16)
	_visuals.add_child(visor)
	
	# Tactical Backpack
	_backpack = MeshInstance3D.new()
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(0.42, 0.48, 0.24)
	_backpack.mesh = pack_mesh
	_backpack.material_override = mat_gear
	_backpack.position = Vector3(0, 0.75, 0.22)
	_visuals.add_child(_backpack)
	
	# Overhead identifier label
	_overhead_label = Label3D.new()
	_overhead_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_overhead_label.no_depth_test = true
	_overhead_label.pixel_size = 0.005
	_overhead_label.font_size = 32
	_overhead_label.outline_size = 8
	_overhead_label.outline_modulate = Color(0, 0, 0, 0.9)
	_overhead_label.position = Vector3(0, 1.85, 0)
	_overhead_label.text = "P1 CIPHER" if player_id == 1 else "P2 SPARK"
	_overhead_label.modulate = accent_color
	add_child(_overhead_label)
	
	# Floor highlight ring
	_halo_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.55
	_halo_ring.mesh = torus
	_halo_ring.material_override = mat_accent
	_halo_ring.position = Vector3(0, 0.04, 0)
	add_child(_halo_ring)
	
	# Diamond carrier attachment (hidden until collected)
	_diamond_prop = Node3D.new()
	_diamond_prop.position = Vector3(0, 1.05, 0.32)
	_diamond_prop.visible = false
	var gem_mesh := MeshInstance3D.new()
	var prism := CylinderMesh.new()
	prism.top_radius = 0.0
	prism.bottom_radius = 0.22
	prism.height = 0.35
	gem_mesh.mesh = prism
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.1, 0.8, 1.0, 0.9)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.3, 0.9, 1.0)
	gem_mat.emission_energy_multiplier = 2.5
	gem_mat.roughness = 0.1
	gem_mesh.material_override = gem_mat
	gem_mesh.rotation.x = PI
	_diamond_prop.add_child(gem_mesh)
	_visuals.add_child(_diamond_prop)
	
	# Keycard prop (hidden until collected)
	_keycard_prop = Node3D.new()
	_keycard_prop.position = Vector3(0.28, 0.8, 0)
	_keycard_prop.visible = false
	var kc_mesh := MeshInstance3D.new()
	var kc_box := BoxMesh.new()
	kc_box.size = Vector3(0.08, 0.14, 0.02)
	kc_mesh.mesh = kc_box
	var kc_mat := StandardMaterial3D.new()
	kc_mat.albedo_color = Color(1.0, 0.9, 0.2)
	kc_mat.emission_enabled = true
	kc_mat.emission = Color(1.0, 0.9, 0.2)
	kc_mat.emission_energy_multiplier = 1.5
	kc_mesh.material_override = kc_mat
	_keycard_prop.add_child(kc_mesh)
	_visuals.add_child(_keycard_prop)
	
	# Character collision shape
	var col_shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.3
	col_shape.shape = cap
	col_shape.position = Vector3(0, 0.7, 0)
	add_child(col_shape)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return
	
	# Read movement inputs
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed(act_up):
		input_dir.y -= 1.0
	if Input.is_action_pressed(act_down):
		input_dir.y += 1.0
	if Input.is_action_pressed(act_left):
		input_dir.x -= 1.0
	if Input.is_action_pressed(act_right):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	# Isometric / elevated diagonal adjustment
	# Camera is angled at isometric view (looking down along +Z and slightly pitched)
	var move_vec := Vector3(input_dir.x, 0.0, input_dir.y)
	
	if move_vec.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, move_vec.x * base_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_vec.z * base_speed, acceleration * delta)
		
		# Rotate character visuals to face movement direction
		_target_yaw = atan2(move_vec.x, move_vec.z) + PI
		_visuals.rotation.y = lerp_angle(_visuals.rotation.y, _target_yaw, delta * 12.0)
		
		# Procedural walk bounce & tilt
		_walk_time += delta * 14.0
		_visuals.position.y = absf(sin(_walk_time)) * 0.08
		_visuals.rotation.z = sin(_walk_time * 0.5) * 0.08
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta * 1.5)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta * 1.5)
		_visuals.position.y = move_toward(_visuals.position.y, 0.0, delta * 0.5)
		_visuals.rotation.z = move_toward(_visuals.rotation.z, 0.0, delta * 4.0)
	
	move_and_slide()
	
	# Handle interaction inputs
	_handle_interactions()

func _handle_interactions() -> void:
	var closest := _get_closest_interactable()
	
	# Update prompt visibility
	for item in _nearby_interactables:
		if is_instance_valid(item):
			if item == closest:
				item.show_prompt_for(player_id)
			else:
				item.hide_prompt()
	
	if Input.is_action_just_pressed(act_interact):
		if closest and closest.can_interact(player_id):
			if closest.is_hold_switch:
				_active_held_interactable = closest
				closest.start_hold(self)
				_is_interacting_held = true
			else:
				closest.trigger_interact(self)
				interacted_with.emit(closest)
	
	if Input.is_action_just_released(act_interact):
		if _active_held_interactable:
			_active_held_interactable.release_hold(self)
			_active_held_interactable = null
			_is_interacting_held = false

func _get_closest_interactable() -> Node:
	var best: Node = null
	var min_dist: float = 9999.0
	for item in _nearby_interactables:
		if is_instance_valid(item) and item.can_interact(player_id):
			var d := global_position.distance_to(item.global_position)
			if d < min_dist:
				min_dist = d
				best = item
	return best

func _on_interaction_area_entered(area: Area3D) -> void:
	if area is InteractableScript:
		if not _nearby_interactables.has(area):
			_nearby_interactables.append(area)

func _on_interaction_area_exited(area: Area3D) -> void:
	if area is InteractableScript:
		_nearby_interactables.erase(area)
		area.hide_prompt()
		if _active_held_interactable == area:
			_active_held_interactable.release_hold(self)
			_active_held_interactable = null

func give_diamond() -> void:
	has_diamond = true
	if _diamond_prop:
		_diamond_prop.visible = true
	diamond_picked_up.emit()

func give_keycard() -> void:
	has_keycard = true
	if _keycard_prop:
		_keycard_prop.visible = true

func remove_keycard() -> void:
	has_keycard = false
	if _keycard_prop:
		_keycard_prop.visible = false

func stun_player(safe_pos: Vector3 = Vector3.ZERO) -> void:
	if is_stunned:
		return
	is_stunned = true
	if _active_held_interactable:
		_active_held_interactable.release_hold(self)
		_active_held_interactable = null
	
	# Flash red and spin
	var tween := create_tween()
	tween.tween_property(_visuals, "rotation:y", _visuals.rotation.y + TAU * 2.0, 0.6)
	
	await get_tree().create_timer(0.6).timeout
	var target := safe_pos if safe_pos != Vector3.ZERO else current_checkpoint
	global_position = target
	velocity = Vector3.ZERO
	is_stunned = false
