class_name FirebreathingStatus
extends StatusEffect


const DEFAULT_DURATION: int = 3


func _init() -> void:
	status_id = &"firebreathing"
	display_name = "Firebreathing"
	stacks = 1
	remaining_turns = DEFAULT_DURATION
	show_stacks = false
	show_duration = true


func initialize(_amount: int, duration: int = -1) -> void:
	stacks = 1
	remaining_turns = (
		duration if duration >= 0 else DEFAULT_DURATION
	)


func add_application(_amount: int, duration: int = -1) -> void:
	stacks = 1
	var refreshed_duration := (
		duration if duration >= 0 else DEFAULT_DURATION
	)
	remaining_turns = max(remaining_turns, refreshed_duration)


func modify_outgoing_status_amount(
	_combatant: Node,
	applied_status_id: StringName,
	amount: int
) -> int:
	if applied_status_id == &"burn":
		return amount + 1

	return amount
