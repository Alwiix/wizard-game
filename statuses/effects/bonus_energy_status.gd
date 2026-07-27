class_name BonusEnergyStatus
extends StatusEffect


func _init() -> void:
	status_id = &"bonus_energy"
	display_name = "Next Turn Energy"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func consume_next_turn_energy_bonus(
	_combatant: Node
) -> int:
	var bonus_energy: int = stacks
	stacks = 0
	return bonus_energy
