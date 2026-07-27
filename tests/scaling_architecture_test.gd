extends Node


func _ready() -> void:
	RunState.start_new_run()

	var encounter := EncounterData.new()
	encounter.encounter_id = &"multi_enemy_test"
	encounter.display_name = "Multi Enemy Test"
	encounter.enemies = [
		ContentCatalog.SKELETON_DATA,
		ContentCatalog.ZOMBIE_DATA
	]

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle := battle_scene.instantiate() as Node2D
	battle.encounter_data = encounter
	add_child(battle)

	var controller := battle.get_node(
		"BattleController"
	) as BattleController
	var resolver := battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver
	var player := battle.get_node("Player") as BattlePlayer
	var enemies := controller.get_enemies()

	assert(player is BattleCombatant)
	assert(enemies.size() == 2)
	assert(enemies[0] is BattleCombatant)
	assert(enemies[1] is BattleCombatant)
	assert(enemies[0].name == "Enemy")
	assert(enemies[1].name == "Enemy2")
	assert(enemies[0].position.x < enemies[1].position.x)
	assert(controller.selected_enemy == enemies[0])

	_test_spell_costs(battle)
	await _test_typed_electric_action(
		resolver,
		player,
		enemies,
		battle
	)
	await _test_all_enemy_targeting(
		resolver,
		player,
		enemies,
		battle
	)
	_test_target_failover(controller, enemies)

	print("Scaling architecture test passed.")
	get_tree().quit()


func _test_spell_costs(battle: Node2D) -> void:
	var deck := battle.get_node("CombatDeck") as CombatDeck
	assert(deck.hand_cards.size() == 3)

	var three_element_spell := (
		ContentCatalog.SPELL_LIBRARY.find_spell(
			&"water",
			&"water",
			&"lightning"
		)
	)
	battle.current_spell = three_element_spell.to_result_dictionary()
	battle.selected_cards = deck.hand_cards.duplicate()
	assert(battle.get_selected_energy_cost() == 2)

	var upgraded_card = deck.hand_cards[0].card_instance
	assert(upgraded_card.apply_upgrade(CardInstance.WHITE_GEM))
	assert(battle.get_selected_energy_cost() == 1)

	var two_element_spell := (
		ContentCatalog.SPELL_LIBRARY.find_spell(
			&"water",
			&"lightning"
		)
	)
	battle.current_spell = two_element_spell.to_result_dictionary()
	battle.selected_cards = [
		deck.hand_cards[0],
		deck.hand_cards[1]
	]
	assert(battle.get_selected_energy_cost() == 0)

	battle.selected_cards = [
		deck.hand_cards[1],
		deck.hand_cards[0]
	]
	assert(battle.get_selected_energy_cost() == 1)


func _test_typed_electric_action(
	resolver: CombatEffectResolver,
	player: BattlePlayer,
	enemies: Array[BattleEnemy],
	battle: Node2D
) -> void:
	var target := enemies[0]
	target.add_status(&"wet", 1, 2)
	var starting_health := target.health
	var lightning_bolt := (
		ContentCatalog.SPELL_LIBRARY.find_spell(
			&"lightning",
			&"lightning",
			&"lightning"
		)
	)
	var action := lightning_bolt.create_action(player, target)
	var context := CombatContext.create(
		player,
		enemies,
		target,
		battle.get_node("CombatDeck") as CombatDeck,
		battle.get_node(
			"BattleModifierController"
		) as BattleModifierController
	)
	var result := await resolver.resolve_action(action, context)

	assert(result.total_health_damage == 11)
	assert(target.health == starting_health - 11)


func _test_all_enemy_targeting(
	resolver: CombatEffectResolver,
	player: BattlePlayer,
	enemies: Array[BattleEnemy],
	battle: Node2D
) -> void:
	var effect := CombatEffectData.new()
	effect.effect_type = CombatEffectData.EffectType.DAMAGE
	effect.target = CombatEffectData.TargetType.ALL_ENEMIES
	effect.amount = 2

	var action := CombatAction.new()
	action.action_id = &"all_enemy_test"
	action.caster = player
	action.primary_target = enemies[0]
	action.effects = [effect]

	var first_health := enemies[0].health
	var second_health := enemies[1].health
	var context := CombatContext.create(
		player,
		enemies,
		enemies[0],
		battle.get_node("CombatDeck") as CombatDeck,
		battle.get_node(
			"BattleModifierController"
		) as BattleModifierController
	)
	var result := await resolver.resolve_action(action, context)

	assert(result.total_health_damage == 4)
	assert(enemies[0].health == first_health - 2)
	assert(enemies[1].health == second_health - 2)


func _test_target_failover(
	controller: BattleController,
	enemies: Array[BattleEnemy]
) -> void:
	enemies[0].defeat_immediately({"source": "test"})
	controller.refresh_selected_target()

	assert(controller.selected_enemy == enemies[1])
	assert(enemies[1].get_node("TargetButton").text == "SELECTED")
