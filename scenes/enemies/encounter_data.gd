class_name EncounterData
extends Resource


@export var encounter_id: StringName = &"encounter"
@export var display_name: String = "Encounter"
# Kept for compatibility with existing encounter resources.
@export var enemy_data: EnemyData
@export var enemies: Array[EnemyData] = []
@export var is_boss: bool = false


func get_enemy_roster() -> Array[EnemyData]:
	var result: Array[EnemyData] = []

	for enemy_value in enemies:
		if enemy_value != null:
			result.append(enemy_value)

	if result.is_empty() and enemy_data != null:
		result.append(enemy_data)

	return result
