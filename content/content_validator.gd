class_name ContentValidator
extends RefCounted


static func validate_all() -> Array[String]:
	var errors: Array[String] = []
	_validate_elements(errors)
	_validate_upgrades(errors)
	_validate_spells(errors)
	_validate_enemies(errors)
	_validate_levels(errors)
	return errors


static func _validate_elements(errors: Array[String]) -> void:
	var ids: Dictionary = {}
	var names: Dictionary = {}

	for element in ContentCatalog.get_all_elements():
		if element == null:
			errors.append("Element catalog contains a null resource.")
			continue

		var card_id := element.card_id.strip_edges().to_lower()
		var element_name := (
			element.element_name.strip_edges().to_lower()
		)

		_require_unique(
			card_id,
			"element card ID",
			ids,
			errors
		)
		_require_unique(
			element_name,
			"element name",
			names,
			errors
		)

		if element.base_energy_cost < 0:
			errors.append(
				element.display_name + " has a negative energy cost."
			)


static func _validate_upgrades(errors: Array[String]) -> void:
	var ids: Dictionary = {}

	for upgrade in ContentCatalog.UPGRADE_LIBRARY.upgrades:
		if upgrade == null:
			errors.append("Upgrade library contains a null resource.")
			continue

		_require_unique(
			String(upgrade.upgrade_id).to_lower(),
			"upgrade ID",
			ids,
			errors
		)

		for slot_index in upgrade.active_cast_slots:
			if slot_index < 0 or slot_index > 2:
				errors.append(
					upgrade.display_name
					+ " has invalid cast slot "
					+ str(slot_index + 1)
					+ "."
				)

		_validate_effects(
			upgrade.on_use_effects,
			"upgrade " + upgrade.display_name,
			errors
		)


static func _validate_spells(errors: Array[String]) -> void:
	var spell_ids: Dictionary = {}
	var recipe_keys: Dictionary = {}
	var previous_recipes: Array[SpellRecipeData] = []
	var known_elements: Dictionary = {}

	for element in ContentCatalog.get_all_elements():
		if element != null:
			known_elements[
				element.element_name.strip_edges().to_lower()
			] = true

	for recipe in ContentCatalog.SPELL_LIBRARY.recipes:
		if recipe == null:
			errors.append("Spell library contains a null recipe.")
			continue

		if recipe.spell == null:
			errors.append(
				"Recipe " + _get_recipe_key(recipe)
				+ " has no spell."
			)
			continue

		var spell := recipe.spell

		if spell.energy_cost < 0:
			errors.append(
				spell.display_name + " has a negative energy cost."
			)

		_require_unique(
			String(spell.spell_id).to_lower(),
			"spell ID",
			spell_ids,
			errors
		)
		_require_unique(
			_get_recipe_key(recipe),
			"spell recipe",
			recipe_keys,
			errors
		)

		for previous_recipe in previous_recipes:
			if _recipes_overlap(recipe, previous_recipe):
				errors.append(
					"Ambiguous spell recipes: "
					+ _get_recipe_key(recipe)
					+ " overlaps "
					+ _get_recipe_key(previous_recipe)
					+ "."
				)

		previous_recipes.append(recipe)

		for element_name in _get_recipe_elements(recipe):
			if element_name.is_empty():
				errors.append(
					spell.display_name + " has an empty element."
				)
			elif not known_elements.has(element_name):
				errors.append(
					spell.display_name
					+ " references unknown element "
					+ element_name
					+ "."
				)

		for property_id in spell.properties:
			if not CombatPropertyRegistry.has_property(property_id):
				errors.append(
					spell.display_name
					+ " uses unknown combat property "
					+ String(property_id)
					+ "."
				)

		_validate_effects(
			spell.effects,
			"spell " + spell.display_name,
			errors
		)


static func _validate_enemies(errors: Array[String]) -> void:
	var ids: Dictionary = {}

	for enemy in ContentCatalog.get_all_enemies():
		if enemy == null:
			errors.append("Enemy catalog contains a null resource.")
			continue

		_require_unique(
			String(enemy.enemy_id).to_lower(),
			"enemy ID",
			ids,
			errors
		)

		if enemy.maximum_health <= 0:
			errors.append(
				enemy.display_name + " must have positive health."
			)

		if enemy.moves.is_empty():
			errors.append(enemy.display_name + " has no moves.")

		for move in enemy.moves:
			if move == null:
				errors.append(
					enemy.display_name + " has a null move."
				)
				continue

			for property_id in move.properties:
				if not CombatPropertyRegistry.has_property(property_id):
					errors.append(
						enemy.display_name
						+ " move "
						+ move.move_name
						+ " uses unknown combat property "
						+ String(property_id)
						+ "."
					)

			_validate_effects(
				move.effects,
				enemy.display_name + " move " + move.move_name,
				errors
			)


static func _validate_levels(errors: Array[String]) -> void:
	var level_ids: Dictionary = {}

	for level in ContentCatalog.get_all_levels():
		if level == null:
			errors.append("Level catalog contains a null resource.")
			continue

		_require_unique(
			String(level.level_id).to_lower(),
			"level ID",
			level_ids,
			errors
		)

		if level.encounters.is_empty():
			errors.append(level.display_name + " has no encounters.")

		for encounter in level.encounters:
			if encounter == null:
				errors.append(
					level.display_name + " has a null encounter."
				)
				continue

			# Reusing an encounter across floors is intentional, so
			# encounter IDs only need a non-empty value.
			if encounter.encounter_id == &"":
				errors.append("Encounter has an empty ID.")

			if encounter.get_enemy_roster().is_empty():
				errors.append(
					encounter.display_name + " has no enemies."
				)

		_validate_leyline_map(level, errors)


