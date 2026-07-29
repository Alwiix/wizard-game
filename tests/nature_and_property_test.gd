extends Node


var battle: Node2D
var player: BattlePlayer
var enemies: Array[BattleEnemy] = []
var resolver: CombatEffectResolver
var modifiers: BattleModifierController
var combat_events: CombatEvents
var spell_library: SpellLibraryData


func _ready() -> void:
	RunState.start_new_run()

	var encounter := EncounterData.new()
	encounter.encounter_id = &"nature_property_test"
	encounter.display_name = "Nature Property Test"
	encounter.enemies = [
		ContentCatalog.SKELETON_DATA,
		ContentCatalog.ZOMBIE_DATA
	]

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	battle = battle_scene.instantiate() as Node2D
	battle.encounter_data = encounter
	add_child(battle)
	await get_tree().process_frame

	player = battle.get_node("Player") as BattlePlayer
	var controller := battle.get_node(
		"BattleController"
	) as BattleController
	enemies = controller.get_enemies()
	resolver = battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver
	modifiers = battle.get_node(
		"BattleModifierController"
	) as BattleModifierController
	combat_events = battle.get_node(
		"CombatEvents"
	) as CombatEvents
	spell_library = ContentCatalog.SPELL_LIBRARY

	await _test_muddy()
	await _test_firebreathing()
	await _test_vines_and_growth()
	await _test_seeping_oil()
	await _test_ignite()
	await _test_gust()
	await _test_static_bulwark()
	await _test_lava_floor()

	print("Nature and property test passed.")
	get_tree().quit()


func _test_muddy() -> void:
	_reset_combatants()
	await _resolve_spell([&"earth", &"water"])

	assert(player.get_status_stacks(&"block") == 3)
	assert(enemies[0].has_status(&"muddy"))
	assert(enemies[0].get_status_stacks(&"muddy") == 1)

	var damage := CombatEffectData.new()
	damage.effect_type = CombatEffectData.EffectType.DAMAGE
	damage.target = CombatEffectData.TargetType.PLAYER
	damage.amount = 8

	var action := CombatAction.new()
	action.action_id = &"muddy_attack"
	action.caster = enemies[0]
	action.primary_target = player
	action.effects = [damage]
	var player_health: int = player.health
	var result := await resolver.resolve_action(
		action,
		_create_context(enemies[0])
	)

	# Muddy reduces 8 to 6, then the existing 3 Block absorbs 3.
	assert(result.total_health_damage == 3)
	assert(player.health == player_health - 3)

	enemies[0].process_statuses_at_turn_end()
	assert(not enemies[0].has_status(&"muddy"))

	enemies[0].add_status(&"muddy", 2)
	enemies[0].process_statuses_at_turn_end()
	assert(enemies[0].get_status_stacks(&"muddy") == 1)

	enemies[0].add_status(&"wet", 1, 2)
	assert(not enemies[0].has_status(&"muddy"))

	# Existing Wet does not prevent a new Muddy application.
	assert(enemies[0].add_status(&"muddy", 1))
	assert(enemies[0].get_status_stacks(&"muddy") == 1)


func _test_firebreathing() -> void:
	_reset_combatants()
	await _resolve_spell([&"fire", &"air"])

	assert(player.get_status_stacks(&"firebreathing") == 1)
	player.add_status(&"firebreathing", 9, 3)
	assert(player.get_status_stacks(&"firebreathing") == 1)

	await _resolve_spell([&"fire", &"fire"])
	assert(enemies[0].get_status_stacks(&"burn") == 3)

	player.process_statuses_at_turn_end()
	player.process_statuses_at_turn_end()
	assert(player.has_status(&"firebreathing"))
	player.process_statuses_at_turn_end()
	assert(not player.has_status(&"firebreathing"))


func _test_vines_and_growth() -> void:
	_reset_combatants()
	var first_health: int = enemies[0].health
	await _resolve_spell([&"earth", &"nature"])
	assert(enemies[0].health == first_health)
	assert(
		enemies[0].get_status_stacks(&"creeping_vines") == 1
	)

	await _resolve_spell([&"earth", &"nature"])
	assert(enemies[0].health == first_health - 2)
	assert(
		enemies[0].get_status_stacks(&"creeping_vines") == 2
	)

	enemies[0].add_status(&"wet", 1, 2)
	assert(
		enemies[0].get_status_stacks(&"creeping_vines") == 3
	)

	await _resolve_spell([&"nature", &"water"])
	assert(
		enemies[0].get_status_stacks(&"creeping_vines") == 6
	)

	enemies[0].remove_status(&"creeping_vines")
	await _resolve_spell([&"nature", &"water"])
	assert(
		enemies[0].get_status_stacks(&"creeping_vines") == 1
	)


