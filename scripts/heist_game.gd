class_name HeistGame
extends Node3D

const PlayerScene = preload("res://scenes/player.tscn")
const DynamicCameraScript = preload("res://scripts/dynamic_camera.gd")
const HUDScript = preload("res://scripts/hud.gd")
const VictoryFailScript = preload("res://scripts/victory_fail_screen.gd")

const PuzzleSecurityOverrideScript = preload("res://scripts/puzzles/puzzle_security_override.gd")
const PuzzleLaserGalleryScript = preload("res://scripts/puzzles/puzzle_laser_gallery.gd")
const PuzzleVaultScript = preload("res://scripts/puzzles/puzzle_vault.gd")

var _p1: CharacterBody3D = null
var _p2: CharacterBody3D = null
var _camera: Camera3D = null
var _hud: CanvasLayer = null
var _victory_fail_ui: CanvasLayer = null

var _puzzle_security: Node3D = null
var _puzzle_lasers: Node3D = null
var _puzzle_vault: Node3D = null

var _audio_mgr: Node = null

var _alarm_strikes: int = 0
var _game_active: bool = true
var _escape_phase: bool = false
var _escape_timer: float = 60.0
var _time_elapsed: float = 0.0

var _players_in_van: Array[Node3D] = []
var _alarm_lights: Array[OmniLight3D] = []

func _ready() -> void:
	_audio_mgr = get_node_or_null("/root/AudioManager")
	_setup_environment()
	_spawn_players_and_camera()
	_build_museum_structure()
	_setup_puzzles()
	_setup_hud()
	
	# Driver opening transmission
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(_hud):
		_hud.show_driver_radio("Cipher, Spark - you're inside. Crack security first, then get that diamond!", 5.0)

func _setup_environment() -> void:
	# Directional key light
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	sun.light_color = Color(0.95, 0.92, 0.85)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	
	# WorldEnvironment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.06, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.25, 0.35)
	env.ambient_light_energy = 0.8
	env.glow_enabled = true
	env.glow_bloom = 0.25
	env.glow_hdr_threshold = 1.0
	env_node.environment = env
	add_child(env_node)

func _spawn_players_and_camera() -> void:
	# Spawn Cipher (P1)
	_p1 = PlayerScene.instantiate()
	_p1.player_id = 1
	_p1.name = "Cipher"
	_p1.position = Vector3(-1.8, 0.5, 6.0)
	_p1.add_to_group("players")
	add_child(_p1)
	
	# Spawn Spark (P2)
	_p2 = PlayerScene.instantiate()
	_p2.player_id = 2
	_p2.name = "Spark"
	_p2.position = Vector3(1.8, 0.5, 6.0)
	_p2.add_to_group("players")
	add_child(_p2)
	
	# Setup shared dynamic camera
	var cam := DynamicCameraScript.new()
	cam.name = "DynamicCamera"
	cam.player_1 = _p1
	cam.player_2 = _p2
	cam.position = Vector3(0, 10, 14)
	add_child(cam)
	_camera = cam

