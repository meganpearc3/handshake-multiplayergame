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
var _security_cameras: Array[Node3D] = []

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
	# High-grade Stylized Museum Palette Materials
	var mat_marble := StandardMaterial3D.new()
	mat_marble.albedo_color = Color(0.09, 0.12, 0.18)
	mat_marble.roughness = 0.18
	mat_marble.metallic = 0.08
	
	var mat_carpet := StandardMaterial3D.new()
	mat_carpet.albedo_color = Color(0.52, 0.08, 0.12) # Royal crimson runner
	mat_carpet.roughness = 0.85
	
	var mat_wainscot := StandardMaterial3D.new()
	mat_wainscot.albedo_color = Color(0.12, 0.08, 0.06) # Rich polished mahogany
	mat_wainscot.roughness = 0.45
	
	var mat_wall_upper := StandardMaterial3D.new()
	mat_wall_upper.albedo_color = Color(0.07, 0.10, 0.15) # Midnight navy museum plaster
	mat_wall_upper.roughness = 0.75
	
	var mat_gold_trim := StandardMaterial3D.new()
	mat_gold_trim.albedo_color = Color(0.9, 0.75, 0.28)
	mat_gold_trim.metallic = 0.95
	mat_gold_trim.roughness = 0.2
	
	var mat_hazard := StandardMaterial3D.new()
	mat_hazard.albedo_color = Color(0.95, 0.8, 0.1) # Caution yellow
	mat_hazard.roughness = 0.5
	
	var mat_asphalt := StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.05, 0.05, 0.06)
	mat_asphalt.roughness = 0.9
	
	var mat_sidewalk := StandardMaterial3D.new()
	mat_sidewalk.albedo_color = Color(0.25, 0.26, 0.28)
	mat_sidewalk.roughness = 0.7
	
	# 1. Floor: Outside Alley & Sidewalk (Z: +8 to +22)
	_create_static_box(Vector3(0, -0.2, 16.0), Vector3(24.0, 0.4, 16.0), mat_asphalt)
	_create_static_box(Vector3(0, 0.05, 9.2), Vector3(22.0, 0.2, 2.4), mat_sidewalk)
	
	# Street Lamp Post outside lighting the alley
	_create_street_lamp(Vector3(-7.5, 0, 15.0))
	_create_street_lamp(Vector3(7.5, 0, 15.0))
	
	# 2. Main Museum Polished Floor (Z: -52.0 to +8.0)
	_create_static_box(Vector3(0, -0.2, -22.0), Vector3(18.0, 0.4, 60.0), mat_marble)
	
	# Royal Crimson Velvet Runner Carpets along main walkways
	# Lobby carpet
	var c1 := _create_decorative_box(Vector3(0, 0.02, 4.0), Vector3(4.0, 0.02, 8.0), mat_carpet)
	# Gold borders on carpet
	_create_decorative_box(Vector3(-2.05, 0.025, 4.0), Vector3(0.1, 0.025, 8.0), mat_gold_trim)
	_create_decorative_box(Vector3(2.05, 0.025, 4.0), Vector3(0.1, 0.025, 8.0), mat_gold_trim)
	
	# Laser Hallway carpet
	_create_decorative_box(Vector3(0, 0.02, -20.5), Vector3(4.2, 0.02, 23.0), mat_carpet)
	_create_decorative_box(Vector3(-2.15, 0.025, -20.5), Vector3(0.1, 0.025, 23.0), mat_gold_trim)
	_create_decorative_box(Vector3(2.15, 0.025, -20.5), Vector3(0.1, 0.025, 23.0), mat_gold_trim)
	
	# Vault Antechamber Carpet
	_create_decorative_box(Vector3(0, 0.02, -41.0), Vector3(5.0, 0.02, 14.0), mat_carpet)
	
	# Yellow Hazard Stripes at Sector Thresholds
	for z_hazard in [-8.0, -32.0]:
		_create_decorative_box(Vector3(0, 0.025, z_hazard), Vector3(7.0, 0.025, 0.6), mat_hazard)
	
	# 3. Outer Walls & Two-Tier Architectural Paneling
	var wall_height: float = 5.2
	
	# East Wall (X = 9.0)
	_create_static_box(Vector3(9.0, wall_height * 0.5, -22.0), Vector3(0.6, wall_height, 60.0), mat_wall_upper)
	_create_decorative_box(Vector3(8.65, 0.6, -22.0), Vector3(0.15, 1.2, 60.0), mat_wainscot)
	_create_decorative_box(Vector3(8.62, 1.22, -22.0), Vector3(0.18, 0.1, 60.0), mat_gold_trim) # Chair rail
	_create_decorative_box(Vector3(8.62, wall_height - 0.1, -22.0), Vector3(0.2, 0.2, 60.0), mat_gold_trim) # Cornice
	
	# West Wall (X = -9.0)
	_create_static_box(Vector3(-9.0, wall_height * 0.5, -22.0), Vector3(0.6, wall_height, 60.0), mat_wall_upper)
	_create_decorative_box(Vector3(-8.65, 0.6, -22.0), Vector3(0.15, 1.2, 60.0), mat_wainscot)
	_create_decorative_box(Vector3(-8.62, 1.22, -22.0), Vector3(0.18, 0.1, 60.0), mat_gold_trim)
	_create_decorative_box(Vector3(-8.62, wall_height - 0.1, -22.0), Vector3(0.2, 0.2, 60.0), mat_gold_trim)
	
	# North Vault Reinforced Wall (Z = -52.0)
	_create_static_box(Vector3(0, wall_height * 0.5, -52.0), Vector3(18.6, wall_height, 0.8), mat_wall_upper)
	_create_decorative_box(Vector3(0, 0.6, -51.55), Vector3(18.6, 1.2, 0.15), mat_wainscot)
	_create_decorative_box(Vector3(0, 1.22, -51.52), Vector3(18.6, 0.1, 0.18), mat_gold_trim)
	
	# 4. South Museum Facade with Grand Columns & Archway
	_create_static_box(Vector3(-6.0, wall_height * 0.5, 8.0), Vector3(6.6, wall_height, 0.8), mat_wall_upper)
	_create_static_box(Vector3(6.0, wall_height * 0.5, 8.0), Vector3(6.6, wall_height, 0.8), mat_wall_upper)
	_create_static_box(Vector3(0, 4.4, 8.0), Vector3(6.0, 1.6, 0.8), mat_gold_trim)
	
	# Museum Entrance Sign & Portico
	var sign := Label3D.new()
	sign.pixel_size = 0.007
	sign.font_size = 38
	sign.modulate = Color(1.0, 0.88, 0.35)
	sign.outline_size = 8
	sign.outline_modulate = Color(0, 0, 0, 0.9)
	sign.position = Vector3(0, 4.4, 8.5)
	sign.text = "🏛 GRAND MERIDIAN MUSEUM OF ANTIQUITIES 🏛"
	add_child(sign)
	
	# Classical Columns with Gold Capitals along the halls
	var column_z_coords := [6.0, 1.5, -3.5, -9.0, -14.5, -20.5, -26.5, -32.0, -36.0, -42.0, -48.0]
	for cz in column_z_coords:
		_create_museum_column(Vector3(-8.2, 0, cz))
		_create_museum_column(Vector3(8.2, 0, cz))
	
	# 5. Framed Classical Artworks along the walls
	_create_framed_painting(Vector3(-8.6, 2.5, 5.0), 0.0, "MASTERPIECE: LA GIOCONDA", Color(0.3, 0.45, 0.35))
	_create_framed_painting(Vector3(8.6, 2.5, 5.0), PI, "MASTERPIECE: THE STARRY HEIST", Color(0.15, 0.25, 0.65))
	_create_framed_painting(Vector3(-8.6, 2.5, -1.0), 0.0, "MODERN ART: GEOMETRIC CRIMSON", Color(0.7, 0.2, 0.25))
	_create_framed_painting(Vector3(8.6, 2.5, -1.0), PI, "ANCIENT MAP OF MERIDIAN", Color(0.65, 0.55, 0.35))
	_create_framed_painting(Vector3(-8.6, 2.5, -16.0), 0.0, "PORTRAIT OF THE FOUNDER", Color(0.25, 0.35, 0.4))
	_create_framed_painting(Vector3(8.6, 2.5, -25.0), PI, "THE LOST ROYAL RUBY", Color(0.75, 0.15, 0.2))
	
	# 6. Potted Museum Plants in decorative ceramic planters
	_create_potted_plant(Vector3(-7.2, 0, 7.0))
	_create_potted_plant(Vector3(7.2, 0, 7.0))
	_create_potted_plant(Vector3(-7.2, 0, -6.5))
	_create_potted_plant(Vector3(7.2, 0, -6.5))
	_create_potted_plant(Vector3(-7.2, 0, -33.5))
	_create_potted_plant(Vector3(7.2, 0, -33.5))
	
	# 7. Animated Museum Security Cameras
	_create_security_camera(Vector3(-8.2, 4.6, 7.2), 0.3)
	_create_security_camera(Vector3(8.2, 4.6, -8.2), -0.4)
	_create_security_camera(Vector3(-8.2, 4.6, -31.5), 0.5)
	
	# 8. Museum Reception Desk in Lobby (X = -5.0, Z = 2.0)
	_create_reception_desk(Vector3(-5.2, 0, 2.0))
	
	# 9. Museum Velvet Rope Stanchions framing lobby exhibits
	_create_stanchion_post(Vector3(-2.8, 0, 2.2))
	_create_stanchion_post(Vector3(-2.8, 0, 5.8))
	_create_stanchion_post(Vector3(2.8, 0, 2.2))
	_create_stanchion_post(Vector3(2.8, 0, 5.8))
	
	# 10. Getaway Van & Escape Zone outside (Z = +14.0)
	_build_getaway_van(Vector3(0, 0, 14.0))
	
	# 11. Sculptural Museum Exhibits
	_create_museum_exhibit(Vector3(-4.5, 0, 4.0), "GOLDEN PHARAOH BUST", 1)
	_create_museum_exhibit(Vector3(4.5, 0, 4.0), "ANCIENT MYCENAEAN URN", 2)
	_create_museum_exhibit(Vector3(-5.5, 0, -20.5), "ROYAL CROWN OF CORONA", 3)
	_create_museum_exhibit(Vector3(5.5, 0, -20.5), "NEOLITHIC EMERALD IDOL", 4)
	
	# 12. Red Emergency Alarm Lights throughout sectors
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

