extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var objective_label: Label = $MarginContainer/HBoxContainer/HBoxContainer/objective_label
@onready var check_button: CheckButton = $CheckButton

var current_score = 0
var current_count = 3
var time_limit = 60
var is_time_based = false
var timer: Timer

signal game_over

func _ready():
	var grid = get_parent().get_node("grid")
	counter_label.text = str(current_count)
	grid.connect("score_updated", _on_score_updated)
	grid.connect("move_counter", _on_move_counter)
	
	# Initialize and configure the Timer
	timer = Timer.new()
	timer.wait_time = 1  # Timer ticks every second
	timer.one_shot = false
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)
	
	# Initialize CheckButton
	check_button.connect("toggled", _on_check_button_toggled)
	_on_check_button_toggled(check_button.pressed)
	
	if is_time_based:
		timer.start()
	else:
		timer.stop()

func _on_score_updated(points):
	current_score += points
	score_label.text = str(current_score)

func _on_move_counter():
	if not is_time_based:
		current_count -= 1
		counter_label.text = str(current_count)
		if current_count == 0:
			emit_signal("game_over")
			print('game over')
			score_label.text = "GAME"
			objective_label.text = "OVER"
			print("Partida terminada")
			get_tree().paused = true
	
func _on_check_button_toggled(pressed):
	is_time_based = pressed
	
	if is_time_based:
		# Switch to time-based mode
		current_count = time_limit
		counter_label.text = str(current_count)
		timer.start()
	else:
		# Switch to move-based mode
		timer.stop()
		current_count = 2
		counter_label.text = str(current_count)

func _on_timer_timeout():
	if is_time_based:
		current_count -= 1
		counter_label.text = str(current_count)
		if current_count <= 0:
			emit_signal("game_over")
			print('game over')
			score_label.text = "GAME"
			objective_label.text = "OVER"
			print("Partida terminada")
			get_tree().paused = true
