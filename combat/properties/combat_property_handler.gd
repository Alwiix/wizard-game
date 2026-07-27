class_name CombatPropertyHandler
extends RefCounted


var property_id: StringName = &"property"


func apply(
	_action: CombatAction,
	_context: CombatContext,
	effects: Array[ResolvedCombatEffect]
) -> Array[ResolvedCombatEffect]:
	return effects
