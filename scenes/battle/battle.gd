extends Node2D


var selected_cards: Array = []
var current_spell: Dictionary = {}

@export var encounter_data: EncounterData


@onready var battle_controller: BattleController = $BattleController


func setup_encounter() -> void:
	if encounter_data == null:
		push_warning("Battle has no EncounterData assigned.")
		return

	if encounter_data.get_enemy_roster().is_empty():
		push_error("EncounterData has no enemies assigned.")
		return

	battle_controller.setup(
		$Player,
		$Enemy,
		$CombatDeck,
		$CombatEffectResolver,
		$BattleModifierController,
		$CombatEvents,
		encounter_data
	)

func _ready() -> void:
	setup_encounter()
	$PlayerHUD.bind_player($Player)

	if not $BattleModifierController.modifiers_changed.is_connected(
		_update_arena_status_label
	):
		$BattleModifierController.modifiers_changed.connect(
			_update_arena_status_label
		)

	_update_arena_status_label()

	if not battle_controller.target_changed.is_connected(
		_on_target_changed
	):
		battle_controller.target_changed.connect(_on_target_changed)

	$VictoryLabel.hide()
	$DefeatLabel.hide()

	$TurnLabel.text = "Starting battle..."
	$CombinationLabel.text = "Select up to three elements"

	$CastButton.disabled = true
	$EndTurnButton.disabled = true

	if not $CombatDeck.card_selection_changed.is_connected(
		_on_card_selection_changed
	):
		$CombatDeck.card_selection_changed.connect(
			_on_card_selection_changed
		)

	if not $CombatDeck.retain_selection_started.is_connected(
		_on_retain_selection_started
	):
		$CombatDeck.retain_selection_started.connect(
			_on_retain_selection_started
		)

	if not $TurnManager.player_turn_started.is_connected(
		_on_player_turn_started
	):
		$TurnManager.player_turn_started.connect(
			_on_player_turn_started
		)

	if not $TurnManager.enemy_turn_started.is_connected(
		_on_enemy_turn_started
	):
		$TurnManager.enemy_turn_started.connect(
			_on_enemy_turn_started
		)

	if not $Player.defeated.is_connected(
		_on_player_defeated
	):
		$Player.defeated.connect(
			_on_player_defeated
		)

	if not $CastButton.pressed.is_connected(
		_on_cast_button_pressed
	):
		$CastButton.pressed.connect(
			_on_cast_button_pressed
		)

	if not $EndTurnButton.pressed.is_connected(
		_on_end_turn_button_pressed
	):
		$EndTurnButton.pressed.connect(
			_on_end_turn_button_pressed
		)
	
	$CombatDeck.start_battle()
	$TurnManager.start_battle()


func _update_arena_status_label() -> void:
	$ArenaStatusLabel.text = (
		$BattleModifierController.get_display_text()
	)


func _on_player_turn_started() -> void:
	print("Battle received player_turn_started")

	battle_controller.begin_player_turn()

	$TurnLabel.text = "Your Turn"
	$EndTurnButton.disabled = false
	$CombatDeck.set_hand_disabled(false)
	$CombinationLabel.text = "Select up to three elements"
	$CombinationLabel.text = (
		"Select up to three elements\n\n"
		+ battle_controller.get_intent_text()
	)


func _on_target_changed(_enemy: BattleEnemy) -> void:
	update_spell_preview()



func _on_card_selection_changed(
	card,
	is_selected: bool
) -> void:
	if not $TurnManager.is_player_turn():
		card.set_pressed_no_signal(false)
		return

	if is_selected:
		if selected_cards.size() >= 3:
			card.set_pressed_no_signal(false)
			return

		if not selected_cards.has(card):
			selected_cards.append(card)
	else:
		selected_cards.erase(card)

	update_spell_preview()


func get_selected_energy_cost() -> int:
	if not current_spell.get("valid", false):
		return 0

	var spell_data := current_spell.get("spell_data") as SpellData

	if spell_data == null:
		return 0

	var total_cost: int = spell_data.energy_cost

	for card_index in range(selected_cards.size()):
		var card = selected_cards[card_index]

		if is_instance_valid(card):
			total_cost += card.get_spell_cost_modifier(card_index)

	return $Player.get_spell_energy_cost(maxi(total_cost, 0))


func _on_retain_selection_started(cards_required: int) -> void:
	$CastButton.disabled = true
	$EndTurnButton.disabled = true
	$CombinationLabel.text = (
		"Choose "
		+ str(cards_required)
		+ (
			" card to Retain."
			if cards_required == 1
			else " cards to Retain."
		)
	)


