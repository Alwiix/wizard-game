class_name PlayerHUD
extends Control


var player: BattlePlayer
var status_controller: StatusController


@onready var health_bar: TextureProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var energy_label: Label = %EnergyLabel
@onready var status_label: Label = %StatusLabel


func bind_player(new_player: BattlePlayer) -> void:
	_disconnect_player()
	player = new_player

	if player == null:
		return

	player.health_changed.connect(_update_health)
	player.energy_changed.connect(_update_energy)
	status_controller = player.get_status_controller()

	if status_controller != null:
		status_controller.statuses_changed.connect(
			_update_statuses
		)

	_update_health(player.health, player.maximum_health)
	_update_energy(player.energy, player.maximum_energy)
	_update_statuses()


func _disconnect_player() -> void:
	if player != null:
		if player.health_changed.is_connected(_update_health):
			player.health_changed.disconnect(_update_health)

		if player.energy_changed.is_connected(_update_energy):
			player.energy_changed.disconnect(_update_energy)

	if status_controller != null:
		if status_controller.statuses_changed.is_connected(
			_update_statuses
		):
			status_controller.statuses_changed.disconnect(
				_update_statuses
			)

	player = null
	status_controller = null


func _update_health(
	current_health: int,
	maximum_health: int
) -> void:
	health_bar.max_value = maxi(maximum_health, 1)
	health_bar.value = current_health
	health_label.text = (
		str(current_health)
		+ "/"
		+ str(maximum_health)
	)


func _update_energy(
	current_energy: int,
	maximum_energy: int
) -> void:
	energy_label.text = (
		"Energy: "
		+ str(current_energy)
		+ " / "
		+ str(maximum_energy)
	)


func _update_statuses() -> void:
	if status_controller == null:
		status_label.text = "Statuses: None"
		return

	status_label.text = status_controller.get_display_text()
