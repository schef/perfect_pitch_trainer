extends "res://scripts/template.gd"

var effect
var recording

enum ElementIndex {
	BACK = -1
	RECORD = 0,
	PLAY,
	STATUS
	}

func init():
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)
	
func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	scroll_array.add_child(generate_label(ElementIndex.STATUS, ""))
	scroll_array.add_child(generate_button(ElementIndex.RECORD, "Record", "on_button_pressed"))
	scroll_array.add_child(generate_button(ElementIndex.PLAY, "Play", "on_button_pressed"))

func record():
	if effect.is_recording_active():
		print("record end")
		set_label(ElementIndex.STATUS, "record end")
		recording = effect.get_recording()
		effect.set_recording_active(false)
	else:
		print("record start")
		set_label(ElementIndex.STATUS, "record start")
		effect.set_recording_active(true)

func play():
	print("play")
	set_label(ElementIndex.STATUS, "play")
	print(recording)
	print(recording.format)
	print(recording.mix_rate)
	print(recording.stereo)
	var data = recording.get_data()
	print(data)
	print(data.size())
	$Display/MarginContainer/VBoxContainer/ScrollContainer/ScrollArray/AudioStreamPlayer.stream = recording
	$Display/MarginContainer/VBoxContainer/ScrollContainer/ScrollArray/AudioStreamPlayer.play()

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK:
			Global.reset_practice_index()
			get_tree().change_scene("res://scenes/masterclass.tscn")
		ElementIndex.RECORD:
			record()
		ElementIndex.PLAY:
			play()
