extends Control


const RUN_SCENE_PATH: String = "res://scenes/run/run_flow.tscn"


@onready var difficulty_option: OptionButton = (
	$Center/Menu/DifficultyOption
)
@onready var difficulty_description: Label = (
	$Center/Menu/DifficultyDescription
)
@onready var wizard_option: OptionButton = (
	$Center/Menu/WizardOption
)
@onready var deck_description: Label = (
	$Center/Menu/DeckDescription
)
@onready var start_button: Button = $Center/Menu/StartButton


func _ready() -> void:
	_populate_difficulties()
	_populate_wizards()

	difficulty_option.item_selected.connect(
		_on_difficulty_selected
	)
	wizard_option.item_selected.connect(_on_wizard_selected)
	start_button.pressed.connect(_on_start_button_pressed)

	difficulty_option.select(1)
	wizard_option.select(0)
	_update_difficulty_description()
	_update_deck_description()


func _populate_difficulties() -> void:
	difficulty_option.clear()
	difficulty_option.add_item(
		"Easy",
		RunState.Difficulty.EASY
	)
	difficulty_option.add_item(
		"Medium",
		RunState.Difficulty.MEDIUM
	)
	difficulty_option.add_item(
		"Hard",
		RunState.Difficulty.HARD
	)


func _populate_wizards() -> void:
	wizard_option.clear()
	wizard_option.add_item(
		"All Elements",
		1
	)


func _on_difficulty_selected(_index: int) -> void:
	_update_difficulty_description()


func _on_wizard_selected(_index: int) -> void:
	_update_deck_description()


func _update_difficulty_description() -> void:
	var difficulty_id: int = difficulty_option.get_selected_id()

	match difficulty_id:
		RunState.Difficulty.EASY:
			difficulty_description.text = "Enemy health: 75%"
		RunState.Difficulty.HARD:
			difficulty_description.text = "Enemy health: 125%"
		_:
			difficulty_description.text = "Enemy health: 100%"


func _update_deck_description() -> void:
	var wizard_number: int = wizard_option.get_selected_id()
	var element_names: PackedStringArray = []

	for element_data in RunState.get_wizard_elements(
		wizard_number
	):
		element_names.append("1 " + element_data.display_name)

	deck_description.text = (
		"Starting deck:\n" + ", ".join(element_names)
	)


func _on_start_button_pressed() -> void:
	start_button.disabled = true

	var difficulty: RunState.Difficulty = (
		difficulty_option.get_selected_id()
	)
	var wizard_number: int = wizard_option.get_selected_id()

	RunState.start_new_run(difficulty, wizard_number)
	get_tree().change_scene_to_file(RUN_SCENE_PATH)
