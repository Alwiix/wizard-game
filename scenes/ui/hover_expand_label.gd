class_name HoverExpandLabel
extends Label


@export var hover_width: float = 300.0
@export var minimum_hover_characters: int = 28


var _last_text: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sync_tooltip()


func _process(_delta: float) -> void:
	if text != _last_text:
		_sync_tooltip()


func _sync_tooltip() -> void:
	_last_text = text
	tooltip_text = (
		text
		if text.length() >= minimum_hover_characters
		else ""
	)


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var full_text := Label.new()
	var viewport_width := get_viewport_rect().size.x

	full_text.custom_minimum_size.x = minf(
		hover_width,
		maxf(viewport_width - 24.0, 160.0)
	)
	full_text.add_theme_font_size_override("font_size", 10)
	full_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	full_text.text = for_text
	panel.add_child(full_text)
	return panel
