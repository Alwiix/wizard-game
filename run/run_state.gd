extends Node


enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}


const BASE_TURN_HAND_SIZE: int = 3
const EXPANDED_TURN_HAND_SIZE: int = 4
const EXPANDED_HAND_DECK_SIZE: int = 12


var maximum_health: int = 30
var current_health: int = 30
var current_floor: int = 1
var deck: Array[CardInstance] = []
var selected_difficulty: Difficulty = Difficulty.MEDIUM
var selected_wizard: int = 1
var is_run_active: bool = false
var current_map_location_id: StringName = &""
var completed_map_locations: Dictionary = {}
var closed_rifts: int = 0
var instability: int = 0
var expanded_hand_unlocked: bool = false


func _ready() -> void:
	if OS.is_debug_build():
		for validation_error in ContentValidator.validate_all():
			push_error("Content validation: " + validation_error)

	if deck.is_empty():
		start_new_run()


func start_new_run(
	difficulty: Difficulty = Difficulty.MEDIUM,
	wizard_number: int = 1
) -> void:
	selected_difficulty = difficulty
	selected_wizard = clampi(wizard_number, 1, 1)
	maximum_health = 30
	current_health = maximum_health
	current_floor = 1
	deck = _create_starting_deck(selected_wizard)
	current_map_location_id = &""
	completed_map_locations.clear()
	closed_rifts = 0
	instability = 0
	expanded_hand_unlocked = false
	is_run_active = true


func restart_current_run() -> void:
	start_new_run(selected_difficulty, selected_wizard)


func end_current_run() -> void:
	is_run_active = false


func get_deck_for_battle() -> Array[CardInstance]:
	return deck.duplicate()


func get_all_element_card_data() -> Array[ElementCardData]:
	return ContentCatalog.get_all_elements()


func get_reward_element_card_data() -> Array[ElementCardData]:
	return ContentCatalog.get_reward_elements()


func add_card_to_deck(card_data: ElementCardData) -> CardInstance:
	if card_data == null:
		return null

	var new_card := CardInstance.new(card_data)
	deck.append(new_card)
	_update_hand_size_unlock()
	return new_card


func apply_card_upgrade(
	card: CardInstance,
	upgrade_id: StringName
) -> bool:
	if card == null or not deck.has(card):
		return false

	return card.apply_upgrade(upgrade_id)


func set_current_health(value: int) -> void:
	current_health = clampi(value, 0, maximum_health)


func set_current_floor(value: int) -> void:
	current_floor = maxi(value, 1)


func get_turn_hand_size() -> int:
	_update_hand_size_unlock()

	return (
		EXPANDED_TURN_HAND_SIZE
		if expanded_hand_unlocked
		else BASE_TURN_HAND_SIZE
	)


func _update_hand_size_unlock() -> void:
	if deck.size() >= EXPANDED_HAND_DECK_SIZE:
		expanded_hand_unlocked = true


func initialize_leyline_map(map_data: LeylineMapData) -> bool:
	if map_data == null:
		return false

	if current_map_location_id != &"":
		return true

	var starting_location := map_data.find_location(
		map_data.starting_location_id
	)

	if starting_location == null:
		return false

	current_map_location_id = starting_location.location_id
	completed_map_locations[starting_location.location_id] = true
	return true


func can_travel_to(
	map_data: LeylineMapData,
	location_id: StringName
) -> bool:
	if map_data == null or location_id == current_map_location_id:
		return false

	var destination := map_data.find_location(location_id)

	if destination == null:
		return false

	if not map_data.are_connected(
		current_map_location_id,
		location_id
	):
		return false

	if (
		destination.location_type
			== LeylineLocationData.LocationType.BOSS
		and closed_rifts < map_data.rifts_required
	):
		return false

	return true


func travel_to_map_location(
	map_data: LeylineMapData,
	location_id: StringName
) -> bool:
	if not can_travel_to(map_data, location_id):
		return false

	current_map_location_id = location_id
	instability += 1
	return true


func complete_map_location(
	location: LeylineLocationData
) -> bool:
	if location == null:
		return false

	if completed_map_locations.has(location.location_id):
		return false

	completed_map_locations[location.location_id] = true

	if (
		location.location_type
			== LeylineLocationData.LocationType.RIFT
	):
		closed_rifts += 1

	return true


func is_map_location_completed(location_id: StringName) -> bool:
	return completed_map_locations.has(location_id)


func get_enemy_health_multiplier() -> float:
	var difficulty_multiplier: float = 1.0

	match selected_difficulty:
		Difficulty.EASY:
			difficulty_multiplier = 0.75
		Difficulty.HARD:
			difficulty_multiplier = 1.25

	var instability_multiplier: float = (
		1.0 + float(instability) * 0.03
	)
	return difficulty_multiplier * instability_multiplier


func get_wizard_elements(
	_wizard_number: int
) -> Array[ElementCardData]:
	return ContentCatalog.get_all_elements()


func _create_starting_deck(
	wizard_number: int
) -> Array[CardInstance]:
	var starting_deck: Array[CardInstance] = []
	var wizard_elements: Array[ElementCardData] = (
		get_wizard_elements(wizard_number)
	)

	for element_data in wizard_elements:
		starting_deck.append(CardInstance.new(element_data))

	return starting_deck
