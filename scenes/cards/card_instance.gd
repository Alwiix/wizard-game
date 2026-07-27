class_name CardInstance
extends RefCounted


const HEAVY_ROCK: StringName = &"heavy_rock"
const WHITE_GEM: StringName = &"white_gem"
const BLUE_GEM: StringName = &"blue_gem"
const UPGRADE_LIBRARY: CardUpgradeLibraryData = (
	ContentCatalog.UPGRADE_LIBRARY
)


var data: ElementCardData

var upgrade_level: int = 0
var upgrades: Array[StringName] = []
var temporary_cost_modifier: int = 0
var is_retained_this_turn: bool = false


func _init(card_data: ElementCardData) -> void:
	data = card_data


func get_element_name() -> String:
	return data.element_name


func get_energy_cost() -> int:
	var final_cost: int = (
		data.base_energy_cost
		+ get_spell_cost_modifier(0)
	)

	return max(final_cost, 0)


func get_spell_cost_modifier(cast_slot: int = -1) -> int:
	var modifier := temporary_cost_modifier

	for upgrade_id in upgrades:
		var upgrade_data := UPGRADE_LIBRARY.find_upgrade(upgrade_id)

		if (
			upgrade_data != null
			and upgrade_data.is_active_in_cast_slot(cast_slot)
		):
			modifier += upgrade_data.energy_cost_modifier

	return modifier


func upgrade() -> void:
	apply_upgrade(WHITE_GEM)


func apply_upgrade(upgrade_id_value: StringName) -> bool:
	var upgrade_id: StringName = StringName(
		String(upgrade_id_value).to_lower()
	)

	var upgrade_data: CardUpgradeData = (
		UPGRADE_LIBRARY.find_upgrade(upgrade_id)
	)

	if upgrade_data == null:
		push_warning("Unknown card upgrade: " + String(upgrade_id))
		return false

	if not upgrade_data.can_stack and upgrades.has(upgrade_id):
		return false

	upgrades.append(upgrade_id)
	upgrade_level = upgrades.size()

	return true


func has_upgrade(upgrade_id_value: StringName) -> bool:
	return upgrades.has(
		StringName(String(upgrade_id_value).to_lower())
	)


func get_upgrade_display_names() -> Array[String]:
	var display_names: Array[String] = []

	for upgrade_id in upgrades:
		var upgrade_data: CardUpgradeData = (
			UPGRADE_LIBRARY.find_upgrade(upgrade_id)
		)

		if upgrade_data != null:
			var display_text := upgrade_data.display_name
			var placement_text := upgrade_data.get_placement_text()

			if not placement_text.is_empty():
				display_text += " [" + placement_text + "]"

			display_names.append(display_text)

	return display_names


func get_on_use_effects(cast_slot: int = -1) -> Array:
	var effects: Array = []

	for upgrade_id in upgrades:
		var upgrade_data: CardUpgradeData = (
			UPGRADE_LIBRARY.find_upgrade(upgrade_id)
		)

		if (
			upgrade_data != null
			and upgrade_data.is_active_in_cast_slot(cast_slot)
		):
			effects.append_array(upgrade_data.on_use_effects)

	return effects


func get_active_cast_upgrade_names(
	cast_slot: int
) -> Array[String]:
	var display_names: Array[String] = []

	for upgrade_id in upgrades:
		var upgrade_data := UPGRADE_LIBRARY.find_upgrade(upgrade_id)

		if (
			upgrade_data != null
			and upgrade_data.is_active_in_cast_slot(cast_slot)
			and (
				upgrade_data.energy_cost_modifier != 0
				or not upgrade_data.on_use_effects.is_empty()
			)
		):
			display_names.append(upgrade_data.display_name)

	return display_names


func has_permanent_retain() -> bool:
	return has_upgrade_property(&"retain")


func has_upgrade_property(property_id: StringName) -> bool:
	for upgrade_id in upgrades:
		var upgrade_data: CardUpgradeData = (
			UPGRADE_LIBRARY.find_upgrade(upgrade_id)
		)

		if (
			upgrade_data != null
			and upgrade_data.has_property(property_id)
		):
			return true

	return false


func should_retain_at_turn_end() -> bool:
	return has_permanent_retain() or is_retained_this_turn


static func get_valid_upgrade_ids() -> Array[StringName]:
	return UPGRADE_LIBRARY.get_upgrade_ids()


func reset_temporary_modifiers() -> void:
	temporary_cost_modifier = 0
	is_retained_this_turn = false


func retain_for_turn() -> void:
	is_retained_this_turn = true


func consume_retain() -> void:
	is_retained_this_turn = false
