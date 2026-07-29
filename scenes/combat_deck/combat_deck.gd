class_name CombatDeck
extends Control


signal card_selection_changed(card, is_selected: bool)
signal retain_selection_started(cards_required: int)
signal retain_selection_finished(cards_retained: int)


const ELEMENT_CARD_SCENE: PackedScene = preload(
	"res://scenes/cards/element_card.tscn"
)

@export var maximum_hand_size: int = 8


var draw_pile: Array[CardInstance] = []
var discard_pile: Array[CardInstance] = []
var hand_cards: Array = []
var is_selecting_retain_targets: bool = false
var retain_targets_required: int = 0
var retain_targets_selected: int = 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_fit_to_viewport()

	if not get_viewport().size_changed.is_connected(
		_fit_to_viewport
	):
		get_viewport().size_changed.connect(_fit_to_viewport)


func _fit_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

	var hand: HBoxContainer = get_node_or_null("Hand") as HBoxContainer

	if hand != null:
		hand.anchor_left = 0.0
		hand.anchor_right = 1.0
		hand.offset_left = 80.0
		hand.offset_top = 252.0
		hand.offset_right = -80.0
		hand.offset_bottom = 358.0
		hand.alignment = BoxContainer.ALIGNMENT_CENTER


func start_battle() -> void:
	draw_pile = RunState.get_deck_for_battle()

	for card in draw_pile:
		card.reset_temporary_modifiers()

	discard_pile.clear()
	hand_cards.clear()

	draw_pile.shuffle()
	update_pile_labels()


func draw_turn_hand() -> int:
	var target_hand_size: int = mini(
		RunState.get_turn_hand_size(),
		maximum_hand_size
	)
	var cards_needed: int = maxi(
		target_hand_size - hand_cards.size(),
		0
	)
	return draw_cards(cards_needed)


func draw_cards(amount: int) -> int:
	var cards_drawn: int = 0

	for _card_number in range(amount):
		if hand_cards.size() >= maximum_hand_size:
			break

		if draw_one_card():
			cards_drawn += 1

	update_pile_labels()
	return cards_drawn


func draw_one_card() -> bool:
	if hand_cards.size() >= maximum_hand_size:
		return false

	if draw_pile.is_empty():
		reshuffle_discard_pile()

	if draw_pile.is_empty():
		return false

	var drawn_card: CardInstance = draw_pile.pop_back()
	var new_card = ELEMENT_CARD_SCENE.instantiate()

	$Hand.add_child(new_card)

	new_card.setup(drawn_card)

	hand_cards.append(new_card)

	new_card.selection_changed.connect(
		_on_card_selection_changed
	)

	return true

func _on_card_selection_changed(
	card,
	is_selected: bool
) -> void:
	if is_selecting_retain_targets:
		_handle_retain_target_selection(card, is_selected)
		return

	card_selection_changed.emit(card, is_selected)


# Used cards are discarded, but are not replaced immediately.
func use_cards(cards: Array) -> void:
	discard_cards(cards)


# Discards every card still in the player's hand.
func discard_hand() -> void:
	var cards_to_discard: Array = []

	for card in hand_cards:
		if not is_instance_valid(card):
			continue

		if card.card_instance.should_retain_at_turn_end():
			card.card_instance.consume_retain()
			card.update_display()
		else:
			cards_to_discard.append(card)

	discard_cards(cards_to_discard)


func choose_cards_to_retain(amount: int) -> int:
	var eligible_cards: Array = _get_retain_eligible_cards()

	retain_targets_required = mini(
		max(amount, 0),
		eligible_cards.size()
	)
	retain_targets_selected = 0

	if retain_targets_required <= 0:
		return 0

	is_selecting_retain_targets = true

	for card in eligible_cards:
		card.disabled = false
		card.set_retain_targeting(true)

	retain_selection_started.emit(retain_targets_required)
	await retain_selection_finished

	return retain_targets_selected


func _handle_retain_target_selection(
	card,
	is_selected: bool
) -> void:
	if not is_selected:
		return

	card.set_pressed_no_signal(false)

	if not is_instance_valid(card):
		return

	if card.card_instance.is_retained_this_turn:
		return

	card.card_instance.retain_for_turn()
	card.set_retain_targeting(false)
	card.update_display()
	card.disabled = true
	retain_targets_selected += 1

	if retain_targets_selected >= retain_targets_required:
		_finish_retain_selection()


func _finish_retain_selection() -> void:
	is_selecting_retain_targets = false

	for card in hand_cards:
		if is_instance_valid(card):
			card.set_retain_targeting(false)

	retain_selection_finished.emit(retain_targets_selected)


func _get_retain_eligible_cards() -> Array:
	var eligible_cards: Array = []

	for card in hand_cards:
		if not is_instance_valid(card):
			continue

		if card.card_instance.should_retain_at_turn_end():
			continue

		eligible_cards.append(card)

	return eligible_cards


func discard_cards(cards: Array) -> void:
	for card in cards:
		if not is_instance_valid(card):
			continue

		discard_pile.append(card.card_instance)
		hand_cards.erase(card)

		if card.get_parent() == $Hand:
			$Hand.remove_child(card)

		card.queue_free()

	update_pile_labels()

func reshuffle_discard_pile() -> void:
	if discard_pile.is_empty():
		return

	draw_pile = discard_pile.duplicate()
	discard_pile.clear()

	draw_pile.shuffle()
	update_pile_labels()


func set_hand_disabled(should_be_disabled: bool) -> void:
	for card in hand_cards:
		if is_instance_valid(card):
			card.disabled = should_be_disabled


func update_pile_labels() -> void:
	$DrawPileLabel.text = (
		"Draw pile: " + str(draw_pile.size())
	)

	$DiscardPileLabel.text = (
		"Discard pile: " + str(discard_pile.size())
	)