func _create_decorative_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = size
	mesh.mesh = mbox
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	return mesh

func _create_museum_column(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	
	var mat_marble := StandardMaterial3D.new()
	mat_marble.albedo_color = Color(0.82, 0.8, 0.76) # Polished ivory marble
	mat_marble.roughness = 0.25
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.9, 0.75, 0.25)
	mat_gold.metallic = 0.95
	mat_gold.roughness = 0.2
	
	# Column Plinth / Base
	var base := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(1.1, 0.4, 1.1)
	base.mesh = bbox
	base.material_override = mat_gold
	base.position = Vector3(0, 0.2, 0)
	root.add_child(base)
	
	# Fluted Column Shaft
	var shaft := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.42
	scyl.bottom_radius = 0.45
	scyl.height = 4.4
	scyl.radial_segments = 16
	shaft.mesh = scyl
	shaft.material_override = mat_marble
	shaft.position = Vector3(0, 2.6, 0)
	root.add_child(shaft)
	
	# Capital Header
	var cap := MeshInstance3D.new()
	cap.mesh = bbox
	cap.material_override = mat_gold
	cap.position = Vector3(0, 4.9, 0)
	root.add_child(cap)
	
	# Physical collider
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var ccyl := CylinderShape3D.new()
	ccyl.radius = 0.5
	ccyl.height = 5.2
	col.shape = ccyl
	col.position = Vector3(0, 2.6, 0)
	sb.add_child(col)
	root.add_child(sb)
	
	add_child(root)

