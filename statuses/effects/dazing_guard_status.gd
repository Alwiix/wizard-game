class_name DazingGuardStatus
extends StatusEffect


func _init() -> void:
	status_id = &"dazing_guard"
	display_name = "Dazing Shield"
	stacks = 1
	remaining_turns = -1
	show_stacks = false
	show_duration = false


func initialize(amount: int, _duration: int = -1) -> void:
	stacks = max(amount, 1)


func add_application(amount: int, _duration: int = -1) -> void:
	stacks += max(amount, 1)


func on_attacked(
	_combatant: Node,
	attacker: Node,
	_context: Dictionary
) -> void:
	if stacks <= 0:
		return

	if not bool(_context.get("hit", true)):
		return

	if attacker != null and attacker.has_method("add_status"):
		attacker.add_status(&"dazed", stacks)

	stacks = 0
