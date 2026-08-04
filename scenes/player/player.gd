class_name BattlePlayer
extends BattleCombatant


signal defeated
signal health_changed(current_health: int, maximum_health: int)
signal energy_changed(current_energy: int, maximum_energy: int)


@export var maximum_energy: int = 2


var energy: int
func _ready() -> void:
	configure_health(
		RunState.maximum_health,
		RunState.current_health
	)
	energy = maximum_energy
	update_energy_text()


func start_turn() -> void:
	energy = (
		maximum_energy
		+ $StatusController.consume_next_turn_energy_bonus()
	)
	update_energy_text()


func get_spell_energy_cost(base_cost: int) -> int:
	return $StatusController.modify_spell_energy_cost(base_cost)


func process_successful_spell_cast() -> void:
	$StatusController.process_successful_spell_cast()


func consume_next_turn_draw_bonus() -> int:
	return $StatusController.consume_next_turn_draw_bonus()


func can_spend_energy(amount: int) -> bool:
	return energy >= amount


func spend_energy(amount: int) -> bool:
	if amount < 0:
		return false

	if not can_spend_energy(amount):
		return false

	energy -= amount
	update_energy_text()

	return true


func _on_health_changed() -> void:
	RunState.set_current_health(health)
	health_changed.emit(health, maximum_health)


func _on_defeated(_context: Dictionary) -> void:
	defeated.emit()


func get_display_name() -> String:
	return "Wizard"


func update_health_text() -> void:
	pass


func update_energy_text() -> void:
	energy_changed.emit(energy, maximum_energy)
