class_name GustCombatProperty
extends CombatPropertyHandler


func _init() -> void:
	property_id = &"gust"


func apply(
	action: CombatAction,
	_context: CombatContext,
	effects: Array[ResolvedCombatEffect]
) -> Array[ResolvedCombatEffect]:
	var affected_targets: Array[Node] = []

	for effect in effects:
		if (
			effect.effect_type
				!= CombatEffectData.EffectType.DAMAGE
		):
			continue

		var target := effect.explicit_target

		if (
			target == null
			or affected_targets.has(target)
			or not target.has_method("has_status")
		):
			continue

		affected_targets.append(target)

		if target.has_status(&"cold"):
			effects.append(
				_create_status_effect(
					target,
					&"cold",
					action.caster
				)
			)

		if target.has_status(&"burn"):
			effects.append(
				_create_status_effect(
					target,
					&"burn",
					action.caster
				)
			)

	return effects


func _create_status_effect(
	target: Node,
	status_id: StringName,
	caster: Node
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.APPLY_STATUS
	effect.explicit_target = target
	effect.status_id = status_id
	effect.amount = 1
	effect.source_id = &"gust"
	effect.source_combatant = caster
	return effect
