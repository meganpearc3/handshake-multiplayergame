class_name LaserBeam
extends Node3D

signal player_hit(player: Node3D)

@export var beam_width: float = 7.0
@export var moves_vertically: bool = false
@export var moves_horizontally: bool = false
@export var move_distance: float = 1.8
@export var move_speed: float = 2.0
@export var is_active: bool = true

var _initial_pos: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _beam_mesh: MeshInstance3D = null
var _area: Area3D = null
var _mat: StandardMaterial3D = null

func _ready() -> void:
	_initial_pos = position
	_build_laser()

func _build_laser() -> void:
	# 1. Outer Crimson Laser Glow Beam
	_beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = beam_width
	cyl.radial_segments = 12
	_beam_mesh.mesh = cyl
	_beam_mesh.rotation.z = PI * 0.5 # Horizontal beam
	
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1.0, 0.05, 0.05, 0.85)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.05, 0.05)
	_mat.emission_energy_multiplier = 5.0
	_beam_mesh.material_override = _mat
	add_child(_beam_mesh)
	
	# 2. Inner White-Hot Laser Core
	var core := MeshInstance3D.new()
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.016
	ccyl.bottom_radius = 0.016
	ccyl.height = beam_width
	ccyl.radial_segments = 8
	core.mesh = ccyl
	core.rotation.z = PI * 0.5
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(1.0, 0.95, 0.95)
	cmat.emission_enabled = true
	cmat.emission = Color(1.0, 1.0, 1.0)
	cmat.emission_energy_multiplier = 3.0
	core.material_override = cmat
	add_child(core)
	
	# 3. Heavy Wall Emitter Fixtures with Ruby Focusing Crystals
	for side in [-1, 1]:
		var emitter := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.24, 0.32, 0.32)
		emitter.mesh = box
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(0.14, 0.16, 0.20)
		emat.metallic = 0.9
		emat.roughness = 0.2
		emitter.material_override = emat
		emitter.position = Vector3(side * (beam_width * 0.5), 0, 0)
		add_child(emitter)
		
		# Ruby Focusing Lens
		var lens := MeshInstance3D.new()
		var ltorus := TorusMesh.new()
		ltorus.inner_radius = 0.04
		ltorus.outer_radius = 0.08
		lens.mesh = ltorus
		lens.rotation.z = PI * 0.5
		lens.material_override = _mat
		lens.position = Vector3(side * ((beam_width * 0.5) - 0.10), 0, 0)
		add_child(lens)
	
	# Collision Area3D (Preserves exact gameplay detection)
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2 # Players
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.18
	cap.height = beam_width
	col.shape = cap
	col.rotation.z = PI * 0.5
	_area.add_child(col)
	_area.body_entered.connect(_on_body_entered)
	add_child(_area)

func set_laser_active(val: bool) -> void:
	is_active = val
	visible = is_active
	if _area:
		_area.monitoring = is_active

func _process(delta: float) -> void:
	if not is_active:
		return
	
	_time += delta * move_speed
	var offset := sin(_time) * move_distance
	
	if moves_vertically:
		position.y = _initial_pos.y + offset
	elif moves_horizontally:
		position.z = _initial_pos.z + offset
	
	# Pulsing intensity
	if _mat:
		_mat.emission_energy_multiplier = 3.5 + sin(_time * 4.0) * 1.5

func _on_body_entered(body: Node3D) -> void:
	if is_active and body.is_in_group("players"):
		player_hit.emit(body)
