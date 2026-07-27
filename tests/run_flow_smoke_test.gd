extends Node


func _ready() -> void:
	var run_scene: PackedScene = load(
		"res://scenes/run/run_flow.tscn"
	)
	var run_flow: RunFlow = run_scene.instantiate() as RunFlow
	run_flow.transition_duration = 0.01
	add_child(run_flow)

	await get_tree().process_frame

	assert(RunState.current_floor == 1)
	assert(run_flow.current_phase == RunFlow.FlowPhase.BATTLE)

	var player: BattlePlayer = run_flow.active_battle.get_node(
		"Player"
	) as BattlePlayer
	player.take_damage(3)
	assert(RunState.current_health == 27)

	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)

	assert(RunState.current_floor == 2)
	assert(run_flow.current_phase == RunFlow.FlowPhase.BATTLE)
	assert(
		run_flow.active_battle.get_node("Player").health == 27
	)

	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)

	assert(RunState.current_floor == 3)
	assert(run_flow.current_phase == RunFlow.FlowPhase.BATTLE)

	run_flow.active_battle.defeat_enemy()
	await _claim_battle_rewards(run_flow)
	await get_tree().process_frame
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.COMPLETE)
	assert(run_flow.transition_overlay.visible)
	assert(run_flow.restart_button.visible)
	assert(run_flow.restart_button.text == "New Run")
	assert(run_flow.main_menu_button.visible)

	run_flow._on_restart_button_pressed()
	await get_tree().process_frame

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


func _claim_battle_rewards(run_flow: RunFlow) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	assert(run_flow.current_phase == RunFlow.FlowPhase.REWARD)

	var reward_screen: RewardScreen = (
		run_flow.active_reward_screen
	)
	assert(reward_screen != null)
	assert(reward_screen.element_choices.size() == 3)

	var deck_size_before_reward: int = RunState.deck.size()
	assert(
		reward_screen.choose_element_card(
			reward_screen.element_choices[0]
		)
	)
	assert(RunState.deck.size() == deck_size_before_reward + 1)

	var upgrade_target: CardInstance

	for card in RunState.deck:
		if not card.has_upgrade(
			reward_screen.pending_upgrade_id
		):
			upgrade_target = card
			break

	assert(upgrade_target != null)
	assert(reward_screen.select_upgrade_card(upgrade_target))
	assert(reward_screen.confirm_upgrade())
	assert(
		upgrade_target.has_upgrade(
			reward_screen.pending_upgrade_id
		)
	)

	await get_tree().create_timer(0.1).timeout
	await get_tree().process_frame
