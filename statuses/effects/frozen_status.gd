class_name FrozenStatus
extends StatusEffect


func _init() -> void:
	status_id = &"frozen"
	display_name = "Frozen"
	stacks = 2
	remaining_turns = -1
	show_stacks = true
	show_duration = false
	action_resolution_priority = 0


func initialize(amount: int, _duration: int = -1) -> void:
	stacks = max(amount, 1)


func add_application(amount: int, _duration: int = -1) -> void:
	stacks += max(amount, 1)


func resolve_action_attempt(
	_combatant: Node,
	_can_miss: bool,
	_rng: RandomNumberGenerator
) -> StringName:
	stacks = max(stacks - 1, 0)
	return &"frozen"