func _create_framed_painting(pos: Vector3, rot_y: float, title: String, art_color: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	
	# Gold Ornate Frame
	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(2.4, 1.8, 0.08)
	frame.mesh = fbox
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.9, 0.75, 0.25)
	fmat.metallic = 0.95
	fmat.roughness = 0.2
	frame.material_override = fmat
	root.add_child(frame)
	
	# Canvas Artwork
	var canvas := MeshInstance3D.new()
	var cbox := BoxMesh.new()
	cbox.size = Vector3(2.1, 1.5, 0.09)
	canvas.mesh = cbox
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = art_color
	cmat.roughness = 0.8
	canvas.material_override = cmat
	root.add_child(canvas)
	
	# Miniature Museum Spotlight above painting
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 1.4, 0.8)
	spot.rotation_degrees = Vector3(-45, 0, 0)
	spot.light_color = Color(1.0, 0.92, 0.75)
	spot.light_energy = 1.8
	spot.spot_range = 3.5
	spot.spot_angle = 35.0
	root.add_child(spot)
	
	# Museum Plaque
	var plq := Label3D.new()
	plq.pixel_size = 0.003
	plq.font_size = 26
	plq.outline_size = 4
	plq.modulate = Color(1.0, 0.88, 0.5)
	plq.position = Vector3(0, -1.05, 0.06)
	plq.text = title
	root.add_child(plq)
	
	add_child(root)

