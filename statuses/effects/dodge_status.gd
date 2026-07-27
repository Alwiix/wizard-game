class_name DodgeStatus
extends StatusEffect


func _init() -> void:
	status_id = &"dodge"
	display_name = "Dodge"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func consume_dodge(_combatant: Node) -> bool:
	if stacks <= 0:
		return false

	stacks -= 1
	return true
