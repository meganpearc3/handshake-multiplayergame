class_name Player
extends CharacterBody3D

const InteractableScript = preload("res://scripts/interactable.gd")

signal interacted_with(interactable: Node)
signal diamond_picked_up()

@export var player_id: int = 1 # 1 = Cipher, 2 = Spark
@export var character_name: String = "Cipher"
@export var base_speed: float = 6.0
@export var acceleration: float = 18.0
@export var is_first_person: bool = true

var fp_yaw: float = 0.0
var fp_pitch: float = 0.0
var turn_speed: float = 3.2

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
var _arm_l: Node3D = null
var _arm_r: Node3D = null
var _leg_l: Node3D = null
var _leg_r: Node3D = null
var _stun_stars: Node3D = null
var _diamond_prop: Node3D = null
var _keycard_prop: Node3D = null
var _overhead_label: Label3D = null
var _halo_ring: MeshInstance3D = null
var _interaction_detector: Area3D = null

var _fp_cam_anchor: Node3D = null
var _fp_arms: Node3D = null
var _fp_arm_l: Node3D = null
var _fp_arm_r: Node3D = null

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
	_build_fp_rig()
	
	# Assign visual layers to completely prevent first-person self-blockage
	# Layer 2 for Cipher (P1) 3D body; Layer 4 for Spark (P2) 3D body
	var body_layer := 2 if player_id == 1 else 4
	_set_node_layers(_visuals, body_layer)
	if _overhead_label:
		_set_node_layers(_overhead_label, body_layer)
	if _halo_ring:
		_set_node_layers(_halo_ring, body_layer)
	if _stun_stars:
		_set_node_layers(_stun_stars, body_layer)
	
	# Layer 8 for Cipher FP hands; Layer 16 for Spark FP hands
	var fp_layer := 8 if player_id == 1 else 16
	_set_node_layers(_fp_arms, fp_layer)
	
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
	var pants_color := Color(0.10, 0.13, 0.18) # Dark stealth tactical pants
	var dark_gear := Color(0.08, 0.09, 0.12)
	var boot_color := Color(0.05, 0.05, 0.06)
	var gold_metal := Color(0.92, 0.78, 0.25)
	
	var mat_main := StandardMaterial3D.new()
	mat_main.albedo_color = main_color
	mat_main.roughness = 0.35
	
	var mat_accent := StandardMaterial3D.new()
	mat_accent.albedo_color = accent_color
	mat_accent.emission_enabled = true
	mat_accent.emission = accent_color
	mat_accent.emission_energy_multiplier = 1.4
	mat_accent.roughness = 0.2
	
	var mat_pants := StandardMaterial3D.new()
	mat_pants.albedo_color = pants_color
	mat_pants.roughness = 0.6
	
	var mat_gear := StandardMaterial3D.new()
	mat_gear.albedo_color = dark_gear
	mat_gear.roughness = 0.5
	
	var mat_boot := StandardMaterial3D.new()
	mat_boot.albedo_color = boot_color
	mat_boot.roughness = 0.7
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = gold_metal
	mat_gold.metallic = 0.9
	mat_gold.roughness = 0.2
	
	# 1. Torso & Fitted Jacket
	_torso = MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.30
	body_mesh.height = 0.85
	_torso.mesh = body_mesh
	_torso.material_override = mat_main
	_torso.position = Vector3(0, 0.68, 0)
	_visuals.add_child(_torso)
	
	# Chest Collar & Zipper line
	var collar := MeshInstance3D.new()
	var cmesh := BoxMesh.new()
	cmesh.size = Vector3(0.08, 0.55, 0.08)
	collar.mesh = cmesh
	collar.material_override = mat_gold
	collar.position = Vector3(0, 0.75, -0.28)
	_visuals.add_child(collar)
	
	# Tactical Chest Harness Straps
	for side in [-1, 1]:
		var strap := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(0.08, 0.5, 0.04)
		strap.mesh = sbox
		strap.material_override = mat_gear
		strap.position = Vector3(side * 0.18, 0.75, -0.26)
		strap.rotation.z = side * 0.25
		_visuals.add_child(strap)
	
	# 2. Utility Belt with Gold Buckle and Pouches
	var belt := MeshInstance3D.new()
	var belt_mesh := CylinderMesh.new()
	belt_mesh.top_radius = 0.33
	belt_mesh.bottom_radius = 0.33
	belt_mesh.height = 0.12
	belt.mesh = belt_mesh
	belt.material_override = mat_gear
	belt.position = Vector3(0, 0.44, 0)
	_visuals.add_child(belt)
	
	var buckle := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(0.14, 0.12, 0.06)
	buckle.mesh = bbox
	buckle.material_override = mat_gold
	buckle.position = Vector3(0, 0.44, -0.32)
	_visuals.add_child(buckle)
	
	# Side Gear Pouches
	for side in [-1, 1]:
		var pouch := MeshInstance3D.new()
		var pbox := BoxMesh.new()
		pbox.size = Vector3(0.12, 0.16, 0.14)
		pouch.mesh = pbox
		pouch.material_override = mat_gear
		pouch.position = Vector3(side * 0.32, 0.44, 0.05)
		_visuals.add_child(pouch)
	
	# 3. Head & Mask
	_head = MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.50
	_head.mesh = head_mesh
	_head.material_override = mat_gear # Balaclava
	_head.position = Vector3(0, 1.25, 0)
	_visuals.add_child(_head)
	
	# Operative Visor / Night Vision Goggles
	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.38, 0.14, 0.20)
	visor.mesh = visor_mesh
	visor.material_override = mat_accent
	visor.position = Vector3(0, 1.28, -0.16)
	_visuals.add_child(visor)
	
	# Dual Goggle Lenses
	for lx in [-0.10, 0.10]:
		var lens := MeshInstance3D.new()
		var lcyl := CylinderMesh.new()
		lcyl.top_radius = 0.065
		lcyl.bottom_radius = 0.065
		lcyl.height = 0.1
		lens.mesh = lcyl
		lens.rotation.x = PI * 0.5
		lens.material_override = mat_accent
		lens.position = Vector3(lx, 1.28, -0.24)
		_visuals.add_child(lens)
	
	# Blinking Comms Earpiece on Cipher / Infiltrator Aerial on Spark
	var antenna := MeshInstance3D.new()
	var acyl := CylinderMesh.new()
	acyl.top_radius = 0.015
	acyl.bottom_radius = 0.02
	acyl.height = 0.22
	antenna.mesh = acyl
	antenna.material_override = mat_gold
	antenna.position = Vector3(-0.25, 1.38, 0)
	antenna.rotation.z = -0.3
	_visuals.add_child(antenna)
	
	# 4. Articulated Legs & Boots
	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.16, 0.42, 0)
	_visuals.add_child(_leg_l)
	
	var leg_l_mesh := MeshInstance3D.new()
	var lcyl_leg := CylinderMesh.new()
	lcyl_leg.top_radius = 0.11
	lcyl_leg.bottom_radius = 0.10
	lcyl_leg.height = 0.32
	leg_l_mesh.mesh = lcyl_leg
	leg_l_mesh.material_override = mat_pants
	leg_l_mesh.position = Vector3(0, -0.16, 0)
	_leg_l.add_child(leg_l_mesh)
	
	var boot_l := MeshInstance3D.new()
	var bbox_boot := BoxMesh.new()
	bbox_boot.size = Vector3(0.18, 0.16, 0.28)
	boot_l.mesh = bbox_boot
	boot_l.material_override = mat_boot
	boot_l.position = Vector3(0, -0.34, -0.05)
	_leg_l.add_child(boot_l)
	
	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.16, 0.42, 0)
	_visuals.add_child(_leg_r)
	
	var leg_r_mesh := MeshInstance3D.new()
	leg_r_mesh.mesh = lcyl_leg
	leg_r_mesh.material_override = mat_pants
	leg_r_mesh.position = Vector3(0, -0.16, 0)
	_leg_r.add_child(leg_r_mesh)
	
	var boot_r := MeshInstance3D.new()
	boot_r.mesh = bbox_boot
	boot_r.material_override = mat_boot
	boot_r.position = Vector3(0, -0.34, -0.05)
	_leg_r.add_child(boot_r)
	
	# 5. Articulated Arms & Gloves
	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-0.35, 0.90, 0)
	_visuals.add_child(_arm_l)
	
	var arm_l_mesh := MeshInstance3D.new()
	var lcyl_arm := CylinderMesh.new()
	lcyl_arm.top_radius = 0.09
	lcyl_arm.bottom_radius = 0.08
	lcyl_arm.height = 0.36
	arm_l_mesh.mesh = lcyl_arm
	arm_l_mesh.material_override = mat_main
	arm_l_mesh.position = Vector3(0, -0.18, 0)
	_arm_l.add_child(arm_l_mesh)
	
	var glove_l := MeshInstance3D.new()
	var gsph := SphereMesh.new()
	gsph.radius = 0.10
	gsph.height = 0.20
	glove_l.mesh = gsph
	glove_l.material_override = mat_gear
	glove_l.position = Vector3(0, -0.38, 0)
	_arm_l.add_child(glove_l)
	
	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.35, 0.90, 0)
	_visuals.add_child(_arm_r)
	
	var arm_r_mesh := MeshInstance3D.new()
	arm_r_mesh.mesh = lcyl_arm
	arm_r_mesh.material_override = mat_main
	arm_r_mesh.position = Vector3(0, -0.18, 0)
	_arm_r.add_child(arm_r_mesh)
	
	var glove_r := MeshInstance3D.new()
	glove_r.mesh = gsph
	glove_r.material_override = mat_gear
	glove_r.position = Vector3(0, -0.38, 0)
	_arm_r.add_child(glove_r)
	
	# 6. Tactical Backpack with Equipment Roll
	_backpack = MeshInstance3D.new()
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(0.42, 0.50, 0.25)
	_backpack.mesh = pack_mesh
	_backpack.material_override = mat_gear
	_backpack.position = Vector3(0, 0.78, 0.24)
	_visuals.add_child(_backpack)
	
	# Backpack bedroll / gear cylinder on top
	var broll := MeshInstance3D.new()
	var rcyl := CylinderMesh.new()
	rcyl.top_radius = 0.10
	rcyl.bottom_radius = 0.10
	rcyl.height = 0.44
	broll.mesh = rcyl
	broll.rotation.z = PI * 0.5
	broll.material_override = mat_accent
	broll.position = Vector3(0, 1.08, 0.24)
	_visuals.add_child(broll)
	
	# 7. Overhead Identifier Label
	_overhead_label = Label3D.new()
	_overhead_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_overhead_label.no_depth_test = true
	_overhead_label.pixel_size = 0.005
	_overhead_label.font_size = 34
	_overhead_label.outline_size = 8
	_overhead_label.outline_modulate = Color(0, 0, 0, 0.95)
	_overhead_label.position = Vector3(0, 1.95, 0)
	_overhead_label.text = "★ CIPHER [P1]" if player_id == 1 else "★ SPARK [P2]"
	_overhead_label.modulate = accent_color
	add_child(_overhead_label)
	
	# 8. Crisp Neon Floor Halo Ring
	_halo_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.58
	_halo_ring.mesh = torus
	_halo_ring.material_override = mat_accent
	_halo_ring.position = Vector3(0, 0.04, 0)
	add_child(_halo_ring)
	
	# 9. Floating Stun Stars (hidden until stunned)
	_stun_stars = Node3D.new()
	_stun_stars.position = Vector3(0, 1.7, 0)
	_stun_stars.visible = false
	for i in range(3):
		var star := MeshInstance3D.new()
		var pmesh := PrismMesh.new()
		pmesh.size = Vector3(0.12, 0.12, 0.06)
		star.mesh = pmesh
		star.material_override = mat_gold
		var angle := (i * TAU) / 3.0
		star.position = Vector3(cos(angle) * 0.35, sin(angle) * 0.1, sin(angle) * 0.35)
		_stun_stars.add_child(star)
	_visuals.add_child(_stun_stars)
	
	# 10. Midnight Diamond Mount on Backpack
	_diamond_prop = Node3D.new()
	_diamond_prop.position = Vector3(0, 1.15, 0.36)
	_diamond_prop.visible = false
	
	var gem_top := MeshInstance3D.new()
	var tcyl_gem := CylinderMesh.new()
	tcyl_gem.top_radius = 0.22
	tcyl_gem.bottom_radius = 0.0
	tcyl_gem.height = 0.32
	gem_top.mesh = tcyl_gem
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.1, 0.9, 1.0, 0.95)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.3, 0.95, 1.0)
	gem_mat.emission_energy_multiplier = 3.5
	gem_mat.roughness = 0.05
	gem_top.material_override = gem_mat
	gem_top.position = Vector3(0, -0.08, 0)
	_diamond_prop.add_child(gem_top)
	
	var gem_bot := MeshInstance3D.new()
	var bcyl_gem := CylinderMesh.new()
	bcyl_gem.top_radius = 0.0
	bcyl_gem.bottom_radius = 0.22
	bcyl_gem.height = 0.18
	gem_bot.mesh = bcyl_gem
	gem_bot.material_override = gem_mat
	gem_bot.position = Vector3(0, 0.12, 0)
	_diamond_prop.add_child(gem_bot)
	
	# Diamond glowing aura
	var gem_light := OmniLight3D.new()
	gem_light.light_color = Color(0.2, 0.9, 1.0)
	gem_light.light_energy = 2.0
	gem_light.omni_range = 3.5
	_diamond_prop.add_child(gem_light)
	
	_visuals.add_child(_diamond_prop)
	
	# 11. Keycard Prop attached to belt
	_keycard_prop = Node3D.new()
	_keycard_prop.position = Vector3(0.32, 0.52, -0.15)
	_keycard_prop.visible = false
	var kc_mesh := MeshInstance3D.new()
	var kc_box := BoxMesh.new()
	kc_box.size = Vector3(0.10, 0.16, 0.02)
	kc_mesh.mesh = kc_box
	var kc_mat := StandardMaterial3D.new()
	kc_mat.albedo_color = Color(1.0, 0.88, 0.2)
	kc_mat.emission_enabled = true
	kc_mat.emission = Color(1.0, 0.88, 0.2)
	kc_mat.emission_energy_multiplier = 2.0
	kc_mesh.material_override = kc_mat
	_keycard_prop.add_child(kc_mesh)
	_visuals.add_child(_keycard_prop)
	
	# Character collision shape (preserved)
	var col_shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.3
	col_shape.shape = cap
	col_shape.position = Vector3(0, 0.7, 0)
	add_child(col_shape)

