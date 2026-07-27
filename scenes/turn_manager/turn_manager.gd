extends Node


signal player_turn_started
signal enemy_turn_started
signal battle_ended


enum TurnState {
	PLAYER,
	ENEMY,
	BATTLE_OVER
}


var current_turn: TurnState = TurnState.BATTLE_OVER


func start_battle() -> void:
	current_turn = TurnState.PLAYER

	print("TurnManager: player turn started")
	player_turn_started.emit()


func end_player_turn() -> void:
	if current_turn != TurnState.PLAYER:
		return

	current_turn = TurnState.ENEMY

	print("TurnManager: enemy turn started")
	enemy_turn_started.emit()


func finish_enemy_turn() -> void:
	if current_turn != TurnState.ENEMY:
		return

	current_turn = TurnState.PLAYER

	print("TurnManager: player turn started")
	player_turn_started.emit()


func end_battle() -> void:
	if current_turn == TurnState.BATTLE_OVER:
		return

	current_turn = TurnState.BATTLE_OVER

	print("TurnManager: battle ended")
	battle_ended.emit()


func is_player_turn() -> bool:
	return current_turn == TurnState.PLAYER


func is_enemy_turn() -> bool:
	return current_turn == TurnState.ENEMY


func is_battle_over() -> bool:
	return current_turn == TurnState.BATTLE_OVER
