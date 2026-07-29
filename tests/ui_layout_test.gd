extends Node


const VIEWPORT_SIZE := Vector2(640.0, 360.0)


func _ready() -> void:
	assert(get_viewport().get_visible_rect().size == VIEWPORT_SIZE)

	await _test_main_menu()
	await _test_battle_layout()
	await _test_reward_layout()
	await _test_map_layout()

	print("640x360 UI layout test passed.")
	get_tree().quit()


func _test_main_menu() -> void:
	var menu_scene: PackedScene = load(
		"res://scenes/menu/main_menu.tscn"
	)
	var menu := menu_scene.instantiate() as Control

	add_child(menu)
	await get_tree().process_frame
	_assert_inside_viewport(menu.get_node("Center/Menu"))
	await _save_capture("ui_main_menu.png")
	menu.queue_free()
	await get_tree().process_frame


func _test_battle_layout() -> void:
	RunState.start_new_run()

	var battle_scene: PackedScene = load(
		"res://scenes/battle/battle.tscn"
	)
	var battle := battle_scene.instantiate() as Node2D
	var encounter := EncounterData.new()

	encounter.encounter_id = &"ui_layout_encounter"
	encounter.display_name = "UI Layout Encounter"
	encounter.enemies = [
		ContentCatalog.SKELETON_DATA,
		ContentCatalog.ZOMBIE_DATA
	]
	battle.encounter_data = encounter

	add_child(battle)
	await get_tree().process_frame
	await get_tree().process_frame

	var hand := battle.get_node(
		"CombatDeck/Hand"
	) as HBoxContainer

	_assert_inside_viewport(hand)

	for card in hand.get_children():
		_assert_inside_viewport(card as Control)
		assert((card as Control).tooltip_text != "")

	var combination := battle.get_node(
		"CombinationLabel"
	) as HoverExpandLabel
	combination.text = (
		"A deliberately long spell preview that should remain "
		+ "available in full when the compact label is hovered."
	)
	await get_tree().process_frame
	assert(combination.tooltip_text == combination.text)

	var tooltip := combination._make_custom_tooltip(
		combination.tooltip_text
	) as PanelContainer
	assert(tooltip != null)
	assert(tooltip.get_child(0).text == combination.text)
	tooltip.free()

	_assert_sprite_inside_viewport(
		battle.get_node("Player/PlayerImage") as Sprite2D
	)
	var controller := battle.get_node(
		"BattleController"
	) as BattleController

	for enemy in controller.get_enemies():
		_assert_sprite_inside_viewport(
			enemy.get_node("EnemyImage") as Sprite2D
		)
		_assert_inside_viewport(
			enemy.get_node("TargetButton") as Control
		)
	await _save_capture("ui_battle.png")
	battle.queue_free()
	await get_tree().process_frame


func _test_reward_layout() -> void:
	RunState.start_new_run()

	var reward_scene: PackedScene = load(
		"res://scenes/rewards/reward_screen.tscn"
	)
	var reward := reward_scene.instantiate() as RewardScreen

	add_child(reward)
	reward.begin_rewards()
	await get_tree().process_frame

	_assert_inside_viewport(reward)

	for choice in reward.element_choice_container.get_children():
		_assert_inside_viewport(choice as Control)
		assert((choice as Control).tooltip_text != "")

	await _save_capture("ui_rewards.png")
	reward.queue_free()
	await get_tree().process_frame


func _test_map_layout() -> void:
	RunState.start_new_run()

	var level := load(
		"res://Data/levels/first_level.tres"
	) as LevelData
	assert(level != null)
	assert(RunState.initialize_leyline_map(level.leyline_map))

	var map_scene: PackedScene = load(
		"res://scenes/map/leyline_map_screen.tscn"
	)
	var map_screen := map_scene.instantiate() as LeylineMapScreen

	add_child(map_screen)
	map_screen.setup(level.leyline_map)
	await get_tree().process_frame
	await get_tree().process_frame

	for button_value in map_screen.location_buttons.values():
		var button := button_value as Control

		_assert_inside_viewport(button)
		assert(button.tooltip_text != "")
		assert(button.get_global_rect().end.y < 294.0)

	await _save_capture("ui_map.png")
	map_screen.queue_free()
	await get_tree().process_frame


func _assert_inside_viewport(control: Control) -> void:
	assert(control != null)

	var rect := control.get_global_rect()

	assert(rect.position.x >= 0.0)
	assert(rect.position.y >= 0.0)
	assert(rect.end.x <= VIEWPORT_SIZE.x)
	assert(rect.end.y <= VIEWPORT_SIZE.y)


func _assert_sprite_inside_viewport(sprite: Sprite2D) -> void:
	assert(sprite != null)

	if sprite.texture == null:
		assert(sprite.global_position.x >= 0.0)
		assert(sprite.global_position.y >= 0.0)
		assert(sprite.global_position.x <= VIEWPORT_SIZE.x)
		assert(sprite.global_position.y <= VIEWPORT_SIZE.y)
		return

	var texture_size := sprite.texture.get_size() * sprite.scale
	var rect := Rect2(
		sprite.global_position - texture_size / 2.0,
		texture_size
	)

	assert(rect.position.x >= 0.0)
	assert(rect.position.y >= 0.0)
	assert(rect.end.x <= VIEWPORT_SIZE.x)
	assert(rect.end.y <= VIEWPORT_SIZE.y)


func _save_capture(file_name: String) -> void:
	await get_tree().process_frame

	if DisplayServer.get_name() == "headless":
		return

	var viewport_texture := get_viewport().get_texture()

	if viewport_texture == null:
		return

	var image := viewport_texture.get_image()

	if image == null:
		return

	assert(
		image.save_png("res://.godot/" + file_name)
			== OK
	)