func _create_potted_plant(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	
	# Ceramic Pot
	var pot := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 0.45
	pcyl.bottom_radius = 0.35
	pcyl.height = 0.8
	pot.mesh = pcyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.4, 0.25) # Terracotta
	pmat.roughness = 0.6
	pot.material_override = pmat
	pot.position = Vector3(0, 0.4, 0)
	root.add_child(pot)
	
	# Ficus Foliage Clusters
	var mat_leaf := StandardMaterial3D.new()
	mat_leaf.albedo_color = Color(0.15, 0.55, 0.22)
	mat_leaf.roughness = 0.5
	
	var leaves1 := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.55
	sph.height = 1.1
	leaves1.mesh = sph
	leaves1.material_override = mat_leaf
	leaves1.position = Vector3(0, 1.2, 0)
	root.add_child(leaves1)
	
	var leaves2 := MeshInstance3D.new()
	var sph2 := SphereMesh.new()
	sph2.radius = 0.4
	sph2.height = 0.8
	leaves2.mesh = sph2
	leaves2.material_override = mat_leaf
	leaves2.position = Vector3(0, 1.6, 0)
	root.add_child(leaves2)
	
	# Collider
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var ccyl := CylinderShape3D.new()
	ccyl.radius = 0.45
	ccyl.height = 1.6
	col.shape = ccyl
	col.position = Vector3(0, 0.8, 0)
	sb.add_child(col)
	root.add_child(sb)
	
	add_child(root)

func _create_security_camera(pos: Vector3, base_rot_y: float) -> void:
	var cam_root := Node3D.new()
	cam_root.position = pos
	cam_root.rotation.y = base_rot_y
	
	# Mount bracket
	var mount := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = Vector3(0.2, 0.2, 0.3)
	mount.mesh = mbox
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.2, 0.22, 0.25)
	mount.material_override = mmat
	cam_root.add_child(mount)
	
	# Camera Body (Pivoting node)
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	cam_root.add_child(pivot)
	
	var cbody := MeshInstance3D.new()
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.14
	ccyl.bottom_radius = 0.18
	ccyl.height = 0.4
	cbody.mesh = ccyl
	cbody.rotation.x = PI * 0.5
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.9, 0.92, 0.95) # Sleek dome camera
	cbody.material_override = cmat
	pivot.add_child(cbody)
	
	# Blinking Green LED (turns Red during escape)
	var led := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.04
	sph.height = 0.08
	led.mesh = sph
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.2, 1.0, 0.3)
	lmat.emission_enabled = true
	lmat.emission = Color(0.2, 1.0, 0.3)
	lmat.emission_energy_multiplier = 2.0
	led.material_override = lmat
	led.position = Vector3(0, -0.1, 0.22)
	pivot.add_child(led)
	cam_root.set_meta("led_mat", lmat)
	cam_root.set_meta("pivot", pivot)
	_security_cameras.append(cam_root)
	add_child(cam_root)

