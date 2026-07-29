extends Node


var battle: Node2D
var player: BattlePlayer
var enemy: BattleEnemy
var resolver: CombatEffectResolver
var combat_events: CombatEvents
var spell_library: SpellLibraryData


func _ready() -> void:
	RunState.start_new_run()

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	battle = battle_scene.instantiate() as Node2D
	add_child(battle)
	await get_tree().process_frame

	player = battle.get_node("Player") as BattlePlayer
	enemy = battle.get_node("Enemy") as BattleEnemy
	resolver = battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver
	combat_events = battle.get_node("CombatEvents") as CombatEvents
	spell_library = load(
		"res://Data/Spells/spell_library.tres"
	) as SpellLibraryData

	_test_recipe_set()
	await _test_setup_spells()
	await _test_damage_and_status_spells()
	await _test_cold_frozen_and_shatter()
	await _test_electric()
	await _test_enemy_electric()
	await _test_stormcloud()

	print("New spell set test passed.")
	get_tree().quit()


func _test_recipe_set() -> void:
	var expected_spells: Array = [
		[[&"water", &"water", &"lightning"], &"speed"],
		[[&"water", &"lightning", &"lightning"], &"lightning_helix"],
		[[&"air", &"air", &"lightning"], &"slip_dodge"],
		[[&"lightning", &"lightning", &"air"], &"dash"],
		[[&"air", &"air", &"air"], &"hurricane"],
		[[&"lightning", &"lightning", &"lightning"], &"lightning_bolt"],
		[[&"water", &"water", &"water"], &"ice_wall"],
		[[&"air", &"air", &"water"], &"typhoon"],
		[[&"water", &"water", &"air"], &"ice_shard"],
		[[&"water", &"air"], &"arctic_gust"],
		[[&"water", &"lightning"], &"conductive_current"],
		[[&"water", &"water"], &"water_ball"],
		[[&"lightning", &"lightning"], &"jolt"],
		[[&"air", &"lightning"], &"stormcloud"],
		[[&"air", &"air"], &"slash"],
		[[&"fire", &"fire"], &"scorch"],
		[[&"fire", &"lightning"], &"burst_lightning"],
		[[&"earth", &"nature"], &"writhing_roots"],
		[[&"earth", &"water"], &"mud_wall"],
		[[&"air", &"nature"], &"splinter"],
		[[&"nature", &"fire"], &"seeping_oil"],
		[[&"fire", &"air"], &"firebreathing"],
		[[&"earth", &"earth"], &"encase"],
		[[&"nature", &"water"], &"rapid_growth"],
		[[&"fire", &"earth"], &"lava_floor"],
		[[&"earth", &"lightning"], &"static_bulwark"]
	]

	assert(spell_library.recipes.size() == expected_spells.size())

	for expected in expected_spells:
		var elements: Array = expected[0]
		var spell: SpellData

		if elements.size() == 2:
			spell = spell_library.find_spell(
				elements[0],
				elements[1]
			)
		else:
			spell = spell_library.find_spell(
				elements[0],
				elements[1],
				elements[2]
			)

		assert(spell != null)
		assert(spell.spell_id == expected[1])
		assert(
			spell.energy_cost == (
				1 if elements.size() == 2 else 2
			)
		)

	assert(
		spell_library.find_spell(
			&"water",
			&"lightning",
			&"air"
		) == null
	)


func _test_setup_spells() -> void:
	_reset_combatants()
	await _resolve_spell([&"water", &"water", &"lightning"])
	assert(player.consume_next_turn_draw_bonus() == 1)

	_reset_combatants()
	await _resolve_spell([&"water", &"lightning", &"lightning"])
	assert(enemy.health == 16)
	assert(player.get_status_stacks(&"block") == 4)

	_reset_combatants()
	await _resolve_spell([&"air", &"air", &"lightning"])
	assert(player.get_status_stacks(&"dodge") == 1)

	var health_before_dodge: int = player.health
	var dodge_result: Dictionary = await enemy.perform_turn(
		player,
		resolver
	)
	assert(bool(dodge_result.get("attack_dodged", false)))
	assert(player.health == health_before_dodge)
	assert(not player.has_status(&"dodge"))

	_reset_combatants()
	await _resolve_spell([&"lightning", &"lightning", &"air"])
	player.start_turn()
	assert(player.energy == 3)
	player.start_turn()
	assert(player.energy == 2)

	_reset_combatants()
	await _resolve_spell([&"water", &"water", &"water"])
	assert(player.get_status_stacks(&"block") == 10)

	_reset_combatants()
	await _resolve_spell([&"water", &"lightning"])
	assert(enemy.has_status(&"wet"))
	assert(not player.has_status(&"block"))
	assert(not player.has_status(&"electrified_guard"))

	var health_before_discharge := enemy.health
	await _resolve_spell([&"water", &"lightning"])
	assert(enemy.health == health_before_discharge - 2)
	assert(not enemy.has_status(&"electrified"))
	assert(enemy.has_status(&"wet"))