func _build_museum_structure() -> void:
	# Materials
	var mat_marble := StandardMaterial3D.new()
	mat_marble.albedo_color = Color(0.12, 0.15, 0.2)
	mat_marble.roughness = 0.2
	
	var mat_wall := StandardMaterial3D.new()
	mat_wall.albedo_color = Color(0.08, 0.1, 0.14)
	mat_wall.roughness = 0.7
	
	var mat_gold_trim := StandardMaterial3D.new()
	mat_gold_trim.albedo_color = Color(0.85, 0.7, 0.25)
	mat_gold_trim.metallic = 0.9
	mat_gold_trim.roughness = 0.2
	
	var mat_asphalt := StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.05, 0.05, 0.06)
	mat_asphalt.roughness = 0.9
	
	# 1. Floor: Outside Alley (Z: +8 to +20)
	_create_static_box(Vector3(0, -0.2, 14.0), Vector3(22.0, 0.4, 12.0), mat_asphalt)
	
	# 2. Floor: Main Museum (Z: -52.0 to +8.0)
	_create_static_box(Vector3(0, -0.2, -22.0), Vector3(18.0, 0.4, 60.0), mat_marble)
	
	# 3. Outer Walls
	var wall_height: float = 5.0
	# East Wall
	_create_static_box(Vector3(9.0, wall_height * 0.5, -22.0), Vector3(0.6, wall_height, 60.0), mat_wall)
	# West Wall
	_create_static_box(Vector3(-9.0, wall_height * 0.5, -22.0), Vector3(0.6, wall_height, 60.0), mat_wall)
	# North Vault Wall
	_create_static_box(Vector3(0, wall_height * 0.5, -52.0), Vector3(18.6, wall_height, 0.6), mat_wall)
	
	# 4. South Museum Facade with Entrance Archway
	_create_static_box(Vector3(-6.0, wall_height * 0.5, 8.0), Vector3(6.6, wall_height, 0.8), mat_wall)
	_create_static_box(Vector3(6.0, wall_height * 0.5, 8.0), Vector3(6.6, wall_height, 0.8), mat_wall)
	_create_static_box(Vector3(0, 4.2, 8.0), Vector3(6.0, 1.6, 0.8), mat_gold_trim)
	
	# Museum Entrance Banner
	var sign := Label3D.new()
	sign.pixel_size = 0.007
	sign.font_size = 38
	sign.modulate = Color(1.0, 0.85, 0.3)
	sign.position = Vector3(0, 4.2, 8.5)
	sign.text = "★ GRAND MERIDIAN MUSEUM OF ANTIQUITIES ★"
	add_child(sign)
	
	# 5. Getaway Van & Escape Zone outside (Z = +14.0)
	_build_getaway_van(Vector3(0, 0, 14.0))
	
	# 6. Museum Exhibits / Decor in Lobby (Z = 2.0 to 7.0)
	_create_museum_exhibit(Vector3(-4.5, 0, 4.0), "ANCIENT AMULET")
	_create_museum_exhibit(Vector3(4.5, 0, 4.0), "GOLDEN PHARAOH BUST")
	
	# 7. Red Emergency Alarm Lights throughout sectors
	var alarm_positions := [
		Vector3(0, 4.2, 7.0),
		Vector3(0, 4.2, -4.0),
		Vector3(0, 4.2, -20.0),
		Vector3(0, 4.2, -37.0),
		Vector3(0, 4.2, -47.0)
	]
	for apos in alarm_positions:
		var light := OmniLight3D.new()
		light.position = apos
		light.light_color = Color(1.0, 0.1, 0.1)
		light.light_energy = 0.0 # Turned off until escape phase!
		light.omni_range = 14.0
		add_child(light)
		_alarm_lights.append(light)

func _create_static_box(pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.position = pos
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	sb.add_child(col)
	
	var mesh := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = size
	mesh.mesh = mbox
	mesh.material_override = mat
	sb.add_child(mesh)
	
	add_child(sb)
	return sb

func _create_museum_exhibit(pos: Vector3, title: String) -> void:
	var root := Node3D.new()
	root.position = pos
	
	# Pedestal
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.6
	cyl.height = 1.0
	ped.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.75, 0.72, 0.68)
	ped.material_override = pmat
	ped.position = Vector3(0, 0.5, 0)
	root.add_child(ped)
	
	# Glass showcase cover
	var glass := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(1.1, 1.1, 1.1)
	glass.mesh = gbox
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.6, 0.85, 1.0, 0.3)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.roughness = 0.1
	glass.material_override = gmat
	glass.position = Vector3(0, 1.55, 0)
	root.add_child(glass)
	
	# Exhibit Artifact (Golden Vase)
	var art := MeshInstance3D.new()
	var acyl := CylinderMesh.new()
	acyl.top_radius = 0.18
	acyl.bottom_radius = 0.12
	acyl.height = 0.6
	art.mesh = acyl
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.9, 0.75, 0.2)
	amat.metallic = 0.95
	art.material_override = amat
	art.position = Vector3(0, 1.35, 0)
	root.add_child(art)
	
	# StaticBody collider so players don't walk through exhibits
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(1.2, 2.2, 1.2)
	col.shape = cbox
	col.position = Vector3(0, 1.1, 0)
	sb.add_child(col)
	root.add_child(sb)
	
	# Exhibit plaque
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.005
	lbl.font_size = 28
	lbl.outline_size = 6
	lbl.position = Vector3(0, 2.3, 0)
	lbl.text = title
	root.add_child(lbl)
	
	add_child(root)

