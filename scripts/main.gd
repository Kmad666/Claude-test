extends Control
## Root of the game: swaps between the setup, board, and results screens.

var screen: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(UI.SKY)
	UI.full_rect(self)
	if Game.autoplay:
		Engine.time_scale = 10.0
		var cls: String = Data.CLASS_ORDER[Game.rng.randi_range(0, Data.CLASS_ORDER.size() - 1)]
		print("AUTOPLAY_START as ", cls)
		start_game(cls)
	else:
		show_setup()


func show_setup() -> void:
	var setup := SetupScreen.new()
	setup.class_chosen.connect(start_game)
	_swap(setup)


func start_game(cls: String) -> void:
	Game.new_game(cls)
	var board := BoardScreen.new()
	board.game_over.connect(show_results)
	_swap(board)


func show_results() -> void:
	var results := ResultsScreen.new()
	results.play_again.connect(show_setup)
	_swap(results)


func _swap(next: Control) -> void:
	if screen:
		screen.queue_free()
	screen = next
	add_child(screen)
