class_name ColdStatus
extends StatusEffect


const FREEZE_THRESHOLD: int = 5


func _init() -> void:
	status_id = &"cold"
	display_name = "Cold"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func on_applied(combatant: Node) -> void:
	if stacks < FREEZE_THRESHOLD:
		return

	combatant.remove_status(&"cold")
	combatant.add_status(&"frozen", 2)