static func _validate_leyline_map(
	level: LevelData,
	errors: Array[String]
) -> void:
	var map_data := level.leyline_map

	if map_data == null:
		errors.append(level.display_name + " has no leyline map.")
		return

	var location_ids: Dictionary = {}

	for location in map_data.locations:
		if location == null:
			errors.append(
				map_data.display_name + " contains a null location."
			)
			continue

		_require_unique(
			String(location.location_id).to_lower(),
			"map location ID",
			location_ids,
			errors
		)

		if (
			location.is_combat_location()
			and (
				location.encounter == null
				or location.encounter.get_enemy_roster().is_empty()
			)
		):
			errors.append(
				location.display_name
				+ " is a combat location without an encounter."
			)

	if map_data.find_location(map_data.starting_location_id) == null:
		errors.append(
			map_data.display_name + " has an invalid starting location."
		)

	if map_data.rifts_required <= 0:
		errors.append(
			map_data.display_name + " must require at least one rift."
		)
	elif map_data.rifts_required > map_data.get_rift_count():
		errors.append(
			map_data.display_name
			+ " requires more rifts than it contains."
		)

	for location in map_data.locations:
		if location == null:
			continue

		for connected_id in location.connected_location_ids:
			var connected := map_data.find_location(connected_id)

			if connected == null:
				errors.append(
					location.display_name
					+ " connects to unknown location "
					+ String(connected_id)
					+ "."
				)
			elif (
				location.location_id
				not in connected.connected_location_ids
			):
				errors.append(
					location.display_name
					+ " has a one-way connection to "
					+ connected.display_name
					+ "."
				)

static func _validate_effects(
	effects: Array,
	owner_name: String,
	errors: Array[String]
) -> void:
	for effect in effects:
		if effect == null:
			errors.append(owner_name + " contains a null effect.")
			continue

		if (
			effect.effect_type
				in [
					CombatEffectData.EffectType.APPLY_STATUS,
					CombatEffectData.EffectType.REMOVE_STATUS,
					CombatEffectData.EffectType.MULTIPLY_STATUS,
					CombatEffectData.EffectType.CONVERT_STATUS
				]
			and not StatusRegistry.has_status(effect.status_id)
		):
			errors.append(
				owner_name
				+ " references unknown status "
				+ String(effect.status_id)
				+ "."
			)

		if (
			effect.effect_type
				== CombatEffectData.EffectType.CONVERT_STATUS
			and not StatusRegistry.has_status(
				effect.converted_status_id
			)
		):
			errors.append(
				owner_name
				+ " converts into unknown status "
				+ String(effect.converted_status_id)
				+ "."
			)

		if (
			effect.effect_type
				== CombatEffectData.EffectType.APPLY_BATTLE_MODIFIER
			and not BattleModifierController.is_supported_modifier(
				effect.status_id
			)
		):
			errors.append(
				owner_name
				+ " references unknown battle modifier "
				+ String(effect.status_id)
				+ "."
			)

		if (
			effect.condition_type
				!= CombatEffectData.ConditionType.ALWAYS
			and not StatusRegistry.has_status(
				effect.condition_status_id
			)
		):
			errors.append(
				owner_name
				+ " has an unknown condition status "
				+ String(effect.condition_status_id)
				+ "."
			)

		if (
			effect.required_target_status != &""
			and not StatusRegistry.has_status(
				effect.required_target_status
			)
		):
			errors.append(
				owner_name
				+ " has an unknown required status "
				+ String(effect.required_target_status)
				+ "."
			)


static func _get_recipe_key(recipe: SpellRecipeData) -> String:
	var elements := _get_recipe_elements(recipe)

	if not recipe.order_matters:
		elements.sort()

	return (
		("ordered:" if recipe.order_matters else "unordered:")
		+ "+".join(elements)
	)


static func _get_recipe_elements(
	recipe: SpellRecipeData
) -> Array[String]:
	var elements: Array[String] = [
		String(recipe.first_element).strip_edges().to_lower(),
		String(recipe.second_element).strip_edges().to_lower()
	]

	if recipe.third_element != &"":
		elements.append(
			String(recipe.third_element).strip_edges().to_lower()
		)

	return elements


static func _recipes_overlap(
	first: SpellRecipeData,
	second: SpellRecipeData
) -> bool:
	var first_elements := _get_recipe_elements(first)
	var second_elements := _get_recipe_elements(second)

	if first_elements.size() != second_elements.size():
		return false

	if first.order_matters and second.order_matters:
		return first_elements == second_elements

	first_elements.sort()
	second_elements.sort()
	return first_elements == second_elements


static func _require_unique(
	value: String,
	label: String,
	seen: Dictionary,
	errors: Array[String]
) -> void:
	if value.is_empty():
		errors.append("A " + label + " is empty.")
		return

	if seen.has(value):
		errors.append("Duplicate " + label + ": " + value + ".")
		return

	seen[value] = true
