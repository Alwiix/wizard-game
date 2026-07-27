class_name StatusApplication
extends RefCounted


var status_id: StringName
var amount: int
var duration: int
var accepted: bool = true
var statuses_to_remove: Array[StringName] = []


func _init(
	requested_status_id: StringName,
	requested_amount: int,
	requested_duration: int
) -> void:
	status_id = requested_status_id
	amount = requested_amount
	duration = requested_duration


func remove_existing(status_to_remove: StringName) -> void:
	if not statuses_to_remove.has(status_to_remove):
		statuses_to_remove.append(status_to_remove)
