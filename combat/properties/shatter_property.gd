class_name ShatterCombatProperty
extends CombatPropertyHandler


func _init() -> void:
	property_id = &"shatter"


func apply(
	_action: CombatAction,
	_context: CombatContext,
	effects: Array[ResolvedCombatEffect]
) -> Array[ResolvedCombatEffect]:
	var frozen_damage_targets: Array[Node] = []

	for effect in effects:
		if (
			effect.effect_type
				!= CombatEffectData.EffectType.DAMAGE
		):
			continue

		var target := effect.explicit_target

		if (
			target != null
			and target.has_method("has_status")
			and target.has_status(&"frozen")
			and not frozen_damage_targets.has(target)
		):
			frozen_damage_targets.append(target)

	for target in frozen_damage_targets:
		effects.append(_create_remove_frozen(target))
		effects.append(_create_shatter_damage(target))
		effects.append(_create_shatter_bleed(target))

	return effects


func _create_remove_frozen(target: Node) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.REMOVE_STATUS
	effect.explicit_target = target
	effect.status_id = &"frozen"
	effect.source_id = &"shatter"
	return effect


func _create_shatter_damage(target: Node) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.DAMAGE
	effect.explicit_target = target
	effect.amount = 3
	effect.element = &"physical"
	effect.source_id = &"shatter"
	return effect


func _create_shatter_bleed(target: Node) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.APPLY_STATUS
	effect.explicit_target = target
	effect.status_id = &"bleed"
	effect.amount = 2
	effect.duration = -1
	effect.source_id = &"shatter"
	return effect
