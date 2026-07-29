class_name StatusEffect
extends RefCounted


var status_id: StringName = &"status"
var display_name: String = "Status"
var stacks: int = 0

# -1 means the status does not expire from duration.
var remaining_turns: int = -1

var show_stacks: bool = true
var show_duration: bool = false

# Lower values modify damage first.
var incoming_damage_priority: int = 50
var action_resolution_priority: int = 100
var removed_by_healing: bool = false


func initialize(amount: int, duration: int = -1) -> void:
	stacks = max(amount, 0)

	if duration >= 0:
		remaining_turns = duration


func add_application(amount: int, duration: int = -1) -> void:
	stacks = max(stacks + amount, 0)

	if duration >= 0:
		if remaining_turns < 0:
			remaining_turns = duration
		else:
			remaining_turns = max(remaining_turns, duration)

func on_applied(_combatant: Node) -> void:
	pass


func on_turn_started(_combatant: Node) -> void:
	pass


func on_turn_ended(_combatant: Node) -> void:
	pass


func modify_incoming_damage(
	_combatant: Node,
	amount: int,
	_context: Dictionary
) -> int:
	return amount


func modify_outgoing_damage(
	_combatant: Node,
	amount: int
) -> int:
	return amount


func modify_outgoing_status_amount(
	_combatant: Node,
	_status_id: StringName,
	amount: int
) -> int:
	return amount


func resolve_action_attempt(
	_combatant: Node,
	_can_miss: bool,
	_rng: RandomNumberGenerator
) -> StringName:
	return &"continue"


func modify_spell_energy_cost(
	_combatant: Node,
	cost: int
) -> int:
	return cost


func on_spell_cast(_combatant: Node) -> void:
	pass


func consume_next_turn_draw_bonus(
	_combatant: Node
) -> int:
	return 0


func consume_next_turn_energy_bonus(
	_combatant: Node
) -> int:
	return 0


func consume_dodge(_combatant: Node) -> bool:
	return false


func on_attacked(
	_combatant: Node,
	_attacker: Node,
	_context: Dictionary
) -> void:
	pass


func tick_duration_after_turn() -> void:
	if remaining_turns > 0:
		remaining_turns -= 1


func is_expired() -> bool:
	return stacks <= 0 or remaining_turns == 0


func get_display_text() -> String:
	var result: String = display_name

	if show_stacks:
		result += ": " + str(stacks)

	if show_duration and remaining_turns >= 0:
		result += " (" + str(remaining_turns) + " turns)"

	return result
