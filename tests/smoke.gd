extends SceneTree

# Run with: godot --headless --path . --script res://tests/smoke.gd
func _initialize():
	call_deferred("run")

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	assert(midi.synth.bank != null)
	assert(midi.synth.audio_stream_players.size() == 32)
	var count = 0
	for masterclass_index in global.root.masterclasses.size():
		global.set_masterclass_index(masterclass_index)
		var menu = load("res://scenes/masterclass.tscn").instantiate()
		root.add_child(menu)
		menu.queue_free()
		await process_frame
		for practice_index in global.get_masterclass().practices.size():
			global.set_practice_index(practice_index)
			var path = "res://scenes/practice_%s.tscn" % global.get_field("practiceType").to_lower()
			var scene = load(path).instantiate()
			assert(scene.get_script() != null and scene.get_script().can_instantiate())
			root.add_child(scene)
			await process_frame
			var selector = scene.find_child("InstrumentSelector", true, false)
			assert(selector == null)
			if global.get_field("practiceType") == "SETTINGS":
				assert(scene.find_child("InstrumentSection", true, false) != null)
			if scene.get("keyboard") != null:
				var answer = global.get_flat_pitch_list(scene.batch.anwser)
				for pitch in answer:
					scene.keyboard.on_key_pressed(pitch)
				assert(scene.score == 1)
			scene.queue_free()
			await process_frame
			midi.allNotesOff()
			count += 1
		global.reset_practice_index()
	global.reset_masterclass_index()
	var instrument_screen = load("res://scenes/settings_instrument.tscn").instantiate()
	root.add_child(instrument_screen)
	assert(instrument_screen.title.text == "Instrument")
	var selector = instrument_screen.find_child("InstrumentSelector", true, false)
	assert(selector.get_child_count() == midi.INSTRUMENTS.size())
	assert(selector.get_child(midi.instrument_index).button_pressed)
	assert(midi.select_instrument((midi.instrument_index + 1) % midi.INSTRUMENTS.size(), false))
	for i in selector.get_child_count():
		assert(selector.get_child(i).button_pressed == (i == midi.instrument_index))
	instrument_screen.queue_free()
	await process_frame
	var menu = load("res://scenes/root.tscn").instantiate()
	root.add_child(menu)
	assert(menu.title.get_theme_font_size("font_size") == 80)
	assert(midi.select_instrument((midi.instrument_index + 1) % midi.INSTRUMENTS.size(), false))
	assert(menu.find_child("InstrumentSelector", true, false) == null)
	midi.noteOn(60)
	assert(midi.synth.audio_stream_players.any(func(s): return s.playing))
	midi.allNotesOff()
	assert(midi.noteActionQueue.is_empty())
	assert(midi.synth.audio_stream_players.all(func(s): return not s.playing and not s.linked.playing))
	menu.queue_free()
	await process_frame
	midi.synth.queue_free()
	# Release audio nodes before shutdown so the mixer can retire their playbacks.
	await create_timer(0.25).timeout
	print("Smoke test passed: %d practices, menus, keyboard answers and audio voices." % count)
	quit()
