class_name WetStatus
extends StatusEffect


func _init() -> void:
	status_id = &"wet"
	display_name = "Wet"
	stacks = 1
	remaining_turns = 2
	show_stacks = false
	show_duration = true
	incoming_damage_priority = 10


func initialize(_amount: int, duration: int = -1) -> void:
	stacks = 1

	if duration >= 0:
		remaining_turns = duration
	else:
		remaining_turns = 2


func add_application(_amount: int, duration: int = -1) -> void:
	stacks = 1

	var refreshed_duration: int = 2

	if duration >= 0:
		refreshed_duration = duration

	remaining_turns = max(remaining_turns, refreshed_duration)


func modify_incoming_damage(
	_combatant: Node,
	amount: int,
	_context: Dictionary
) -> int:
	return amount
