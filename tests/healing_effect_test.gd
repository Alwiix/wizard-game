extends Node


func _ready() -> void:
	RunState.start_new_run()
	RunState.set_current_health(20)

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle: Node2D = battle_scene.instantiate() as Node2D
	add_child(battle)

	var heal_effect := CombatEffectData.new()
	heal_effect.effect_type = CombatEffectData.EffectType.HEAL
	heal_effect.target = CombatEffectData.TargetType.PLAYER
	heal_effect.amount = 4

	var player: BattlePlayer = battle.get_node("Player") as BattlePlayer
	var enemy: BattleEnemy = battle.get_node("Enemy") as BattleEnemy
	var resolver: CombatEffectResolver = battle.get_node(
		"CombatEffectResolver"
	) as CombatEffectResolver

	var result: Dictionary = await (
		resolver.resolve_effects(
			[heal_effect],
			player,
			enemy
		)
	)

	assert(player.health == 24)
	assert(RunState.current_health == 24)
	assert(int(result.get("total_health_healed", 0)) == 4)

	var capped_healing: int = player.heal(100)
	assert(capped_healing == 6)
	assert(player.health == player.maximum_health)
	assert(RunState.current_health == RunState.maximum_health)

	print("Healing effect test passed.")
	get_tree().quit()