func _create_reception_desk(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	
	# Polished Curved Reception Desk
	var desk := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(3.2, 1.1, 1.2)
	desk.mesh = dbox
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.12, 0.08, 0.06) # Mahogany desk
	dmat.roughness = 0.3
	desk.material_override = dmat
	desk.position = Vector3(0, 0.55, 0)
	root.add_child(desk)
	
	# Gold Top Trim
	var gtop := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(3.25, 0.08, 1.25)
	gtop.mesh = tbox
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.9, 0.75, 0.25)
	gmat.metallic = 0.9
	gmat.roughness = 0.2
	gtop.material_override = gmat
	gtop.position = Vector3(0, 1.14, 0)
	root.add_child(gtop)
	
	# Computer Monitor on Desk
	var mon := MeshInstance3D.new()
	var mbox := BoxMesh.new()
	mbox.size = Vector3(0.6, 0.45, 0.05)
	mon.mesh = mbox
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.05, 0.15, 0.25)
	mmat.emission_enabled = true
	mmat.emission = Color(0.1, 0.5, 0.8)
	mmat.emission_energy_multiplier = 0.8
	mon.material_override = mmat
	mon.position = Vector3(-0.6, 1.45, 0.1)
	root.add_child(mon)
	
	# Desk Lamp with Banker's Green Shade
	var lamp := MeshInstance3D.new()
	var lcyl := CylinderMesh.new()
	lcyl.top_radius = 0.08
	lcyl.bottom_radius = 0.16
	lcyl.height = 0.12
	lamp.mesh = lcyl
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.1, 0.6, 0.3)
	lmat.emission_enabled = true
	lmat.emission = Color(0.1, 0.7, 0.3)
	lmat.emission_energy_multiplier = 1.2
	lamp.material_override = lmat
	lamp.position = Vector3(0.7, 1.4, 0.1)
	root.add_child(lamp)
	
	# StaticBody collider
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var sbox := BoxShape3D.new()
	sbox.size = Vector3(3.4, 1.4, 1.4)
	col.shape = sbox
	col.position = Vector3(0, 0.7, 0)
	sb.add_child(col)
	root.add_child(sb)
	
	add_child(root)

func _create_stanchion_post(pos: Vector3) -> void:
	var post := Node3D.new()
	post.position = pos
	
	var mat_gold := StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.9, 0.75, 0.25)
	mat_gold.metallic = 0.95
	mat_gold.roughness = 0.15
	
	var mat_rope := StandardMaterial3D.new()
	mat_rope.albedo_color = Color(0.65, 0.08, 0.12) # Velvet red rope
	mat_rope.roughness = 0.8
	
	# Brass Base
	var b := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.18
	bcyl.bottom_radius = 0.22
	bcyl.height = 0.08
	b.mesh = bcyl
	b.material_override = mat_gold
	b.position = Vector3(0, 0.04, 0)
	post.add_child(b)
	
	# Post Rod
	var rod := MeshInstance3D.new()
	var rcyl := CylinderMesh.new()
	rcyl.top_radius = 0.035
	rcyl.bottom_radius = 0.035
	rcyl.height = 0.9
	rod.mesh = rcyl
	rod.material_override = mat_gold
	rod.position = Vector3(0, 0.5, 0)
	post.add_child(rod)
	
	# Ball top
	var ball := MeshInstance3D.new()
	var bsph := SphereMesh.new()
	bsph.radius = 0.07
	bsph.height = 0.14
	ball.mesh = bsph
	ball.material_override = mat_gold
	ball.position = Vector3(0, 0.98, 0)
	post.add_child(ball)
	
	add_child(post)

func _create_street_lamp(pos: Vector3) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	
	var mat_iron := StandardMaterial3D.new()
	mat_iron.albedo_color = Color(0.15, 0.16, 0.18)
	mat_iron.metallic = 0.8
	mat_iron.roughness = 0.4
	
	# Pole
	var pole := MeshInstance3D.new()
	var pcyl := CylinderMesh.new()
	pcyl.top_radius = 0.08
	pcyl.bottom_radius = 0.12
	pcyl.height = 4.2
	pole.mesh = pcyl
	pole.material_override = mat_iron
	pole.position = Vector3(0, 2.1, 0)
	lamp.add_child(pole)
	
	# Lantern Head
	var head := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(0.5, 0.6, 0.5)
	head.mesh = hbox
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(1.0, 0.9, 0.7)
	hmat.emission_enabled = true
	hmat.emission = Color(1.0, 0.88, 0.65)
	hmat.emission_energy_multiplier = 3.0
	head.material_override = hmat
	head.position = Vector3(0, 4.2, 0)
	lamp.add_child(head)
	
	# Warm Light Pool
	var light := OmniLight3D.new()
	light.position = Vector3(0, 3.8, 0)
	light.light_color = Color(1.0, 0.88, 0.65)
	light.light_energy = 3.2
	light.omni_range = 10.0
	lamp.add_child(light)
	
	add_child(lamp)

