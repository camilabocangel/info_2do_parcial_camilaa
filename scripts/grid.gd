extends Node2D

# state machine
enum {WAIT, MOVE}
# COLORS
const BLUE = "blue"
const GREEN = "green"
const LIGHT_GREEN = "light_green"
const PINK = "pink"
const YELLOW = "yellow"
const ORANGE = "orange"
# SPECIAL TYPE PIECES
const COLUMN =  "column"
const ROW =  "row"
const ADJACENT = "adjacent"
const NORMAL = "normal"
const RAINBOW = "rainbow"

var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/BluePieces/blue_piece.tscn"),
	preload("res://scenes/greenPieces/green_piece.tscn"),
	preload("res://scenes/lightGreenPieces/light_green_piece.tscn"),
	preload("res://scenes/pinkPieces/pink_piece.tscn"),
	#preload("res://scenes/yellowPieces/yellow_piece.tscn"),
	#preload("res://scenes/orangePieces/orange_piece.tscn"),
]

var row_pieces = {
	BLUE: preload("res://scenes/BluePieces/blue_piece_row.tscn"),
	GREEN: preload("res://scenes/greenPieces/green_piece_row.tscn"),
	LIGHT_GREEN: preload("res://scenes/lightGreenPieces/light_green_piece_row.tscn"),
	ORANGE: preload("res://scenes/orangePieces/orange_piece_row.tscn"),
	PINK: preload("res://scenes/pinkPieces/pink_piece_row.tscn"),
	YELLOW: preload("res://scenes/yellowPieces/yellow_piece_row.tscn")
}

var column_pieces = {
	BLUE: preload("res://scenes/BluePieces/blue_piece_column.tscn"),
	GREEN: preload("res://scenes/greenPieces/green_piece_column.tscn"),
	LIGHT_GREEN: preload("res://scenes/lightGreenPieces/light_green_piece_column.tscn"),
	ORANGE: preload("res://scenes/orangePieces/orange_piece_column.tscn"),
	PINK: preload("res://scenes/pinkPieces/pink_piece_column.tscn"),
	YELLOW: preload("res://scenes/yellowPieces/yellow_piece_column.tscn")
}

var adjacent_pieces = {
	BLUE: preload("res://scenes/BluePieces/blue_piece_adjacent.tscn"),
	GREEN: preload("res://scenes/greenPieces/green_piece_adjacent.tscn"),
	LIGHT_GREEN: preload("res://scenes/lightGreenPieces/light_green_piece_adjacent.tscn"),
	ORANGE: preload("res://scenes/orangePieces/orange_piece_adjacent.tscn"),
	PINK: preload("res://scenes/pinkPieces/pink_piece_adjacent.tscn"),
	YELLOW: preload("res://scenes/yellowPieces/yellow_piece_adjacent.tscn")
}

var rainbow_piece = preload("res://scenes/rainbow_piece.tscn")


# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# scoring variables and signals
signal score_updated(points)


# counter variables and signals
signal move_counter()
var moves = 15
var deduct_move = false

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	
	
	if first_piece == null or other_piece == null:
		return
	var is_first_rainbow = first_piece.type == RAINBOW
	var is_other_rainbow =  other_piece.type == RAINBOW
	
	if is_first_rainbow:
		clean_color(column, row, other_piece.color)
		move_checked = true
	if is_other_rainbow:
		clean_color(column + direction.x, row + direction.y, first_piece.color)
		move_checked = true
		
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	
	deduct_move = true
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()
			
func destroy_matched():
	var was_matched = false
	var number_matched = 0
	# i = col, j = row
	for i in width:
		for j in height:
			var current_piece = all_pieces[i][j]
			if current_piece != null and current_piece.matched:
				was_matched = true
				number_matched += 1
				if current_piece.type == ROW:
					clean_row(j)
				elif current_piece.type == COLUMN:
					clean_col(i)
				elif current_piece.type == ADJACENT:
					clean_col(i)
					clean_row(j)
					clean_all_diag(i, j)
				elif current_piece.type == RAINBOW:
					clean_color(i, j, current_piece.color)
				elif current_piece.type == NORMAL:
				# Destroy the matched piece itself
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
				
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
		emit_signal("score_updated", number_matched * 10)        
		if deduct_move:
			emit_signal("move_counter")
			deduct_move = false
		if moves == 0:
			game_over()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				#print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				var color
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
					color = piece.color
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				all_pieces[i][j].color = piece.color
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	#print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	#print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	print("game over")
	show_game_over_screen()