func _set_node_layers(node: Node, layer_mask: int) -> void:
	if node is VisualInstance3D:
		node.layers = layer_mask
	for child in node.get_children():
		_set_node_layers(child, layer_mask)

func _build_fp_rig() -> void:
	_fp_cam_anchor = Node3D.new()
	_fp_cam_anchor.name = "FPCamAnchor"
	_fp_cam_anchor.position = Vector3(0, 1.30, -0.32)
	_visuals.add_child(_fp_cam_anchor)
	
	_fp_arms = Node3D.new()
	_fp_arms.name = "FPArms"
	_fp_cam_anchor.add_child(_fp_arms)
	
	var main_col := Color(0.05, 0.65, 1.0) if player_id == 1 else Color(1.0, 0.52, 0.05)
	var gear_col := Color(0.08, 0.10, 0.14)
	var glow_col := Color(0.2, 0.95, 1.0) if player_id == 1 else Color(1.0, 0.85, 0.2)
	
	var mat_arm := StandardMaterial3D.new()
	mat_arm.albedo_color = main_col
	mat_arm.roughness = 0.35
	
	var mat_glove := StandardMaterial3D.new()
	mat_glove.albedo_color = gear_col
	mat_glove.roughness = 0.5
	
	var mat_cuff := StandardMaterial3D.new()
	mat_cuff.albedo_color = glow_col
	mat_cuff.emission_enabled = true
	mat_cuff.emission = glow_col
	mat_cuff.emission_energy_multiplier = 2.5
	
	# Left arm placed cleanly at bottom-left perimeter (completely unobscured view)
	_fp_arm_l = Node3D.new()
	_fp_arm_l.position = Vector3(-0.35, -0.32, -0.38)
	_fp_arm_l.rotation = Vector3(0.20, -0.25, 0.12)
	_fp_arms.add_child(_fp_arm_l)
	
	var mesh_l := MeshInstance3D.new()
	var cap_l := CapsuleMesh.new()
	cap_l.radius = 0.035
	cap_l.height = 0.28
	mesh_l.mesh = cap_l
	mesh_l.material_override = mat_arm
	mesh_l.rotation.x = PI * 0.4
	_fp_arm_l.add_child(mesh_l)
	
	var glove_l := MeshInstance3D.new()
	var gbox_l := BoxMesh.new()
	gbox_l.size = Vector3(0.06, 0.05, 0.12)
	glove_l.mesh = gbox_l
	glove_l.material_override = mat_glove
	glove_l.position = Vector3(0, 0.04, -0.14)
	_fp_arm_l.add_child(glove_l)
	
	var cuff_l := MeshInstance3D.new()
	var cbox_l := BoxMesh.new()
	cbox_l.size = Vector3(0.065, 0.02, 0.025)
	cuff_l.mesh = cbox_l
	cuff_l.material_override = mat_cuff
	cuff_l.position = Vector3(0, 0.06, -0.08)
	_fp_arm_l.add_child(cuff_l)
	
	# Right arm placed cleanly at bottom-right perimeter (completely unobscured view)
	_fp_arm_r = Node3D.new()
	_fp_arm_r.position = Vector3(0.35, -0.32, -0.38)
	_fp_arm_r.rotation = Vector3(0.20, 0.25, -0.12)
	_fp_arms.add_child(_fp_arm_r)
	
	var mesh_r := MeshInstance3D.new()
	mesh_r.mesh = cap_l
	mesh_r.material_override = mat_arm
	mesh_r.rotation.x = PI * 0.4
	_fp_arm_r.add_child(mesh_r)
	
	var glove_r := MeshInstance3D.new()
	glove_r.mesh = gbox_l
	glove_r.material_override = mat_glove
	glove_r.position = Vector3(0, 0.04, -0.14)
	_fp_arm_r.add_child(glove_r)
	
	var cuff_r := MeshInstance3D.new()
	cuff_r.mesh = cbox_l
	cuff_r.material_override = mat_cuff
	cuff_r.position = Vector3(0, 0.06, -0.08)
	_fp_arm_r.add_child(cuff_r)
	
	set_first_person(is_first_person)

