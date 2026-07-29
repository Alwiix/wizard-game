class_name RewardScreen
extends Control


signal rewards_completed


const UPGRADE_LIBRARY: CardUpgradeLibraryData = (
	ContentCatalog.UPGRADE_LIBRARY
)
const HOVER_EXPAND_BUTTON: GDScript = preload(
	"res://scenes/ui/hover_expand_button.gd"
)


var rng := RandomNumberGenerator.new()
var element_choices: Array[ElementCardData] = []
var pending_upgrade_id: StringName = &""
var selected_upgrade_card: CardInstance
var deck_card_buttons: Dictionary = {}
var element_reward_claimed: bool = false
var preferred_element: StringName = &""


@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var reward_description: Label = %RewardDescription
@onready var element_choice_container: HBoxContainer = (
	%ElementChoiceContainer
)
@onready var deck_scroll: ScrollContainer = %DeckScroll
@onready var deck_grid: GridContainer = %DeckGrid
@onready var apply_upgrade_button: Button = %ApplyUpgradeButton
@onready var skip_reward_button: Button = %SkipRewardButton


func _ready() -> void:
	rng.randomize()
	apply_upgrade_button.pressed.connect(confirm_upgrade)
	skip_reward_button.pressed.connect(_on_skip_reward_pressed)


func begin_rewards(
	elemental_affinity: StringName = &""
) -> void:
	preferred_element = elemental_affinity
	element_reward_claimed = false
	selected_upgrade_card = null
	element_choices = _generate_element_choices()
	pending_upgrade_id = _generate_upgrade_id()
	_show_element_choice()


func choose_element_card(card_data: ElementCardData) -> bool:
	if element_reward_claimed or not element_choices.has(card_data):
		return false

	if RunState.add_card_to_deck(card_data) == null:
		return false

	element_reward_claimed = true
	_show_upgrade_choice()
	return true


func skip_element_reward() -> bool:
	if element_reward_claimed:
		return false

	element_reward_claimed = true
	_show_upgrade_choice()
	return true


func select_upgrade_card(card: CardInstance) -> bool:
	if (
		not element_reward_claimed
		or pending_upgrade_id == &""
		or card == null
		or not RunState.deck.has(card)
		or not _card_can_receive_upgrade(
			card,
			UPGRADE_LIBRARY.find_upgrade(pending_upgrade_id)
		)
	):
		return false

	selected_upgrade_card = card

	for button_value in deck_card_buttons.keys():
		var button: Button = button_value as Button

		if button != null:
			button.set_pressed_no_signal(
				deck_card_buttons[button] == card
			)

	apply_upgrade_button.disabled = false
	return true


func confirm_upgrade() -> bool:
	if selected_upgrade_card == null:
		return false

	if not RunState.apply_card_upgrade(
		selected_upgrade_card,
		pending_upgrade_id
	):
		return false

	apply_upgrade_button.disabled = true
	rewards_completed.emit()
	return true


func skip_upgrade_reward() -> bool:
	if not element_reward_claimed:
		return false

	apply_upgrade_button.disabled = true
	skip_reward_button.disabled = true
	rewards_completed.emit()
	return true


func get_upgrade_name(upgrade_id: StringName) -> String:
	var upgrade_data: CardUpgradeData = (
		UPGRADE_LIBRARY.find_upgrade(upgrade_id)
	)

	if upgrade_data == null:
		return "Unknown Upgrade"

	return upgrade_data.display_name


func _generate_element_choices() -> Array[ElementCardData]:
	var available_elements: Array[ElementCardData] = (
		RunState.get_all_element_card_data()
		if preferred_element != &""
		else RunState.get_reward_element_card_data()
	)
	var choices: Array[ElementCardData] = []
	var preferred_card: ElementCardData

	for card_data in available_elements:
		if (
			card_data.element_name.to_lower()
			== String(preferred_element).to_lower()
		):
			preferred_card = card_data
			break

	if preferred_card != null:
		choices.append(preferred_card)
		available_elements.erase(preferred_card)

	available_elements.shuffle()

	for card_data in available_elements:
		if choices.size() >= 3:
			break

		choices.append(card_data)

	return choices


func _generate_upgrade_id() -> StringName:
	var eligible_upgrades: Array[CardUpgradeData] = []

	for upgrade_data in UPGRADE_LIBRARY.upgrades:
		if upgrade_data == null:
			continue

		for card in RunState.deck:
			if _card_can_receive_upgrade(card, upgrade_data):
				eligible_upgrades.append(upgrade_data)
				break

	if eligible_upgrades.is_empty():
		return &""

	var total_weight: float = 0.0

	for upgrade_data in eligible_upgrades:
		total_weight += max(upgrade_data.reward_weight, 0.0)

	if total_weight <= 0.0:
		return eligible_upgrades[
			rng.randi_range(0, eligible_upgrades.size() - 1)
		].upgrade_id

	var selection_roll: float = rng.randf_range(0.0, total_weight)

	for upgrade_data in eligible_upgrades:
		selection_roll -= max(upgrade_data.reward_weight, 0.0)

		if selection_roll <= 0.0:
			return upgrade_data.upgrade_id

	return eligible_upgrades.back().upgrade_id


