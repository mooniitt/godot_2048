extends SceneTree

func _init() -> void:
	print("Building Main Scene using Godot API with Unique Names...")
	
	DirAccess.make_dir_absolute("res://scenes")
	
	var main = Control.new()
	main.name = "Main"
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter = Control.MOUSE_FILTER_STOP
	var main_script = load("res://scripts/main.gd")
	main.set_script(main_script)

	# 1. 全局背景底色
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("faf8ef")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(bg)
	bg.owner = main

	# 2. 安全边距容器
	var safe_margin = MarginContainer.new()
	safe_margin.name = "SafeMargin"
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 24)
	safe_margin.add_theme_constant_override("margin_right", 24)
	safe_margin.add_theme_constant_override("margin_top", 44)
	safe_margin.add_theme_constant_override("margin_bottom", 30)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(safe_margin)
	safe_margin.owner = main

	# 3. 垂直流式布局
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 16)
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(main_vbox)
	main_vbox.owner = main

	# 4. Header 区域
	var header = VBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(header)
	header.owner = main

	# 顶部标题栏与计分板
	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(top_bar)
	top_bar.owner = main

	var title_box = VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(title_box)
	title_box.owner = main

	var title_label = Label.new()
	title_label.name = "GameTitle"
	title_label.text = "2048"
	title_label.add_theme_font_size_override("font_size", 54)
	title_label.add_theme_color_override("font_color", Color("776e65"))
	title_box.add_child(title_label)
	title_label.owner = main

	var sub_title = Label.new()
	sub_title.name = "SubTitle"
	sub_title.text = "合并方块，冲击 2048！"
	sub_title.add_theme_font_size_override("font_size", 15)
	sub_title.add_theme_color_override("font_color", Color("8f7a66"))
	title_box.add_child(sub_title)
	sub_title.owner = main

	# 计分板
	var score_board = HBoxContainer.new()
	score_board.name = "ScoreBoard"
	score_board.add_theme_constant_override("separation", 8)
	score_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(score_board)
	score_board.owner = main

	# Score 卡片
	var score_card = PanelContainer.new()
	score_card.name = "ScoreCard"
	score_card.custom_minimum_size = Vector2(116, 72)
	var card_style1 = StyleBoxFlat.new()
	card_style1.bg_color = Color("bbada0")
	card_style1.corner_radius_top_left = 6
	card_style1.corner_radius_top_right = 6
	card_style1.corner_radius_bottom_left = 6
	card_style1.corner_radius_bottom_right = 6
	score_card.add_theme_stylebox_override("panel", card_style1)
	score_board.add_child(score_card)
	score_card.owner = main

	var score_vbox = VBoxContainer.new()
	score_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	score_card.add_child(score_vbox)
	score_vbox.owner = main

	var score_title = Label.new()
	score_title.text = "SCORE"
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title.add_theme_font_size_override("font_size", 15)
	score_title.add_theme_color_override("font_color", Color("eee4da"))
	score_vbox.add_child(score_title)
	score_title.owner = main

	var score_val = Label.new()
	score_val.name = "ScoreValue"
	score_val.unique_name_in_owner = true
	score_val.text = "0"
	score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_val.add_theme_font_size_override("font_size", 30)
	score_val.add_theme_color_override("font_color", Color("ffffff"))
	score_vbox.add_child(score_val)
	score_val.owner = main

	# Best 卡片
	var best_card = PanelContainer.new()
	best_card.name = "BestCard"
	best_card.custom_minimum_size = Vector2(116, 72)
	var card_style2 = card_style1.duplicate()
	best_card.add_theme_stylebox_override("panel", card_style2)
	score_board.add_child(best_card)
	best_card.owner = main

	var best_vbox = VBoxContainer.new()
	best_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	best_card.add_child(best_vbox)
	best_vbox.owner = main

	var best_title = Label.new()
	best_title.text = "BEST"
	best_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_title.add_theme_font_size_override("font_size", 15)
	best_title.add_theme_color_override("font_color", Color("eee4da"))
	best_vbox.add_child(best_title)
	best_title.owner = main

	var best_val = Label.new()
	best_val.name = "BestValue"
	best_val.unique_name_in_owner = true
	best_val.text = "0"
	best_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_val.add_theme_font_size_override("font_size", 30)
	best_val.add_theme_color_override("font_color", Color("ffffff"))
	best_vbox.add_child(best_val)
	best_val.owner = main

	# 操作按钮栏
	var actions = HBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", 12)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(actions)
	actions.owner = main

	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color("8f7a66")
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8

	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color("9f8a76")

	var btn_disabled = btn_normal.duplicate()
	btn_disabled.bg_color = Color("d0c7bd")

	var undo_btn = Button.new()
	undo_btn.name = "UndoBtn"
	undo_btn.unique_name_in_owner = true
	undo_btn.text = "撤回一步"
	undo_btn.custom_minimum_size = Vector2(120, 52)
	undo_btn.add_theme_stylebox_override("normal", btn_normal)
	undo_btn.add_theme_stylebox_override("hover", btn_hover)
	undo_btn.add_theme_stylebox_override("pressed", btn_hover)
	undo_btn.add_theme_stylebox_override("disabled", btn_disabled)
	undo_btn.add_theme_font_size_override("font_size", 18)
	undo_btn.add_theme_color_override("font_color", Color("ffffff"))
	actions.add_child(undo_btn)
	undo_btn.owner = main

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_child(spacer)
	spacer.owner = main

	var restart_btn = Button.new()
	restart_btn.name = "RestartBtn"
	restart_btn.unique_name_in_owner = true
	restart_btn.text = "新游戏"
	restart_btn.custom_minimum_size = Vector2(120, 52)
	restart_btn.add_theme_stylebox_override("normal", btn_normal)
	restart_btn.add_theme_stylebox_override("hover", btn_hover)
	restart_btn.add_theme_stylebox_override("pressed", btn_hover)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.add_theme_color_override("font_color", Color("ffffff"))
	actions.add_child(restart_btn)
	restart_btn.owner = main

	# 5. 核心 BoardArea 自适应区域
	var board_area = Control.new()
	board_area.name = "BoardArea"
	board_area.unique_name_in_owner = true
	board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_area.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_child(board_area)
	board_area.owner = main

	# 棋盘容器
	var board_container = Control.new()
	board_container.name = "BoardContainer"
	board_container.unique_name_in_owner = true
	board_container.mouse_filter = Control.MOUSE_FILTER_PASS
	board_area.add_child(board_container)
	board_container.owner = main

	# 棋盘底板
	var board_bg = Panel.new()
	board_bg.name = "BoardBg"
	board_bg.unique_name_in_owner = true
	var board_bg_style = StyleBoxFlat.new()
	board_bg_style.bg_color = Color("bbada0")
	board_bg_style.corner_radius_top_left = 12
	board_bg_style.corner_radius_top_right = 12
	board_bg_style.corner_radius_bottom_left = 12
	board_bg_style.corner_radius_bottom_right = 12
	board_bg_style.corner_detail = 8
	board_bg.add_theme_stylebox_override("panel", board_bg_style)
	board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_container.add_child(board_bg)
	board_bg.owner = main

	# 网格底槽
	var grid_slots = Control.new()
	grid_slots.name = "GridSlots"
	grid_slots.unique_name_in_owner = true
	grid_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_container.add_child(grid_slots)
	grid_slots.owner = main

	# 方块活动层
	var tiles_layer = Control.new()
	tiles_layer.name = "TilesLayer"
	tiles_layer.unique_name_in_owner = true
	tiles_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_container.add_child(tiles_layer)
	tiles_layer.owner = main

	# 结算弹窗遮罩
	var overlay = Panel.new()
	overlay.name = "Overlay"
	overlay.unique_name_in_owner = true
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.93, 0.89, 0.85, 0.92)
	overlay_style.corner_radius_top_left = 12
	overlay_style.corner_radius_top_right = 12
	overlay_style.corner_radius_bottom_left = 12
	overlay_style.corner_radius_bottom_right = 12
	overlay.add_theme_stylebox_override("panel", overlay_style)
	board_container.add_child(overlay)
	overlay.owner = main

	var overlay_vbox = VBoxContainer.new()
	overlay_vbox.name = "OverlayVBox"
	overlay_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_vbox.add_theme_constant_override("separation", 14)
	overlay.add_child(overlay_vbox)
	overlay_vbox.owner = main

	var overlay_title = Label.new()
	overlay_title.name = "TitleLabel"
	overlay_title.unique_name_in_owner = true
	overlay_title.text = "游戏结束"
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 38)
	overlay_title.add_theme_color_override("font_color", Color("776e65"))
	overlay_vbox.add_child(overlay_title)
	overlay_title.owner = main

	var overlay_msg = Label.new()
	overlay_msg.name = "MsgLabel"
	overlay_msg.unique_name_in_owner = true
	overlay_msg.text = "最终得分: 0"
	overlay_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_msg.add_theme_font_size_override("font_size", 18)
	overlay_msg.add_theme_color_override("font_color", Color("8f7a66"))
	overlay_vbox.add_child(overlay_msg)
	overlay_msg.owner = main

	var overlay_action_btn = Button.new()
	overlay_action_btn.name = "ActionButton"
	overlay_action_btn.unique_name_in_owner = true
	overlay_action_btn.text = "再玩一次"
	overlay_action_btn.add_theme_stylebox_override("normal", btn_normal)
	overlay_action_btn.add_theme_stylebox_override("hover", btn_hover)
	overlay_action_btn.add_theme_stylebox_override("pressed", btn_hover)
	overlay_action_btn.add_theme_font_size_override("font_size", 18)
	overlay_action_btn.add_theme_color_override("font_color", Color("ffffff"))
	overlay_action_btn.custom_minimum_size = Vector2(130, 46)
	overlay_action_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	overlay_vbox.add_child(overlay_action_btn)
	overlay_action_btn.owner = main

	# 6. Footer 区域
	var footer = MarginContainer.new()
	footer.name = "Footer"
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(footer)
	footer.owner = main

	var footer_label = Label.new()
	footer_label.text = "触屏任意滑动 / 键盘 WASD 及方向键控制"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 14)
	footer_label.add_theme_color_override("font_color", Color("8f7a66"))
	footer.add_child(footer_label)
	footer_label.owner = main

	# 打包保存场景
	var scene = PackedScene.new()
	var pack_result = scene.pack(main)
	if pack_result == OK:
		var save_result = ResourceSaver.save(scene, "res://scenes/main.tscn")
		if save_result == OK:
			print("Successfully saved scenes/main.tscn with unique names!")
		else:
			printerr("Failed to save scenes/main.tscn: ", save_result)
	else:
		printerr("Failed to pack main scene: ", pack_result)
		
	quit(0)
