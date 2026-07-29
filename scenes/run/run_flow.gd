class_name RunFlow
extends Node


enum FlowPhase {
	BATTLE,
	REWARD,
	MAP,
	TRANSITION,
	COMPLETE,
	DEFEAT
}


const BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/battle.tscn"
)
const REWARD_SCREEN_SCENE: PackedScene = preload(
	"res://scenes/rewards/reward_screen.tscn"
)
const LEYLINE_MAP_SCENE: PackedScene = preload(
	"res://scenes/map/leyline_map_screen.tscn"
)
const MAIN_MENU_SCENE_PATH: String = (
	"res://scenes/menu/main_menu.tscn"
)


@export var level_data: LevelData
@export var transition_duration: float = 1.5


var current_phase: FlowPhase = FlowPhase.TRANSITION
var active_battle: Node2D
var active_reward_screen: RewardScreen
var active_map_screen: LeylineMapScreen
var active_map_location: LeylineLocationData


@onready var battle_container: Node = $BattleContainer
@onready var floor_label: Label = $Interface/FloorLabel
@onready var transition_overlay: ColorRect = (
	$Interface/TransitionOverlay
)
@onready var transition_label: Label = (
	$Interface/TransitionOverlay/MessageLabel
)
@onready var restart_button: Button = (
	$Interface/TransitionOverlay/RestartButton
)
@onready var main_menu_button: Button = (
	$Interface/TransitionOverlay/MainMenuButton
)


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	if level_data == null or level_data.leyline_map == null:
		push_error("RunFlow requires a LevelData with a leyline map.")
		_show_terminal_message("No leyline map is configured.")
		return

	if not RunState.is_run_active:
		RunState.start_new_run()

	RunState.set_current_floor(1)

	if not RunState.initialize_leyline_map(level_data.leyline_map):
		push_error("The leyline map has no valid starting location.")
		_show_terminal_message("The leyline map could not be opened.")
		return

	transition_overlay.hide()
	restart_button.hide()
	main_menu_button.hide()
	_begin_map_phase()


func _start_current_battle() -> void:
	var encounter: EncounterData

	if active_map_location != null:
		encounter = active_map_location.encounter

	if encounter == null:
		push_error("The selected map location has no encounter.")
		_show_terminal_message("This location has no encounter.")
		return

	current_phase = FlowPhase.BATTLE
	_update_run_label()
	_clear_map_screen()

	var new_battle: Node2D = BATTLE_SCENE.instantiate() as Node2D

	if new_battle == null:
		push_error("Could not instantiate the battle scene.")
		_show_terminal_message("The battle could not be loaded.")
		return

	new_battle.encounter_data = encounter

	var combat_events: CombatEvents = new_battle.get_node(
		"CombatEvents"
	) as CombatEvents

	combat_events.battle_ended.connect(_on_battle_ended)

	active_battle = new_battle
	battle_container.add_child(active_battle)


func _on_battle_ended(
	result: StringName,
	_winner: Variant,
	_loser: Variant
) -> void:
	if current_phase != FlowPhase.BATTLE:
		return

	if result == &"victory":
		RunState.complete_map_location(active_map_location)

		if (
			active_map_location != null
			and active_map_location.location_type
				== LeylineLocationData.LocationType.BOSS
		):
			call_deferred("_show_level_complete")
		else:
			call_deferred("_begin_reward_phase")
	else:
		call_deferred("_show_run_defeat")


func _begin_reward_phase() -> void:
	current_phase = FlowPhase.REWARD
	_clear_active_battle()

	var new_reward_screen: RewardScreen = (
		REWARD_SCREEN_SCENE.instantiate() as RewardScreen
	)

	if new_reward_screen == null:
		push_error("Could not instantiate the reward screen.")
		_begin_map_phase()
		return

	active_reward_screen = new_reward_screen
	$Interface.add_child(active_reward_screen)
	active_reward_screen.rewards_completed.connect(
		_on_rewards_completed
	)
	var affinity: StringName = &""

	if active_map_location != null:
		affinity = active_map_location.elemental_affinity

	active_reward_screen.begin_rewards(affinity)


