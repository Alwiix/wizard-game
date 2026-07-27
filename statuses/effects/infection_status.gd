class_name InfectionStatus
extends StatusEffect


const LETHAL_STACKS: int = 6


func _init() -> void:
	status_id = &"infection"
	display_name = "Infection"

	show_stacks = true
	show_duration = false

	# Infection does not naturally expire.
	remaining_turns = -1


func on_applied(combatant: Node) -> void:
	if stacks < LETHAL_STACKS:
		return

	if combatant.has_method("defeat_immediately"):
		combatant.call(
			"defeat_immediately",
			{
				"source": "status",
				"status_id": "infection"
			}
		)
		return

	# Fallback in case Infection is applied to something
	# without defeat_immediately().
	if combatant.has_method("take_damage"):
		combatant.call(
			"take_damage",
			999999,
			{
				"source": "status",
				"status_id": "infection",
				"bypass_block": true
			}
		)


func get_display_text() -> String:
	return (
		display_name
		+ ": "
		+ str(stacks)
		+ " / "
		+ str(LETHAL_STACKS)
	)
