# extends：继承 Godot 类，使本脚本拥有 Control 的 UI 属性和方法。
extends Control

# preload：预加载脚本文件，返回可通过 new() 创建实例的类引用。
const GameLogicClass = preload("res://scripts/game_logic.gd")
const TileClass = preload("res://scripts/tile.gd")
const MERGE_SHEET: Texture2D = preload("res://assets/merge_fx/merge_sheet.png")

# const：声明常量；类型标注格式为“名称: 类型”。
# user:// 指向 Godot 为当前游戏提供的用户数据目录。
const SAVE_PATH: String = "user://save_data.cfg"
const SWIPE_THRESHOLD: float = 40.0
const ANIM_DURATION: float = 0.08

# @onready：节点进入场景树并完成初始化后，再执行右侧的节点查找。
# %Name：按场景中的唯一节点名称取得节点。
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

# var 声明变量；类型标注写在变量名后，格式为“var 名称: 类型 = 初始值”。
var logic: GameLogicClass
# Array 是动态数组；这里使用二维数组保存 Tile，访问形式是 tile_map[行][列]。
var tile_map: Array = []

# bool 只有 true/false；Vector2.ZERO 是值为 (0, 0) 的向量常量。
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
	# func 定义函数，-> void 表示函数不返回值；缩进内容属于函数体。
	# _ready 是 Godot 生命周期函数，节点加入场景树后会自动调用一次。
	logic = GameLogicClass.new()
	load_best_score()
	
	# 对象.方法(...) 是方法调用；pressed 是 Button 的信号。
	# connect(回调函数) 把信号连接到指定函数。
	restart_btn.pressed.connect(_on_restart_pressed)
	undo_btn.pressed.connect(_on_undo_pressed)
	overlay_btn.pressed.connect(_on_overlay_action_pressed)
	
	board_area.resized.connect(_on_board_area_resized)
	
	init_board_layout()
	# call_deferred：当前帧的其他初始化完成后，再延迟调用指定函数。
	call_deferred("_initialize_game")

func _initialize_game() -> void:
	# 等待节点完成布局后再计算棋盘尺寸，避免启动时尺寸仍为 0。
	_recalc_board_dimensions()
	start_new_game()

func load_best_score() -> void:
	# 最高分保存在本地配置中，即使重新启动游戏也不会丢失。
	# new() 创建对象；不写类型时，var 的类型由右侧表达式推断。
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	# == 是比较运算符；OK 是 Godot 表示成功的常量。
	if err == OK:
		# get_value(section, key, default) 读取配置项，找不到时使用默认值。
		logic.best_score = config.get_value("game", "best_score", 0)
	update_score_ui()

func save_best_score() -> void:
	# 只保存最高分，棋盘当前状态由新游戏和撤销逻辑负责管理。
	var config = ConfigFile.new()
	# set_value(section, key, value) 设置配置项，save() 将其写入文件。
	config.set_value("game", "best_score", logic.best_score)
	config.save(SAVE_PATH)

func init_board_layout() -> void:
	# tile_map 与逻辑棋盘保持相同的 4x4 结构，用于快速定位显示节点。
	# range(4) 产生 0、1、2、3；for 变量 in 集合表示遍历集合。
	for r in range(4):
		var row: Array = []
		for c in range(4):
			# append(value) 将元素添加到数组末尾；null 表示没有 Tile。
			row.append(null)
		tile_map.append(row)
	_recalc_board_dimensions()

func _on_board_area_resized() -> void:
	# 窗口尺寸变化时重新布局背景格和已有方块。
	_recalc_board_dimensions()
	_update_all_tile_positions()

# 核心自适应逻辑：支持手机细长屏与 iPad 4:3 屏幕
func _recalc_board_dimensions() -> void:
	# 根据可用区域计算正方形棋盘，保证手机和大屏设备上的比例一致。
	# not 表示逻辑取反；or 表示“任意一个条件成立”；return 立即退出函数。
	if not is_inside_tree() or board_area == null:
		return
	var area_size: Vector2 = board_area.size
	# Vector2 的 x、y 是属性；<= 表示“小于或等于”。
	if area_size.x <= 0 or area_size.y <= 0:
		return
	
	# 取宽高的较小值，并限制在合理范围内（在 iPad 上最大不超过 600px，在手机上自适应宽度）
	# min() 返回较小值；clamp(value, min, max) 将数值限制在指定区间。
	var max_dim = min(area_size.x - 16.0, area_size.y - 16.0)
	board_size = clamp(max_dim, 260.0, 580.0)
	
	# 设置 BoardContainer 居中
	# Vector2 支持加、减、乘、除等运算，这里用剩余空间除以 2 得到居中位置。
	board_container.size = Vector2(board_size, board_size)
	board_container.position = (area_size - Vector2(board_size, board_size)) / 2.0
	board_bg.size = Vector2(board_size, board_size)
	overlay.size = Vector2(board_size, board_size)
	
	pad = clamp(board_size * 0.03, 8.0, 16.0)
	gap = clamp(board_size * 0.03, 8.0, 16.0)
	cell_size = (board_size - pad * 2.0 - gap * 3.0) / 4.0
	
	_rebuild_grid_background_slots()