func _create_museum_exhibit(pos: Vector3, title: String, exhibit_type: int = 1) -> void:
	var root := Node3D.new()
	root.position = pos
	
	# Luxury Ivory & Gold Museum Pedestal
	var ped := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.65
	cyl.height = 1.0
	ped.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.88, 0.86, 0.82)
	pmat.roughness = 0.2
	ped.material_override = pmat
	ped.position = Vector3(0, 0.5, 0)
	root.add_child(ped)
	
	# Gold Plinth Ring
	var gring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.55
	t.outer_radius = 0.62
	gring.mesh = t
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.9, 0.75, 0.25)
	gmat.metallic = 0.95
	gring.material_override = gmat
	gring.position = Vector3(0, 0.98, 0)
	root.add_child(gring)
	
	# Realistic Glass Showcase with Beveled Brass Corner Edge Posts
	var glass := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(1.15, 1.25, 1.15)
	glass.mesh = gbox
	var gl_mat := StandardMaterial3D.new()
	gl_mat.albedo_color = Color(0.65, 0.88, 1.0, 0.22)
	gl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl_mat.roughness = 0.05
	glass.material_override = gl_mat
	glass.position = Vector3(0, 1.62, 0)
	root.add_child(glass)
	
	# Interior Artifact
	var art := Node3D.new()
	art.position = Vector3(0, 1.45, 0)
	if exhibit_type == 1:
		# Golden Pharaoh Bust
		var bmesh := MeshInstance3D.new()
		var scyl := CylinderMesh.new()
		scyl.top_radius = 0.22
		scyl.bottom_radius = 0.12
		scyl.height = 0.65
		bmesh.mesh = scyl
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.95, 0.78, 0.2)
		bmat.metallic = 0.95
		bmat.roughness = 0.15
		bmesh.material_override = bmat
		art.add_child(bmesh)
	elif exhibit_type == 2:
		# Ancient Mycenaean Urn
		var umesh := MeshInstance3D.new()
		var usph := SphereMesh.new()
		usph.radius = 0.28
		usph.height = 0.6
		umesh.mesh = usph
		var umat := StandardMaterial3D.new()
		umat.albedo_color = Color(0.75, 0.45, 0.25) # Painted terracotta
		umat.roughness = 0.6
		umesh.material_override = umat
		art.add_child(umesh)
	elif exhibit_type == 3:
		# Royal Crown of Corona
		var cmesh := MeshInstance3D.new()
		var ctorus := TorusMesh.new()
		ctorus.inner_radius = 0.18
		ctorus.outer_radius = 0.28
		cmesh.mesh = ctorus
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(1.0, 0.82, 0.2)
		cmat.metallic = 0.95
		cmesh.material_override = cmat
		art.add_child(cmesh)
	else:
		# Emerald Idol
		var emesh := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		ebox.size = Vector3(0.3, 0.55, 0.3)
		emesh.mesh = ebox
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(0.1, 0.85, 0.4)
		emat.emission_enabled = true
		emat.emission = Color(0.1, 0.85, 0.4)
		emat.emission_energy_multiplier = 0.8
		emesh.material_override = emat
		art.add_child(emesh)
	
	root.add_child(art)
	
	# Museum Showcase Downlight
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 3.2, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.light_color = Color(1.0, 0.95, 0.85)
	spot.light_energy = 2.2
	spot.spot_range = 3.5
	spot.spot_angle = 30.0
	root.add_child(spot)
	
	# StaticBody collider
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(1.3, 2.3, 1.3)
	col.shape = cbox
	col.position = Vector3(0, 1.15, 0)
	sb.add_child(col)
	root.add_child(sb)
	
	# Exhibit Brass Plaque
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.005
	lbl.font_size = 28
	lbl.outline_size = 6
	lbl.modulate = Color(1.0, 0.88, 0.4)
	lbl.position = Vector3(0, 2.45, 0)
	lbl.text = "🏛 " + title
	root.add_child(lbl)
	
	add_child(root)

