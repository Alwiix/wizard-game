class_name SpellRecipeData
extends Resource


@export_group("Combination")
@export var first_element: StringName = &""
@export var second_element: StringName = &""
@export var third_element: StringName = &""

# False:
# The same two or three elements work in any selection order.
#
# True:
# Only the exact listed order produces this spell.
@export var order_matters: bool = false

@export_group("Result")
@export var spell: SpellData


func matches(
	cast_first_element: StringName,
	cast_second_element: StringName,
	cast_third_element: StringName = &""
) -> bool:
	var cast_elements: Array[StringName] = [
		cast_first_element,
		cast_second_element
	]

	if cast_third_element != &"":
		cast_elements.append(cast_third_element)

	return matches_elements(cast_elements)


func matches_elements(
	cast_elements: Array[StringName]
) -> bool:
	var recipe_elements: Array[String] = [
		_normalize_element(first_element),
		_normalize_element(second_element)
	]

	if third_element != &"":
		recipe_elements.append(
			_normalize_element(third_element)
		)

	if cast_elements.size() != recipe_elements.size():
		return false

	var normalized_cast_elements: Array[String] = []

	for element in cast_elements:
		normalized_cast_elements.append(
			_normalize_element(element)
		)

	if order_matters:
		return normalized_cast_elements == recipe_elements

	# Sorting preserves duplicate counts, so Water + Water + Air does
	# not accidentally match Water + Air + Air.
	recipe_elements.sort()
	normalized_cast_elements.sort()
	return normalized_cast_elements == recipe_elements


func _normalize_element(element: StringName) -> String:
	return String(element).strip_edges().to_lower()
