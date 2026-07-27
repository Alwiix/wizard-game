class_name DazedStatus
extends StatusEffect


func _init() -> void:
	status_id = &"dazed"
	display_name = "Dazed"
	stacks = 1
	remaining_turns = -1
	show_stacks = true
	show_duration = false
	action_resolution_priority = 10


func initialize(amount: int, _duration: int = -1) -> void:
	stacks = max(amount, 1)


func add_application(amount: int, _duration: int = -1) -> void:
	stacks += max(amount, 1)


func resolve_action_attempt(
	_combatant: Node,
	can_miss: bool,
	rng: RandomNumberGenerator
) -> StringName:
	if not can_miss:
		return &"continue"

	stacks = max(stacks - 1, 0)

	if rng.randf() < 0.5:
		return &"missed"

	return &"continue"
