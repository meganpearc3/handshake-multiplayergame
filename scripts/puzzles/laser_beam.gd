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
	# Laser beam line
	_beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.035
	cyl.bottom_radius = 0.035
	cyl.height = beam_width
	_beam_mesh.mesh = cyl
	_beam_mesh.rotation.z = PI * 0.5 # Horizontal beam
	
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1.0, 0.05, 0.05, 0.9)
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.1, 0.1)
	_mat.emission_energy_multiplier = 4.0
	_beam_mesh.material_override = _mat
	add_child(_beam_mesh)
	
	# Emitters on both sides
	for side in [-1, 1]:
		var emitter := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.2, 0.25, 0.25)
		emitter.mesh = box
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(0.2, 0.22, 0.25)
		emat.metallic = 0.8
		emitter.material_override = emat
		emitter.position = Vector3(side * (beam_width * 0.5), 0, 0)
		add_child(emitter)
	
	# Collision Area3D
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
