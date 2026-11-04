# class_name：给脚本注册一个全局类名，其他脚本可以用 GameLogic 引用它。
class_name GameLogic
# RefCounted：引用计数对象；没有节点生命周期，也不需要加入场景树。
extends RefCounted

# 4x4 棋盘的边长；const 声明后不能在运行时重新赋值。
const GRID_SIZE: int = 4

# Array：动态数组；这里每个元素又是一个表示行的数组。
var grid: Array = []
var score: int = 0
var best_score: int = 0
var has_won: bool = false
var game_over: bool = false
var history_stack: Array = []

func _init() -> void:
	# _init 是对象构造函数，调用 GameLogic.new() 时会自动执行。
	reset()

func reset() -> void:
	# 清空游戏状态，并重新创建 GRID_SIZE x GRID_SIZE 的二维数组。
	score = 0
	has_won = false
	game_over = false
	history_stack.clear()
	grid = []
	# range(GRID_SIZE) 生成从 0 到 GRID_SIZE - 1 的整数序列。
	for r in range(GRID_SIZE):
		var row: Array = []
		for c in range(GRID_SIZE):
			row.append(0)
		grid.append(row)

func get_empty_cells() -> Array[Vector2i]:
	# -> Array[Vector2i] 是返回值类型，表示返回只包含 Vector2i 的数组。
	var cells: Array[Vector2i] = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			# 0 代表空格；Vector2i(r, c) 保存行列坐标。
			if grid[r][c] == 0:
				cells.append(Vector2i(r, c))
	return cells

func spawn_tile() -> Dictionary:
	# Dictionary 用键值对返回新方块的位置和值。
	var empty_cells = get_empty_cells()
	if empty_cells.is_empty():
		return {}
	# randi() 生成随机整数；% 是取余运算，用来得到合法数组下标。
	var rand_index = randi() % empty_cells.size()
	var pos: Vector2i = empty_cells[rand_index]
	# 90% 概率生成 2，10% 概率生成 4
	# 条件表达式格式：值1 if 条件 else 值2。
	var val: int = 4 if randf() < 0.1 else 2
	grid[pos.x][pos.y] = val
	return {"pos": pos, "val": val}

func save_state_for_undo() -> void:
	# duplicate() 复制数组，避免撤销快照与当前棋盘共享同一行数组。
	var snapshot_grid: Array = []
	for r in range(GRID_SIZE):
		snapshot_grid.append(grid[r].duplicate())
	# {} 是字典字面量；字典可以一次保存多个带名称的数据。
	history_stack.append({
		"grid": snapshot_grid,
		"score": score,
		"has_won": has_won
	})
	# 仅保留最近 3 步撤回，保证轻量
	if history_stack.size() > 3:
		history_stack.pop_front()

func can_undo() -> bool:
	# not 将布尔值取反；空历史数组表示不能撤销。
	return not history_stack.is_empty()

func undo() -> bool:
	# 返回 bool，让调用方知道撤销是否成功。
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
	# dir 是整数方向向量；函数返回移动结果、动画数据和得分变化。
	if game_over:
		return {"moved": false, "moves": [], "spawn": {}, "score_gained": 0}

	# 先复制移动前状态，成功移动后压入撤销栈。
	var pre_move_snapshot: Array = []
	for r in range(GRID_SIZE):
		pre_move_snapshot.append(grid[r].duplicate())

	var moves: Array = []
	var score_gained: int = 0
	# 使用新数组计算结果，避免边遍历原棋盘边修改造成重复处理。
	var new_grid: Array = []
	for r in range(GRID_SIZE):
		var row: Array = []
		for c in range(GRID_SIZE):
			row.append(0)
		new_grid.append(row)

	var has_any_moved: bool = false

	# == 比较值是否相等；or 表示任意一个方向条件满足即可进入分支。
	if dir == Vector2i.LEFT or dir == Vector2i.RIGHT:
		# 条件表达式根据方向决定遍历顺序。
		var cols = range(GRID_SIZE) if dir == Vector2i.LEFT else range(GRID_SIZE - 1, -1, -1)
		for r in range(GRID_SIZE):
			var target_c = 0 if dir == Vector2i.LEFT else GRID_SIZE - 1
			var step = 1 if dir == Vector2i.LEFT else -1
			# null 表示当前还没有放置过方块；字典记录上一个目标方块。
			var last_placed = null

			for c in cols:
				var v: int = grid[r][c]
				# continue 跳过本次循环，直接处理下一个元素。
				if v == 0:
					continue
				# and 要求所有条件都成立；not 防止一个方块在同一步中合并两次。
				if last_placed != null and last_placed["val"] == v and not last_placed["merged"]:
					# 合并到上一块
					# append() 记录一个移动描述，供界面层播放动画。
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
	# elif：前面的 if 不成立时，再判断垂直方向。
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

	# 没有发生位移或合并时，不生成新方块，也不记录撤销状态。
	if not has_any_moved:
		return {"moved": false, "moves": [], "spawn": {}, "score_gained": 0}

	# 确实发生有效移动，保存撤回快照
	# 有效移动后保存快照；pop_front() 在超过上限时删除最旧记录。
	history_stack.append({
		"grid": pre_move_snapshot,
		"score": score,
		"has_won": has_won
	})
	if history_stack.size() > 5:
		history_stack.pop_front()

	# 将计算完成的新棋盘替换为当前棋盘。
	grid = new_grid
	score += score_gained
	if score > best_score:
		best_score = score

	# 胜负检测
	# 只在第一次达到 2048 时将 newly_won 设为 true。
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

	# 移动成功后随机生成一个新方块。
	var spawn_info = spawn_tile()

	# 检查是否无路可走 Game Over
	check_game_over()

	# 返回字典；调用方通过 result["moves"] 等键读取结果。
	return {
		"moved": true,
		"moves": moves,
		"spawn": spawn_info,
		"score_gained": score_gained,
		"newly_won": newly_won,
		"game_over": game_over
	}

func check_game_over() -> void:
	# 先检查是否有空格；有空格就一定还能继续。
	if not get_empty_cells().is_empty():
		game_over = false
		return
	# 无空格子时，只检查右侧和下侧，避免重复检查相邻组合。
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var v = grid[r][c]
			# 短路判断：前一个条件为 false 时，不再计算后面的数组访问。
			if r + 1 < GRID_SIZE and grid[r + 1][c] == v:
				game_over = false
				return
			if c + 1 < GRID_SIZE and grid[r][c + 1] == v:
				game_over = false
				return
	game_over = true
