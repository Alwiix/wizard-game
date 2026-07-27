class_name EnemyData
extends Resource


@export_group("Identity")
@export var enemy_id: StringName = &"enemy"
@export var display_name: String = "Enemy"
@export var artwork: Texture2D

@export_group("Stats")
@export var maximum_health: int = 20

@export_group("Move Pattern")
@export var moves: Array[EnemyMoveData] = []
