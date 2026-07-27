class_name BurnStatus
extends StatusEffect


func _init() -> void:
	status_id = &"burn"
	display_name = "Burn"
	show_stacks = true
	show_duration = false
	incoming_damage_priority = 50


func on_turn_ended(combatant: Node) -> void:
	if stacks <= 0:
		return

	combatant.take_damage(
		2,
		{
			"source": "status",
			"status_id": "burn",
			"element": "fire"
		}
	)

	# Burn stacks now represent its remaining end-turn triggers.
	stacks = max(stacks - 1, 0)
