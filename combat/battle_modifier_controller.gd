class_name BattleModifierController
extends Node


signal modifiers_changed


const LAVA_FLOOR_ID: StringName = &"lava_floor"


var combat_events: CombatEvents
var player: Node
var enemies: Array[Node] = []
var active_modifiers: Dictionary = {}
var lava_triggered_for_current_action: bool = false


static func is_supported_modifier(
	modifier_id: StringName
) -> bool:
	return modifier_id == LAVA_FLOOR_ID


func setup(
	events: CombatEvents,
	player_combatant: Node,
	enemy_combatants: Variant
) -> void:
	combat_events = events
	player = player_combatant
	enemies.clear()

	if enemy_combatants is Array:
		for enemy_value in enemy_combatants:
			var battle_enemy := enemy_value as Node

			if battle_enemy != null:
				enemies.append(battle_enemy)
	else:
		var battle_enemy := enemy_combatants as Node

		if battle_enemy != null:
			enemies.append(battle_enemy)

	if not combat_events.attack_completed.is_connected(
		_on_attack_completed
	):
		combat_events.attack_completed.connect(
			_on_attack_completed
		)

func apply_modifier(
	modifier_id: StringName,
	source: Node,
	amount: int = 1,
	duration: int = 1
) -> bool:
	match modifier_id:
		LAVA_FLOOR_ID:
			active_modifiers[modifier_id] = {
				"burn_amount": max(amount, 1),
				"ticks_after_side": (
					&"enemy" if source == player else &"player"
				),
				"remaining_turns": max(duration, 1)
			}
			modifiers_changed.emit()
			return true

		_:
			push_warning(
				"Unknown battle modifier: " + String(modifier_id)
			)
			return false


func has_modifier(modifier_id: StringName) -> bool:
	return active_modifiers.has(modifier_id)


func get_display_text() -> String:
	if active_modifiers.is_empty():
		return "Arena: None"

	var lines: Array[String] = ["Arena:"]

	if active_modifiers.has(LAVA_FLOOR_ID):
		var lava_floor: Dictionary = active_modifiers[
			LAVA_FLOOR_ID
		]
		lines.append(
			"Lava Floor — attackers gain "
			+ str(lava_floor.get("burn_amount", 2))
			+ " Burn"
		)

	return "\n".join(lines)


func _on_attack_completed(
	attacker: Node,
	target: Node,
	source: Variant,
	hit: bool,
	damage_dealt: int
) -> void:
	if target != null and target.has_method(
		"process_attack_completed"
	):
		target.process_attack_completed(
			attacker,
			{
				"source": source,
				"hit": hit,
				"damage_dealt": damage_dealt
			}
		)

	if not active_modifiers.has(LAVA_FLOOR_ID):
		return

	if lava_triggered_for_current_action:
		return

	if attacker == null or not attacker.has_method("add_status"):
		return

	lava_triggered_for_current_action = true
	call_deferred("_reset_lava_action_guard")

	var lava_floor: Dictionary = active_modifiers[LAVA_FLOOR_ID]
	attacker.add_status(
		&"burn",
		int(lava_floor.get("burn_amount", 2))
	)


func _reset_lava_action_guard() -> void:
	lava_triggered_for_current_action = false


func process_side_turn_end(side: StringName) -> void:
	var modifier_ids: Array = active_modifiers.keys().duplicate()
	var modifiers_changed_value: bool = false

	for modifier_id in modifier_ids:
		var modifier: Dictionary = active_modifiers[modifier_id]

		if modifier.get("ticks_after_side") != side:
			continue

		modifier["remaining_turns"] = (
			int(modifier.get("remaining_turns", 1)) - 1
		)

		if int(modifier["remaining_turns"]) <= 0:
			active_modifiers.erase(modifier_id)
		else:
			active_modifiers[modifier_id] = modifier

		modifiers_changed_value = true

	if modifiers_changed_value:
		modifiers_changed.emit()
