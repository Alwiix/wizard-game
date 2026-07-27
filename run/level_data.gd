class_name LevelData
extends Resource


@export_group("Identity")
@export var level_id: StringName = &"level"
@export var display_name: String = "Level"

@export_group("Encounters")
@export var encounters: Array[EncounterData] = []
