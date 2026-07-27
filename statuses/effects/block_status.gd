class_name BlockStatus
extends StatusEffect


func _init() -> void:
	status_id = &"block"
	display_name = "Block"
	show_stacks = true
	show_duration = false
	incoming_damage_priority = 100


func on_turn_started(_combatant: Node) -> void:
	# Block protects the owner until the beginning of their next turn.
	stacks = 0


func modify_incoming_damage(
	_combatant: Node,
	amount: int,
	context: Dictionary
) -> int:
	if bool(context.get("bypass_block", false)):
		return amount

	var absorbed_damage: int = min(stacks, max(amount, 0))
	stacks -= absorbed_damage

	return max(amount - absorbed_damage, 0)
