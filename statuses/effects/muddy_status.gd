class_name MuddyStatus
extends StatusEffect


const DAMAGE_MULTIPLIER: float = 0.75


func _init() -> void:
	status_id = &"muddy"
	display_name = "Muddy"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func on_turn_ended(_combatant: Node) -> void:
	stacks = max(stacks - 1, 0)


func modify_outgoing_damage(
	_combatant: Node,
	amount: int
) -> int:
	return roundi(float(amount) * DAMAGE_MULTIPLIER)
