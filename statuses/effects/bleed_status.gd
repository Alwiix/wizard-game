class_name BleedStatus
extends StatusEffect


func _init() -> void:
	status_id = &"bleed"
	display_name = "Bleed"
	show_stacks = true
	show_duration = false
	remaining_turns = -1
	removed_by_healing = true


func on_turn_ended(combatant: Node) -> void:
	if stacks <= 0:
		return

	var bleed_damage: int = stacks

	combatant.take_damage(
		bleed_damage,
		{
			"source": "status",
			"status_id": "bleed",
			"element": "physical"
		}
	)

	stacks = max(stacks - 1, 0)
