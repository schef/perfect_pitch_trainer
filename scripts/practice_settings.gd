extends "res://scripts/template.gd"

enum ElementIndex {
	BACK = -1,
	INSTRUMENT = 0,
}

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	var instrument = generate_button(ElementIndex.INSTRUMENT, "Instrument", "on_button_pressed")
	instrument.name = "InstrumentSection"
	scroll_array.add_child(instrument)

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK:
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.INSTRUMENT:
			get_tree().change_scene_to_file("res://scenes/settings_instrument.tscn")
