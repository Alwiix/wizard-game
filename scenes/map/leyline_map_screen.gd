class_name LeylineMapScreen
extends Control


signal location_selected(location_id: StringName)


const BUTTON_SIZE := Vector2(100.0, 38.0)
const HOVER_EXPAND_BUTTON: GDScript = preload(
	"res://scenes/ui/hover_expand_button.gd"
)


var map_data: LeylineMapData
var location_buttons: Dictionary = {}


@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var details_label: Label = %DetailsLabel
@onready var instructions_label: Label = %InstructionsLabel


func _ready() -> void:
	resized.connect(_render_map)

	if map_data != null:
		_render_map()


func setup(new_map_data: LeylineMapData) -> void:
	map_data = new_map_data

	if is_node_ready():
		_render_map()


func _render_map() -> void:
	if map_data == null or not is_node_ready():
		return

	for button_value in location_buttons.values():
		var old_button := button_value as Button

		if is_instance_valid(old_button):
			old_button.queue_free()

	location_buttons.clear()
	title_label.text = map_data.display_name
	status_label.text = (
		"Rifts sealed: "
		+ str(RunState.closed_rifts)
		+ " / "
		+ str(map_data.rifts_required)
		+ "    |    Instability: "
		+ str(RunState.instability)
		+ "    |    Enemy health: +"
		+ str(RunState.instability * 3)
		+ "%"
	)
	instructions_label.text = (
		"Choose a connected leyline. Cleared locations remain "
		+ "available for travel."
	)
	details_label.text = (
		"Hover over a location to inspect its affinity and danger."
	)

	for location in map_data.locations:
		if location == null:
			continue

		var location_button := (
			HOVER_EXPAND_BUTTON.new() as Button
		)
		location_button.custom_minimum_size = BUTTON_SIZE
		location_button.size = BUTTON_SIZE
		location_button.position = _get_button_position(location)
		location_button.add_theme_font_size_override("font_size", 8)
		location_button.clip_text = true
		location_button.text = _get_button_text(location)
		location_button.tooltip_text = _get_location_details_text(
			location
		)
		location_button.disabled = not _is_location_selectable(
			location
		)
		location_button.mouse_entered.connect(
			_show_location_details.bind(location)
		)

		if not location_button.disabled:
			location_button.pressed.connect(
				_on_location_pressed.bind(location.location_id)
			)

		_apply_location_color(location_button, location)
		add_child(location_button)
		location_buttons[location.location_id] = location_button

	queue_redraw()


func _draw() -> void:
	if map_data == null:
		return

	var drawn_connections: Dictionary = {}

	for location in map_data.locations:
		if location == null:
			continue

		for connected_id in location.connected_location_ids:
			var connection_key: Array[String] = [
				String(location.location_id),
				String(connected_id)
			]
			connection_key.sort()
			var key: String = "|".join(connection_key)

			if drawn_connections.has(key):
				continue

			var connected_location := map_data.find_location(
				connected_id
			)

			if connected_location == null:
				continue

			drawn_connections[key] = true
			var is_active_connection: bool = (
				location.location_id
					== RunState.current_map_location_id
				or connected_id
					== RunState.current_map_location_id
			)
			var line_color := (
				Color(0.58, 0.82, 1.0, 0.9)
				if is_active_connection
				else Color(0.32, 0.30, 0.48, 0.75)
			)
			draw_line(
				_get_location_center(location),
				_get_location_center(connected_location),
				line_color,
				4.0 if is_active_connection else 2.0,
				true
			)


func _get_button_position(
	location: LeylineLocationData
) -> Vector2:
	return _get_location_center(location) - BUTTON_SIZE / 2.0


func _get_location_center(
	location: LeylineLocationData
) -> Vector2:
	var map_top: float = 70.0
	var map_height: float = maxf(size.y - 195.0, 120.0)
	return Vector2(
		lerpf(64.0, size.x - 64.0, location.map_position.x),
		map_top + map_height * location.map_position.y
	)


func _get_button_text(location: LeylineLocationData) -> String:
	var lines: Array[String] = [location.display_name]

	if location.location_id == RunState.current_map_location_id:
		lines.append("[CURRENT]")
	elif RunState.is_map_location_completed(location.location_id):
		lines.append("[CLEARED]")
	elif (
		location.location_type
			== LeylineLocationData.LocationType.BOSS
		and RunState.closed_rifts < map_data.rifts_required
	):
		lines.append("[SEALED]")
	else:
		lines.append(location.get_type_name())

	return "\n".join(lines)


func _is_location_selectable(
	location: LeylineLocationData
) -> bool:
	return RunState.can_travel_to(
		map_data,
		location.location_id
	)


func _show_location_details(
	location: LeylineLocationData
) -> void:
	details_label.text = _get_location_details_text(location)


func _get_location_details_text(
	location: LeylineLocationData
) -> String:
	var affinity: String = (
		"Unaligned"
		if location.elemental_affinity == &""
		else String(location.elemental_affinity).capitalize()
	)
	var state_text: String = "Unexplored"

	if location.location_id == RunState.current_map_location_id:
		state_text = "Current location"
	elif RunState.is_map_location_completed(location.location_id):
		state_text = "Cleared"
	elif (
		location.location_type
			== LeylineLocationData.LocationType.BOSS
		and RunState.closed_rifts < map_data.rifts_required
	):
		state_text = (
			"Sealed until all "
			+ str(map_data.rifts_required)
			+ " rifts are closed"
		)
	elif not _is_location_selectable(location):
		state_text = "Not connected to your current location"

	return (
		location.display_name
		+ " - "
		+ location.get_type_name()
		+ "\nAffinity: "
		+ affinity
		+ "    Danger: "
		+ str(location.danger_level)
		+ "    "
		+ state_text
		+ "\n"
		+ location.description
	)


func _apply_location_color(
	button: Button,
	location: LeylineLocationData
) -> void:
	var affinity_colors: Dictionary = {
		&"water": Color(0.62, 0.80, 1.0),
		&"lightning": Color(0.94, 0.88, 0.45),
		&"air": Color(0.78, 0.92, 0.90),
		&"nature": Color(0.58, 0.86, 0.60)
	}
	button.modulate = affinity_colors.get(
		location.elemental_affinity,
		Color(0.88, 0.82, 1.0)
	)

	if (
		location.location_type
			== LeylineLocationData.LocationType.BOSS
	):
		button.modulate = Color(1.0, 0.55, 0.62)

	if location.location_id == RunState.current_map_location_id:
		button.modulate = Color.WHITE


func _on_location_pressed(location_id: StringName) -> void:
	location_selected.emit(location_id)
