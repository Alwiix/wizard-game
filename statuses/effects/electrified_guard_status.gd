class_name ElectrifiedGuardStatus
extends StatusEffect


func _init() -> void:
	status_id = &"electrified_guard"
	display_name = "Electrified Guard"
	stacks = 1
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func initialize(amount: int, _duration: int = -1) -> void:
	stacks = max(amount, 1)


func add_application(amount: int, _duration: int = -1) -> void:
	stacks += max(amount, 1)


func on_attacked(
	_combatant: Node,
	attacker: Node,
	context: Dictionary
) -> void:
	if stacks <= 0 or not bool(context.get("hit", true)):
		return

	if attacker != null and attacker.has_method("add_status"):
		attacker.add_status(&"electrified", stacks)

	stacks = 0
