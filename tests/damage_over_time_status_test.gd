extends Node


func _ready() -> void:
	RunState.start_new_run()

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle: Node2D = battle_scene.instantiate() as Node2D
	add_child(battle)

	var player: BattlePlayer = battle.get_node("Player") as BattlePlayer
	var enemy: BattleEnemy = battle.get_node("Enemy") as BattleEnemy

	_test_bleed(player, enemy)
	_test_burn(player)
	_test_burn_and_wet(player)

	print("Damage-over-time status test passed.")
	get_tree().quit()


func _test_bleed(
	player: BattlePlayer,
	enemy: BattleEnemy
) -> void:
	player.add_status(&"bleed", 4)
	player.process_statuses_at_turn_end()

	assert(player.health == 26)
	assert(player.get_status_stacks(&"bleed") == 3)

	var restored_health: int = player.heal(2)

	assert(restored_health == 2)
	assert(player.health == 28)
	assert(not player.has_status(&"bleed"))

	# Healing removes Bleed even when some or all healing is capped.
	player.add_status(&"bleed", 2)
	player.heal(100)

	assert(player.health == player.maximum_health)
	assert(not player.has_status(&"bleed"))

	enemy.add_status(&"bleed", 3)
	enemy.heal(1)
	assert(not enemy.has_status(&"bleed"))


func _test_burn(player: BattlePlayer) -> void:
	player.add_status(&"burn", 3)

	player.process_statuses_at_turn_end()
	assert(player.health == 28)
	assert(player.get_status_stacks(&"burn") == 2)

	player.process_statuses_at_turn_end()
	assert(player.health == 26)
	assert(player.get_status_stacks(&"burn") == 1)

	player.process_statuses_at_turn_end()
	assert(player.health == 24)
	assert(not player.has_status(&"burn"))


func _test_burn_and_wet(player: BattlePlayer) -> void:
	player.add_status(&"wet", 1, 3)
	assert(not player.add_status(&"burn", 4))
	assert(player.has_status(&"wet"))
	assert(not player.has_status(&"burn"))

	var health_before_blocked_burn: int = player.health
	player.process_statuses_at_turn_end()
	assert(player.health == health_before_blocked_burn)

	player.remove_status(&"wet")
	assert(player.add_status(&"burn", 4))
	assert(player.has_status(&"burn"))

	assert(player.add_status(&"wet", 1, 3))
	assert(player.has_status(&"wet"))
	assert(not player.has_status(&"burn"))
