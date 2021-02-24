extends Node2D


func _process(delta):
	if (OS.get_ticks_msec() >= 3000):
		get_tree().change_scene("res://scenes/root.tscn")
