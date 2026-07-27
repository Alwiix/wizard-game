extends Node


func _ready() -> void:
	var errors := ContentValidator.validate_all()

	for validation_error in errors:
		push_error(validation_error)

	assert(
		errors.is_empty(),
		"Content validation failed with "
			+ str(errors.size())
			+ " errors."
	)

	print("Content validation test passed.")
	get_tree().quit()
