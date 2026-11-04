extends SceneTree

const GameLogicClass = preload("res://scripts/game_logic.gd")

func _init() -> void:
	var logic = GameLogicClass.new()
	print("GameLogic initialized. Grid size: ", logic.grid.size())
	logic.grid = [
		[2, 0, 2, 4],
		[0, 0, 0, 0],
		[0, 0, 0, 0],
		[0, 0, 0, 0]
	]
	var res = logic.move(Vector2i.LEFT)
	print("Move LEFT result moved: ", res["moved"], " score gained: ", res["score_gained"])
	print("Row 0: ", logic.grid[0])
	assert(logic.grid[0][0] == 4)
	assert(logic.grid[0][1] == 4)
	print("Moves count: ", res["moves"].size())
	for m in res["moves"]:
		print("Move: ", m)
	print("All tests passed!")
	quit(0)
