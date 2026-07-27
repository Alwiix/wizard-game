class_name ConductiveStatusRule
extends StatusInteractionRule


func after_apply(
	application: StatusApplication,
	controller: StatusController,
	combatant: Node
) -> void:
	var conductivity_was_activated: bool = (
		application.status_id == &"wet"
		and controller.has_status(&"electrified")
	) or (
		application.status_id == &"electrified"
		and controller.has_status(&"wet")
	)

	if (
		not conductivity_was_activated
		or not combatant.has_method("take_damage")
	):
		return

	var electrified_stacks := controller.get_status_stacks(
		&"electrified"
	)

	if electrified_stacks <= 0:
		return

	controller.remove_status(&"electrified")
	combatant.take_damage(
		electrified_stacks,
		{
			"source": "status_interaction",
			"status_id": "electrified",
			"element": "lightning"
		}
	)