func _build_getaway_van(pos: Vector3) -> void:
	var van := Node3D.new()
	van.position = pos
	add_child(van)
	
	# Van Body
	var body := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(3.4, 2.4, 6.2)
	body.mesh = bbox
	var vmat := StandardMaterial3D.new()
	vmat.albedo_color = Color(0.1, 0.1, 0.12) # Sleek black van
	vmat.metallic = 0.6
	body.material_override = vmat
	body.position = Vector3(0, 1.4, 0)
	van.add_child(body)
	
	# Gold Racing Stripe
	var stripe := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(3.45, 0.35, 6.25)
	stripe.mesh = sbox
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.85, 0.2)
	stripe.material_override = smat
	stripe.position = Vector3(0, 1.3, 0)
	van.add_child(stripe)
	
	# Van Collider
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(3.6, 2.6, 6.4)
	col.shape = cbox
	col.position = Vector3(0, 1.4, 0)
	sb.add_child(col)
	van.add_child(sb)
	
	# Overhead indicator
	var vlbl := Label3D.new()
	vlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vlbl.pixel_size = 0.006
	vlbl.font_size = 38
	vlbl.outline_size = 8
	vlbl.modulate = Color(1.0, 0.85, 0.2)
	vlbl.position = Vector3(0, 3.4, 0)
	vlbl.text = "★ GETAWAY VAN ★\n[ESCAPE ZONE]"
	van.add_child(vlbl)
	
	# Van Hazard Lights
	var hazard_l := OmniLight3D.new()
	hazard_l.position = Vector3(-1.6, 1.8, 3.2)
	hazard_l.light_color = Color(1.0, 0.6, 0.0)
	hazard_l.light_energy = 2.0
	van.add_child(hazard_l)
	
	var hazard_r := OmniLight3D.new()
	hazard_r.position = Vector3(1.6, 1.8, 3.2)
	hazard_r.light_color = Color(1.0, 0.6, 0.0)
	hazard_r.light_energy = 2.0
	van.add_child(hazard_r)
	
	# Escape Zone Area3D
	var escape_area := Area3D.new()
	escape_area.collision_layer = 0
	escape_area.collision_mask = 2 # Players
	var acol := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(7.0, 3.0, 6.0)
	acol.shape = abox
	acol.position = Vector3(0, 1.5, -3.8) # Right behind back doors of van
	escape_area.add_child(acol)
	
	escape_area.body_entered.connect(_on_escape_zone_entered)
	escape_area.body_exited.connect(_on_escape_zone_exited)
	van.add_child(escape_area)

func _setup_puzzles() -> void:
	# Puzzle 1: Security Override (Z = -4.0)
	_puzzle_security = PuzzleSecurityOverrideScript.new()
	_puzzle_security.position = Vector3(0, 0, -4.0)
	_puzzle_security.puzzle_solved.connect(_on_puzzle_1_solved)
	_puzzle_security.alarm_triggered.connect(_add_alarm_strike)
	add_child(_puzzle_security)
	
	# Puzzle 2: Laser Gallery (Z = 0)
	_puzzle_lasers = PuzzleLaserGalleryScript.new()
	_puzzle_lasers.position = Vector3(0, 0, 0)
	_puzzle_lasers.puzzle_solved.connect(_on_puzzle_2_solved)
	_puzzle_lasers.alarm_triggered.connect(_add_alarm_strike)
	add_child(_puzzle_lasers)
	
	# Puzzle 3: Vault & Diamond (Z = 0)
	_puzzle_vault = PuzzleVaultScript.new()
	_puzzle_vault.position = Vector3(0, 0, 0)
	_puzzle_vault.vault_unlocked.connect(_on_puzzle_3_vault_opened)
	_puzzle_vault.diamond_stolen.connect(_on_diamond_stolen)
	_puzzle_vault.alarm_triggered.connect(_add_alarm_strike)
	add_child(_puzzle_vault)

