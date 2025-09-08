extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var objective_label: Label = $MarginContainer/HBoxContainer/HBoxContainer/objective_label
@onready var check_button: CheckButton = $CheckButton
@onready var grid: Node = get_parent().get_node("grid")

# === Configurables (solo tiempo) ===
@export var objective_score: int = 100   # objetivo para ganar
@export var time_limit: int = 120        # segundos del nivel

# === Estado ===
var current_score: int = 0
var current_count: int = 0
var timer: Timer
var ended: bool = false  # evita dobles finales

signal game_over

func _ready() -> void:
	# UI inicial
	objective_label.text = "OBJ: %s" % str(objective_score)

	# Ocultar/ignorar el check: el nivel SIEMPRE es por tiempo
	if check_button:
		check_button.visible = false
		check_button.disabled = true

	# Conexiones
	if grid:
		grid.connect("score_updated", Callable(self, "_on_score_updated"))
		# Si el grid emite move_counter, lo ignoramos (modo tiempo)
		grid.connect("move_counter", Callable(self, "_on_move_counter"))

	# Timer 1Hz
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

	# Arranque del conteo
	current_count = time_limit
	counter_label.text = str(current_count)
	timer.start()

func _on_score_updated(points: int) -> void:
	if ended:
		return
	current_score += points
	score_label.text = str(current_score)

	# Victoria inmediata si alcanza objetivo
	if current_score >= objective_score:
		_finish_game(true, "objetivo alcanzado")

func _on_move_counter() -> void:
	# No hace nada: el nivel es por tiempo
	return

func _on_timer_timeout() -> void:
	if ended:
		return
	current_count -= 1
	if current_count < 0:
		current_count = 0
	counter_label.text = str(current_count)

	if current_count <= 0:
		# Al agotarse el tiempo, decide WIN vs GAME OVER
		_finish_game(current_score >= objective_score, "tiempo agotado")

func _finish_game(is_win: bool, reason: String) -> void:
	if ended:
		return
	ended = true
	if timer:
		timer.stop()

	if is_win:
		# "game_won"
		print("Victoria (%s)" % reason)
		score_label.text = "YOU"
		objective_label.text = "WIN!"
	else:
		emit_signal("game_over")
		print("game over (%s)" % reason)
		score_label.text = "GAME"
		objective_label.text = "OVER"

	get_tree().paused = true
