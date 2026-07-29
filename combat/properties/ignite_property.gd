class_name IgniteCombatProperty
extends CombatPropertyHandler


const EXPLOSION_THRESHOLD: int = 5
const EXPLOSION_DAMAGE: int = 8


func _init() -> void:
	property_id = &"ignite"


func apply(
	action: CombatAction,
	_context: CombatContext,
	effects: Array[ResolvedCombatEffect]
) -> Array[ResolvedCombatEffect]:
	var ignited_targets: Array[Node] = []

	for effect in effects:
		if (
			effect.effect_type
				!= CombatEffectData.EffectType.DAMAGE
		):
			continue

		var target := effect.explicit_target

		if (
			target == null
			or ignited_targets.has(target)
			or not target.has_method("get_status_stacks")
		):
			continue

		var oil_stacks: int = target.get_status_stacks(&"oil")

		if oil_stacks <= 0:
			continue

		ignited_targets.append(target)
		effects.append(
			_create_remove_oil(target, action.caster)
		)
		effects.append(
			_create_burn(target, oil_stacks, action.caster)
		)

		if oil_stacks >= EXPLOSION_THRESHOLD:
			effects.append(
				_create_explosion(target, action.caster)
			)

	return effects


func _create_remove_oil(
	target: Node,
	caster: Node
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.REMOVE_STATUS
	effect.explicit_target = target
	effect.status_id = &"oil"
	effect.source_id = &"ignite"
	effect.source_combatant = caster
	return effect


func _create_burn(
	target: Node,
	amount: int,
	caster: Node
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.APPLY_STATUS
	effect.explicit_target = target
	effect.status_id = &"burn"
	effect.amount = amount
	effect.source_id = &"ignite"
	effect.source_combatant = caster
	return effect


func _create_explosion(
	target: Node,
	caster: Node
) -> ResolvedCombatEffect:
	var effect := ResolvedCombatEffect.new()
	effect.effect_type = CombatEffectData.EffectType.DAMAGE
	effect.explicit_target = target
	effect.amount = EXPLOSION_DAMAGE
	effect.element = &"fire"
	effect.source_id = &"ignite"
	effect.source_combatant = caster
	return effect
