class_name BattleEnemy
extends BattleCombatant


signal target_requested(enemy: BattleEnemy)


@export var enemy_data: EnemyData


var current_move_index: int = 0


func _ready() -> void:
	if has_node("TargetButton"):
		$TargetButton.pressed.connect(_on_target_button_pressed)

	# EnemyData may be assigned later by Battle.
	if enemy_data != null:
		setup(enemy_data)


func setup(new_enemy_data: EnemyData) -> void:
	if new_enemy_data == null:
		push_error("Enemy setup received null EnemyData.")
		return

	enemy_data = new_enemy_data
	var scaled_maximum_health := maxi(
		roundi(
			enemy_data.maximum_health
			* RunState.get_enemy_health_multiplier()
		),
		1
	)
	configure_health(
		scaled_maximum_health,
		scaled_maximum_health
	)
	current_move_index = 0

	show()

	var status_controller: StatusController = get_node_or_null(
		"StatusController"
	) as StatusController

	if status_controller != null:
		status_controller.clear_statuses()

	update_artwork()
	update_name_text()
	update_health_text()
	update_intent_text()


func get_display_name() -> String:
	if enemy_data == null:
		return "Enemy"

	return enemy_data.display_name


func get_current_move() -> EnemyMoveData:
	if enemy_data == null:
		return null

	if enemy_data.moves.is_empty():
		return null

	if current_move_index >= enemy_data.moves.size():
		current_move_index = 0

	return enemy_data.moves[current_move_index]


func get_intent_text() -> String:
	var move: EnemyMoveData = get_current_move()

	if move == null:
		return "Intent: No move"

	var result: String = "Intent: " + move.intent_text
	var property_names: Array[String] = (
		move.get_property_display_names()
	)

	if not property_names.is_empty():
		result += "\nProperties: " + ", ".join(property_names)

	return result


func perform_turn(
	player: Node,
	effect_resolver: CombatEffectResolver,
	all_enemies: Array = []
) -> Dictionary:
	var move: EnemyMoveData = get_current_move()

	if move == null:
		return {
			"move_name": "No Move",
			"messages": [get_display_name() + " did nothing."]
		}

	var action_outcome: StringName = (
		$StatusController.resolve_action_attempt(move.is_attack())
	)

	if action_outcome == &"stunned":
		return {
			"move_name": "Stunned",
			"messages": [
				get_display_name()
				+ " is stunned and does nothing."
			],
			"total_health_damage": 0,
			"action_skipped": true
		}

	if action_outcome == &"frozen":
		return {
			"move_name": "Frozen",
			"messages": [
				get_display_name()
				+ " is frozen and does nothing."
			],
			"total_health_damage": 0,
			"action_skipped": true
		}

	if action_outcome == &"missed":
		if combat_events != null:
			combat_events.attack_completed.emit(
				self,
				player,
				move,
				false,
				0
			)

		advance_move()

		return {
			"move_name": move.move_name,
			"messages": [
				get_display_name()
				+ " is dazed and misses the attack."
			],
			"total_health_damage": 0,
			"attack_missed": true
		}

	if (
		move.is_attack()
		and player.has_method("consume_dodge")
		and bool(player.consume_dodge())
	):
		if combat_events != null:
			combat_events.attack_completed.emit(
				self,
				player,
				move,
				false,
				0
			)

		advance_move()

		return {
			"move_name": move.move_name,
			"messages": ["You dodged the attack."],
			"total_health_damage": 0,
			"attack_missed": true,
			"attack_dodged": true
		}

	var context := CombatContext.create(
		player,
		all_enemies if not all_enemies.is_empty() else [self],
		self,
		effect_resolver.combat_deck,
		effect_resolver.battle_modifiers
	)
	var action := move.create_action(self, player)
	var typed_result := await effect_resolver.resolve_action(
		action,
		context
	)
	var result := typed_result.to_dictionary()

	var messages: Array = result.get("messages", [])

	if move.is_attack() and combat_events != null:
		combat_events.attack_completed.emit(
			self,
			player,
			move,
			true,
			int(result.get("total_health_damage", 0))
		)

	if not move.action_text.is_empty():
		messages.push_front(move.action_text)

	advance_move()

	return {
		"move_name": move.move_name,
		"messages": messages,
		"total_health_damage": int(
			result.get("total_health_damage", 0)
		)
	}


func advance_move() -> void:
	if enemy_data == null or enemy_data.moves.is_empty():
		current_move_index = 0
		update_intent_text()
		return

	current_move_index = (
		current_move_index + 1
	) % enemy_data.moves.size()

	update_intent_text()


func _on_defeated(_context: Dictionary) -> void:
	hide()


func set_target_selected(is_selected: bool) -> void:
	if not has_node("TargetButton"):
		return

	$TargetButton.text = (
		"SELECTED" if is_selected else "Target"
	)
	$TargetButton.disabled = health <= 0


func _on_target_button_pressed() -> void:
	if health > 0:
		target_requested.emit(self)


func update_artwork() -> void:
	var enemy_image: Sprite2D = get_node_or_null(
		"EnemyImage"
	) as Sprite2D

	if enemy_image == null:
		return

	if enemy_data == null:
		enemy_image.texture = null
		return

	enemy_image.texture = enemy_data.artwork


func update_name_text() -> void:
	var name_label: Label = get_node_or_null(
		"NameLabel"
	) as Label

	if name_label != null:
		name_label.text = get_display_name()


func update_health_text() -> void:
	var health_label: Label = get_node_or_null(
		"HealthLabel"
	) as Label

	if health_label == null:
		return

	health_label.text = (
		"Health: "
		+ str(health)
		+ " / "
		+ str(get_maximum_health())
	)


func update_intent_text() -> void:
	var intent_label: Label = get_node_or_null(
		"IntentLabel"
	) as Label

	if intent_label != null:
		intent_label.text = get_intent_text()
