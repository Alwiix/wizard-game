extends Node


func _ready() -> void:
	RunState.start_new_run()
	_test_new_elements()
	_expand_deck_for_draw_tests()

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle: Node2D = battle_scene.instantiate() as Node2D
	add_child(battle)
	await get_tree().process_frame

	var player: BattlePlayer = battle.get_node("Player") as BattlePlayer
	var enemy: BattleEnemy = battle.get_node("Enemy") as BattleEnemy
	var deck: Node = battle.get_node("CombatDeck")
	var resolver: CombatEffectResolver = battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver

	await _test_draw_and_retain(deck, resolver, player, enemy)
	await _test_stun_and_daze(enemy, player, resolver)

	print("Card and control mechanics test passed.")
	get_tree().quit()


func _test_new_elements() -> void:
	var air_cards: int = 0
	var lightning_cards: int = 0
	var water_cards: int = 0

	for card in RunState.deck:
		match card.get_element_name().to_lower():
			"air":
				air_cards += 1
			"lightning":
				lightning_cards += 1
			"water":
				water_cards += 1

	assert(RunState.deck.size() == 3)
	assert(air_cards == 1)
	assert(lightning_cards == 1)
	assert(water_cards == 1)


func _expand_deck_for_draw_tests() -> void:
	var starting_elements: Array[ElementCardData] = (
		RunState.get_wizard_elements(1)
	)

	for _extra_copy in range(2):
		for element_data in starting_elements:
			RunState.add_card_to_deck(element_data)

	assert(RunState.deck.size() == 9)


func _test_draw_and_retain(
	deck: CombatDeck,
	resolver: CombatEffectResolver,
	player: BattlePlayer,
	enemy: BattleEnemy
) -> void:
	var hand: HBoxContainer = deck.get_node("Hand") as HBoxContainer

	assert(deck.size.x >= 1000.0)
	assert(hand.size.x >= 900.0)
	assert(deck.hand_cards[0].position.x > 200.0)

	var initial_hand_size: int = deck.hand_cards.size()

	var draw_effect := CombatEffectData.new()
	draw_effect.effect_type = (
		CombatEffectData.EffectType.DRAW_CARDS
	)
	draw_effect.target = CombatEffectData.TargetType.PLAYER
	draw_effect.amount = 2

	var draw_result: Dictionary = await (
		resolver.resolve_effects(
			[draw_effect],
			player,
			enemy
		)
	)

	assert(deck.hand_cards.size() == initial_hand_size + 2)
	assert("Drew 2 cards." in draw_result.get("messages", []))

	var retain_effect := CombatEffectData.new()
	retain_effect.effect_type = (
		CombatEffectData.EffectType.RETAIN_CARDS
	)
	retain_effect.target = CombatEffectData.TargetType.PLAYER
	retain_effect.amount = 1

	var selected_retain_card = deck.hand_cards[2]
	call_deferred(
		"_select_retain_target",
		deck,
		selected_retain_card
	)

	await resolver.resolve_effects(
		[retain_effect],
		player,
		enemy
	)

	var retained_card: CardInstance = (
		selected_retain_card.card_instance
	)
	assert(retained_card.is_retained_this_turn)
	assert(not deck.hand_cards[0].card_instance.is_retained_this_turn)

	deck.discard_hand()

	assert(deck.hand_cards.size() == 1)
	assert(deck.hand_cards[0].card_instance == retained_card)
	assert(not retained_card.is_retained_this_turn)

	deck.draw_turn_hand()
	assert(deck.hand_cards.size() == 4)

	var cards_drawn_before_cap: int = deck.draw_cards(99)
	assert(cards_drawn_before_cap == 4)
	assert(deck.hand_cards.size() == deck.maximum_hand_size)
	assert(deck.draw_cards(1) == 0)


func _test_stun_and_daze(
	enemy: BattleEnemy,
	player: BattlePlayer,
	resolver: CombatEffectResolver
) -> void:
	var initial_move_index: int = enemy.current_move_index
	var initial_player_health: int = player.health

	enemy.add_status(&"stunned", 1)
	var stunned_result: Dictionary = await (
		enemy.perform_turn(
			player,
			resolver
		)
	)

	assert(bool(stunned_result.get("action_skipped", false)))
	assert(enemy.current_move_index == initial_move_index)
	assert(player.health == initial_player_health)
	assert(not enemy.has_status(&"stunned"))

	enemy.add_status(&"dazed", 1)
	assert(enemy.has_status(&"dazed"))

	enemy.add_status(&"dazed", 1)
	assert(not enemy.has_status(&"dazed"))
	assert(enemy.has_status(&"stunned"))

	await enemy.perform_turn(player, resolver)
	assert(enemy.current_move_index == initial_move_index)

	var status_controller: StatusController = enemy.get_node(
		"StatusController"
	) as StatusController
	var miss_seed: int = _find_miss_seed()
	status_controller.action_rng.seed = miss_seed

	enemy.add_status(&"dazed", 1)
	var dazed_result: Dictionary = await (
		enemy.perform_turn(
			player,
			resolver
		)
	)

	assert(bool(dazed_result.get("attack_missed", false)))
	assert(enemy.current_move_index == initial_move_index + 1)
	assert(player.health == initial_player_health)
	assert(not enemy.has_status(&"dazed"))


func _select_retain_target(
	deck: CombatDeck,
	card
) -> void:
	assert(deck.is_selecting_retain_targets)
	card.toggled.emit(true)


func _find_miss_seed() -> int:
	var test_rng := RandomNumberGenerator.new()

	for candidate_seed in range(1000):
		test_rng.seed = candidate_seed

		if test_rng.randf() < 0.5:
			return candidate_seed

	return 0