func replace_with_special_piece(i, j, color, type):
	print('special type', type)
	var special_piece
	if type == ROW:
		special_piece = row_pieces[color].instantiate()
	elif type == COLUMN:
		special_piece = column_pieces[color].instantiate()
	elif type == ADJACENT:
		special_piece = adjacent_pieces[color].instantiate()
	elif type == RAINBOW:
		special_piece = rainbow_piece.instantiate()
		print(special_piece, 'de reokace')
	
	if type == ROW or type == COLUMN:
		for k in range(-1, 3):
			if type == ROW and in_grid(i + k, j):
				if all_pieces[i + k][j]:
					all_pieces[i + k][j].matched = true
					all_pieces[i + k][j].dim()
					all_pieces[i + k][j].queue_free()
					all_pieces[i + k][j].queue_free()
					all_pieces[i + k][j] = null
			elif type == COLUMN and in_grid(i, j + k):
				if all_pieces[i][j + k]:
					all_pieces[i][j + k].matched = true
					all_pieces[i][j + k].dim()
					all_pieces[i][j + k].queue_free()
					all_pieces[i][j + k] = null
	elif type == ADJACENT or type == RAINBOW:
		for di in range(-1, 2):
			for dj in range(-1, 2):
				if in_grid(i + di, j + dj) and all_pieces[i + di][j + dj]:
					all_pieces[i + di][j + dj].matched = true
					all_pieces[i + di][j + dj].dim()
					all_pieces[i + di][j + dj].queue_free()
					all_pieces[i + di][j + dj] = null
	
	if all_pieces[i][j]:
		all_pieces[i][j].queue_free()
	all_pieces[i][j] = special_piece
	all_pieces[i][j].type = type
	if all_pieces[i][j].color == "":
		all_pieces[i][j].color = color
	add_child(special_piece)
	special_piece.position = grid_to_pixel(i, j)
	get_parent().get_node("collapse_timer").start()


func mark_pieces_for_removal(i, j, is_horizontal):
	if is_horizontal:
		for k in range(0, 3):
			if in_grid(i + k, j):
				all_pieces[i + k][j].matched = true
				all_pieces[i + k][j].dim()
	else:
		for k in range(0, 3):
			if in_grid(i, j + k):
				all_pieces[i][j + k].matched = true
				all_pieces[i][j + k].dim()

func clean_row(row):
	for col in range(width):
		if all_pieces[col][row] != null:
			all_pieces[col][row].matched = true
			all_pieces[col][row].dim()
			all_pieces[col][row].queue_free()
			all_pieces[col][row] = null

func clean_col(col):
	for row in range(height):
		if all_pieces[col][row] != null:
			all_pieces[col][row].matched = true
			all_pieces[col][row].dim()
			all_pieces[col][row].queue_free()
			all_pieces[col][row] = null

func clean_all_diag(col, row):
	for offset in range(-min(width, height), min(width, height)):
		# (top-left to bottom-right)
		if (
			in_grid(col + offset, row + offset)
			and all_pieces[col + offset][row + offset] != null
		):
			all_pieces[col + offset][row + offset].matched = true
			all_pieces[col + offset][row + offset].dim()
			all_pieces[col + offset][row + offset].queue_free()
			all_pieces[col + offset][row + offset] = null

		# (top-right to bottom-left)
		if (
			in_grid(col + offset, row - offset) 
			and all_pieces[col + offset][row - offset] != null
		):
			all_pieces[col + offset][row - offset].matched = true
			all_pieces[col + offset][row - offset].dim()
			all_pieces[col + offset][row - offset].queue_free()
			all_pieces[col + offset][row - offset] = null

func clean_color(curr_col, curr_row, color):
	print('cleaneando color ', color)
	for col in range(width):
		for row in range(height):
			var curr_piece = all_pieces[col][row] 
			if curr_piece.color == color:
				all_pieces[col][row].matched = true
				all_pieces[col][row].dim()
				all_pieces[col][row].queue_free()
				all_pieces[col][row] = null
	all_pieces[curr_col][curr_row].matched = true
	all_pieces[curr_col][curr_row].dim()
	all_pieces[curr_col][curr_row].queue_free()
	all_pieces[curr_col][curr_row] = null
	get_parent().get_node("collapse_timer").start()


