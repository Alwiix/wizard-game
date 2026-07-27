class_name SpellResolver
extends Node


@export var spell_library: SpellLibraryData


func resolve_spell(
	first_element: String,
	second_element: String,
	third_element: String = ""
) -> Dictionary:
	var element_names: Array[String] = [
		first_element,
		second_element
	]

	if not third_element.is_empty():
		element_names.append(third_element)

	return resolve_elements(element_names)


func resolve_elements(
	element_names: Array[String]
) -> Dictionary:
	if spell_library == null:
		push_error(
			"SpellResolver has no SpellLibraryData assigned."
		)

		return _get_invalid_result(
			"Spell library is missing."
		)

	var cast_elements: Array[StringName] = []

	for element_name in element_names:
		cast_elements.append(StringName(element_name))

	var spell: SpellData = (
		spell_library.find_spell_for_elements(cast_elements)
	)

	if spell == null:
		return _get_invalid_result(
			"These elements do not create a spell."
		)

	return spell.to_result_dictionary()


func _get_invalid_result(
	message: String
) -> Dictionary:
	return {
		"valid": false,
		"name": "",
		"description": message,
		"artwork": null,
		"effects": []
	}
