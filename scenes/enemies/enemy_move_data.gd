class_name EnemyMoveData
extends Resource


@export var move_name: String = "Enemy Move"
@export_multiline var intent_text: String = "The enemy is preparing a move."
@export_multiline var action_text: String = ""
@export var effects: Array[CombatEffectData] = []
@export var properties: Array[StringName] = []


func create_action(
	caster: Node,
	target: Node = null
) -> CombatAction:
	return CombatAction.from_enemy_move(self, caster, target)


func get_effect_dictionaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for effect in effects:
		if effect != null:
			result.append(effect.to_effect_dictionary())

	return result


func to_combat_source_dictionary() -> Dictionary:
	return {
		"effects": get_effect_dictionaries(),
		"properties": properties.duplicate()
	}


func get_property_display_names() -> Array[String]:
	var display_names: Array[String] = []

	for property_id in properties:
		display_names.append(
			String(property_id).capitalize()
		)

	return display_names


func is_attack() -> bool:
	for effect in effects:
		if (
			effect != null
			and effect.effect_type == CombatEffectData.EffectType.DAMAGE
		):
			return true

	return false
