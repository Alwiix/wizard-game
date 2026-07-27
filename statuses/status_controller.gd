class_name StatusController
extends Node


signal statuses_changed


var active_statuses: Dictionary = {}
var combat_events: CombatEvents
var action_rng: RandomNumberGenerator = RandomNumberGenerator.new()


@onready var combatant: Node = get_parent()
@onready var status_label: Label = (
	get_parent().get_node_or_null("StatusLabel") as Label
)


func _ready() -> void:
	action_rng.randomize()
	update_status_label()


func set_combat_events(events: CombatEvents) -> void:
	combat_events = events


func add_status(
	status_id_value: StringName,
	amount: int = 1,
	duration: int = -1
) -> bool:
	var normalized_id: StringName = StringName(
		String(status_id_value).to_lower()
	)

	if not StatusRegistry.has_status(normalized_id):
		push_warning(
			"Unknown status: " + String(normalized_id)
		)
		return false

	var application := StatusInteractionResolver.resolve(
		self,
		normalized_id,
		amount,
		duration
	)

	if not application.accepted:
		return false

	for status_to_remove in application.statuses_to_remove:
		active_statuses.erase(status_to_remove)

	normalized_id = application.status_id
	amount = application.amount
	duration = application.duration

	var affected_status: StatusEffect

	if active_statuses.has(normalized_id):
		affected_status = active_statuses[normalized_id]
		affected_status.add_application(amount, duration)
	else:
		affected_status = StatusRegistry.create_status(normalized_id)

		if affected_status == null:
			push_error(
				"Could not create status: "
				+ String(normalized_id)
			)
			return false

		affected_status.initialize(amount, duration)
		active_statuses[normalized_id] = affected_status

	if combat_events != null:
		combat_events.status_applied.emit(
			combatant,
			normalized_id,
			amount,
			duration
		)

	# Allows statuses such as Infection to react immediately.
	affected_status.on_applied(combatant)
	StatusInteractionResolver.after_apply(
		self,
		application,
		combatant
	)

	cleanup_expired_statuses()
	return true



func remove_status(status_id_value: StringName) -> void:
	var normalized_id: StringName = StringName(
		String(status_id_value).to_lower()
	)

	active_statuses.erase(normalized_id)
	update_status_label()
	statuses_changed.emit()


func has_status(status_id_value: StringName) -> bool:
	var normalized_id: StringName = StringName(
		String(status_id_value).to_lower()
	)

	return active_statuses.has(normalized_id)


func get_status_stacks(status_id_value: StringName) -> int:
	var normalized_id: StringName = StringName(
		String(status_id_value).to_lower()
	)

	if not active_statuses.has(normalized_id):
		return 0

	var status: StatusEffect = active_statuses[normalized_id]
	return status.stacks


func process_turn_start() -> void:
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		status.on_turn_started(combatant)

	cleanup_expired_statuses()


func process_turn_end() -> void:
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		status.on_turn_ended(combatant)
		status.tick_duration_after_turn()

	cleanup_expired_statuses()


func modify_incoming_damage(
	amount: int,
	context: Dictionary = {}
) -> int:
	var final_amount: int = max(amount, 0)
	var statuses: Array[StatusEffect] = get_damage_modifying_statuses()

	for status in statuses:
		final_amount = status.modify_incoming_damage(
			combatant,
			final_amount,
			context
		)

		final_amount = max(final_amount, 0)

	cleanup_expired_statuses()
	return final_amount


func resolve_action_attempt(can_miss: bool = true) -> StringName:
	var statuses: Array[StatusEffect] = []

	for status_value in active_statuses.values():
		var status: StatusEffect = status_value as StatusEffect

		if status != null:
			statuses.append(status)

	statuses.sort_custom(
		func(first: StatusEffect, second: StatusEffect) -> bool:
			return (
				first.action_resolution_priority
				< second.action_resolution_priority
			)
	)

	for status in statuses:
		var outcome: StringName = status.resolve_action_attempt(
			combatant,
			can_miss,
			action_rng
		)

		if outcome != &"continue":
			cleanup_expired_statuses()
			return outcome

	cleanup_expired_statuses()
	return &"continue"


func process_healing(requested_amount: int) -> void:
	if requested_amount <= 0:
		return

	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]

		if status.removed_by_healing:
			active_statuses.erase(status_id_value)

	update_status_label()
	statuses_changed.emit()


func modify_spell_energy_cost(cost: int) -> int:
	var final_cost: int = max(cost, 0)

	for status_value in active_statuses.values():
		var status: StatusEffect = status_value as StatusEffect

		if status != null:
			final_cost = status.modify_spell_energy_cost(
				combatant,
				final_cost
			)

	return max(final_cost, 0)


func process_successful_spell_cast() -> void:
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		status.on_spell_cast(combatant)

	cleanup_expired_statuses()


func consume_next_turn_draw_bonus() -> int:
	var total_bonus: int = 0
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		total_bonus += status.consume_next_turn_draw_bonus(
			combatant
		)

	cleanup_expired_statuses()
	return total_bonus


func consume_next_turn_energy_bonus() -> int:
	var total_bonus: int = 0
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		total_bonus += status.consume_next_turn_energy_bonus(
			combatant
		)

	cleanup_expired_statuses()
	return total_bonus


func consume_dodge() -> bool:
	if not active_statuses.has(&"dodge"):
		return false

	var dodge_status: StatusEffect = active_statuses[&"dodge"]
	var attack_was_dodged: bool = dodge_status.consume_dodge(
		combatant
	)
	cleanup_expired_statuses()
	return attack_was_dodged


func process_attack_completed(
	attacker: Node,
	context: Dictionary = {}
) -> void:
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		if not active_statuses.has(status_id_value):
			continue

		var status: StatusEffect = active_statuses[status_id_value]
		status.on_attacked(combatant, attacker, context)

	cleanup_expired_statuses()


func get_damage_modifying_statuses() -> Array[StatusEffect]:
	var statuses: Array[StatusEffect] = []

	for status_value in active_statuses.values():
		var status: StatusEffect = status_value as StatusEffect

		if status != null:
			statuses.append(status)

	statuses.sort_custom(
		func(first: StatusEffect, second: StatusEffect) -> bool:
			return (
				first.incoming_damage_priority
				< second.incoming_damage_priority
			)
	)

	return statuses


func clear_statuses() -> void:
	active_statuses.clear()
	update_status_label()
	statuses_changed.emit()


func cleanup_expired_statuses() -> void:
	var status_ids: Array = active_statuses.keys().duplicate()

	for status_id_value in status_ids:
		var status: StatusEffect = active_statuses[status_id_value]

		if status.is_expired():
			active_statuses.erase(status_id_value)

	update_status_label()
	statuses_changed.emit()


func update_status_label() -> void:
	if status_label == null:
		return

	if active_statuses.is_empty():
		status_label.text = "Statuses: None"
		return

	var lines: Array[String] = ["Statuses:"]

	for status_value in active_statuses.values():
		var status: StatusEffect = status_value as StatusEffect

		if status != null:
			lines.append(status.get_display_text())

	status_label.text = "\n".join(lines)
