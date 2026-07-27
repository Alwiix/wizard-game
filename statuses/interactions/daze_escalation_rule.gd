class_name DazeEscalationRule
extends StatusInteractionRule


func apply(
	application: StatusApplication,
	controller: StatusController
) -> void:
	if (
		application.status_id != &"dazed"
		or not controller.has_status(&"dazed")
	):
		return

	application.remove_existing(&"dazed")
	application.status_id = &"stunned"
	application.amount = 1
	application.duration = -1