func _test_seeping_oil() -> void:
	_reset_combatants()
	await _resolve_spell([&"nature", &"fire"])

	for enemy in enemies:
		assert(enemy.get_status_stacks(&"creeping_vines") == 1)
		assert(not enemy.has_status(&"oil"))

	await _resolve_spell([&"nature", &"fire"])

	for enemy in enemies:
		assert(enemy.get_status_stacks(&"oil") == 1)
		assert(not enemy.has_status(&"creeping_vines"))

	enemies[0].add_status(&"creeping_vines", 5)
	enemies[1].add_status(&"creeping_vines", 2)
	await _resolve_spell([&"nature", &"fire"])
	assert(enemies[0].get_status_stacks(&"oil") == 4)
	assert(enemies[0].get_status_stacks(&"creeping_vines") == 2)
	assert(enemies[1].get_status_stacks(&"oil") == 3)
	assert(not enemies[1].has_status(&"creeping_vines"))

	await _resolve_spell([&"nature", &"fire"])
	assert(enemies[0].get_status_stacks(&"oil") == 6)
	assert(not enemies[0].has_status(&"creeping_vines"))
	assert(enemies[1].get_status_stacks(&"oil") == 3)
	assert(not enemies[1].has_status(&"creeping_vines"))


func _test_ignite() -> void:
	_reset_combatants()
	enemies[0].add_status(&"oil", 2)
	var starting_health: int = enemies[0].health
	await _resolve_spell([&"fire", &"lightning"])

	assert(enemies[0].health == starting_health - 3)
	assert(enemies[0].get_status_stacks(&"burn") == 3)
	assert(not enemies[0].has_status(&"oil"))

	_reset_combatants()
	enemies[0].add_status(&"oil", 5)
	starting_health = enemies[0].health
	var result := await _resolve_spell([&"fire", &"lightning"])

	assert(result.total_health_damage == 11)
	assert(enemies[0].health == starting_health - 11)
	assert(enemies[0].get_status_stacks(&"burn") == 6)
	assert(not enemies[0].has_status(&"oil"))


func _test_gust() -> void:
	_reset_combatants()
	enemies[0].add_status(&"cold", 2)
	await _resolve_spell([&"air", &"nature"])
	assert(enemies[0].get_status_stacks(&"cold") == 3)
	assert(enemies[0].get_status_stacks(&"bleed") == 2)

	_reset_combatants()
	enemies[0].add_status(&"burn", 2)
	await _resolve_spell([&"air", &"nature"])
	assert(enemies[0].get_status_stacks(&"burn") == 3)


func _test_static_bulwark() -> void:
	_reset_combatants()
	await _resolve_spell([&"earth", &"lightning"])

	assert(player.get_status_stacks(&"block") == 4)
	assert(player.get_status_stacks(&"electrified_guard") == 1)

	combat_events.attack_completed.emit(
		enemies[0],
		player,
		{},
		true,
		1
	)
	assert(enemies[0].get_status_stacks(&"electrified") == 1)
	assert(not player.has_status(&"electrified_guard"))


func _test_lava_floor() -> void:
	_reset_combatants()
	await _resolve_spell([&"fire", &"earth"])
	assert(modifiers.has_modifier(&"lava_floor"))

	combat_events.attack_completed.emit(
		player,
		enemies[0],
		{},
		true,
		1
	)
	assert(player.get_status_stacks(&"burn") == 2)

	modifiers.process_side_turn_end(&"enemy")
	assert(modifiers.has_modifier(&"lava_floor"))
	modifiers.process_side_turn_end(&"enemy")
	assert(not modifiers.has_modifier(&"lava_floor"))


func _resolve_spell(
	elements: Array[StringName],
	target: BattleEnemy = null
) -> CombatResult:
	var spell := spell_library.find_spell_for_elements(elements)
	assert(spell != null)

	var selected_target: BattleEnemy = (
		target if target != null else enemies[0]
	)
	var action := spell.create_action(player, selected_target)
	return await resolver.resolve_action(
		action,
		_create_context(selected_target)
	)


func _create_context(
	selected_enemy: BattleEnemy
) -> CombatContext:
	return CombatContext.create(
		player,
		enemies,
		selected_enemy,
		battle.get_node("CombatDeck") as CombatDeck,
		modifiers
	)


func _reset_combatants() -> void:
	for enemy in enemies:
		enemy.setup(enemy.enemy_data)

	var player_status_controller := player.get_status_controller()
	player_status_controller.clear_statuses()
	player.health = player.maximum_health
	player.energy = player.maximum_energy
	RunState.set_current_health(player.health)
	player.update_health_text()
	player.update_energy_text()
	modifiers.active_modifiers.clear()
