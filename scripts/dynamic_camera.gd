class_name DynamicCamera
extends Camera3D

@export var player_1: Node3D = null
@export var player_2: Node3D = null

@export var min_zoom_dist: float = 7.0
@export var max_zoom_dist: float = 16.0
@export var base_height: float = 8.5
@export var base_depth_offset: float = 7.5
@export var smooth_speed: float = 6.0

var _shake_amount: float = 0.0

func _ready() -> void:
	current = true
	fov = 54.0
	# Fixed isometric / angled overhead pitch
	rotation_degrees = Vector3(-48.0, 0.0, 0.0)

func shake(amount: float = 0.4) -> void:
	_shake_amount = maxf(_shake_amount, amount)

func _process(delta: float) -> void:
	if not is_instance_valid(player_1) or not is_instance_valid(player_2):
		return
	
	var p1_pos := player_1.global_position
	var p2_pos := player_2.global_position
	var midpoint := (p1_pos + p2_pos) * 0.5
	var separation := p1_pos.distance_to(p2_pos)
	
	# Compute zoom factor based on separation
	var t := clampf((separation - 3.0) / 12.0, 0.0, 1.0)
	var target_height := lerpf(base_height, base_height + 6.0, t)
	var target_depth := lerpf(base_depth_offset, base_depth_offset + 5.5, t)
	
	var target_pos := Vector3(
		midpoint.x,
		midpoint.y + target_height,
		midpoint.z + target_depth
	)
	
	# Apply screen shake if active
	if _shake_amount > 0.001:
		target_pos.x += randf_range(-_shake_amount, _shake_amount)
		target_pos.y += randf_range(-_shake_amount, _shake_amount)
		_shake_amount = move_toward(_shake_amount, 0.0, delta * 1.5)
	
	global_position = global_position.lerp(target_pos, delta * smooth_speed)
