class_name CombatPropertyRegistry
extends RefCounted


const PROPERTY_SCRIPTS: Dictionary = {
	&"electric": preload(
		"res://combat/properties/electric_property.gd"
	),
	&"shatter": preload(
		"res://combat/properties/shatter_property.gd"
	),
	&"ignite": preload(
		"res://combat/properties/ignite_property.gd"
	),
	&"gust": preload(
		"res://combat/properties/gust_property.gd"
	)
}


static func prepare_effects(
	action: CombatAction,
	context: CombatContext
) -> Array[ResolvedCombatEffect]:
	var effects: Array[ResolvedCombatEffect] = []

	for effect_data in action.effects:
		if effect_data == null:
			continue

		var targets := context.resolve_targets(
			effect_data.target,
			action
		)

		for target in targets:
			var runtime_effect := ResolvedCombatEffect.from_data(
				effect_data
			)
			runtime_effect.explicit_target = target
			runtime_effect.source_id = action.action_id
			runtime_effect.source_combatant = action.caster
			effects.append(runtime_effect)

	for property_value in action.properties:
		var property_id := StringName(
			String(property_value).to_lower()
		)

		if not PROPERTY_SCRIPTS.has(property_id):
			push_warning(
				"Unknown combat property: " + String(property_id)
			)
			continue

		var handler: CombatPropertyHandler = (
			PROPERTY_SCRIPTS[property_id].new()
			as CombatPropertyHandler
		)

		if handler == null:
			continue

		effects = handler.apply(action, context, effects)

	if (
		action.caster != null
		and action.caster.has_method("modify_outgoing_damage")
	):
		for effect in effects:
			if (
				effect.effect_type
				== CombatEffectData.EffectType.DAMAGE
			):
				effect.amount = action.caster.modify_outgoing_damage(
					effect.amount
				)

				if effect.amount_if_target_has_status >= 0:
					effect.amount_if_target_has_status = (
						action.caster.modify_outgoing_damage(
							effect.amount_if_target_has_status
						)
					)

	return effects


static func has_property(property_id: StringName) -> bool:
	return PROPERTY_SCRIPTS.has(
		StringName(String(property_id).to_lower())
	)