func _setup_hud() -> void:
	_hud = HUDScript.new()
	add_child(_hud)
	
	_victory_fail_ui = VictoryFailScript.new()
	_victory_fail_ui.play_again_pressed.connect(_on_restart_game)
	_victory_fail_ui.main_menu_pressed.connect(_on_main_menu)
	add_child(_victory_fail_ui)

func _add_alarm_strike() -> void:
	_alarm_strikes += 1
	if _hud:
		_hud.update_alarms(_alarm_strikes)
	if _camera and _camera.has_method("shake"):
		_camera.shake(0.3)

func _on_puzzle_1_solved() -> void:
	if _hud:
		_hud.set_objective("Bypass Laser Gallery & Retrieve Vault Keycard")
		_hud.show_driver_radio("Security override complete! Now coordinate to cross the laser gallery!", 4.5)
	# Update checkpoint for both players
	if _p1:
		_p1.current_checkpoint = Vector3(-1.5, 0.5, -9.0)
	if _p2:
		_p2.current_checkpoint = Vector3(1.5, 0.5, -9.0)

func _on_puzzle_2_solved() -> void:
	if _hud:
		_hud.set_objective("Activate Dual Pressure Plates & Unlock the Diamond Vault")
		_hud.show_driver_radio("Lasers cleared! The vault door is ahead. Find the master code from the plaques!", 4.5)
	if _p1:
		_p1.current_checkpoint = Vector3(-1.5, 0.5, -34.0)
	if _p2:
		_p2.current_checkpoint = Vector3(1.5, 0.5, -34.0)

func _on_puzzle_3_vault_opened() -> void:
	if _hud:
		_hud.set_objective("Grab the Midnight Diamond from the Inner Vault!")
		_hud.show_driver_radio("Vault door open! The Midnight Diamond is right there! GRAB IT!", 4.0)

func _on_diamond_stolen(carrier: Node3D) -> void:
	_escape_phase = true
	_escape_timer = 60.0
	
	# Activate red flashing alarms
	for light in _alarm_lights:
		light.light_energy = 3.5
	
	if _hud:
		_hud.set_objective("EMERGENCY ESCAPE: BOTH PLAYERS TO GETAWAY VAN OUTSIDE!")
		_hud.start_escape_countdown(60.0)
		_hud.show_driver_radio("SIRENS ARE WAILING! COPS ARE EN ROUTE! GET BACK TO THE VAN OUTSIDE IN 60 SECONDS!", 5.5)

func _on_escape_zone_entered(player: Node3D) -> void:
	if not _players_in_van.has(player):
		_players_in_van.append(player)
	_check_escape_success()

func _on_escape_zone_exited(player: Node3D) -> void:
	_players_in_van.erase(player)

func _check_escape_success() -> void:
	if not _escape_phase or not _game_active:
		return
	
	var has_diamond_in_party: bool = false
	if _p1 and _p1.has_diamond:
		has_diamond_in_party = true
	if _p2 and _p2.has_diamond:
		has_diamond_in_party = true
	
	# Both players must be present in getaway zone with diamond
	if _players_in_van.has(_p1) and _players_in_van.has(_p2) and has_diamond_in_party:
		_game_active = false
		if _audio_mgr:
			_audio_mgr.stop_alarm_siren()
			_audio_mgr.play_success()
		if _victory_fail_ui:
			_victory_fail_ui.show_victory(_time_elapsed, _alarm_strikes)

func _process(delta: float) -> void:
	if not _game_active:
		return
	
	_time_elapsed += delta
	
	if _escape_phase:
		_escape_timer -= delta
		
		# Flash emergency alarm lights
		var strobe := 2.5 + sin(Time.get_ticks_msec() * 0.008) * 2.0
		for light in _alarm_lights:
			light.light_energy = strobe
		
		# Time out failure
		if _escape_timer <= 0.0:
			_game_active = false
			if _audio_mgr:
				_audio_mgr.stop_alarm_siren()
				_audio_mgr.play_buzzer()
			if _victory_fail_ui:
				_victory_fail_ui.show_failure("Time expired! The getaway van had to abandon the scene!")

func _on_restart_game() -> void:
	if _audio_mgr:
		_audio_mgr.stop_alarm_siren()
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	if _audio_mgr:
		_audio_mgr.stop_alarm_siren()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