func _build_getaway_van(pos: Vector3) -> void:
	var van := Node3D.new()
	van.position = pos
	add_child(van)
	
	var mat_body := StandardMaterial3D.new()
	mat_body.albedo_color = Color(0.1, 0.12, 0.15) # Matte stealth charcoal
	mat_body.metallic = 0.4
	mat_body.roughness = 0.35
	
	var mat_gold_stripe := StandardMaterial3D.new()
	mat_gold_stripe.albedo_color = Color(1.0, 0.82, 0.22) # Golden racing stripes
	mat_gold_stripe.metallic = 0.8
	mat_gold_stripe.roughness = 0.2
	
	var mat_glass := StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.08, 0.16, 0.25, 0.7)
	mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_glass.roughness = 0.1
	
	var mat_rubber := StandardMaterial3D.new()
	mat_rubber.albedo_color = Color(0.06, 0.06, 0.07)
	mat_rubber.roughness = 0.85
	
	var mat_chrome := StandardMaterial3D.new()
	mat_chrome.albedo_color = Color(0.9, 0.92, 0.95)
	mat_chrome.metallic = 0.95
	mat_chrome.roughness = 0.1
	
	# 1. Main Van Cabin Body
	var body := MeshInstance3D.new()
	var bbox := BoxMesh.new()
	bbox.size = Vector3(3.2, 2.2, 5.8)
	body.mesh = bbox
	body.material_override = mat_body
	body.position = Vector3(0, 1.45, 0)
	van.add_child(body)
	
	# Slanted Front Windshield Hood
	var hood := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(3.1, 1.2, 1.4)
	hood.mesh = hbox
	hood.material_override = mat_body
	hood.position = Vector3(0, 0.95, 3.2)
	van.add_child(hood)
	
	# Glass Windshield
	var windshield := MeshInstance3D.new()
	var wbox := BoxMesh.new()
	wbox.size = Vector3(2.8, 1.1, 0.1)
	windshield.mesh = wbox
	windshield.material_override = mat_glass
	windshield.position = Vector3(0, 1.85, 2.75)
	windshield.rotation.x = -0.35
	van.add_child(windshield)
	
	# Dual Gold Racing Stripes
	var stripe1 := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(0.3, 0.05, 7.2)
	stripe1.mesh = sbox
	stripe1.material_override = mat_gold_stripe
	stripe1.position = Vector3(-0.45, 2.58, 0.6)
	van.add_child(stripe1)
	
	var stripe2 := MeshInstance3D.new()
	stripe2.mesh = sbox
	stripe2.material_override = mat_gold_stripe
	stripe2.position = Vector3(0.45, 2.58, 0.6)
	van.add_child(stripe2)
	
	# 4 Heavy Rubber Wheels with Chrome Hubcaps
	var wheel_positions := [
		Vector3(-1.65, 0.45, 2.0),
		Vector3(1.65, 0.45, 2.0),
		Vector3(-1.65, 0.45, -2.0),
		Vector3(1.65, 0.45, -2.0)
	]
	for wp in wheel_positions:
		var wheel := MeshInstance3D.new()
		var wcyl := CylinderMesh.new()
		wcyl.top_radius = 0.45
		wcyl.bottom_radius = 0.45
		wcyl.height = 0.35
		wheel.mesh = wcyl
		wheel.rotation.z = PI * 0.5
		wheel.material_override = mat_rubber
		wheel.position = wp
		van.add_child(wheel)
		
		# Hubcap
		var hub := MeshInstance3D.new()
		var hcyl := CylinderMesh.new()
		hcyl.top_radius = 0.22
		hcyl.bottom_radius = 0.22
		hcyl.height = 0.38
		hub.mesh = hcyl
		hub.rotation.z = PI * 0.5
		hub.material_override = mat_chrome
		hub.position = wp
		van.add_child(hub)
	
	# Roof Rack & Stealth Antenna
	var rack := MeshInstance3D.new()
	var rbox := BoxMesh.new()
	rbox.size = Vector3(2.6, 0.2, 4.2)
	rack.mesh = rbox
	rack.material_override = mat_chrome
	rack.position = Vector3(0, 2.65, -0.4)
	van.add_child(rack)
	
	var antenna := MeshInstance3D.new()
	var acyl := CylinderMesh.new()
	acyl.top_radius = 0.02
	acyl.bottom_radius = 0.04
	acyl.height = 1.6
	antenna.mesh = acyl
	antenna.material_override = mat_chrome
	antenna.position = Vector3(-0.9, 3.45, -1.8)
	van.add_child(antenna)
	
	# Front Headlights
	for x_side in [-1.1, 1.1]:
		var hlight := MeshInstance3D.new()
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.5, 0.35, 0.1)
		hlight.mesh = hl_mesh
		var hl_mat := StandardMaterial3D.new()
		hl_mat.albedo_color = Color(1.0, 0.98, 0.8)
		hl_mat.emission_enabled = true
		hl_mat.emission = Color(1.0, 0.98, 0.8)
		hl_mat.emission_energy_multiplier = 4.0
		hlight.material_override = hl_mat
		hlight.position = Vector3(x_side, 1.0, 3.9)
		van.add_child(hlight)
		
		var spot := SpotLight3D.new()
		spot.position = Vector3(x_side, 1.0, 4.0)
		spot.light_color = Color(1.0, 0.95, 0.8)
		spot.light_energy = 3.5
		spot.spot_range = 14.0
		spot.spot_angle = 35.0
		van.add_child(spot)
	
	# Rear Taillights
	for x_side in [-1.3, 1.3]:
		var tlight := MeshInstance3D.new()
		var tl_mesh := BoxMesh.new()
		tl_mesh.size = Vector3(0.4, 0.5, 0.1)
		tlight.mesh = tl_mesh
		var tl_mat := StandardMaterial3D.new()
		tl_mat.albedo_color = Color(1.0, 0.1, 0.1)
		tl_mat.emission_enabled = true
		tl_mat.emission = Color(1.0, 0.1, 0.1)
		tl_mat.emission_energy_multiplier = 3.0
		tlight.material_override = tl_mat
		tlight.position = Vector3(x_side, 1.4, -2.9)
		van.add_child(tlight)
	
	# Physical Collider for Van
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	var col := CollisionShape3D.new()
	var cbox := BoxShape3D.new()
	cbox.size = Vector3(3.6, 2.6, 6.8)
	col.shape = cbox
	col.position = Vector3(0, 1.4, 0.2)
	sb.add_child(col)
	van.add_child(sb)
	
	# Overhead Escape Zone Indicator
	var vlbl := Label3D.new()
	vlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	vlbl.pixel_size = 0.006
	vlbl.font_size = 38
	vlbl.outline_size = 8
	vlbl.outline_modulate = Color(0, 0, 0, 0.9)
	vlbl.modulate = Color(1.0, 0.85, 0.25)
	vlbl.position = Vector3(0, 3.8, 0)
	vlbl.text = "🚐 GETAWAY EXTRACTION ZONE 🚐\n[BRING THE MIDNIGHT DIAMOND HERE]"
	van.add_child(vlbl)
	
	# Van Amber Hazard Lights
	var hazard_l := OmniLight3D.new()
	hazard_l.position = Vector3(-1.6, 1.8, 3.2)
	hazard_l.light_color = Color(1.0, 0.65, 0.0)
	hazard_l.light_energy = 2.5
	van.add_child(hazard_l)
	
	var hazard_r := OmniLight3D.new()
	hazard_r.position = Vector3(1.6, 1.8, 3.2)
	hazard_r.light_color = Color(1.0, 0.65, 0.0)
	hazard_r.light_energy = 2.5
	van.add_child(hazard_r)
	
	# Escape Zone Area3D (Preserves exact trigger size and position behind van)
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
	if _camera and _camera.has_method("shake"):
		_camera.shake(0.35)
	if _hud:
		_hud.set_objective("Grab the Midnight Diamond from the Inner Vault!")
		_hud.show_driver_radio("Vault door open! The Midnight Diamond is right there! GRAB IT!", 4.0)

func _on_diamond_stolen(carrier: Node3D) -> void:
	_escape_phase = true
	_escape_timer = 60.0
	if _camera and _camera.has_method("shake"):
		_camera.shake(0.55)
	
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
	
	# Animate security cameras
	var cam_pan := sin(_time_elapsed * 0.8) * 0.45
	for cam in _security_cameras:
		if is_instance_valid(cam):
			var pivot: Node3D = cam.get_meta("pivot")
			if pivot:
				pivot.rotation.y = cam_pan
			if _escape_phase:
				var led_mat: StandardMaterial3D = cam.get_meta("led_mat")
				if led_mat:
					led_mat.albedo_color = Color(1.0, 0.1, 0.1)
					led_mat.emission = Color(1.0, 0.1, 0.1)
	
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
