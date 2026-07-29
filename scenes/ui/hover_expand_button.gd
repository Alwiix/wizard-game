class_name HoverExpandButton
extends Button


@export var hover_width: float = 260.0


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
