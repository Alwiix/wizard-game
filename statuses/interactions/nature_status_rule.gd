class_name NatureStatusRule
extends StatusInteractionRule


func after_apply(
	application: StatusApplication,
	controller: StatusController,
	_combatant: Node
) -> void:
	if (
		application.status_id == &"wet"
		and controller.has_status(&"creeping_vines")
	):
		controller.add_status(&"creeping_vines", 1)
