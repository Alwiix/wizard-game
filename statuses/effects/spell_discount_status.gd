class_name SpellDiscountStatus
extends StatusEffect


func _init() -> void:
	status_id = &"spell_discount"
	display_name = "Spell Discount"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func modify_spell_energy_cost(
	_combatant: Node,
	cost: int
) -> int:
	return max(cost - stacks, 0)


func on_spell_cast(_combatant: Node) -> void:
	stacks = 0
