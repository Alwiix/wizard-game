class_name ResolvedCombatEffect
extends RefCounted


var effect_type: CombatEffectData.EffectType = (
	CombatEffectData.EffectType.DAMAGE
)
var target_type: CombatEffectData.TargetType = (
	CombatEffectData.TargetType.PLAYER
)
var explicit_target: Node
var amount: int = 0
var element: StringName = &"physical"
var status_id: StringName = &""
var duration: int = -1
var condition_type: CombatEffectData.ConditionType = (
	CombatEffectData.ConditionType.ALWAYS
)
var condition_status_id: StringName = &""
var required_target_status: StringName = &""
var amount_if_target_has_status: int = -1
var consume_required_status: bool = false
var condition_message: String = ""
var source_id: StringName = &"combat_effect"


static func from_data(
	data: CombatEffectData
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()

	if data == null:
		return effect

	effect.effect_type = data.effect_type
	effect.target_type = data.target
	effect.amount = data.amount
	effect.element = data.element
	effect.status_id = data.status_id
	effect.duration = data.duration
	effect.condition_type = data.condition_type
	effect.condition_status_id = data.condition_status_id
	effect.required_target_status = data.required_target_status
	effect.amount_if_target_has_status = (
		data.amount_if_target_has_status
	)
	effect.consume_required_status = data.consume_required_status
	effect.condition_message = data.condition_message
	return effect


static func from_dictionary(
	value: Dictionary
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.effect_type_from_name(
		str(value.get("type", ""))
	)
	effect.target_type = CombatEffectData.target_type_from_name(
		str(value.get("target", "player"))
	)
	effect.amount = int(value.get("amount", 0))
	effect.element = StringName(str(value.get("element", "physical")))
	effect.status_id = StringName(str(value.get("status_id", "")))
	effect.duration = int(value.get("duration", -1))
	effect.condition_type = CombatEffectData.condition_type_from_name(
		str(value.get("condition_type", "always"))
	)
	effect.condition_status_id = StringName(
		str(value.get("condition_status_id", ""))
	)
	effect.required_target_status = StringName(
		str(value.get("required_target_status", ""))
	)
	effect.amount_if_target_has_status = int(
		value.get("amount_if_target_has_status", -1)
	)
	effect.consume_required_status = bool(
		value.get("consume_required_status", false)
	)
	effect.condition_message = str(
		value.get("condition_message", "")
	)
	effect.source_id = StringName(
		str(value.get("source", "combat_effect"))
	)
	return effect


func duplicate_effect() -> ResolvedCombatEffect:
	var copy := ResolvedCombatEffect.new()
	copy.effect_type = effect_type
	copy.target_type = target_type
	copy.explicit_target = explicit_target
	copy.amount = amount
	copy.element = element
	copy.status_id = status_id
	copy.duration = duration
	copy.condition_type = condition_type
	copy.condition_status_id = condition_status_id
	copy.required_target_status = required_target_status
	copy.amount_if_target_has_status = amount_if_target_has_status
	copy.consume_required_status = consume_required_status
	copy.condition_message = condition_message
	copy.source_id = source_id
	return copy


func to_dictionary() -> Dictionary:
	return {
		"type": CombatEffectData.get_effect_type_name_for(effect_type),
		"target": CombatEffectData.get_target_name_for(target_type),
		"amount": amount,
		"element": String(element),
		"status_id": String(status_id),
		"duration": duration,
		"condition_type": (
			CombatEffectData.get_condition_type_name_for(
				condition_type
			)
		),
		"condition_status_id": String(condition_status_id),
		"required_target_status": String(required_target_status),
		"amount_if_target_has_status": amount_if_target_has_status,
		"consume_required_status": consume_required_status,
		"condition_message": condition_message,
		"source": String(source_id)
	}