func _on_rewards_completed() -> void:
	_clear_reward_screen()
	call_deferred("_begin_map_phase")


func _begin_map_phase() -> void:
	current_phase = FlowPhase.MAP
	_clear_active_battle()
	_clear_reward_screen()
	_clear_map_screen()
	transition_overlay.hide()
	_update_run_label()

	var new_map_screen := (
		LEYLINE_MAP_SCENE.instantiate() as LeylineMapScreen
	)

	if new_map_screen == null:
		push_error("Could not instantiate the leyline map.")
		_show_terminal_message("The leyline map could not be loaded.")
		return

	active_map_screen = new_map_screen
	active_map_screen.setup(level_data.leyline_map)
	active_map_screen.location_selected.connect(
		_on_map_location_selected
	)
	$Interface.add_child(active_map_screen)


func _on_map_location_selected(location_id: StringName) -> void:
	if current_phase != FlowPhase.MAP:
		return

	var destination := level_data.leyline_map.find_location(
		location_id
	)

	if (
		destination == null
		or not RunState.travel_to_map_location(
			level_data.leyline_map,
			location_id
		)
	):
		return

	active_map_location = destination

	if RunState.is_map_location_completed(location_id):
		call_deferred("_begin_map_phase")
		return

	match destination.location_type:
		LeylineLocationData.LocationType.REST:
			var healing: int = mini(
				8,
				RunState.maximum_health - RunState.current_health
			)
			RunState.set_current_health(
				RunState.current_health + healing
			)
			RunState.complete_map_location(destination)
			call_deferred("_begin_map_phase")
		LeylineLocationData.LocationType.START:
			RunState.complete_map_location(destination)
			call_deferred("_begin_map_phase")
		_:
			if not destination.is_combat_location():
				push_error("Map location has no supported behavior.")
				return

			RunState.set_current_floor(
				RunState.current_floor + 1
			)
			_start_current_battle()


func _show_level_complete() -> void:
	current_phase = FlowPhase.COMPLETE
	transition_label.text = (
		"Convergence stabilized!\n"
		+ str(RunState.closed_rifts)
		+ " rifts sealed at "
		+ str(RunState.instability)
		+ " instability"
	)
	restart_button.text = "New Run"
	restart_button.show()
	main_menu_button.show()
	transition_overlay.show()


func _show_run_defeat() -> void:
	current_phase = FlowPhase.DEFEAT
	transition_label.text = (
		"Run defeated\nSealed "
		+ str(RunState.closed_rifts)
		+ " rifts before the leylines collapsed"
	)
	restart_button.text = "New Run"
	restart_button.show()
	main_menu_button.show()
	transition_overlay.show()


func _show_terminal_message(message: String) -> void:
	transition_label.text = message
	restart_button.hide()
	main_menu_button.hide()
	transition_overlay.show()


func _on_restart_button_pressed() -> void:
	_clear_active_battle()
	_clear_reward_screen()
	_clear_map_screen()
	RunState.restart_current_run()
	RunState.set_current_floor(1)
	RunState.initialize_leyline_map(level_data.leyline_map)
	active_map_location = null

	transition_overlay.hide()
	restart_button.hide()
	main_menu_button.hide()
	_begin_map_phase()


func _on_main_menu_button_pressed() -> void:
	_clear_active_battle()
	_clear_reward_screen()
	RunState.end_current_run()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _clear_active_battle() -> void:
	if not is_instance_valid(active_battle):
		active_battle = null
		return

	active_battle.queue_free()
	active_battle = null


func _clear_reward_screen() -> void:
	if not is_instance_valid(active_reward_screen):
		active_reward_screen = null
		return

	active_reward_screen.queue_free()
	active_reward_screen = null


func _clear_map_screen() -> void:
	if not is_instance_valid(active_map_screen):
		active_map_screen = null
		return

	active_map_screen.queue_free()
	active_map_screen = null


func _update_run_label() -> void:
	floor_label.text = (
		"Rifts "
		+ str(RunState.closed_rifts)
		+ " / "
		+ str(level_data.leyline_map.rifts_required)
		+ "    Instability "
		+ str(RunState.instability)
	)
