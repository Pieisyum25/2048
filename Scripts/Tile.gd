extends Node2D

onready var label = $Label
onready var slide_tween = $SlideTween
onready var creation_tween = $CreationTween
var start_position
var next_position

var value = 2 setget set_value, get_value
var tile_to_combine_with = null

func skip_animations():
	
	if slide_tween.is_active():
		slide_tween.stop_all()
		position = next_position
		
	if creation_tween.is_active():
		creation_tween.stop_all()
		position = start_position
		scale = Vector2(1, 1)
		modulate.a = 1

func appear():
	start_position = position
	var duration = 0.2
	
	# If value is 2, do grow-in animation:
	if value == 2:
		creation_tween.interpolate_property(self, "scale", Vector2(0, 0), Vector2(1, 1), 
		duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
		creation_tween.interpolate_property(self, "position", position + (get_parent().cell_size/2), position, 
		duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
		
	# Else, do fade-in and bounce-in animation:
	else:
		var max_scale = Vector2(1.2, 1.2)
		creation_tween.interpolate_property(self, "scale", scale, max_scale, 
		duration/2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		creation_tween.interpolate_property(self, "scale", max_scale, Vector2(1, 1), 
		duration/2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, duration/2)
		creation_tween.interpolate_property(self, "position", position, position - (get_parent().cell_size*(max_scale.x-1)/2), 
		duration/2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		creation_tween.interpolate_property(self, "position", position - (get_parent().cell_size*(max_scale.x-1)/2), position, 
		duration/2, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, duration/2)
		creation_tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 
		duration, Tween.TRANS_QUAD, Tween.EASE_OUT)
	
	creation_tween.start()

func slide(next_pos, other_tile = null):
	next_position = next_pos
	var duration = 0.2
	slide_tween.interpolate_property(self, "position", position, next_pos, 
	duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	slide_tween.start()

func set_value(v):
	value = v
	label.text = str(value)

func get_value():
	return value

func _to_string():
	return str(value)
