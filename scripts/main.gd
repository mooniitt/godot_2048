extends Control

const GameLogicClass = preload("res://scripts/game_logic.gd")
const TileClass = preload("res://scripts/tile.gd")

const SAVE_PATH: String = "user://save_data.cfg"
const SWIPE_THRESHOLD: float = 40.0
const ANIM_DURATION: float = 0.08

# 节点引用
@onready var score_label: Label = %ScoreValue
@onready var best_label: Label = %BestValue
@onready var board_area: Control = %BoardArea
@onready var board_container: Control = %BoardContainer
@onready var board_bg: Panel = %BoardBg
@onready var grid_slots_container: Control = %GridSlots
@onready var tiles_layer: Control = %TilesLayer
@onready var overlay: Panel = %Overlay
@onready var overlay_title: Label = %TitleLabel
@onready var overlay_msg: Label = %MsgLabel
@onready var overlay_btn: Button = %ActionButton
@onready var undo_btn: Button = %UndoBtn
@onready var restart_btn: Button = %RestartBtn

var logic: GameLogicClass
# 二维数组存储当前活动的 Tile 节点引用: tile_map[r][c]
var tile_map: Array = []

var is_animating: bool = false
var touch_start_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false
var has_swiped_current_gesture: bool = false
var restart_confirmation_pending: bool = false
var overlay_mode: String = ""

# 几何尺寸动态自适应参数
var board_size: float = 400.0
var pad: float = 12.0
var gap: float = 12.0
var cell_size: float = 80.0

