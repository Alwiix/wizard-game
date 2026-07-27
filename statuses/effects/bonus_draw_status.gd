class_name BonusDrawStatus
extends StatusEffect


func _init() -> void:
	status_id = &"bonus_draw"
	display_name = "Next Turn Draw"
	remaining_turns = -1
	show_stacks = true
	show_duration = false


func consume_next_turn_draw_bonus(
	_combatant: Node
) -> int:
	var bonus_cards: int = stacks
	stacks = 0
	return bonus_cards
