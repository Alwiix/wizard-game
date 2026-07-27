class_name ElectricCombatProperty
extends CombatPropertyHandler


const WET_DAMAGE_MULTIPLIER: float = 1.5


func _init() -> void:
	property_id = &"electric"


func apply(
	_action: CombatAction,
	_context: CombatContext,
	effects: Array[ResolvedCombatEffect]
) -> Array[ResolvedCombatEffect]:
	for effect in effects:
		if (
			effect.effect_type
				!= CombatEffectData.EffectType.DAMAGE
		):
			continue

		var target := effect.explicit_target

		if (
			target == null
			or not target.has_method("has_status")
			or not target.has_status(&"wet")
		):
			continue

		effect.amount = roundi(
			effect.amount * WET_DAMAGE_MULTIPLIER
		)

		if effect.amount_if_target_has_status >= 0:
			effect.amount_if_target_has_status = roundi(
				effect.amount_if_target_has_status
				* WET_DAMAGE_MULTIPLIER
			)

	return effects
