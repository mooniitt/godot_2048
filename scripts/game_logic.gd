class_name GameLogic
extends RefCounted

const GRID_SIZE: int = 4

var grid: Array = []
var score: int = 0
var best_score: int = 0
var has_won: bool = false
var game_over: bool = false
var history_stack: Array = []

func _init() -> void:
	reset()

func reset() -> void:
	score = 0
	has_won = false
	game_over = false
	history_stack.clear()
	grid = []
	for r in range(GRID_SIZE):
		var row: Array = []
		for c in range(GRID_SIZE):
			row.append(0)
		grid.append(row)

func get_empty_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if grid[r][c] == 0:
				cells.append(Vector2i(r, c))
	return cells

func spawn_tile() -> Dictionary:
	var empty_cells = get_empty_cells()
	if empty_cells.is_empty():
		return {}
	var rand_index = randi() % empty_cells.size()
	var pos: Vector2i = empty_cells[rand_index]
	# 90% 概率生成 2，10% 概率生成 4
	var val: int = 4 if randf() < 0.1 else 2
	grid[pos.x][pos.y] = val
	return {"pos": pos, "val": val}

func save_state_for_undo() -> void:
	var snapshot_grid: Array = []
	for r in range(GRID_SIZE):
		snapshot_grid.append(grid[r].duplicate())
	history_stack.append({
		"grid": snapshot_grid,
		"score": score,
		"has_won": has_won
	})
	# 仅保留最近 3 步撤回，保证轻量
	if history_stack.size() > 3:
		history_stack.pop_front()

func can_undo() -> bool:
	return not history_stack.is_empty()

func undo() -> bool:
	if history_stack.is_empty():
		return false
	var last_state: Dictionary = history_stack.pop_back()
	grid = []
	for r in range(GRID_SIZE):
		grid.append(last_state["grid"][r].duplicate())
	score = last_state["score"]
	has_won = last_state["has_won"]
	game_over = false
	return true

# dir: Vector2i.UP (-1, 0), DOWN (1, 0), LEFT (0, -1), RIGHT (0, 1)
func move(dir: Vector2i) -> Dictionary:
	if game_over:
		return {"moved": false, "moves": [], "spawn": {}, "score_gained": 0}

	var pre_move_snapshot: Array = []
	for r in range(GRID_SIZE):
		pre_move_snapshot.append(grid[r].duplicate())

	var moves: Array = []
	var score_gained: int = 0
	var new_grid: Array = []
	for r in range(GRID_SIZE):
		var row: Array = []
		for c in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)

	var has_any_moved: bool = false

	if dir == Vector2i.LEFT or dir == Vector2i.RIGHT:
		var cols = range(GRID_SIZE) if dir == Vector2i.LEFT else range(GRID_SIZE - 1, -1, -1)
		for r in range(GRID_SIZE):
			var target_c = 0 if dir == Vector2i.LEFT else GRID_SIZE - 1
			var step = 1 if dir == Vector2i.LEFT else -1
			var last_placed = null

			for c in cols:
				var v: int = grid[r][c]
				if v == 0:
					continue
				if last_placed != null and last_placed["val"] == v and not last_placed["merged"]:
					# 合并到上一块
					moves.append({
						"from": Vector2i(r, c),
						"to": last_placed["pos"],
						"val": v,
						"merged": true,
						"result_val": v * 2
					})
					last_placed["val"] = v * 2
					last_placed["merged"] = true
					new_grid[last_placed["pos"].x][last_placed["pos"].y] = v * 2
					score_gained += v * 2
					has_any_moved = true
				else:
					var target_pos = Vector2i(r, target_c)
					var moved = (target_pos != Vector2i(r, c))
					if moved:
						has_any_moved = true
					moves.append({
						"from": Vector2i(r, c),
						"to": target_pos,
						"val": v,
						"merged": false,
						"result_val": v
					})
					last_placed = {
						"pos": target_pos,
						"val": v,
						"merged": false
					}
					new_grid[target_pos.x][target_pos.y] = v
					target_c += step
	elif dir == Vector2i.UP or dir == Vector2i.DOWN:
		var rows = range(GRID_SIZE) if dir == Vector2i.UP else range(GRID_SIZE - 1, -1, -1)
		for c in range(GRID_SIZE):
			var target_r = 0 if dir == Vector2i.UP else GRID_SIZE - 1
			var step = 1 if dir == Vector2i.UP else -1
			var last_placed = null

			for r in rows:
				var v: int = grid[r][c]
				if v == 0:
					continue
				if last_placed != null and last_placed["val"] == v and not last_placed["merged"]:
					# 合并
					moves.append({
						"from": Vector2i(r, c),
						"to": last_placed["pos"],
						"val": v,
						"merged": true,
						"result_val": v * 2
					})
					last_placed["val"] = v * 2
					last_placed["merged"] = true
					new_grid[last_placed["pos"].x][last_placed["pos"].y] = v * 2
					score_gained += v * 2
					has_any_moved = true
				else:
					var target_pos = Vector2i(target_r, c)
					var moved = (target_pos != Vector2i(r, c))
					if moved:
						has_any_moved = true
					moves.append({
						"from": Vector2i(r, c),
						"to": target_pos,
						"val": v,
						"merged": false,
						"result_val": v
					})
					last_placed = {
						"pos": target_pos,
						"val": v,
						"merged": false
					}
					new_grid[target_pos.x][target_pos.y] = v
					target_r += step

	if not has_any_moved:
		return {"moved": false, "moves": [], "spawn": {}, "score_gained": 0}

	# 确实发生有效移动，保存撤回快照
	history_stack.append({
		"grid": pre_move_snapshot,
		"score": score,
		"has_won": has_won
	})
	if history_stack.size() > 5:
		history_stack.pop_front()

	grid = new_grid
	score += score_gained
	if score > best_score:
		best_score = score

	# 胜负检测
	var newly_won = false
	if not has_won:
		for r in range(GRID_SIZE):
			for c in range(GRID_SIZE):
				if grid[r][c] >= 2048:
					has_won = true
					newly_won = true
					break
			if newly_won:
				break

	# 生成新方块
	var spawn_info = spawn_tile()

	# 检查是否无路可走 Game Over
	check_game_over()

	return {
		"moved": true,
		"moves": moves,
		"spawn": spawn_info,
		"score_gained": score_gained,
		"newly_won": newly_won,
		"game_over": game_over
	}

func check_game_over() -> void:
	if not get_empty_cells().is_empty():
		game_over = false
		return
	# 无空格子时，检查四周是否有相邻相等项
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var v = grid[r][c]
			if r + 1 < GRID_SIZE and grid[r + 1][c] == v:
				game_over = false
				return
			if c + 1 < GRID_SIZE and grid[r][c + 1] == v:
				game_over = false
				return
	game_over = true
