class_name MainArena
extends Node3D

# ==============================================================================
# MAIN ARENA - 3D ISOMETRIC ARENA CONTROLLER
# ==============================================================================

@onready var hero_manager: HeroManager = $HeroManager
@onready var camera: IsometricCamera3D = $IsometricCamera3D
@onready var hud: CombatHUD = $CombatHUD

func _ready() -> void:
	print("⚔️ [MAIN ARENA] Initializing 3D Isometric Cel-Shaded Arena...")
	
	# Real-time Elemental Core testing without pausing
	var initial_core = ElementalCore3D.new()
	add_child(initial_core)
	initial_core.setup("fire", Vector3(3.0, 0.0, 2.0))
	
	EnvironmentPropsBuilder.spawn_tactical_arena_props(self, 1)
	
	# Instantiate ScreenshotCapture for AGENT-06 verification
	var screen_cap = ScreenshotCapture.new()
	screen_cap.prefix = "directive_08_overhaul"
	add_child(screen_cap)
	
	if hero_manager and hud:
		hero_manager.camera = camera
		hero_manager.hero_switched.connect(hud.hook_hero)
		if hero_manager.active_hero:
			hud.hook_hero(hero_manager.active_hero)
			
	_spawn_testing_dummies()
	
	# Initial Elemental Pillar for instant user testing
	var initial_pillar = ElementalPillar3D.new()
	add_child(initial_pillar)
	initial_pillar.setup("wind", Vector3(3.0, 0.0, 2.0))

func _spawn_testing_dummies() -> void:
	var dummy_positions = [
		Vector3(6.0, 0.0, 3.0),
		Vector3(-5.0, 0.0, 5.0),
		Vector3(3.0, 0.0, -6.0),
		Vector3(-4.0, 0.0, -4.0)
	]
	for pos in dummy_positions:
		var dummy = DummyTarget.new()
		dummy.position = pos
		add_child(dummy)
