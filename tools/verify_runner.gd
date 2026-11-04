extends SceneTree

const MainScene = preload("res://scenes/main.tscn")

var main_node: Control
var step: int = 0
var timer: float = 0.0

func _init() -> void:
	print("Starting automated test runner...")
	main_node = MainScene.instantiate()
	root.add_child(main_node)

func _process(delta: float) -> bool:
	timer += delta
	# 每 0.3 秒推进一个动作
	if timer > 0.35:
		timer = 0.0
		step += 1
		match step:
			1:
				print("Step 1: Check initial state")
				var score = main_node.logic.score
				var tiles_count = main_node.tiles_layer.get_child_count()
				print("Initial score: ", score, " Active tiles in layer: ", tiles_count)
				assert(tiles_count >= 2, "Should have spawned 2 initial tiles")
				
				# 触发向左移动
				print("Triggering Move LEFT...")
				main_node.handle_move(Vector2i.LEFT)
			2:
				print("Step 2: Checking state after move LEFT")
				print("Score: ", main_node.logic.score, " Best: ", main_node.logic.best_score)
				
				# 触发向下移动
				print("Triggering Move DOWN...")
				main_node.handle_move(Vector2i.DOWN)
			3:
				print("Step 3: Triggering Move RIGHT...")
				main_node.handle_move(Vector2i.RIGHT)
			4:
				print("Step 4: Triggering Move UP...")
				main_node.handle_move(Vector2i.UP)
			5:
				print("Step 5: Testing Undo...")
				var can_undo = main_node.logic.can_undo()
				print("Can undo: ", can_undo)
				if can_undo:
					main_node._on_undo_pressed()
					print("Undo executed successfully!")
			6:
				print("Step 6: Testing New Game...")
				main_node._on_restart_pressed()
				print("Game restarted, tiles count: ", main_node.tiles_layer.get_child_count())
			7:
				print("All interactive simulation steps passed!")
				quit(0)
				return true
	return false
