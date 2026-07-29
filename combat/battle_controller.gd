class_name BattleController
extends Node


signal target_changed(enemy: BattleEnemy)


const ENEMY_SCENE: PackedScene = preload(
	"res://scenes/enemies/enemy.tscn"
)


var player: BattlePlayer
var combat_deck: CombatDeck
var effect_resolver: CombatEffectResolver
var battle_modifiers: BattleModifierController
var combat_events: CombatEvents
var enemies: Array[BattleEnemy] = []
var selected_enemy: BattleEnemy


func setup(
	player_combatant: BattlePlayer,
	first_enemy: BattleEnemy,
	deck: CombatDeck,
	resolver: CombatEffectResolver,
	modifiers: BattleModifierController,
	events: CombatEvents,
	encounter: EncounterData
) -> bool:
	player = player_combatant
	combat_deck = deck
	effect_resolver = resolver
	battle_modifiers = modifiers
	combat_events = events

	if (
		player == null
		or first_enemy == null
		or encounter == null
	):
		push_error("BattleController setup is missing required data.")
		return false

	var roster := encounter.get_enemy_roster()

	if roster.is_empty():
		push_error("Encounter has no enemies.")
		return false

	enemies.clear()
	player.set_combat_events(combat_events)
	_setup_enemy(first_enemy, roster[0], 0)

	for index in range(1, roster.size()):
		var enemy := ENEMY_SCENE.instantiate() as BattleEnemy

		if enemy == null:
			continue

		enemy.name = "Enemy" + str(index + 1)
		get_parent().add_child(enemy)
		_setup_enemy(enemy, roster[index], index)

	_layout_enemies()
	select_target(get_first_living_enemy())

	battle_modifiers.setup(
		combat_events,
		player,
		enemies
	)
	effect_resolver.setup(combat_deck, battle_modifiers)

	combat_events.battle_started.emit(
		player,
		enemies.duplicate(),
		encounter
	)
	return true


func _setup_enemy(
	enemy: BattleEnemy,
	enemy_data: EnemyData,
	_index: int
) -> void:
	enemy.set_combat_events(combat_events)
	enemy.setup(enemy_data)
	enemies.append(enemy)

	if not enemy.target_requested.is_connected(select_target):
		enemy.target_requested.connect(select_target)


func _layout_enemies() -> void:
	var count := enemies.size()
	var spacing := 110.0
	var starting_offset := -spacing * float(count - 1) / 2.0

	for index in range(count):
		enemies[index].position.x = (
			starting_offset + spacing * index
		)


func select_target(enemy: BattleEnemy) -> void:
	if (
		enemy == null
		or not enemies.has(enemy)
		or enemy.health <= 0
	):
		return

	selected_enemy = enemy

	for battle_enemy in enemies:
		battle_enemy.set_target_selected(
			battle_enemy == selected_enemy
		)

	target_changed.emit(selected_enemy)


func refresh_selected_target() -> void:
	if (
		selected_enemy != null
		and is_instance_valid(selected_enemy)
		and selected_enemy.health > 0
	):
		return

	select_target(get_first_living_enemy())


func get_enemies() -> Array[BattleEnemy]:
	return enemies.duplicate()


func get_living_enemies() -> Array[BattleEnemy]:
	var result: Array[BattleEnemy] = []

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.health > 0:
			result.append(enemy)

	return result


func get_first_living_enemy() -> BattleEnemy:
	var living_enemies := get_living_enemies()

	if living_enemies.is_empty():
		return null

	return living_enemies[0]


func all_enemies_defeated() -> bool:
	return get_living_enemies().is_empty()


func get_intent_text() -> String:
	var living_enemies := get_living_enemies()

	if living_enemies.is_empty():
		return "No enemies remain."

	var lines: Array[String] = []

	for enemy in living_enemies:
		var marker := (
			" [TARGET]" if enemy == selected_enemy else ""
		)
		lines.append(
			enemy.get_display_name()
			+ marker
			+ ": "
			+ enemy.get_intent_text().trim_prefix("Intent: ")
		)

	return "\n".join(lines)


func begin_player_turn() -> int:
	player.process_statuses_at_turn_start()
	combat_events.turn_started.emit(player)
	player.start_turn()
	combat_deck.draw_turn_hand()

	var bonus_draw := player.consume_next_turn_draw_bonus()

	if bonus_draw > 0:
		combat_deck.draw_cards(bonus_draw)

	return bonus_draw


func finish_player_turn() -> void:
	combat_events.turn_ended.emit(player)
	player.process_statuses_at_turn_end()
	battle_modifiers.process_side_turn_end(&"player")


func resolve_player_spell(
	spell: SpellData,
	used_cards: Array[CardInstance],
	card_upgrade_effects: Array
) -> CombatResult:
	var combined_result := CombatResult.new()

	if spell == null or selected_enemy == null:
		return combined_result

	for card in used_cards:
		combat_events.card_used.emit(player, card)

	var spell_snapshot := spell.to_result_dictionary()
	combat_events.spell_cast.emit(
		player,
		spell_snapshot,
		used_cards
	)
	player.process_successful_spell_cast()

	var context := _create_context(selected_enemy)

	if not card_upgrade_effects.is_empty():
		var upgrade_action := CombatAction.new()
		upgrade_action.action_id = &"card_upgrades"
		upgrade_action.display_name = "Card Upgrades"
		upgrade_action.caster = player
		upgrade_action.primary_target = selected_enemy

		for effect_value in card_upgrade_effects:
			if effect_value is CombatEffectData:
				upgrade_action.effects.append(effect_value)

		var upgrade_result := await effect_resolver.resolve_action(
			upgrade_action,
			context
		)
		combined_result.merge(upgrade_result)

	var spell_action := spell.create_action(
		player,
		selected_enemy
	)
	var spell_result := await effect_resolver.resolve_action(
		spell_action,
		context
	)
	combined_result.merge(spell_result)

	if spell_action.includes_damage():
		for damaged_target in combined_result.damage_by_target:
			combat_events.attack_completed.emit(
				player,
				damaged_target,
				spell,
				true,
				int(
					combined_result.damage_by_target[
						damaged_target
					]
				)
			)

	refresh_selected_target()
	return combined_result


func execute_enemy_turn(enemy: BattleEnemy) -> Dictionary:
	if enemy == null or enemy.health <= 0:
		return {}

	enemy.process_statuses_at_turn_start()
	combat_events.turn_started.emit(enemy)

	if enemy.health <= 0:
		refresh_selected_target()
		return {
			"move_name": enemy.get_display_name(),
			"messages": ["Status damage defeated the enemy."]
		}

	var result := await enemy.perform_turn(
		player,
		effect_resolver,
		get_living_enemies()
	)

	if player.health > 0:
		combat_events.turn_ended.emit(enemy)
		enemy.process_statuses_at_turn_end()

	refresh_selected_target()
	return result


func finish_enemy_round() -> void:
	battle_modifiers.process_side_turn_end(&"enemy")


func _create_context(
	primary_enemy: BattleEnemy
) -> CombatContext:
	return CombatContext.create(
		player,
		get_living_enemies(),
		primary_enemy,
		combat_deck,
		battle_modifiers
	)
