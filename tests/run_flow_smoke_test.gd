extends Node


func _ready() -> void:
	var run_scene: PackedScene = load(
		"res://scenes/run/run_flow.tscn"
	)
	var run_flow: RunFlow = run_scene.instantiate() as RunFlow
	add_child(run_flow)

	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)
	assert(run_flow.active_map_screen != null)
	assert(RunState.current_map_location_id == &"astral_sanctum")
	assert(RunState.closed_rifts == 0)
	assert(RunState.instability == 0)
	assert(
		not RunState.can_travel_to(
			run_flow.level_data.leyline_map,
			&"final_convergence"
		)
	)

	await _travel_to_battle(run_flow, &"drowned_rift")
	var player: BattlePlayer = run_flow.active_battle.get_node(
		"Player"
	) as BattlePlayer
	player.take_damage(10)
	assert(RunState.current_health == 20)
	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)
	assert(RunState.closed_rifts == 1)

	await _travel_to_battle(run_flow, &"shattered_crossing")
	assert(
		run_flow.active_battle.get_node("Player").health == 20
	)
	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)

	await _travel_to_battle(run_flow, &"gale_rift")
	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)
	assert(RunState.closed_rifts == 2)

	await _travel_to_map(run_flow, &"whispering_sanctuary")
	assert(RunState.current_health == 28)
	assert(
		RunState.is_map_location_completed(
			&"whispering_sanctuary"
		)
	)

	await _travel_to_battle(run_flow, &"storm_rift")
	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)
	assert(RunState.closed_rifts == 3)
	assert(
		RunState.can_travel_to(
			run_flow.level_data.leyline_map,
			&"final_convergence"
		)
	)

	await _travel_to_battle(run_flow, &"final_convergence")
	assert(
		run_flow.active_battle.battle_controller.get_enemies().size()
		== 2
	)
	run_flow.active_battle.defeat_enemy()
	await get_tree().process_frame
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.COMPLETE)
	assert(run_flow.transition_overlay.visible)
	assert(run_flow.restart_button.visible)
	assert(run_flow.restart_button.text == "New Run")
	assert(run_flow.main_menu_button.visible)

	run_flow._on_restart_button_pressed()
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)
	assert(RunState.closed_rifts == 0)
	assert(RunState.instability == 0)

	await _travel_to_battle(run_flow, &"drowned_rift")
	var restarted_player: BattlePlayer = (
		run_flow.active_battle.get_node("Player") as BattlePlayer
	)
	restarted_player.defeat_immediately()

	await get_tree().process_frame
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.DEFEAT)
	assert(run_flow.restart_button.visible)
	assert(run_flow.restart_button.text == "New Run")
	assert(run_flow.main_menu_button.visible)

	print("Run flow smoke test passed.")
	get_tree().quit()


func _travel_to_battle(
	run_flow: RunFlow,
	location_id: StringName
) -> void:
	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)
	run_flow.active_map_screen.location_selected.emit(location_id)
	await get_tree().process_frame
	assert(run_flow.current_phase == RunFlow.FlowPhase.BATTLE)
	assert(run_flow.active_battle != null)


func _travel_to_map(
	run_flow: RunFlow,
	location_id: StringName
) -> void:
	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)
	run_flow.active_map_screen.location_selected.emit(location_id)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)


func _claim_battle_rewards(run_flow: RunFlow) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.REWARD)

	var reward_screen: RewardScreen = (
		run_flow.active_reward_screen
	)
	assert(reward_screen != null)
	assert(reward_screen.element_choices.size() == 3)

	if run_flow.active_map_location.elemental_affinity != &"":
		var found_affinity: bool = false

		for card_data in reward_screen.element_choices:
			if (
				card_data.element_name.to_lower()
				== String(
					run_flow.active_map_location.elemental_affinity
				).to_lower()
			):
				found_affinity = true
				break

		assert(found_affinity)

	assert(
		reward_screen.choose_element_card(
			reward_screen.element_choices[0]
		)
	)

	if reward_screen.pending_upgrade_id != &"":
		assert(reward_screen.skip_upgrade_reward())

	await get_tree().process_frame
	await get_tree().process_frame
	assert(run_flow.current_phase == RunFlow.FlowPhase.MAP)