func update_spell_preview() -> void:
	current_spell = {}
	$CastButton.disabled = true

	if selected_cards.is_empty():
		$CombinationLabel.text = (
			"Select up to three elements\n\n"
			+ battle_controller.get_intent_text()
		)
		return

	var recipe_element_names: Array[String] = []
	var display_element_names: Array[String] = []

	for card_index in range(selected_cards.size()):
		var card: Variant = selected_cards[card_index]
		var element_name: String = str(card.get_element_name())
		var element_display: String = element_name
		var active_upgrades: Array[String] = (
			card.card_instance.get_active_cast_upgrade_names(
				card_index
			)
		)

		recipe_element_names.append(element_name)

		if not active_upgrades.is_empty():
			element_display += (
				" ["
				+ ", ".join(active_upgrades)
				+ " active]"
			)

		display_element_names.append(element_display)

	var combination_text: String = " + ".join(
		display_element_names
	)

	if selected_cards.size() == 1:
		$CombinationLabel.text = (
			"Selected: "
			+ combination_text
			+ "\nSelect up to two more elements"
		)
		return

	current_spell = $SpellResolver.resolve_elements(
		recipe_element_names
	)

	if not current_spell.get("valid", false):
		if selected_cards.size() < 3:
			$CombinationLabel.text = (
				"Selected: "
				+ combination_text
				+ "\nNo two-element spell found."
				+ "\nSelect one more element"
			)
		else:
			$CombinationLabel.text = (
				combination_text
				+ "\n"
				+ str(
					current_spell.get(
						"description",
						"These elements do not combine."
					)
				)
			)
		return

	var total_energy_cost: int = get_selected_energy_cost()

	$CombinationLabel.text = (
		combination_text
		+ "\nCreates: "
		+ str(current_spell["name"])
		+ "\n"
		+ str(current_spell["description"])
		+ "\nEnergy cost: "
		+ str(total_energy_cost)
	)

	if $Player.can_spend_energy(total_energy_cost):
		$CastButton.disabled = false
	else:
		$CombinationLabel.text += (
			"\nNot enough energy!"
			+ "\nCurrent energy: "
			+ str($Player.energy)
		)


func _on_cast_button_pressed() -> void:
	if not $TurnManager.is_player_turn():
		return

	if current_spell.is_empty():
		return

	if not current_spell.get("valid", false):
		return

	var energy_cost: int = get_selected_energy_cost()

	if not $Player.spend_energy(energy_cost):
		update_spell_preview()
		return

	var spell_name: String = str(current_spell["name"])
	var spell_data := current_spell.get("spell_data") as SpellData

	if spell_data == null:
		push_error("Resolved spell is missing SpellData.")
		return

	var card_upgrade_effects: Array = []
	var used_cards: Array = selected_cards.duplicate()
	var used_card_instances: Array[CardInstance] = []

	for card_index in range(used_cards.size()):
		var card = used_cards[card_index]

		if is_instance_valid(card):
			used_card_instances.append(card.card_instance)
			card_upgrade_effects.append_array(
				card.card_instance.get_on_use_effects(card_index)
			)

	# Used cards leave the hand before Draw or Retain effects resolve.
	# This prevents a spell from retaining either card spent to cast it.
	clear_selection()
	$CombatDeck.use_cards(used_cards)

	var typed_result := await battle_controller.resolve_player_spell(
		spell_data,
		used_card_instances,
		card_upgrade_effects
	)
	var result := typed_result.to_dictionary()

	var result_text: String = "Cast " + spell_name + "!"
	var messages: Array = result.get("messages", [])

	for message in messages:
		result_text += "\n" + str(message)

	result_text += (
		"\nEnergy remaining: " + str($Player.energy)
	)

	$CombinationLabel.text = result_text

	if battle_controller.all_enemies_defeated():
		defeat_enemy()
	else:
		$EndTurnButton.disabled = false
		$CombatDeck.set_hand_disabled(false)


func _on_end_turn_button_pressed() -> void:
	if not $TurnManager.is_player_turn():
		return

	clear_selection()
	$CombatDeck.discard_hand()

	$CombatDeck.set_hand_disabled(true)
	$CastButton.disabled = true
	$EndTurnButton.disabled = true

	battle_controller.finish_player_turn()

	if $Player.health <= 0:
		return

	$TurnManager.end_player_turn()


func _on_enemy_turn_started() -> void:
	print("Battle received enemy_turn_started")

	$TurnLabel.text = "Enemy Turn"
	$CombatDeck.set_hand_disabled(true)
	$CastButton.disabled = true
	$EndTurnButton.disabled = true

	for enemy in battle_controller.get_living_enemies():
		$CombinationLabel.text = (
			enemy.get_display_name()
			+ "\n"
			+ enemy.get_intent_text()
		)

		await get_tree().create_timer(0.75).timeout

		if $TurnManager.is_battle_over():
			return

		var turn_result := await (
			battle_controller.execute_enemy_turn(enemy)
		)
		var result_text := str(
			turn_result.get("move_name", "Enemy Move")
		)
		var messages: Array = turn_result.get("messages", [])

		for message in messages:
			result_text += "\n" + str(message)

		$CombinationLabel.text = result_text

		if $Player.health <= 0:
			return

		if battle_controller.all_enemies_defeated():
			defeat_enemy()
			return

		await get_tree().create_timer(0.5).timeout

		if $TurnManager.is_battle_over():
			return

	battle_controller.finish_enemy_round()
	$TurnManager.finish_enemy_turn()



func clear_selection() -> void:
	for card in selected_cards:
		if is_instance_valid(card):
			card.set_pressed_no_signal(false)

	selected_cards.clear()
	current_spell = {}
	$CastButton.disabled = true


func defeat_enemy() -> void:
	$TurnManager.end_battle()
	$CombatEvents.battle_ended.emit(
		&"victory",
		$Player,
		battle_controller.get_enemies()
	)

	clear_selection()
	$CombatDeck.set_hand_disabled(true)
	$CastButton.disabled = true
	$EndTurnButton.disabled = true

	$TurnLabel.text = "Battle Won"
	$CombinationLabel.text = "The enemy was defeated!"
	$VictoryLabel.show()


func _on_player_defeated() -> void:
	$TurnManager.end_battle()
	$CombatEvents.battle_ended.emit(
		&"defeat",
		battle_controller.get_living_enemies(),
		$Player
	)

	clear_selection()
	$CombatDeck.set_hand_disabled(true)
	$CastButton.disabled = true
	$EndTurnButton.disabled = true

	$TurnLabel.text = "Battle Lost"
	$CombinationLabel.text = "You were defeated."
	$DefeatLabel.show()
