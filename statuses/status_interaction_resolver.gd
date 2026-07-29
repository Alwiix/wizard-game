class_name StatusInteractionResolver
extends RefCounted


const RULE_SCRIPTS: Array[Script] = [
	preload(
		"res://statuses/interactions/elemental_status_rule.gd"
	),
	preload(
		"res://statuses/interactions/daze_escalation_rule.gd"
	),
	preload(
		"res://statuses/interactions/conductive_status_rule.gd"
	),
	preload(
		"res://statuses/interactions/nature_status_rule.gd"
	)
]


static func resolve(
	controller: StatusController,
	status_id: StringName,
	amount: int,
	duration: int
) -> StatusApplication:
	var application := StatusApplication.new(
		status_id,
		amount,
		duration
	)

	for rule_script in RULE_SCRIPTS:
		var rule := rule_script.new() as StatusInteractionRule

		if rule == null:
			continue

		rule.apply(application, controller)

		if not application.accepted:
			break

	return application


static func after_apply(
	controller: StatusController,
	application: StatusApplication,
	combatant: Node
) -> void:
	for rule_script in RULE_SCRIPTS:
		var rule := rule_script.new() as StatusInteractionRule

		if rule != null:
			rule.after_apply(
				application,
				controller,
				combatant
			)
