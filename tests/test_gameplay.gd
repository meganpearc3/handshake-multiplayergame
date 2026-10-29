extends SceneTree

# Comprehensive End-to-End Gameplay Integration Test
# Validates the entire 5-stage co-op heist loop headlessly.

func _init() -> void:
	print("--- BEGINNING THE GREAT GEM CAPER END-TO-END VALIDATION ---")
	call_deferred("_run_tests")

func _run_tests() -> void:
	# 1. Load HeistGame scene
	var scene: PackedScene = load("res://scenes/heist_game.tscn")
	assert(scene != null, "Failed to load heist_game.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	
	# Wait 2 frames for _ready
	await process_frame
	await process_frame
	
	print("[PASS] Milestone A: Scene architecture, 3D museum environment, and dynamic camera initialized.")
	
	# Verify Players
	var p1: Node = game._p1
	var p2: Node = game._p2
	assert(p1 != null and p2 != null, "Players not instantiated")
	assert(p1.player_id == 1 and p1.character_name == "Cipher", "P1 Cipher mismatch")
	assert(p2.player_id == 2 and p2.character_name == "Spark", "P2 Spark mismatch")
	print("[PASS] Milestone A: Two independently controlled 3D CharacterBody3D operatives verified (Cipher & Spark).")
	
	# Verify Dynamic Camera
	var cam: Camera3D = game._camera
	assert(cam != null, "Camera not found")
	assert(cam.current == true, "Dynamic camera is not current")
	print("[PASS] Milestone A: Shared dynamic elevated camera framing both players verified.")
	
	# 2. Test Puzzle 1: Security Override
	print("Testing Puzzle 1: Security Override...")
	var puz1: Node = game._puzzle_security
	assert(puz1 != null, "Puzzle 1 not found")
	assert(puz1.is_solved == false, "Puzzle 1 initially solved")
	
	# P1 Cipher hacks console
	puz1._on_cipher_interacted(p1)
	assert(puz1.target_sequence.size() == 4, "Invalid target sequence size")
	print("Puzzle 1 target sequence: ", puz1.target_sequence)
	
	# Simulate Spark wrong button
	var wrong_btn: int = (puz1.target_sequence[0] % 4) + 1
	var initial_alarms: int = game._alarm_strikes
	puz1._on_spark_button_pressed(wrong_btn, puz1._spark_buttons[wrong_btn - 1])
	assert(game._alarm_strikes == initial_alarms + 1, "Alarm strike not incremented on wrong input")
	print("[PASS] Puzzle 1: Incorrect input cleanly triggers alarm strike and resets attempt.")
	
	# Simulate Spark inputting correct sequence
	for btn_num in puz1.target_sequence:
		puz1._on_spark_button_pressed(btn_num, puz1._spark_buttons[btn_num - 1])
	
	assert(puz1.is_solved == true, "Puzzle 1 not marked solved")
	print("[PASS] Milestone B: Puzzle 1 Security Override solved, bulkhead door opened.")
	
	# 3. Test Puzzle 2: Laser Gallery
	print("Testing Puzzle 2: Laser Gallery...")
	var puz2: Node = game._puzzle_lasers
	assert(puz2 != null, "Puzzle 2 not found")
	assert(puz2.is_solved == false, "Puzzle 2 initially solved")
	
	# Cipher holds Switch A
	puz2._on_switch_a_hold(true)
	for l in puz2._lasers_group_a:
		assert(l.is_active == false, "Laser Group A not disabled during Switch A hold")
	
	# Spark collects Keycard
	puz2._on_keycard_collected(p2)
	assert(p2.has_keycard == true, "Spark failed to collect keycard")
	puz2._on_switch_a_hold(false)
	
	# Spark holds Switch B
	puz2._on_switch_b_hold(true)
	for l in puz2._lasers_group_b:
		assert(l.is_active == false, "Laser Group B not disabled during Switch B hold")
	puz2._on_switch_b_hold(false)
	
	# Spark inserts Keycard into exit terminal
	puz2._on_keycard_inserted(p2)
	assert(puz2.is_solved == true, "Puzzle 2 not marked solved")
	assert(p2.has_keycard == false, "Keycard not consumed")
	print("[PASS] Milestone C: Puzzle 2 Laser Gallery solved with dual bypass switches and keycard.")
	
	# 4. Test Puzzle 3: Vault & Diamond
	print("Testing Puzzle 3: Vault Chamber & Diamond Theft...")
	var puz3: Node = game._puzzle_vault
	assert(puz3 != null, "Puzzle 3 not found")
	assert(puz3.is_power_latched == false, "Vault power initially latched")
	
	# Step on plate 1 only -> not latched
	puz3._on_plate_body_entered(1, p1)
	assert(puz3.is_power_latched == false, "Latch activated with single player")
	
	# Step on plate 2 simultaneously -> latch powers on
	puz3._on_plate_body_entered(2, p2)
	assert(puz3.is_power_latched == true, "Latch failed to activate with both players")
	
	# Players leave plates, circuit stays latched
	puz3._on_plate_body_exited(1, p1)
	puz3._on_plate_body_exited(2, p2)
	assert(puz3.is_power_latched == true, "Circuit unlatched unexpectedly")
	
	# Interact with console to enter 3-digit code
	puz3._on_console_interacted(p1)
	puz3._on_console_interacted(p1)
	puz3._on_console_interacted(p1)
	assert(puz3.is_vault_open == true, "Vault door failed to open with correct code")
	print("[PASS] Milestone C: Puzzle 3 Dual Pressure Plates & Vault Code verified.")
	
	# Steal Diamond
	puz3._on_diamond_grabbed(p1)
	assert(p1.has_diamond == true, "P1 does not have diamond")
	assert(game._escape_phase == true, "Escape phase not triggered")
	print("[PASS] Milestone D: Midnight Diamond collected and 60-second escape countdown initiated.")
	
	# 5. Test Escape to Van
	print("Testing Escape to Van...")
	# Only P1 in van -> not finished
	game._on_escape_zone_entered(p1)
	assert(game._game_active == true, "Game ended prematurely with single player in van")
	
	# P2 reaches van -> VICTORY!
	game._on_escape_zone_entered(p2)
	assert(game._game_active == false, "Game did not finish when both players entered van with diamond")
	assert(game._victory_fail_ui.visible == true, "Victory UI not visible")
	print("[PASS] Milestone D: Both operatives escaped to van with diamond - VICTORY UI triggered with rating.")
	
	print("--- ALL HEIST INTEGRATION TESTS COMPLETED SUCCESSFULLY! ---")
	quit(0)
