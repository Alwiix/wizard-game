class_name StatusInteractionRule
extends RefCounted


func apply(
	_application: StatusApplication,
	_controller: StatusController
) -> void:
	pass


func after_apply(
	_application: StatusApplication,
	_controller: StatusController,
	_combatant: Node
) -> void:
	pass
