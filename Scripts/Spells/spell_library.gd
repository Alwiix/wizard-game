class_name SpellLibraryData
extends Resource


@export var recipes: Array[SpellRecipeData] = []


func find_spell(
	first_element: StringName,
	second_element: StringName,
	third_element: StringName = &""
) -> SpellData:
	var cast_elements: Array[StringName] = [
		first_element,
		second_element
	]

	if third_element != &"":
		cast_elements.append(third_element)

	return find_spell_for_elements(cast_elements)


func find_spell_for_elements(
	cast_elements: Array[StringName]
) -> SpellData:
	for recipe in recipes:
		if recipe == null:
			continue

		if not recipe.matches_elements(cast_elements):
			continue

		return recipe.spell

	return null