func _test_damage_and_status_spells() -> void:
	_reset_combatants()
	await _resolve_spell([&"air", &"air", &"air"])
	assert(enemy.health == 18)
	assert(enemy.get_status_stacks(&"bleed") == 4)

	_reset_combatants()
	await _resolve_spell([&"air", &"air", &"water"])
	assert(enemy.health == 14)
	assert(enemy.has_status(&"wet"))
	assert(player.has_status(&"wet"))

	_reset_combatants()
	await _resolve_spell([&"water", &"water"])
	assert(enemy.health == 15)
	assert(enemy.has_status(&"wet"))

	_reset_combatants()
	await _resolve_spell([&"lightning", &"lightning"])
	assert(enemy.health == 16)
	assert(enemy.get_status_stacks(&"electrified") == 2)
	assert(not enemy.has_status(&"dazed"))

	var health_before_wet := enemy.health
	enemy.add_status(&"wet", 1, 2)
	assert(enemy.health == health_before_wet - 2)
	assert(not enemy.has_status(&"electrified"))

	var health_before_reapplication := enemy.health
	enemy.add_status(&"electrified", 1)
	assert(enemy.health == health_before_reapplication - 1)
	assert(not enemy.has_status(&"electrified"))

	_reset_combatants()
	enemy.add_status(&"wet", 1, 2)
	await _resolve_spell([&"lightning", &"lightning"])
	assert(enemy.health == 14)
	assert(not enemy.has_status(&"electrified"))

	_reset_combatants()
	await _resolve_spell([&"air", &"air"])
	assert(enemy.health == 17)
	assert(enemy.get_status_stacks(&"bleed") == 2)


func _test_cold_frozen_and_shatter() -> void:
	_reset_combatants()
	await _resolve_spell([&"water", &"air"])
	assert(enemy.health == 17)
	assert(enemy.get_status_stacks(&"cold") == 1)

	enemy.add_status(&"wet", 1, 3)
	enemy.add_status(&"cold", 1)
	assert(enemy.get_status_stacks(&"cold") == 3)

	enemy.add_status(&"cold", 1)
	assert(enemy.has_status(&"frozen"))
	assert(enemy.get_status_stacks(&"frozen") == 2)
	assert(not enemy.has_status(&"cold"))

	var frozen_move_index: int = enemy.current_move_index
	var frozen_result: Dictionary = await enemy.perform_turn(
		player,
		resolver
	)
	assert(bool(frozen_result.get("action_skipped", false)))
	assert(enemy.current_move_index == frozen_move_index)
	assert(enemy.get_status_stacks(&"frozen") == 1)

	var shatter_result: Dictionary = await _resolve_spell(
		[&"water", &"water", &"air"]
	)
	assert(enemy.health == 8)
	assert(int(shatter_result.get("total_health_damage", 0)) == 9)
	assert(not enemy.has_status(&"frozen"))
	assert(enemy.get_status_stacks(&"bleed") == 2)
	assert(enemy.get_status_stacks(&"cold") == 2)

	_reset_combatants()
	enemy.add_status(&"cold", 3)
	assert(enemy.add_status(&"burn", 1))
	assert(not enemy.has_status(&"cold"))
	assert(enemy.has_status(&"burn"))

	_reset_combatants()
	enemy.add_status(&"wet", 1, 3)
	enemy.add_status(&"cold", 1)
	assert(enemy.get_status_stacks(&"cold") == 2)
	assert(not enemy.add_status(&"burn", 1))
	assert(enemy.get_status_stacks(&"cold") == 2)

func _test_electric() -> void:
	_reset_combatants()
	var lightning_bolt: SpellData = spell_library.find_spell(
		&"lightning",
		&"lightning",
		&"lightning"
	)
	assert(lightning_bolt.properties.has(&"electric"))

	await _resolve_spell(
		[&"lightning", &"lightning", &"lightning"]
	)
	assert(enemy.health == 13)

	_reset_combatants()
	enemy.add_status(&"wet", 1, 3)
	var electric_result: Dictionary = await _resolve_spell(
		[&"lightning", &"lightning", &"lightning"]
	)
	assert(enemy.health == 9)
	assert(int(electric_result.get("total_health_damage", 0)) == 11)


func _test_enemy_electric() -> void:
	_reset_combatants()
	enemy.current_move_index = 3

	var electric_move: EnemyMoveData = enemy.get_current_move()
	assert(electric_move.properties.has(&"electric"))
	assert("Electric" in enemy.get_intent_text())

	var dry_health: int = player.health
	await enemy.perform_turn(player, resolver)
	assert(player.health == dry_health - 8)

	_reset_combatants()
	player.add_status(&"wet", 1, 3)
	enemy.current_move_index = 3

	var wet_health: int = player.health
	var electric_result: Dictionary = await enemy.perform_turn(
		player,
		resolver
	)
	assert(player.health == wet_health - 12)
	assert(
		int(electric_result.get("total_health_damage", 0))
		== 12
	)


func _test_stormcloud() -> void:
	_reset_combatants()
	await _resolve_spell([&"air", &"lightning"])
	assert(enemy.has_status(&"stormcloud"))

	enemy.process_statuses_at_turn_end()
	assert(enemy.health == 18)

	enemy.add_status(&"wet", 1, 3)
	enemy.process_statuses_at_turn_end()
	assert(enemy.health == 15)

	enemy.process_statuses_at_turn_end()
	assert(enemy.health == 12)
	assert(not enemy.has_status(&"stormcloud"))


func _resolve_spell(elements: Array) -> Dictionary:
	var spell: SpellData

	if elements.size() == 2:
		spell = spell_library.find_spell(
			elements[0],
			elements[1]
		)
	else:
		spell = spell_library.find_spell(
			elements[0],
			elements[1],
			elements[2]
		)

	assert(spell != null)

	var action := spell.create_action(player, enemy)
	var context := CombatContext.create(
		player,
		[enemy],
		enemy,
		resolver.combat_deck,
		resolver.battle_modifiers
	)
	var result := await resolver.resolve_action(action, context)
	return result.to_dictionary()


func _reset_combatants() -> void:
	enemy.setup(enemy.enemy_data)

	var player_status_controller: StatusController = player.get_node(
		"StatusController"
	) as StatusController
	player_status_controller.clear_statuses()
	player.health = player.maximum_health
	player.energy = player.maximum_energy
	RunState.set_current_health(player.health)
	player.update_health_text()
	player.update_energy_text()
