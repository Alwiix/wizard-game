class_name ElementalStatusRule
extends StatusInteractionRule


func apply(
	application: StatusApplication,
	controller: StatusController
) -> void:
	if (
		application.status_id == &"burn"
		and controller.has_status(&"wet")
	):
		application.accepted = false
		return

	if application.status_id == &"wet":
		application.remove_existing(&"burn")
		application.remove_existing(&"muddy")

	if application.status_id == &"burn":
		application.remove_existing(&"cold")

	if (
		application.status_id == &"cold"
		and controller.has_status(&"wet")
	):
		application.amount *= 2
