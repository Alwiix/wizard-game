class_name LeylineLocationData
extends Resource


enum LocationType {
	START,
	BATTLE,
	RIFT,
	REST,
	BOSS
}


@export_group("Identity")
@export var location_id: StringName = &"location"
@export var display_name: String = "Location"
@export_multiline var description: String = ""

@export_group("Gameplay")
@export var location_type: LocationType = LocationType.BATTLE
@export var elemental_affinity: StringName = &""
@export var danger_level: int = 1
@export var encounter: EncounterData

@export_group("Map")
@export var map_position: Vector2 = Vector2(0.5, 0.5)
@export var connected_location_ids: Array[StringName] = []


func is_combat_location() -> bool:
	return location_type in [
		LocationType.BATTLE,
		LocationType.RIFT,
		LocationType.BOSS
	]


func get_type_name() -> String:
	match location_type:
		LocationType.START:
			return "Sanctum"
		LocationType.RIFT:
			return "Elemental Rift"
		LocationType.REST:
			return "Rest Site"
		LocationType.BOSS:
			return "Final Convergence"
		_:
			return "Encounter"