func set_first_person(enabled: bool) -> void:
	is_first_person = enabled
	if _fp_arms:
		_fp_arms.visible = enabled
	if _overhead_label:
		_overhead_label.visible = not enabled
	if _halo_ring:
		_halo_ring.visible = not enabled

func get_fp_cam_transform() -> Transform3D:
	if _fp_cam_anchor:
		return _fp_cam_anchor.global_transform
	return global_transform.translated_local(Vector3(0, 1.28, -0.28))

func _unhandled_input(event: InputEvent) -> void:
	if player_id == 1 and is_first_person:
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			fp_yaw -= event.relative.x * 0.005
			fp_pitch = clampf(fp_pitch - event.relative.y * 0.005, -0.9, 0.9)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return
	
	var move_vec := Vector3.ZERO
	
	if is_first_person:
		# First-person keyboard controls: A/D turn view, W/S walk forward/back
		if Input.is_action_pressed(act_left):
			fp_yaw += turn_speed * delta
		if Input.is_action_pressed(act_right):
			fp_yaw -= turn_speed * delta
		
		var forward := Vector3(-sin(fp_yaw), 0.0, -cos(fp_yaw))
		var right_dir := Vector3(cos(fp_yaw), 0.0, -sin(fp_yaw))
		
		if Input.is_action_pressed(act_up):
			move_vec += forward
		if Input.is_action_pressed(act_down):
			move_vec -= forward
		
		if Input.is_key_pressed(KEY_SHIFT):
			if Input.is_action_pressed(act_left):
				move_vec -= right_dir
			if Input.is_action_pressed(act_right):
				move_vec += right_dir
		
		move_vec = move_vec.normalized()
		
		_visuals.rotation.y = fp_yaw
		if _fp_cam_anchor:
			_fp_cam_anchor.rotation.y = 0.0
			_fp_cam_anchor.rotation.x = fp_pitch
	else:
		# Overhead perspective movement
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
		
		move_vec = Vector3(input_dir.x, 0.0, input_dir.y)
		if move_vec.length_squared() > 0.01:
			_target_yaw = atan2(move_vec.x, move_vec.z) + PI
			_visuals.rotation.y = lerp_angle(_visuals.rotation.y, _target_yaw, delta * 12.0)
	
	if move_vec.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, move_vec.x * base_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_vec.z * base_speed, acceleration * delta)
		
		# Procedural walk bounce & tilt
		_walk_time += delta * 14.0
		_visuals.position.y = absf(sin(_walk_time)) * 0.08
		_visuals.rotation.z = sin(_walk_time * 0.5) * 0.08
		
		# First-person arm swing & head bob
		if _fp_arms:
			_fp_arms.position.y = absf(sin(_walk_time)) * 0.012
			if not _is_interacting_held:
				_fp_arm_r.position.z = -0.38 + sin(_walk_time) * 0.02
				_fp_arm_l.position.z = -0.38 - sin(_walk_time) * 0.02
			else:
				_fp_arm_r.position.z = -0.48
		
		# Articulated leg walking swing
		if _leg_l and _leg_r:
			_leg_l.rotation.x = sin(_walk_time) * 0.75
			_leg_r.rotation.x = -sin(_walk_time) * 0.75
		
		# Articulated arm walking swing (unless holding interaction)
		if _arm_l and _arm_r:
			if not _is_interacting_held:
				_arm_l.rotation.x = -sin(_walk_time) * 0.6
				_arm_r.rotation.x = sin(_walk_time) * 0.6
			else:
				_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, -1.2, delta * 12.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta * 1.5)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta * 1.5)
		_visuals.position.y = move_toward(_visuals.position.y, 0.0, delta * 0.5)
		_visuals.rotation.z = move_toward(_visuals.rotation.z, 0.0, delta * 4.0)
		
		if _fp_arms:
			_fp_arms.position.y = move_toward(_fp_arms.position.y, 0.0, delta * 0.5)
			if not _is_interacting_held:
				_fp_arm_r.position.z = move_toward(_fp_arm_r.position.z, -0.42, delta * 0.5)
				_fp_arm_l.position.z = move_toward(_fp_arm_l.position.z, -0.42, delta * 0.5)
		
		# Return limbs to rest and idle breathing
		if _leg_l and _leg_r:
			_leg_l.rotation.x = lerp_angle(_leg_l.rotation.x, 0.0, delta * 10.0)
			_leg_r.rotation.x = lerp_angle(_leg_r.rotation.x, 0.0, delta * 10.0)
		if _arm_l and _arm_r:
			if not _is_interacting_held:
				_arm_l.rotation.x = lerp_angle(_arm_l.rotation.x, 0.0, delta * 10.0)
				_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, 0.0, delta * 10.0)
			else:
				_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, -1.2, delta * 12.0)
		
		if _torso:
			_torso.position.y = 0.68 + sin(Time.get_ticks_msec() * 0.003) * 0.015
	
	# Animate stun stars if visible
	if _stun_stars and _stun_stars.visible:
		_stun_stars.rotation.y += delta * 10.0
	
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
	
	if _stun_stars:
		_stun_stars.visible = true
	
	# Flash red and spin
	var tween := create_tween()
	tween.tween_property(_visuals, "rotation:y", _visuals.rotation.y + TAU * 2.0, 0.6)
	
	await get_tree().create_timer(0.6).timeout
	var target := safe_pos if safe_pos != Vector3.ZERO else current_checkpoint
	global_position = target
	velocity = Vector3.ZERO
	if _stun_stars:
		_stun_stars.visible = false
	is_stunned = false