func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				
				if is_t_shape(i, j):
					replace_with_special_piece(i, j, current_color, ADJACENT)
				# Check for horizontal matches
				if i <= width - 5:
					if is_match(i, j, Vector2(1, 0), 5):
						replace_with_special_piece(i + 2, j, current_color, RAINBOW)
						#continue
					elif is_match(i, j, Vector2(1, 0), 4):
						replace_with_special_piece(i + 1, j, current_color, ROW)
						#continue
				elif i <= width - 4:
					if is_match(i, j, Vector2(1, 0), 4):
						replace_with_special_piece(i + 1, j, current_color, ROW)
						#continue
				
				# Check for vertical matches
				if j <= height - 5:
					if is_match(i, j, Vector2(0, 1), 5):
						replace_with_special_piece(i, j + 2, current_color, RAINBOW)
						#continue
					elif is_match(i, j, Vector2(0, 1), 4):
						replace_with_special_piece(i, j + 1, current_color, COLUMN)
						#continue
				elif j <= height - 4:
					if is_match(i, j, Vector2(0, 1), 4):
						replace_with_special_piece(i, j + 1, current_color, COLUMN)
						#continue
				 #Check for horizontal match of 3
				if i > 0 and i < width - 1 and is_match(i, j, Vector2(1, 0), 3):
					mark_pieces_for_removal(i, j, true)
				## Check for vertical match of 3
				if j > 0 and j < height - 1 and is_match(i, j, Vector2(0, 1), 3):
					mark_pieces_for_removal(i, j, false)

	get_parent().get_node("destroy_timer").start()

func is_match(i, j, direction: Vector2, length: int) -> bool:
	#if all_pieces[i][j].type == RAINBOW:
		#return true
	if all_pieces[i][j] == null:
			return false
	if all_pieces[i][j].color == null:
		return false
	for k in range(1, length):
		var x = i + k * direction.x
		var y = j + k * direction.y
		if not in_grid(x, y):
			return false
		if all_pieces[x][y] == null:
			return false
		if all_pieces[x][y].color == null or all_pieces[x][y].color == "":
			return false
		
		if all_pieces[x][y].color != all_pieces[i][j].color:
			return false
	return true


func is_t_shape(i, j) -> bool:
	# Horizontal T shape
	if is_match(i, j, Vector2(1, 0), 3) and (
		(j > 0 and all_pieces[i + 1][j - 1] != null and all_pieces[i + 1][j - 1].color == all_pieces[i][j].color) or
		(j < height - 1 and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color)
	):
		return true

	# Vertical T shape
	if is_match(i, j, Vector2(0, 1), 3) and (
		(i > 0 and all_pieces[i - 1][j + 1] != null and all_pieces[i - 1][j + 1].color == all_pieces[i][j].color) or
		(i < width - 1 and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color)
	):
		return true

	return false

func is_l_shape(i, j) -> bool:
	# L shape, starting horizontally
	if is_match(i, j, Vector2(1, 0), 3):
		if ((
			j > 0 
			and all_pieces[i + 2][j - 1] != null
			and all_pieces[i + 2][j - 1].color == all_pieces[i][j].color) 
			or (
			j < height - 1 
			and all_pieces[i + 2][j + 1] != null 
			and all_pieces[i + 2][j + 1].color == all_pieces[i][j].color)
		):
			return true

	# L shape, starting vertically
	if is_match(i, j, Vector2(0, 1), 3):
		if ((
			i > 0
			and all_pieces[i - 1][j + 2] != null
			and all_pieces[i - 1][j + 2].color == all_pieces[i][j].color) 
			or (
			i < width - 1
			and all_pieces[i + 1][j + 2] != null 
			and all_pieces[i + 1][j + 2].color == all_pieces[i][j].color)
		):
			return true

	return false

func show_game_over_screen():
	# Asegúrate de tener una instancia de la escena de Game Over
	print('showed game over')
	
	# Puedes añadir la instancia de Game Over a la escena actual
	#get_tree().root.add_child(game_over_instance)
	
	# Desactivar las interacciones del juego
	get_tree().paused = true
