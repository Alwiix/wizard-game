class_name CombatEffectResolver
extends Node


var combat_deck: CombatDeck
var battle_modifiers: BattleModifierController


func setup(
	deck: CombatDeck,
	modifier_controller: BattleModifierController
) -> void:
	combat_deck = deck
	battle_modifiers = modifier_controller


func resolve_action(
	action: CombatAction,
	context: CombatContext
) -> CombatResult:
	if action == null or context == null:
		return CombatResult.new()

	var prepared_effects := CombatPropertyRegistry.prepare_effects(
		action,
		context
	)
	return await resolve_runtime_effects(
		prepared_effects,
		context
	)


# Compatibility adapter for tests and older call sites. New combat code
# should construct a CombatAction and call resolve_action().
func resolve_effects(
	effects: Array,
	player: Node,
	enemy: Node
) -> Dictionary:
	var context := CombatContext.create(
		player,
		[enemy] if enemy != null else [],
		enemy,
		combat_deck,
		battle_modifiers
	)
	var runtime_effects: Array[ResolvedCombatEffect] = []

	for effect_value in effects:
		var effect := _convert_to_runtime_effect(effect_value)

		if effect == null:
			continue

		if effect.explicit_target == null:
			var targets := context.resolve_targets(
				effect.target_type,
				CombatAction.new()
			)

			for target in targets:
				var target_effect := effect.duplicate_effect()
				target_effect.explicit_target = target
				runtime_effects.append(target_effect)
		else:
			runtime_effects.append(effect)

	var result := await resolve_runtime_effects(
		runtime_effects,
		context
	)
	return result.to_dictionary()


func resolve_runtime_effects(
	effects: Array[ResolvedCombatEffect],
	context: CombatContext
) -> CombatResult:
	var result := CombatResult.new()

	for effect in effects:
		if effect == null:
			continue

		var target := effect.explicit_target

		if target == null or not is_instance_valid(target):
			continue

		if not _effect_condition_is_met(effect, target):
			continue

		result.record_target(target)

		match effect.effect_type:
			CombatEffectData.EffectType.DAMAGE:
				_resolve_damage(effect, target, context, result)

			CombatEffectData.EffectType.HEAL:
				_resolve_healing(effect, target, context, result)

			CombatEffectData.EffectType.DRAW_CARDS:
				_resolve_draw(effect, result)

			CombatEffectData.EffectType.RETAIN_CARDS:
				await _resolve_retain(effect, result)

			CombatEffectData.EffectType.APPLY_BATTLE_MODIFIER:
				_resolve_battle_modifier(
					effect,
					target,
					result
				)

			CombatEffectData.EffectType.APPLY_STATUS:
				_resolve_apply_status(
					effect,
					target,
					context,
					result
				)

			CombatEffectData.EffectType.REMOVE_STATUS:
				if (
					effect.status_id != &""
					and target.has_method("remove_status")
				):
					target.remove_status(effect.status_id)

	return result


func _resolve_damage(
	effect: ResolvedCombatEffect,
	target: Node,
	context: CombatContext,
	result: CombatResult
) -> void:
	if not target.has_method("take_damage"):
		push_warning("Effect target cannot receive damage.")
		return

	var condition_was_met := _target_meets_status_condition(
		effect,
		target
	)
	var requested_damage := _get_effect_amount(
		effect,
		condition_was_met
	)
	var damage_dealt: int = target.take_damage(
		requested_damage,
		{
			"source": String(effect.source_id),
			"element": String(effect.element)
		}
	)

	result.total_health_damage += damage_dealt
	result.record_damage(target, damage_dealt)
	result.add_message(
		"Dealt "
		+ str(damage_dealt)
		+ " damage to "
		+ context.get_target_display_name(target)
		+ "."
	)

	if not condition_was_met:
		return

	result.add_message(effect.condition_message)

	if (
		effect.consume_required_status
		and effect.required_target_status != &""
		and target.has_method("remove_status")
	):
		target.remove_status(effect.required_target_status)


func _resolve_healing(
	effect: ResolvedCombatEffect,
	target: Node,
	context: CombatContext,
	result: CombatResult
) -> void:
	if not target.has_method("heal"):
		push_warning("Effect target cannot receive healing.")
		return

	var healing_received: int = target.heal(
		max(effect.amount, 0),
		{"source": String(effect.source_id)}
	)
	result.total_health_healed += healing_received
	result.add_message(
		"Restored "
		+ str(healing_received)
		+ " health to "
		+ context.get_target_display_name(target)
		+ "."
	)


