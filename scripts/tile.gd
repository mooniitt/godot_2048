class_name Tile
extends Control

const COLORS: Dictionary = {
	2:    {"bg": Color("eee4da"), "text": Color("776e65")},
	4:    {"bg": Color("ede0c8"), "text": Color("776e65")},
	8:    {"bg": Color("f2b179"), "text": Color("f9f6f2")},
	16:   {"bg": Color("f59563"), "text": Color("f9f6f2")},
	32:   {"bg": Color("f67c5f"), "text": Color("f9f6f2")},
	64:   {"bg": Color("f65e3b"), "text": Color("f9f6f2")},
	128:  {"bg": Color("edcf72"), "text": Color("f9f6f2")},
	256:  {"bg": Color("edcc61"), "text": Color("f9f6f2")},
	512:  {"bg": Color("edc850"), "text": Color("f9f6f2")},
	1024: {"bg": Color("edc53f"), "text": Color("f9f6f2")},
	2048: {"bg": Color("ecc400"), "text": Color("ffffff")},
	4096: {"bg": Color("3c3a32"), "text": Color("ffffff")},
	8192: {"bg": Color("242320"), "text": Color("ffffff")}
}

var value: int = 2
var panel: Panel
var label: Label
var style_box: StyleBoxFlat
var current_tween: Tween

func _init() -> void:
	custom_minimum_size = Vector2(80, 80)
	
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.corner_detail = 8
	panel.add_theme_stylebox_override("panel", style_box)
	add_child(panel)

	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func setup(val: int, tile_size: Vector2) -> void:
	value = val
	size = tile_size
	custom_minimum_size = tile_size
	pivot_offset = tile_size / 2.0
	scale = Vector2.ONE
	rotation = 0.0
	
	# 设置圆角半径根据 tile 尺寸自适应
	var radius = int(clamp(tile_size.x * 0.08, 6, 16))
	style_box.corner_radius_top_left = radius
	style_box.corner_radius_top_right = radius
	style_box.corner_radius_bottom_left = radius
	style_box.corner_radius_bottom_right = radius
	style_box.border_width_left = 0
	style_box.border_width_top = 0
	style_box.border_width_right = 0
	style_box.border_width_bottom = 0
	style_box.border_color = Color.TRANSPARENT
	
	var col_info = COLORS.get(val, {"bg": Color("3c3a32"), "text": Color("ffffff")})
	style_box.bg_color = col_info["bg"]
	
	# 如果达到 2048 及以上，添加华丽的金色边框高光
	if val >= 2048:
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color("fff59d")

	label.text = str(val)
	label.add_theme_color_override("font_color", col_info["text"])
	
	# 动态调整字体大小，避免 4 位数溢出
	var font_size = int(tile_size.x * 0.42)
	var text_len = str(val).length()
	if text_len == 3:
		font_size = int(tile_size.x * 0.35)
	elif text_len == 4:
		font_size = int(tile_size.x * 0.28)
	elif text_len >= 5:
		font_size = int(tile_size.x * 0.22)
		
	label.add_theme_font_size_override("font_size", font_size)

func play_spawn_animation() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	scale = Vector2.ONE

func play_merge_pop() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	scale = Vector2.ONE
	current_tween = create_tween()
	current_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	current_tween.tween_callback(func() -> void:
		scale = Vector2.ONE
	)

func move_to(target_pos: Vector2, duration: float) -> Tween:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return current_tween
