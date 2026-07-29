class_name LeylineMapData
extends Resource


@export_group("Identity")
@export var map_id: StringName = &"leyline_map"
@export var display_name: String = "Leyline Atlas"

@export_group("Structure")
@export var starting_location_id: StringName = &""
@export var rifts_required: int = 3
@export var locations: Array[LeylineLocationData] = []


func find_location(location_id: StringName) -> LeylineLocationData:
	for location in locations:
		if location != null and location.location_id == location_id:
			return location

	return null


func are_connected(
	first_location_id: StringName,
	second_location_id: StringName
) -> bool:
	var first_location := find_location(first_location_id)

	if first_location == null:
		return false

	return second_location_id in first_location.connected_location_ids


func get_rift_count() -> int:
	var count: int = 0

	for location in locations:
		if (
			location != null
			and location.location_type
				== LeylineLocationData.LocationType.RIFT
		):
			count += 1

	return count