func _resolve_draw(
	effect: ResolvedCombatEffect,
	result: CombatResult
) -> void:
	if combat_deck == null:
		push_warning("Draw effect has no CombatDeck.")
		return

	var cards_drawn := combat_deck.draw_cards(max(effect.amount, 0))
	result.add_message(
		"Drew "
		+ str(cards_drawn)
		+ _get_card_word(cards_drawn)
		+ "."
	)


func _resolve_retain(
	effect: ResolvedCombatEffect,
	result: CombatResult
) -> void:
	if combat_deck == null:
		push_warning("Retain effect has no CombatDeck.")
		return

	var cards_retained: int = await (
		combat_deck.choose_cards_to_retain(max(effect.amount, 0))
	)
	result.add_message(
		"Retained "
		+ str(cards_retained)
		+ _get_card_word(cards_retained)
		+ "."
	)


func _resolve_battle_modifier(
	effect: ResolvedCombatEffect,
	target: Node,
	result: CombatResult
) -> void:
	if battle_modifiers == null:
		push_warning("Battle modifier effect has no controller.")
		return

	if battle_modifiers.apply_modifier(
		effect.status_id,
		target,
		effect.amount,
		effect.duration
	):
		result.add_message(
			String(effect.status_id).capitalize() + " is active."
		)


func _resolve_apply_status(
	effect: ResolvedCombatEffect,
	target: Node,
	context: CombatContext,
	result: CombatResult
) -> void:
	if (
		effect.status_id == &""
		or not target.has_method("add_status")
	):
		return

	var status_was_applied := bool(
		target.add_status(
			effect.status_id,
			effect.amount,
			effect.duration
		)
	)

	if status_was_applied:
		result.add_message(
			"Applied "
			+ String(effect.status_id).capitalize()
			+ " to "
			+ context.get_target_display_name(target)
			+ "."
		)
	elif (
		effect.status_id == &"burn"
		and target.has_method("has_status")
		and target.has_status(&"wet")
	):
		result.add_message(
			"Wet prevented Burn on "
			+ context.get_target_display_name(target)
			+ "."
		)


func _convert_to_runtime_effect(
	effect_value: Variant
) -> ResolvedCombatEffect:
	if effect_value is ResolvedCombatEffect:
		return effect_value

	if effect_value is CombatEffectData:
		return ResolvedCombatEffect.from_data(effect_value)

	if effect_value is Dictionary:
		return ResolvedCombatEffect.from_dictionary(effect_value)

	return null


func _target_meets_status_condition(
	effect: ResolvedCombatEffect,
	target: Node
) -> bool:
	if effect.required_target_status == &"":
		return false

	if not target.has_method("has_status"):
		return false

	return bool(target.has_status(effect.required_target_status))


func _effect_condition_is_met(
	effect: ResolvedCombatEffect,
	target: Node
) -> bool:
	if (
		effect.condition_type
		== CombatEffectData.ConditionType.ALWAYS
	):
		return true

	if (
		effect.condition_status_id == &""
		or not target.has_method("has_status")
	):
		return false

	var target_has_status := bool(
		target.has_status(effect.condition_status_id)
	)

	match effect.condition_type:
		CombatEffectData.ConditionType.TARGET_HAS_STATUS:
			return target_has_status
		CombatEffectData.ConditionType.TARGET_LACKS_STATUS:
			return not target_has_status
		_:
			return false


func _get_effect_amount(
	effect: ResolvedCombatEffect,
	condition_was_met: bool
) -> int:
	if (
		condition_was_met
		and effect.amount_if_target_has_status >= 0
	):
		return effect.amount_if_target_has_status

	return effect.amount


func effects_include_damage(effects: Array) -> bool:
	for effect_value in effects:
		var effect := _convert_to_runtime_effect(effect_value)

		if (
			effect != null
			and effect.effect_type
				== CombatEffectData.EffectType.DAMAGE
		):
			return true

	return false


func _get_card_word(amount: int) -> String:
	if amount == 1:
		return " card"

	return " cards"
