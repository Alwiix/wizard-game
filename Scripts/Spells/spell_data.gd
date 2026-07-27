class_name SpellData
extends Resource


@export_group("Identity")
@export var spell_id: StringName = &""
@export var display_name: String = "Spell"
@export_multiline var description: String = ""
@export var artwork: Texture2D

@export_group("Combat")
@export_range(0, 10, 1) var energy_cost: int = 1
@export var effects: Array[CombatEffectData] = []

@export_group("Properties")
@export var properties: Array[StringName] = []


func create_action(
	caster: Node,
	target: Node = null
) -> CombatAction:
	return CombatAction.from_spell(self, caster, target)


# Compatibility representation used by the preview UI.
func to_result_dictionary() -> Dictionary:
	return {
		"valid": true,
		"name": display_name,
		"description": description,
		"artwork": artwork,
		"energy_cost": energy_cost,
		"effects": effects,
		"properties": properties.duplicate(),
		"spell_data": self
	}
