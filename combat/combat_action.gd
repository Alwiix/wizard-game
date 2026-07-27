class_name CombatAction
extends RefCounted


var action_id: StringName = &"action"
var display_name: String = "Action"
var caster: Node
var source_data: Variant
var effects: Array[CombatEffectData] = []
var properties: Array[StringName] = []
var primary_target: Node


static func from_spell(
	spell: SpellData,
	action_caster: Node,
	target: Node = null
) -> CombatAction:
	var action := CombatAction.new()
	action.caster = action_caster
	action.primary_target = target
	action.source_data = spell

	if spell != null:
		action.action_id = spell.spell_id
		action.display_name = spell.display_name
		action.effects = spell.effects.duplicate()
		action.properties = spell.properties.duplicate()

	return action


static func from_enemy_move(
	move: EnemyMoveData,
	action_caster: Node,
	target: Node = null
) -> CombatAction:
	var action := CombatAction.new()
	action.caster = action_caster
	action.primary_target = target
	action.source_data = move

	if move != null:
		action.action_id = StringName(
			move.move_name.to_snake_case()
		)
		action.display_name = move.move_name
		action.effects = move.effects.duplicate()
		action.properties = move.properties.duplicate()

	return action


func has_property(property_id: StringName) -> bool:
	var normalized_id := StringName(String(property_id).to_lower())

	for property_value in properties:
		if (
			StringName(String(property_value).to_lower())
			== normalized_id
		):
			return true

	return false


func includes_damage() -> bool:
	for effect in effects:
		if (
			effect != null
			and effect.effect_type
				== CombatEffectData.EffectType.DAMAGE
		):
			return true

	return false
