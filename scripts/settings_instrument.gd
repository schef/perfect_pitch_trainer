extends "res://scripts/template.gd"

enum ElementIndex {
	BACK = -1
	}

var instrument_buttons: Array[Button] = []

func init_header():
	title.text = "Instrument"
	subtitle.text = "Choose your instrument"

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	var selector = VBoxContainer.new()
	selector.name = "InstrumentSelector"
	selector.add_theme_constant_override("separation", 50)
	var group = ButtonGroup.new()
	for index in MidiPlayer.INSTRUMENTS.size():
		var instrument = MidiPlayer.INSTRUMENTS[index]
		var choice = generate_button(index, instrument.name, "on_instrument_pressed")
		choice.name = "Instrument%d" % index
		choice.theme = load("res://assets/btn_v%d.tres" % (index + 1))
		choice.add_theme_stylebox_override("hover_pressed", choice.theme.get_stylebox("pressed", "Button"))
		choice.toggle_mode = true
		choice.button_group = group
		instrument_buttons.append(choice)
		selector.add_child(choice)
	scroll_array.add_child(selector)
	update_instrument_buttons(MidiPlayer.instrument_index)
	MidiPlayer.instrument_changed.connect(update_instrument_buttons)

func on_instrument_pressed(index: int):
	MidiPlayer.select_instrument(index)
	# Restore the current selection if loading the requested SoundFont failed.
	update_instrument_buttons(MidiPlayer.instrument_index)

func update_instrument_buttons(index: int):
	for i in instrument_buttons.size():
		instrument_buttons[i].set_pressed_no_signal(i == index)

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK:
			get_tree().change_scene_to_file("res://scenes/practice_settings.tscn")
