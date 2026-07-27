class_name CombatEvents
extends Node


signal battle_started(
	player: Node,
	enemies: Array,
	encounter: Resource
)
signal turn_started(combatant: Node)
signal turn_ended(combatant: Node)

signal card_used(
	combatant: Node,
	card: CardInstance
)
signal spell_cast(
	combatant: Node,
	spell: Dictionary,
	cards: Array
)
signal attack_completed(
	attacker: Node,
	target: Node,
	source: Variant,
	hit: bool,
	damage_dealt: int
)

signal damage_requested(
	target: Node,
	amount: int,
	context: Dictionary
)
signal damage_dealt(
	target: Node,
	requested_amount: int,
	dealt_amount: int,
	context: Dictionary
)
signal healing_requested(
	target: Node,
	amount: int,
	context: Dictionary
)
signal health_restored(
	target: Node,
	requested_amount: int,
	restored_amount: int,
	context: Dictionary
)
signal status_applied(
	target: Node,
	status_id: StringName,
	amount: int,
	duration: int
)
signal combatant_defeated(
	combatant: Node,
	context: Dictionary
)

signal battle_ended(
	result: StringName,
	winner: Variant,
	loser: Variant
)