func _ready() -> void:
	logic = GameLogicClass.new()
	load_best_score()
	
	restart_btn.pressed.connect(_on_restart_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	overlay_btn.pressed.connect(_on_overlay_action_pressed)
	
	board_area.resized.connect(_on_board_area_resized)
	
	init_board_layout()
	call_deferred("_initialize_game")

func _initialize_game() -> void:
	_recalc_board_dimensions()
	start_new_game()

func load_best_score() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		logic.best_score = config.get_value("game", "best_score", 0)
	update_score_ui()

func save_best_score() -> void:
	var config = ConfigFile.new()
	config.set_value("game", "best_score", logic.best_score)
	config.save(SAVE_PATH)

func init_board_layout() -> void:
	for r in range(4):
		var row: Array = []
		for c in range(4):
			row.append(null)
		tile_map.append(row)
	_recalc_board_dimensions()

func _on_board_area_resized() -> void:
	_recalc_board_dimensions()
	_update_all_tile_positions()

# 核心自适应逻辑：支持手机细长屏与 iPad 4:3 屏幕
func _recalc_board_dimensions() -> void:
	if not is_inside_tree() or board_area == null:
		return
	var area_size: Vector2 = board_area.size
	if area_size.x <= 0 or area_size.y <= 0:
		return
	
	# 取宽高的较小值，并限制在合理范围内（在 iPad 上最大不超过 600px，在手机上自适应宽度）
	var max_dim = min(area_size.x - 16.0, area_size.y - 16.0)
	board_size = clamp(max_dim, 260.0, 580.0)
	
	# 设置 BoardContainer 居中
	board_container.size = Vector2(board_size, board_size)
	board_container.position = (area_size - Vector2(board_size, board_size)) / 2.0
	board_bg.size = Vector2(board_size, board_size)
	overlay.size = Vector2(board_size, board_size)
	
	pad = clamp(board_size * 0.03, 8.0, 16.0)
	gap = clamp(board_size * 0.03, 8.0, 16.0)
	cell_size = (board_size - pad * 2.0 - gap * 3.0) / 4.0
	
	_rebuild_grid_background_slots()

func _rebuild_grid_background_slots() -> void:
	for child in grid_slots_container.get_children():
		child.queue_free()
	
	for r in range(4):
		for c in range(4):
			var slot = Panel.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.size = Vector2(cell_size, cell_size)
			slot.position = get_cell_pos(r, c)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color("cdc1b4")
			var radius = int(clamp(cell_size * 0.08, 6, 14))
			style.corner_radius_top_left = radius
			style.corner_radius_top_right = radius
			style.corner_radius_bottom_left = radius
			style.corner_radius_bottom_right = radius
			style.corner_detail = 8
			slot.add_theme_stylebox_override("panel", style)
			
			grid_slots_container.add_child(slot)

func get_cell_pos(r: int, c: int) -> Vector2:
	return Vector2(pad + c * (cell_size + gap), pad + r * (cell_size + gap))

func start_new_game() -> void:
	restart_confirmation_pending = false
	overlay_mode = ""
	overlay.visible = false
	var saved_best: int = logic.best_score
	logic.reset()
	logic.best_score = saved_best
	clear_all_tiles()
	
	# 初始生成 2 个方块
	var s1 = logic.spawn_tile()
	if not s1.is_empty():
		create_tile_at(s1["pos"].x, s1["pos"].y, s1["val"], true)
	var s2 = logic.spawn_tile()
	if not s2.is_empty():
		create_tile_at(s2["pos"].x, s2["pos"].y, s2["val"], true)
		
	update_score_ui()

func clear_all_tiles() -> void:
	for r in range(4):
		for c in range(4):
			tile_map[r][c] = null
	for child in tiles_layer.get_children():
		tiles_layer.remove_child(child)
		child.queue_free()

func create_tile_at(r: int, c: int, val: int, play_anim: bool = true) -> TileClass:
	var tile = TileClass.new()
	tiles_layer.add_child(tile)
	tile.setup(val, Vector2(cell_size, cell_size))
	tile.scale = Vector2.ONE
	tile.rotation = 0.0
	tile.position = get_cell_pos(r, c)
	tile_map[r][c] = tile
	if play_anim:
		tile.play_spawn_animation()
	return tile

func update_score_ui() -> void:
	score_label.text = str(logic.score)
	best_label.text = str(logic.best_score)
	undo_btn.disabled = not logic.can_undo()
	if logic.score > logic.best_score:
		logic.best_score = logic.score
		best_label.text = str(logic.best_score)

func _update_all_tile_positions() -> void:
	for r in range(4):
		for c in range(4):
			var tile = tile_map[r][c]
			if tile != null and is_instance_valid(tile):
				tile.setup(tile.value, Vector2(cell_size, cell_size))
				tile.position = get_cell_pos(r, c)

func handle_move(dir: Vector2i) -> void:
	if is_animating or logic.game_over:
		return
	
	var res = logic.move(dir)
	if not res["moved"]:
		return
		
	is_animating = true
	var moves: Array = res["moves"]
	
	# 收集所有目标位置被合并的原方块
	var merged_targets: Dictionary = {} # Vector2i -> Array[TileClass]
	var moving_tweens: Array = []
	
	for m in moves:
		var from_pos: Vector2i = m["from"]
		var to_pos: Vector2i = m["to"]
		var tile: TileClass = tile_map[from_pos.x][from_pos.y]
		if tile == null:
			continue
			
		var target_pixel_pos = get_cell_pos(to_pos.x, to_pos.y)
		var tw = tile.move_to(target_pixel_pos, ANIM_DURATION)
		moving_tweens.append(tw)
		
		if m["merged"]:
			if not merged_targets.has(to_pos):
				merged_targets[to_pos] = []
			var target_tile: TileClass = tile_map[to_pos.x][to_pos.y]
			if target_tile != null and target_tile != tile and not merged_targets[to_pos].has(target_tile):
				merged_targets[to_pos].append(target_tile)
			merged_targets[to_pos].append(tile)
			tile_map[from_pos.x][from_pos.y] = null
			tile_map[to_pos.x][to_pos.y] = null
		else:
			if from_pos != to_pos:
				tile_map[to_pos.x][to_pos.y] = tile
				tile_map[from_pos.x][from_pos.y] = null
	
	# 创建滑动结束定时器
	get_tree().create_timer(ANIM_DURATION).timeout.connect(func():
		# 销毁被合并的旧方块，并生成新数值方块
		for to_pos in merged_targets.keys():
			var old_tiles = merged_targets[to_pos]
			for ot in old_tiles:
				if is_instance_valid(ot):
					if ot.get_parent() == tiles_layer:
						tiles_layer.remove_child(ot)
					ot.queue_free()
			var new_val = logic.grid[to_pos.x][to_pos.y]
			var new_tile = create_tile_at(to_pos.x, to_pos.y, new_val, false)
			new_tile.play_merge_pop()
			
		# 处理新方块生成
		var spawn_info = res["spawn"]
		if not spawn_info.is_empty():
			var sp_pos = spawn_info["pos"]
			create_tile_at(sp_pos.x, sp_pos.y, spawn_info["val"], true)
			
		update_score_ui()
		save_best_score()
		
		# 胜利检测
		if res.get("newly_won", false):
			show_win_overlay()
		elif res.get("game_over", false):
			show_game_over_overlay()
			
		is_animating = false
	)

func show_game_over_overlay() -> void:
	restart_confirmation_pending = false
	overlay_mode = "game_over"
	overlay_title.text = "游戏结束"
	overlay_msg.text = "没有更多可移动方块！\n最终得分: " + str(logic.score)
	overlay_btn.text = "再玩一次"
	overlay.visible = true

func show_win_overlay() -> void:
	restart_confirmation_pending = false
	overlay_mode = "win"
	overlay_title.text = "太棒了！"
	overlay_msg.text = "成功合成 2048！"
	overlay_btn.text = "继续挑战"
	overlay.visible = true

func _on_overlay_action_pressed() -> void:
	if overlay_mode == "win":
		overlay.visible = false
		restart_confirmation_pending = false
		overlay_mode = ""
	elif overlay_mode == "restart_confirm":
		start_new_game()
	elif overlay_mode == "game_over":
		start_new_game()
	elif restart_confirmation_pending:
		start_new_game()
	else:
		restart_confirmation_pending = true
		overlay_mode = "restart_confirm"
		overlay_title.text = "重新开始？"
		overlay_msg.text = "当前进度将会清空。"
		overlay_btn.text = "确认新游戏"
		overlay.visible = true

func _on_restart_pressed() -> void:
	if is_animating:
		return
	restart_confirmation_pending = true
	overlay_mode = "restart_confirm"
	overlay_title.text = "重新开始？"
	overlay_msg.text = "当前进度将会清空。"
	overlay_btn.text = "确认新游戏"
	overlay.visible = true

func _on_undo_pressed() -> void:
	if is_animating or not logic.can_undo():
		return
	if logic.undo():
		overlay.visible = false
		clear_all_tiles()
		for r in range(4):
			for c in range(4):
				var v = logic.grid[r][c]
				if v > 0:
					create_tile_at(r, c, v, false)
		update_score_ui()
		save_best_score()

# 触屏手势与键盘输入系统
func _unhandled_input(event: InputEvent) -> void:
	# 键盘输入适配
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				handle_move(Vector2i.LEFT)
			KEY_RIGHT, KEY_D:
				handle_move(Vector2i.RIGHT)
			KEY_UP, KEY_W:
				handle_move(Vector2i.UP)
			KEY_DOWN, KEY_S:
				handle_move(Vector2i.DOWN)
		return

	# 触控与鼠标模拟触控输入
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			is_touching = true
			has_swiped_current_gesture = false
		else:
			if is_touching and not has_swiped_current_gesture:
				var delta = event.position - touch_start_pos
				_process_swipe(delta)
			is_touching = false
			has_swiped_current_gesture = false
	elif event is InputEventScreenDrag:
		if is_touching and not has_swiped_current_gesture:
			var delta = event.position - touch_start_pos
			if delta.length() >= SWIPE_THRESHOLD:
				_process_swipe(delta)
				has_swiped_current_gesture = true

func _process_swipe(delta: Vector2) -> void:
	if delta.length() < SWIPE_THRESHOLD:
		return
	if abs(delta.x) > abs(delta.y):
		if delta.x > 0:
			handle_move(Vector2i.RIGHT)
		else:
			handle_move(Vector2i.LEFT)
	else:
		if delta.y > 0:
			handle_move(Vector2i.DOWN)
		else:
			handle_move(Vector2i.UP)
