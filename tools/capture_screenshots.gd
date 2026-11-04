extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const ARTIFACT_DIR = "/Users/mit-xl/.gemini/antigravity-ide/brain/243cc2da-e1be-4337-92c5-989ebd58ea51"

var main_node: Control
var frame_count: int = 0
var mode: int = 0

func _init() -> void:
	print("Starting screenshot capture...")
	main_node = MainScene.instantiate()
	root.add_child(main_node)

func _process(_delta: float) -> bool:
	frame_count += 1
	
	if frame_count == 10:
		# 手机比例 720x1280
		print("Capturing Mobile 720x1280...")
		root.size = Vector2i(720, 1280)
		main_node.size = Vector2(720, 1280)
		main_node._recalc_board_dimensions()
		main_node._update_all_tile_positions()
	elif frame_count == 15:
		var img = root.get_texture().get_image()
		var path = ARTIFACT_DIR + "/2048_mobile_view.png"
		img.save_png(path)
		print("Saved mobile screenshot to: ", path)
		
		# 切换为 iPad 4:3 比例 (768x1024)
		print("Switching to iPad 768x1024...")
		root.size = Vector2i(768, 1024)
		main_node.size = Vector2(768, 1024)
		main_node._recalc_board_dimensions()
		main_node._update_all_tile_positions()
	elif frame_count == 25:
		var img = root.get_texture().get_image()
		var path = ARTIFACT_DIR + "/2048_ipad_view.png"
		img.save_png(path)
		print("Saved iPad screenshot to: ", path)
		print("All screenshots captured successfully!")
		quit(0)
		return true

	return false
