class_name CombatResult
extends RefCounted


var messages: Array[String] = []
var total_health_damage: int = 0
var total_health_healed: int = 0
var affected_targets: Array[Node] = []
var damage_by_target: Dictionary = {}


func add_message(message: String) -> void:
	if not message.is_empty():
		messages.append(message)


func record_target(target: Node) -> void:
	if target != null and not affected_targets.has(target):
		affected_targets.append(target)


func record_damage(target: Node, amount: int) -> void:
	record_target(target)
	damage_by_target[target] = (
		int(damage_by_target.get(target, 0)) + amount
	)


func merge(other: CombatResult) -> void:
	if other == null:
		return

	messages.append_array(other.messages)
	total_health_damage += other.total_health_damage
	total_health_healed += other.total_health_healed

	for target in other.affected_targets:
		record_target(target)

	for target in other.damage_by_target:
		record_damage(
			target,
			int(other.damage_by_target[target])
		)


func to_dictionary() -> Dictionary:
	return {
		"messages": messages.duplicate(),
		"total_health_damage": total_health_damage,
		"total_health_healed": total_health_healed,
		"affected_targets": affected_targets.duplicate(),
		"damage_by_target": damage_by_target.duplicate()
	}
