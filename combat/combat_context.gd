class_name CombatContext
extends RefCounted


var player: Node
var enemies: Array[Node] = []
var primary_enemy: Node
var combat_deck: CombatDeck
var battle_modifiers: BattleModifierController


static func create(
	player_combatant: Node,
	enemy_combatants: Array,
	selected_enemy: Node = null,
	deck: CombatDeck = null,
	modifiers: BattleModifierController = null
) -> CombatContext:
	var context := CombatContext.new()
	context.player = player_combatant
	context.combat_deck = deck
	context.battle_modifiers = modifiers

	for enemy_value in enemy_combatants:
		var enemy := enemy_value as Node

		if enemy != null:
			context.enemies.append(enemy)

	context.primary_enemy = selected_enemy

	if context.primary_enemy == null:
		context.primary_enemy = context.get_first_living_enemy()

	return context


func get_living_enemies() -> Array[Node]:
	var result: Array[Node] = []

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		if "health" in enemy and int(enemy.health) <= 0:
			continue

		result.append(enemy)

	return result


func get_first_living_enemy() -> Node:
	var living_enemies := get_living_enemies()

	if living_enemies.is_empty():
		return null

	return living_enemies[0]


func resolve_targets(
	target_type: CombatEffectData.TargetType,
	action: CombatAction
) -> Array[Node]:
	match target_type:
		CombatEffectData.TargetType.PLAYER:
			return _single_target(player)

		CombatEffectData.TargetType.ENEMY:
			return _single_target(primary_enemy)

		CombatEffectData.TargetType.CASTER:
			return _single_target(action.caster)

		CombatEffectData.TargetType.PRIMARY_TARGET:
			return _single_target(action.primary_target)

		CombatEffectData.TargetType.ALL_ENEMIES:
			return get_living_enemies()

		CombatEffectData.TargetType.ALL_OPPONENTS:
			if action.caster == player:
				return get_living_enemies()

			return _single_target(player)

		CombatEffectData.TargetType.ALL_COMBATANTS:
			var result: Array[Node] = _single_target(player)
			result.append_array(get_living_enemies())
			return result

		_:
			return []


func get_target_display_name(target: Node) -> String:
	if target == player:
		return "you"

	if target != null and target.has_method("get_display_name"):
		return str(target.get_display_name())

	return "the target"


func _single_target(target: Node) -> Array[Node]:
	if target == null or not is_instance_valid(target):
		return []

	return [target]
