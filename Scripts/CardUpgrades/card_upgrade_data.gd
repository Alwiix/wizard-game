class_name CardUpgradeData
extends Resource


@export_group("Identity")
@export var upgrade_id: StringName = &""
@export var display_name: String = "Card Upgrade"
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Reward Rules")
@export var can_stack: bool = false
@export_range(0.0, 100.0, 0.1) var reward_weight: float = 1.0

@export_group("Card Modifiers")
@export var energy_cost_modifier: int = 0
@export var properties: Array[StringName] = []

@export_group("Cast Placement")
# Zero-based ingredient slots. Empty means the upgrade works in any slot.
@export var active_cast_slots: Array[int] = []

@export_group("On-Use Effects")
@export var on_use_effects: Array[CombatEffectData] = []


func has_property(property_id: StringName) -> bool:
	var normalized_id: StringName = StringName(
		String(property_id).to_lower()
	)

	for property_value in properties:
		if (
			StringName(String(property_value).to_lower())
			== normalized_id
		):
			return true

	return false


func is_active_in_cast_slot(slot_index: int) -> bool:
	if active_cast_slots.is_empty():
		return true

	return active_cast_slots.has(slot_index)


func get_placement_text() -> String:
	if active_cast_slots.is_empty():
		return ""

	var slot_names: Array[String] = []

	for slot_index in active_cast_slots:
		slot_names.append(str(slot_index + 1))

	return "cast slot " + "/".join(slot_names) + " only"