func _rebuild_grid_background_slots() -> void:
	# 背景格不参与输入，只负责显示棋盘的 16 个固定位置。
	# get_children() 返回子节点数组；queue_free() 会在安全时机销毁节点。
	for child in grid_slots_container.get_children():
		child.queue_free()
	
	for r in range(4):
		for c in range(4):
			# Panel.new() 动态创建 UI 节点；add_child() 将节点加入场景树。
			var slot = Panel.new()
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.size = Vector2(cell_size, cell_size)
			slot.position = get_cell_pos(r, c)
			
			# StyleBoxFlat.new() 创建可配置的面板样式对象。
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
	# 将逻辑坐标转换为棋盘容器内的像素坐标。
	# return 将计算结果返回给调用者。
	return Vector2(pad + c * (cell_size + gap), pad + r * (cell_size + gap))

func start_new_game() -> void:
	# 重置棋盘但保留历史最高分，然后创建两个初始方块。
	restart_confirmation_pending = false
	overlay_mode = ""
	overlay.visible = false
	# 局部变量只在当前函数中有效；先保存最高分，再重置游戏数据。
	var saved_best: int = logic.best_score
	logic.reset()
	logic.best_score = saved_best
	clear_all_tiles()
	
	# 初始生成 2 个方块
	var s1 = logic.spawn_tile()
	# Dictionary.is_empty() 判断字典是否为空；not 也可以写作 !。
	if not s1.is_empty():
		# 字典使用 ["键"] 取值；Vector2i 的 x、y 表示整数坐标。
		create_tile_at(s1["pos"].x, s1["pos"].y, s1["val"], true)
	var s2 = logic.spawn_tile()
	if not s2.is_empty():
		create_tile_at(s2["pos"].x, s2["pos"].y, s2["val"], true)
		
	update_score_ui()

func clear_all_tiles() -> void:
	# 同步清空逻辑映射和场景树中的方块节点。
	for r in range(4):
		for c in range(4):
			tile_map[r][c] = null
	# remove_child() 解除父子关系，queue_free() 负责释放节点。
	for child in tiles_layer.get_children():
		tiles_layer.remove_child(child)
		child.queue_free()

func create_tile_at(r: int, c: int, val: int, play_anim: bool = true) -> TileClass:
	# 创建一个显示方块，并将它登记到与逻辑棋盘对应的位置。
	# 参数可以有默认值；调用时省略 play_anim 时，它自动使用 true。
	# -> TileClass 表示该函数返回 TileClass 类型的对象。
	var tile = TileClass.new()
	tiles_layer.add_child(tile)
	tile.setup(val, Vector2(cell_size, cell_size))
	tile.scale = Vector2.ONE
	tile.rotation = 0.0
	tile.position = get_cell_pos(r, c)
	tile_map[r][c] = tile
	# if 条件为 true 时执行缩进代码，false 时跳过。
	if play_anim:
		tile.play_spawn_animation()
	return tile

func update_score_ui() -> void:
	# 刷新分数和撤销按钮状态；最高分在这里进行最终兜底更新。
	score_label.text = str(logic.score)
	best_label.text = str(logic.best_score)
	# can_undo() 返回 bool；disabled 使用取反结果控制按钮是否禁用。
	undo_btn.disabled = not logic.can_undo()
	if logic.score > logic.best_score:
		logic.best_score = logic.score
		best_label.text = str(logic.best_score)

func _update_all_tile_positions() -> void:
	for r in range(4):
		for c in range(4):
			var tile = tile_map[r][c]
			# and 表示“两个条件都成立”；is_instance_valid() 防止访问已释放对象。
			if tile != null and is_instance_valid(tile):
				tile.setup(tile.value, Vector2(cell_size, cell_size))
				tile.position = get_cell_pos(r, c)

