extends Node


func _ready() -> void:
	_test_wizard_decks()
	_test_hand_size_milestone()
	_test_difficulty_multipliers()
	_test_enemy_health_scaling()
	_test_player_energy()

	print("Run configuration test passed.")
	get_tree().quit()


func _test_wizard_decks() -> void:
	RunState.start_new_run(
		RunState.Difficulty.MEDIUM,
		1
	)

	assert(RunState.deck.size() == 6)
	assert(RunState.selected_wizard == 1)

	var card_counts: Dictionary = {}

	for card in RunState.deck:
		var element_id: StringName = StringName(
			card.get_element_name().to_lower()
		)
		card_counts[element_id] = int(
			card_counts.get(element_id, 0)
		) + 1

	assert(card_counts.size() == 6)
	assert(int(card_counts.get(&"water", 0)) == 1)
	assert(int(card_counts.get(&"fire", 0)) == 1)
	assert(int(card_counts.get(&"earth", 0)) == 1)
	assert(int(card_counts.get(&"lightning", 0)) == 1)
	assert(int(card_counts.get(&"air", 0)) == 1)
	assert(int(card_counts.get(&"nature", 0)) == 1)

	# Any unavailable legacy wizard number falls back to the sole
	# currently available starting deck.
	RunState.start_new_run(
		RunState.Difficulty.MEDIUM,
		5
	)
	assert(RunState.selected_wizard == 1)
	assert(RunState.deck.size() == 6)


func _test_hand_size_milestone() -> void:
	RunState.start_new_run()
	assert(RunState.get_turn_hand_size() == 3)
	assert(not RunState.expanded_hand_unlocked)

	for element_data in RunState.get_all_element_card_data():
		RunState.add_card_to_deck(element_data)

	assert(RunState.deck.size() == 12)
	assert(RunState.expanded_hand_unlocked)
	assert(RunState.get_turn_hand_size() == 4)

	# The larger hand remains unlocked after later deck thinning.
	RunState.deck.resize(11)
	assert(RunState.get_turn_hand_size() == 4)

	RunState.start_new_run()
	assert(RunState.deck.size() == 6)
	assert(RunState.get_turn_hand_size() == 3)
	assert(not RunState.expanded_hand_unlocked)


func _test_difficulty_multipliers() -> void:
	RunState.start_new_run(RunState.Difficulty.EASY, 1)
	assert(RunState.get_enemy_health_multiplier() == 0.75)

	RunState.start_new_run(RunState.Difficulty.MEDIUM, 1)
	assert(RunState.get_enemy_health_multiplier() == 1.0)

	RunState.start_new_run(RunState.Difficulty.HARD, 1)
	assert(RunState.get_enemy_health_multiplier() == 1.25)


func _test_enemy_health_scaling() -> void:
	var enemy_scene: PackedScene = load(
		"res://scenes/enemies/enemy.tscn"
	)
	var skeleton_data: EnemyData = load(
		"res://Data/enemy_types/skeleton.tres"
	) as EnemyData
	var enemy: BattleEnemy = enemy_scene.instantiate() as BattleEnemy
	add_child(enemy)

	RunState.start_new_run(RunState.Difficulty.EASY, 1)
	enemy.setup(skeleton_data)
	assert(enemy.get_maximum_health() == 15)

	RunState.start_new_run(RunState.Difficulty.MEDIUM, 1)
	enemy.setup(skeleton_data)
	assert(enemy.get_maximum_health() == 20)

	RunState.start_new_run(RunState.Difficulty.HARD, 1)
	enemy.setup(skeleton_data)
	assert(enemy.get_maximum_health() == 25)


func _test_player_energy() -> void:
	RunState.start_new_run()

	var player_scene: PackedScene = load(
		"res://scenes/player/player.tscn"
	)
	var player: BattlePlayer = (
		player_scene.instantiate() as BattlePlayer
	)
	add_child(player)

	assert(player.maximum_energy == 2)
	assert(player.energy == 2)

	player.energy = 0
	player.start_turn()
	assert(player.energy == 2)