func _show_element_choice() -> void:
	title_label.text = "Battle Rewards"
	instruction_label.text = "Choose one Element Card"
	reward_description.text = (
		"Add one of these three cards to your deck.\n"
		+ _get_hand_size_progress_text()
	)

	if preferred_element != &"":
		reward_description.text += (
			"\nThe local "
			+ String(preferred_element).capitalize()
			+ " leyline guarantees a matching choice when available."
		)
	element_choice_container.show()
	deck_scroll.hide()
	apply_upgrade_button.hide()
	skip_reward_button.text = "Skip Card"
	skip_reward_button.disabled = false
	skip_reward_button.show()
	_clear_container(element_choice_container)

	for card_data in element_choices:
		var card_button := (
			HOVER_EXPAND_BUTTON.new() as Button
		)
		card_button.custom_minimum_size = Vector2(110.0, 72.0)
		card_button.add_theme_font_size_override("font_size", 9)
		card_button.clip_text = true
		card_button.text = (
			card_data.display_name
			+ "\nSpell ingredient"
			+ "\nAdd to deck"
		)
		card_button.tooltip_text = card_button.text
		card_button.pressed.connect(
			_on_element_button_pressed.bind(card_data)
		)
		element_choice_container.add_child(card_button)


func _show_upgrade_choice() -> void:
	_clear_container(element_choice_container)
	element_choice_container.hide()

	if pending_upgrade_id == &"":
		title_label.text = "Rewards Complete"
		instruction_label.text = "No upgrades are currently available."
		reward_description.text = ""
		rewards_completed.emit()
		return

	var upgrade_data: CardUpgradeData = (
		UPGRADE_LIBRARY.find_upgrade(pending_upgrade_id)
	)

	instruction_label.text = (
		"Choose a card for " + upgrade_data.display_name
	)
	reward_description.text = (
		upgrade_data.description
		+ "\n"
		+ _get_hand_size_progress_text()
	)
	deck_scroll.show()
	apply_upgrade_button.text = (
		"Apply " + upgrade_data.display_name
	)
	apply_upgrade_button.disabled = true
	apply_upgrade_button.show()
	skip_reward_button.text = "Skip Upgrade"
	skip_reward_button.disabled = false
	skip_reward_button.show()
	_populate_deck_grid()


func _populate_deck_grid() -> void:
	_clear_container(deck_grid)
	deck_card_buttons.clear()

	for card_index in range(RunState.deck.size()):
		var card: CardInstance = RunState.deck[card_index]
		var card_button := (
			HOVER_EXPAND_BUTTON.new() as Button
		)
		var upgrade_names: Array[String] = (
			card.get_upgrade_display_names()
		)

		card_button.custom_minimum_size = Vector2(102.0, 54.0)
		card_button.add_theme_font_size_override("font_size", 8)
		card_button.clip_text = true
		card_button.toggle_mode = true
		card_button.text = (
			str(card_index + 1)
			+ ". "
			+ card.data.display_name
			+ "\nSpell cost modifier: "
			+ str(card.get_spell_cost_modifier())
		)

		if not upgrade_names.is_empty():
			card_button.text += (
				"\n" + ", ".join(upgrade_names)
			)

		var pending_upgrade: CardUpgradeData = (
			UPGRADE_LIBRARY.find_upgrade(pending_upgrade_id)
		)

		if not _card_can_receive_upgrade(card, pending_upgrade):
			card_button.text += "\nAlready has this upgrade"
			card_button.disabled = true
		else:
			card_button.pressed.connect(
				_on_deck_card_pressed.bind(card)
			)

		card_button.tooltip_text = card_button.text
		deck_grid.add_child(card_button)
		deck_card_buttons[card_button] = card


func _on_element_button_pressed(
	card_data: ElementCardData
) -> void:
	choose_element_card(card_data)


func _on_deck_card_pressed(card: CardInstance) -> void:
	select_upgrade_card(card)


func _on_skip_reward_pressed() -> void:
	if element_reward_claimed:
		skip_upgrade_reward()
	else:
		skip_element_reward()


func _card_can_receive_upgrade(
	card: CardInstance,
	upgrade_data: CardUpgradeData
) -> bool:
	if card == null or upgrade_data == null:
		return false

	return (
		upgrade_data.can_stack
		or not card.has_upgrade(upgrade_data.upgrade_id)
	)


func _get_hand_size_progress_text() -> String:
	if RunState.expanded_hand_unlocked:
		return "Expanded spellbook: refill your hand to 4."

	return (
		"Spellbook expansion: "
		+ str(RunState.deck.size())
		+ " / "
		+ str(RunState.EXPANDED_HAND_DECK_SIZE)
		+ " cards. Reach 12 to permanently refill to 4."
	)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
