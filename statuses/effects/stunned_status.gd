class_name StunnedStatus
extends StatusEffect


func _init() -> void:
	status_id = &"stunned"
	display_name = "Stunned"
	stacks = 1
	remaining_turns = -1
	show_stacks = false
	show_duration = false
	action_resolution_priority = 0


func initialize(_amount: int, _duration: int = -1) -> void:
	stacks = 1


func add_application(_amount: int, _duration: int = -1) -> void:
	stacks = 1


func resolve_action_attempt(
	_combatant: Node,
	_can_miss: bool,
	_rng: RandomNumberGenerator
) -> StringName:
	stacks = 0
	return &"stunned"
