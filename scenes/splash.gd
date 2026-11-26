extends Node2D


func _process(delta):
	if (Time.get_ticks_msec() >= 3000):
		get_tree().change_scene_to_file("res://scenes/root.tscn")
