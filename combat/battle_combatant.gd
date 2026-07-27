class_name BattleCombatant
extends Node2D


var maximum_health: int = 0
var health: int = 0
var is_defeated: bool = false
var combat_events: CombatEvents


func configure_health(
	new_maximum_health: int,
	new_current_health: int
) -> void:
	maximum_health = maxi(new_maximum_health, 1)
	health = clampi(
		new_current_health,
		0,
		maximum_health
	)
	is_defeated = health <= 0
	update_health_text()
	_on_health_changed()


func set_combat_events(events: CombatEvents) -> void:
	combat_events = events

	var controller := get_status_controller()

	if controller != null:
		controller.set_combat_events(events)


func get_status_controller() -> StatusController:
	return get_node_or_null("StatusController") as StatusController


func process_statuses_at_turn_start() -> void:
	var controller := get_status_controller()

	if controller != null:
		controller.process_turn_start()


func process_statuses_at_turn_end() -> void:
	var controller := get_status_controller()

	if controller != null:
		controller.process_turn_end()


func add_status(
	status_id: StringName,
	amount: int = 1,
	duration: int = -1
) -> bool:
	var controller := get_status_controller()

	if controller == null:
		return false

	return controller.add_status(status_id, amount, duration)


func remove_status(status_id: StringName) -> void:
	var controller := get_status_controller()

	if controller != null:
		controller.remove_status(status_id)


func has_status(status_id: StringName) -> bool:
	var controller := get_status_controller()
	return controller != null and controller.has_status(status_id)


func get_status_stacks(status_id: StringName) -> int:
	var controller := get_status_controller()

	if controller == null:
		return 0

	return controller.get_status_stacks(status_id)


func process_attack_completed(
	attacker: Node,
	context: Dictionary = {}
) -> void:
	var controller := get_status_controller()

	if controller != null:
		controller.process_attack_completed(attacker, context)


func consume_dodge() -> bool:
	var controller := get_status_controller()
	return controller != null and controller.consume_dodge()


func take_damage(
	amount: int,
	context: Dictionary = {}
) -> int:
	if is_defeated:
		return 0

	var requested_damage: int = maxi(amount, 0)

	if combat_events != null:
		combat_events.damage_requested.emit(
			self,
			requested_damage,
			context
		)

	var final_damage: int = requested_damage
	var controller := get_status_controller()

	if controller != null:
		final_damage = controller.modify_incoming_damage(
			requested_damage,
			context
		)

	health = maxi(health - final_damage, 0)
	update_health_text()
	_on_health_changed()

	if combat_events != null:
		combat_events.damage_dealt.emit(
			self,
			requested_damage,
			final_damage,
			context
		)

	if health == 0:
		_mark_defeated(context)

	return final_damage


func heal(
	amount: int,
	context: Dictionary = {}
) -> int:
	if is_defeated:
		return 0

	var requested_healing: int = maxi(amount, 0)

	if combat_events != null:
		combat_events.healing_requested.emit(
			self,
			requested_healing,
			context
		)

	var controller := get_status_controller()

	if controller != null:
		controller.process_healing(requested_healing)

	var previous_health := health
	health = mini(health + requested_healing, maximum_health)
	var restored_health := health - previous_health

	update_health_text()
	_on_health_changed()

	if combat_events != null:
		combat_events.health_restored.emit(
			self,
			requested_healing,
			restored_health,
			context
		)

	return restored_health


func defeat_immediately(
	context: Dictionary = {}
) -> void:
	if is_defeated:
		return

	health = 0
	update_health_text()
	_on_health_changed()
	_mark_defeated(context)


func get_maximum_health() -> int:
	return maximum_health


func get_display_name() -> String:
	return "Combatant"


func update_health_text() -> void:
	pass


func _on_health_changed() -> void:
	pass


func _on_defeated(_context: Dictionary) -> void:
	pass


func _mark_defeated(context: Dictionary) -> void:
	if is_defeated:
		return

	is_defeated = true

	if combat_events != null:
		combat_events.combatant_defeated.emit(self, context)

	_on_defeated(context)
