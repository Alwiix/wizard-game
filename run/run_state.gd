extends Node


enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}


var maximum_health: int = 30
var current_health: int = 30
var current_floor: int = 1
var deck: Array[CardInstance] = []
var selected_difficulty: Difficulty = Difficulty.MEDIUM
var selected_wizard: int = 1
var is_run_active: bool = false


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


func get_enemy_health_multiplier() -> float:
	match selected_difficulty:
		Difficulty.EASY:
			return 0.75
		Difficulty.HARD:
			return 1.25
		_:
			return 1.0


func get_wizard_elements(
	_wizard_number: int
) -> Array[ElementCardData]:
	return [
		ContentCatalog.WATER_CARD_DATA,
		ContentCatalog.LIGHTNING_CARD_DATA,
		ContentCatalog.AIR_CARD_DATA
	]


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
