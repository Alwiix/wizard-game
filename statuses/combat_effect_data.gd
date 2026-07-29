class_name CombatEffectData
extends Resource


enum EffectType {
	DAMAGE,
	APPLY_STATUS,
	REMOVE_STATUS,
	HEAL,
	DRAW_CARDS,
	RETAIN_CARDS,
	APPLY_BATTLE_MODIFIER,
	MULTIPLY_STATUS,
	CONVERT_STATUS
}


enum TargetType {
	PLAYER,
	ENEMY,
	CASTER,
	PRIMARY_TARGET,
	ALL_ENEMIES,
	ALL_OPPONENTS,
	ALL_COMBATANTS
}


enum ConditionType {
	ALWAYS,
	TARGET_HAS_STATUS,
	TARGET_LACKS_STATUS,
	NO_ENEMY_HAS_STATUS
}


@export_group("Main Effect")
@export var effect_type: EffectType = EffectType.DAMAGE
@export var target: TargetType = TargetType.PLAYER
@export var amount: int = 0

@export_group("Damage")
@export var element: StringName = &"physical"

@export_group("Status")
@export var status_id: StringName = &""
@export var converted_status_id: StringName = &""
@export var duration: int = -1

@export_group("Effect Condition")
@export var condition_type: ConditionType = ConditionType.ALWAYS
@export var condition_status_id: StringName = &""

@export_group("Optional Condition")
@export var required_target_status: StringName = &""
@export var amount_if_target_has_status: int = -1
@export var consume_required_status: bool = false
@export_multiline var condition_message: String = ""


func to_effect_dictionary() -> Dictionary:
	return {
		"type": get_effect_type_name(),
		"target": get_target_name(),
		"amount": amount,
		"element": String(element),
		"status_id": String(status_id),
		"converted_status_id": String(converted_status_id),
		"duration": duration,
		"condition_type": get_condition_type_name(),
		"condition_status_id": String(condition_status_id),
		"required_target_status": String(required_target_status),
		"amount_if_target_has_status": amount_if_target_has_status,
		"consume_required_status": consume_required_status,
		"condition_message": condition_message
	}


func to_runtime_effect() -> ResolvedCombatEffect:
	return ResolvedCombatEffect.from_data(self)


func get_effect_type_name() -> String:
	return get_effect_type_name_for(effect_type)


static func get_effect_type_name_for(
	value: EffectType
) -> String:
	match value:
		EffectType.DAMAGE:
			return "damage"
		EffectType.APPLY_STATUS:
			return "apply_status"
		EffectType.REMOVE_STATUS:
			return "remove_status"
		EffectType.HEAL:
			return "heal"
		EffectType.DRAW_CARDS:
			return "draw_cards"
		EffectType.RETAIN_CARDS:
			return "retain_cards"
		EffectType.APPLY_BATTLE_MODIFIER:
			return "apply_battle_modifier"
		EffectType.MULTIPLY_STATUS:
			return "multiply_status"
		EffectType.CONVERT_STATUS:
			return "convert_status"
		_:
			return ""


func get_condition_type_name() -> String:
	return get_condition_type_name_for(condition_type)


static func get_condition_type_name_for(
	value: ConditionType
) -> String:
	match value:
		ConditionType.ALWAYS:
			return "always"
		ConditionType.TARGET_HAS_STATUS:
			return "target_has_status"
		ConditionType.TARGET_LACKS_STATUS:
			return "target_lacks_status"
		ConditionType.NO_ENEMY_HAS_STATUS:
			return "no_enemy_has_status"
		_:
			return "always"


func get_target_name() -> String:
	return get_target_name_for(target)


static func get_target_name_for(value: TargetType) -> String:
	match value:
		TargetType.PLAYER:
			return "player"
		TargetType.ENEMY:
			return "enemy"
		TargetType.CASTER:
			return "caster"
		TargetType.PRIMARY_TARGET:
			return "primary_target"
		TargetType.ALL_ENEMIES:
			return "all_enemies"
		TargetType.ALL_OPPONENTS:
			return "all_opponents"
		TargetType.ALL_COMBATANTS:
			return "all_combatants"
		_:
			return ""


static func effect_type_from_name(value: String) -> EffectType:
	match value.to_lower():
		"apply_status":
			return EffectType.APPLY_STATUS
		"remove_status":
			return EffectType.REMOVE_STATUS
		"heal":
			return EffectType.HEAL
		"draw_cards":
			return EffectType.DRAW_CARDS
		"retain_cards":
			return EffectType.RETAIN_CARDS
		"apply_battle_modifier":
			return EffectType.APPLY_BATTLE_MODIFIER
		"multiply_status":
			return EffectType.MULTIPLY_STATUS
		"convert_status":
			return EffectType.CONVERT_STATUS
		_:
			return EffectType.DAMAGE


static func condition_type_from_name(value: String) -> ConditionType:
	match value.to_lower():
		"target_has_status":
			return ConditionType.TARGET_HAS_STATUS
		"target_lacks_status":
			return ConditionType.TARGET_LACKS_STATUS
		"no_enemy_has_status":
			return ConditionType.NO_ENEMY_HAS_STATUS
		_:
			return ConditionType.ALWAYS


static func target_type_from_name(value: String) -> TargetType:
	match value.to_lower():
		"enemy":
			return TargetType.ENEMY
		"caster":
			return TargetType.CASTER
		"primary_target":
			return TargetType.PRIMARY_TARGET
		"all_enemies":
			return TargetType.ALL_ENEMIES
		"all_opponents":
			return TargetType.ALL_OPPONENTS
		"all_combatants":
			return TargetType.ALL_COMBATANTS
		_:
			return TargetType.PLAYER
