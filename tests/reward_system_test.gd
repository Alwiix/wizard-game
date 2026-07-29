extends Node


func _ready() -> void:
	await _test_upgrade_mechanics()
	await _test_reward_screen()
	await _test_skipping_rewards()

	print("Reward system test passed.")
	get_tree().quit()


func _test_upgrade_mechanics() -> void:
	RunState.start_new_run()

	var upgrade_library: CardUpgradeLibraryData = load(
		"res://Data/CardUpgrades/card_upgrade_library.tres"
	) as CardUpgradeLibraryData
	assert(upgrade_library != null)
	assert(upgrade_library.upgrades.size() == 3)

	var heavy_rock_data: CardUpgradeData = (
		upgrade_library.find_upgrade(CardInstance.HEAVY_ROCK)
	)
	var white_gem_data: CardUpgradeData = (
		upgrade_library.find_upgrade(CardInstance.WHITE_GEM)
	)
	var blue_gem_data: CardUpgradeData = (
		upgrade_library.find_upgrade(CardInstance.BLUE_GEM)
	)

	assert(heavy_rock_data.display_name == "Heavy Rock")
	assert(heavy_rock_data.has_property(&"retain"))
	assert(heavy_rock_data.reward_weight == 1.0)
	assert(white_gem_data.energy_cost_modifier == -1)
	assert(white_gem_data.active_cast_slots == [0])
	assert(white_gem_data.reward_weight == 1.0)
	assert(blue_gem_data.on_use_effects.size() == 1)
	assert(blue_gem_data.active_cast_slots == [0])
	assert(blue_gem_data.reward_weight == 1.0)

	var white_gem_card: CardInstance = RunState.deck[0]
	var original_cost: int = white_gem_card.get_energy_cost()

	assert(white_gem_card.apply_upgrade(CardInstance.WHITE_GEM))
	assert(white_gem_card.get_energy_cost() == maxi(original_cost - 1, 0))
	assert(white_gem_card.get_spell_cost_modifier(0) == -1)
	assert(white_gem_card.get_spell_cost_modifier(1) == 0)
	assert(not white_gem_card.apply_upgrade(CardInstance.WHITE_GEM))

	var heavy_rock_card: CardInstance = RunState.deck[1]
	assert(heavy_rock_card.apply_upgrade(CardInstance.HEAVY_ROCK))
	assert(heavy_rock_card.should_retain_at_turn_end())

	var blue_gem_card: CardInstance = RunState.deck[2]
	assert(blue_gem_card.apply_upgrade(CardInstance.BLUE_GEM))
	assert(blue_gem_card.get_on_use_effects(0).size() == 1)
	assert(blue_gem_card.get_on_use_effects(1).is_empty())

	# Keep every upgraded card in the opening hand so the Retain check
	# does not depend on the shuffled order of a nine-card deck.
	RunState.deck = [
		white_gem_card,
		heavy_rock_card,
		blue_gem_card
	]

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle: Node2D = battle_scene.instantiate() as Node2D
	add_child(battle)
	await get_tree().process_frame

	var player: BattlePlayer = battle.get_node("Player") as BattlePlayer
	var enemy: BattleEnemy = battle.get_node("Enemy") as BattleEnemy
	var resolver: CombatEffectResolver = battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver

	await resolver.resolve_effects(
		blue_gem_card.get_on_use_effects(0),
		player,
		enemy
	)
	assert(enemy.has_status(&"wet"))

	enemy.remove_status(&"wet")
	await resolver.resolve_effects(
		blue_gem_card.get_on_use_effects(1),
		player,
		enemy
	)
	assert(not enemy.has_status(&"wet"))

	var combat_deck: CombatDeck = battle.get_node(
		"CombatDeck"
	) as CombatDeck
	combat_deck.draw_cards(99)
	combat_deck.discard_hand()

	var retained_heavy_rock: bool = false

	for card_control in combat_deck.hand_cards:
		if card_control.card_instance == heavy_rock_card:
			retained_heavy_rock = true
			break

	assert(retained_heavy_rock)
	battle.queue_free()
	await get_tree().process_frame


func _test_reward_screen() -> void:
	RunState.start_new_run()

	var reward_scene: PackedScene = load(
		"res://scenes/rewards/reward_screen.tscn"
	)
	var reward_screen: RewardScreen = (
		reward_scene.instantiate() as RewardScreen
	)
	add_child(reward_screen)
	reward_screen.begin_rewards()

	assert(reward_screen.element_choices.size() == 3)
	reward_screen.rng.seed = 123456

	var upgrade_roll_counts: Dictionary = {}

	for _roll in range(300):
		var rolled_upgrade: StringName = (
			reward_screen._generate_upgrade_id()
		)
		upgrade_roll_counts[rolled_upgrade] = int(
			upgrade_roll_counts.get(rolled_upgrade, 0)
		) + 1

	assert(upgrade_roll_counts.has(CardInstance.HEAVY_ROCK))
	assert(upgrade_roll_counts.has(CardInstance.WHITE_GEM))
	assert(upgrade_roll_counts.has(CardInstance.BLUE_GEM))

	var unique_elements: Dictionary = {}

	for card_data in reward_screen.element_choices:
		unique_elements[card_data.element_name] = true

	assert(unique_elements.size() == 3)
	assert(unique_elements.has("Water"))
	assert(unique_elements.has("Air"))
	assert(unique_elements.has("Lightning"))

	var starting_deck_size: int = RunState.deck.size()
	assert(
		reward_screen.choose_element_card(
			reward_screen.element_choices[0]
		)
	)
	assert(RunState.deck.size() == starting_deck_size + 1)

	var upgrade_target: CardInstance

	for card in RunState.deck:
		if not card.has_upgrade(reward_screen.pending_upgrade_id):
			upgrade_target = card
			break

	assert(upgrade_target != null)
	assert(reward_screen.select_upgrade_card(upgrade_target))
	assert(reward_screen.confirm_upgrade())
	assert(upgrade_target.has_upgrade(reward_screen.pending_upgrade_id))

	reward_screen.queue_free()
	await get_tree().process_frame


func _test_skipping_rewards() -> void:
	RunState.start_new_run()

	var reward_scene: PackedScene = load(
		"res://scenes/rewards/reward_screen.tscn"
	)
	var reward_screen: RewardScreen = (
		reward_scene.instantiate() as RewardScreen
	)
	add_child(reward_screen)
	reward_screen.begin_rewards()

	var starting_deck_size: int = RunState.deck.size()

	assert(reward_screen.skip_reward_button.text == "Skip Card")
	assert(reward_screen.skip_element_reward())
	assert(RunState.deck.size() == starting_deck_size)
	assert(not reward_screen.element_choice_container.visible)
	assert(reward_screen.deck_scroll.visible)
	assert(reward_screen.skip_reward_button.text == "Skip Upgrade")

	await get_tree().process_frame
	assert(reward_screen.deck_grid.columns == 5)
	assert(reward_screen.deck_scroll.size.x <= 624.0)
	assert(reward_screen.deck_scroll.size.y > 100.0)

	assert(reward_screen.skip_upgrade_reward())

	for card in RunState.deck:
		assert(card.upgrades.is_empty())

	reward_screen.queue_free()
	await get_tree().process_frame
