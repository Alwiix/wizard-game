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
const MAIN_MENU_SCENE_PATH: String = (
	"res://scenes/menu/main_menu.tscn"
)


@export var level_data: LevelData
@export var transition_duration: float = 1.5


var current_encounter_index: int = 0
var current_phase: FlowPhase = FlowPhase.TRANSITION
var active_battle: Node2D
var active_reward_screen: RewardScreen


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

	if level_data == null or level_data.encounters.is_empty():
		push_error("RunFlow requires a LevelData with encounters.")
		_show_terminal_message("No encounters are configured.")
		return

	if not RunState.is_run_active:
		RunState.start_new_run()

	current_encounter_index = 0
	RunState.set_current_floor(1)

	transition_overlay.hide()
	restart_button.hide()
	main_menu_button.hide()
	_start_current_battle()


func _start_current_battle() -> void:
	var encounter: EncounterData = _get_current_encounter()

	if encounter == null:
		push_error("The current floor has no encounter.")
		_show_terminal_message("This floor has no encounter.")
		return

	current_phase = FlowPhase.BATTLE
	_update_floor_label()

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
	active_reward_screen.begin_rewards()


func _on_rewards_completed() -> void:
	_clear_reward_screen()
	call_deferred("_begin_map_phase")


# This is where a future map will return the player's chosen encounter.
# The prototype follows the fixed encounter order in LevelData.
func _begin_map_phase() -> void:
	current_phase = FlowPhase.MAP

	if current_encounter_index + 1 >= level_data.encounters.size():
		_show_level_complete()
		return

	_begin_floor_transition(current_encounter_index + 1)


func _begin_floor_transition(next_encounter_index: int) -> void:
	current_phase = FlowPhase.TRANSITION

	var next_floor: int = next_encounter_index + 1
	transition_label.text = "Moving to level " + str(next_floor)
	restart_button.hide()
	main_menu_button.hide()
	transition_overlay.show()

	await get_tree().create_timer(transition_duration).timeout

	_clear_active_battle()
	current_encounter_index = next_encounter_index
	RunState.set_current_floor(next_floor)

	transition_overlay.hide()
	_start_current_battle()


func _show_level_complete() -> void:
	current_phase = FlowPhase.COMPLETE
	transition_label.text = (
		"Level complete!\n"
		+ str(level_data.encounters.size())
		+ " floors cleared"
	)
	restart_button.text = "New Run"
	restart_button.show()
	main_menu_button.show()
	transition_overlay.show()


func _show_run_defeat() -> void:
	current_phase = FlowPhase.DEFEAT
	transition_label.text = (
		"Run defeated\nReached floor "
		+ str(RunState.current_floor)
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
	RunState.restart_current_run()
	current_encounter_index = 0
	RunState.set_current_floor(1)

	transition_overlay.hide()
	restart_button.hide()
	main_menu_button.hide()
	_start_current_battle()


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


func _get_current_encounter() -> EncounterData:
	if current_encounter_index < 0:
		return null

	if current_encounter_index >= level_data.encounters.size():
		return null

	return level_data.encounters[current_encounter_index]


func _update_floor_label() -> void:
	floor_label.text = (
		"Floor "
		+ str(RunState.current_floor)
		+ " / "
		+ str(level_data.encounters.size())
	)
