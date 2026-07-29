extends HoverExpandButton


signal selection_changed(card, is_selected: bool)


var card_instance: CardInstance
var is_retain_target: bool = false


func setup(new_card_instance: CardInstance) -> void:
	card_instance = new_card_instance

	update_display()


func _ready() -> void:
	toggle_mode = true
	toggled.connect(_on_toggled)

	update_display()


func update_display() -> void:
	if card_instance == null:
		text = "Missing card data"
		tooltip_text = text
		return

	text = (
		card_instance.data.display_name
		+ "\nSpell ingredient"
	)

	var cost_modifier := card_instance.get_spell_cost_modifier()

	if cost_modifier != 0:
		text += (
			"\nSpell cost "
			+ ("+" if cost_modifier > 0 else "")
			+ str(cost_modifier)
		)

	if card_instance.is_retained_this_turn:
		text += "\nRetain"
	elif card_instance.has_permanent_retain():
		text += "\nRetain"
	elif is_retain_target:
		text += "\nChoose to Retain"

	var upgrade_names: Array[String] = (
		card_instance.get_upgrade_display_names()
	)

	if not upgrade_names.is_empty():
		text += "\n" + ", ".join(upgrade_names)

	tooltip_text = text


func get_element_name() -> String:
	if card_instance == null:
		return ""

	return card_instance.get_element_name()


func get_energy_cost() -> int:
	if card_instance == null:
		return 0

	return card_instance.get_energy_cost()


func get_spell_cost_modifier(cast_slot: int = -1) -> int:
	if card_instance == null:
		return 0

	return card_instance.get_spell_cost_modifier(cast_slot)


func set_retain_targeting(is_target: bool) -> void:
	is_retain_target = is_target
	update_display()


func _on_toggled(is_selected: bool) -> void:
	selection_changed.emit(self, is_selected)
