class_name Interactable
extends Area3D

signal interacted(player: Node3D)
signal hold_started(player: Node3D)
signal hold_ended(player: Node3D)

@export var prompt_text: String = "Interact"
@export var target_action_name: String = "" # e.g. "Hack", "Push", "Collect"
@export var allowed_player_id: int = 0 # 0 = Any, 1 = Cipher, 2 = Spark
@export var is_hold_switch: bool = false
@export var is_enabled: bool = true

var _current_holding_player: Node3D = null
var _highlight_mesh: MeshInstance3D = null
var _label3d: Label3D = null

func _ready() -> void:
	collision_layer = 4 # Interaction layer
	collision_mask = 2 # Players layer
	
	# Create floating 3D prompt label
	_label3d = Label3D.new()
	_label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label3d.no_depth_test = true
	_label3d.fixed_size = false
	_label3d.pixel_size = 0.005
	_label3d.font_size = 36
	_label3d.outline_size = 8
	_label3d.outline_modulate = Color(0, 0, 0, 0.9)
	_label3d.position = Vector3(0, 1.4, 0)
	_label3d.visible = false
	add_child(_label3d)
	_update_label_text()

func set_enabled(val: bool) -> void:
	is_enabled = val
	if not is_enabled:
		hide_prompt()
		if _current_holding_player:
			release_hold(_current_holding_player)

func _update_label_text() -> void:
	if not _label3d:
		return
	var key_prompt := "[E / Enter]"
	if allowed_player_id == 1:
		key_prompt = "[E - Cipher]"
		_label3d.modulate = Color(0.3, 0.8, 1.0)
	elif allowed_player_id == 2:
		key_prompt = "[Enter - Spark]"
		_label3d.modulate = Color(1.0, 0.65, 0.2)
	else:
		key_prompt = "[E or Enter]"
		_label3d.modulate = Color(1.0, 0.95, 0.7)
	
	var verb := target_action_name if not target_action_name.is_empty() else prompt_text
	_label3d.text = "%s %s" % [key_prompt, verb]

func show_prompt_for(player_id: int) -> void:
	if not is_enabled:
		return
	if allowed_player_id != 0 and allowed_player_id != player_id:
		return
	_update_label_text()
	if _label3d:
		_label3d.visible = true

func hide_prompt() -> void:
	if _label3d:
		_label3d.visible = false

func can_interact(player_id: int) -> bool:
	if not is_enabled:
		return false
	if allowed_player_id != 0 and allowed_player_id != player_id:
		return false
	return true

func trigger_interact(player: Node3D) -> void:
	if not is_enabled:
		return
	var pid: int = player.get("player_id") if player else 0
	if not can_interact(pid):
		return
	interacted.emit(player)

func start_hold(player: Node3D) -> void:
	if not is_enabled or not is_hold_switch:
		return
	var pid: int = player.get("player_id") if player else 0
	if not can_interact(pid):
		return
	_current_holding_player = player
	hold_started.emit(player)

func release_hold(player: Node3D) -> void:
	if _current_holding_player == player:
		_current_holding_player = null
		hold_ended.emit(player)

func is_being_held() -> bool:
	return _current_holding_player != null
