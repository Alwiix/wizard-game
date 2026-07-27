class_name StormcloudStatus
extends StatusEffect


func _init() -> void:
	status_id = &"stormcloud"
	display_name = "Stormcloud"
	stacks = 1
	remaining_turns = 3
	show_stacks = false
	show_duration = true


func initialize(_amount: int, duration: int = -1) -> void:
	stacks = 1
	remaining_turns = duration if duration >= 0 else 3


func add_application(_amount: int, duration: int = -1) -> void:
	stacks = 1
	var refreshed_duration: int = duration if duration >= 0 else 3
	remaining_turns = max(remaining_turns, refreshed_duration)


func on_turn_ended(combatant: Node) -> void:
	var damage: int = 3 if combatant.has_status(&"wet") else 2
	combatant.take_damage(
		damage,
		{
			"source": "status",
			"status_id": "stormcloud",
			"element": "stormcloud"
		}
	)
