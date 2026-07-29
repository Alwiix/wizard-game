class_name StatusRegistry
extends RefCounted


const STATUS_SCRIPTS: Dictionary = {
	&"block": preload("res://statuses/effects/block_status.gd"),
	&"burn": preload("res://statuses/effects/burn_status.gd"),
	&"wet": preload("res://statuses/effects/wet_status.gd"),
	&"infection": preload(
		"res://statuses/effects/infection_status.gd"
	),
	&"stunned": preload(
		"res://statuses/effects/stunned_status.gd"
	),
	&"frozen": preload(
		"res://statuses/effects/frozen_status.gd"
	),
	&"dazed": preload("res://statuses/effects/dazed_status.gd"),
	&"dodge": preload("res://statuses/effects/dodge_status.gd"),
	&"electrified": preload(
		"res://statuses/effects/electrified_status.gd"
	),
	&"cold": preload("res://statuses/effects/cold_status.gd"),
	&"stormcloud": preload(
		"res://statuses/effects/stormcloud_status.gd"
	),
	&"bleed": preload("res://statuses/effects/bleed_status.gd"),
	&"dazing_guard": preload(
		"res://statuses/effects/dazing_guard_status.gd"
	),
	&"electrified_guard": preload(
		"res://statuses/effects/electrified_guard_status.gd"
	),
	&"spell_discount": preload(
		"res://statuses/effects/spell_discount_status.gd"
	),
	&"bonus_draw": preload(
		"res://statuses/effects/bonus_draw_status.gd"
	),
	&"bonus_energy": preload(
		"res://statuses/effects/bonus_energy_status.gd"
	),
	&"muddy": preload(
		"res://statuses/effects/muddy_status.gd"
	),
	&"firebreathing": preload(
		"res://statuses/effects/firebreathing_status.gd"
	),
	&"creeping_vines": preload(
		"res://statuses/effects/creeping_vines_status.gd"
	),
	&"oil": preload(
		"res://statuses/effects/oil_status.gd"
	)
}


static func has_status(status_id: StringName) -> bool:
	return STATUS_SCRIPTS.has(_normalize(status_id))


static func create_status(
	status_id: StringName
) -> StatusEffect:
	var normalized_id := _normalize(status_id)

	if not STATUS_SCRIPTS.has(normalized_id):
		return null

	return STATUS_SCRIPTS[normalized_id].new() as StatusEffect


static func get_status_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	for status_id in STATUS_SCRIPTS.keys():
		result.append(status_id)

	return result


static func _normalize(status_id: StringName) -> StringName:
	return StringName(String(status_id).to_lower())