func handle_move(dir: Vector2i) -> void:
	# 先由逻辑层计算移动结果，再根据移动列表驱动界面动画。
	# Vector2i 是整数向量，适合表示棋盘方向和行列坐标。
	if is_animating or logic.game_over:
		return
	
	var res = logic.move(dir)
	if not res["moved"]:
		return
		
	is_animating = true
	var moves: Array = res["moves"]
	
	# 收集所有目标位置被合并的原方块
	# {} 是空字典字面量；字典的键和值可以分别保存位置和方块数组。
	var merged_targets: Dictionary = {} # Vector2i -> Array[TileClass]
	var moving_tweens: Array = []
	
	# m 是 moves 数组当前遍历到的元素，通常是一个 Dictionary。
	for m in moves:
		# 移动中的方块暂时从映射中移除，合并完成后再创建结果方块。
		var from_pos: Vector2i = m["from"]
		var to_pos: Vector2i = m["to"]
		var tile: TileClass = tile_map[from_pos.x][from_pos.y]
		if tile == null:
			continue
			
		var target_pixel_pos = get_cell_pos(to_pos.x, to_pos.y)
		var tw = tile.move_to(target_pixel_pos, ANIM_DURATION)
		moving_tweens.append(tw)
		
		# Dictionary.has(key) 判断键是否存在；Array.has(value) 判断元素是否存在。
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
	get_tree().create_timer(ANIM_DURATION).timeout.connect(func(): _complete_move(res, merged_targets))

func _complete_move(res: Dictionary, merged_targets: Dictionary) -> void:
	# 逐目标播放 12 帧融合特效，完成后再恢复方块显示。
	for merge_pos in merged_targets.keys():
		await _play_merge_effect(merge_pos)

	clear_all_tiles()
	for r in range(4):
		for c in range(4):
			var value: int = logic.grid[r][c]
			if value == 0:
				continue
			create_tile_at(r, c, value, false)

	update_score_ui()
	save_best_score()
	if res.get("newly_won", false):
		show_win_overlay()
	elif res.get("game_over", false):
		show_game_over_overlay()
	is_animating = false

func _play_merge_effect(cell: Vector2i) -> void:
	var effect := TextureRect.new()
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_SCALE
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.z_index = 20
	var effect_size := Vector2(cell_size * 2.4, cell_size * 2.4)
	effect.size = effect_size
	effect.position = get_cell_pos(cell.x, cell.y) + Vector2(cell_size, cell_size) / 2.0 - effect_size / 2.0
	tiles_layer.add_child(effect)
	for frame_index in range(1, 13):
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = MERGE_SHEET
		var frame_column := (frame_index - 1) % 4
		var frame_row := floori(float(frame_index - 1) / 4.0)
		var frame_size := Vector2(MERGE_SHEET.get_width() / 4.0, MERGE_SHEET.get_height() / 3.0)
		atlas_frame.region = Rect2(Vector2(frame_column, frame_row) * frame_size, frame_size)
		effect.texture = atlas_frame
		await get_tree().create_timer(0.055).timeout
	effect.queue_free()

func show_game_over_overlay() -> void:
	# 显示无路可走时的结束面板。
	# 点号语法用于访问对象属性，例如 overlay.visible。
	restart_confirmation_pending = false
	overlay_mode = "game_over"
	overlay_title.text = "游戏结束"
	overlay_msg.text = "没有更多可移动方块！\n最终得分: " + str(logic.score)
	overlay_btn.text = "再玩一次"
	overlay.visible = true

func show_win_overlay() -> void:
	# 达到 2048 后允许玩家关闭提示并继续挑战更高分。
	restart_confirmation_pending = false
	overlay_mode = "win"
	overlay_title.text = "太棒了！"
	overlay_msg.text = "成功合成 2048！"
	overlay_btn.text = "继续挑战"
	overlay.visible = true

func _on_overlay_action_pressed() -> void:
	# 面板按钮根据当前模式执行继续、重开或确认重开操作。
	# elif 表示“前一个 if 不成立时继续判断另一个条件”。
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
	# 重开前先要求确认，避免误触导致当前进度丢失。
	if is_animating:
		return
	restart_confirmation_pending = true
	overlay_mode = "restart_confirm"
	overlay_title.text = "重新开始？"
	overlay_msg.text = "当前进度将会清空。"
	overlay_btn.text = "确认新游戏"
	overlay.visible = true

func _on_undo_pressed() -> void:
	# 恢复逻辑层快照后重建所有显示方块，确保界面与数据一致。
	# 嵌套 if：只有外层条件和内层 logic.undo() 都成功才执行恢复界面。
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
	# 键盘输入适配：方向键和 WASD 共用同一套移动逻辑。
	# 参数 event 声明为 InputEvent；Godot 会把实际输入事件传入此函数。
	if event is InputEventKey and event.pressed and not event.echo:
		# is 用于判断对象类型；match 根据一个值选择多个分支。
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

	# 触控输入在按下和拖动阶段分别记录起点、判断并处理滑动方向。
	# elif 也可以写作“否则如果”；这里用于区分触摸和拖动事件类型。
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
	# 只取位移较大的轴作为方向，避免斜向滑动产生歧义。
	# abs() 返回绝对值；> 表示“大于”比较。
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
