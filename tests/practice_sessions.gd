extends SceneTree

# Exercises sessions without invoking Back/Finish (which persist user progress).
func _initialize():
	call_deferred("run")

func select_practice(global, class_id: int, practice_id: int):
	for class_index in global.root.masterclasses.size():
		if global.root.masterclasses[class_index].id != class_id:
			continue
		global.set_masterclass_index(class_index)
		for index in global.get_masterclass().practices.size():
			if global.get_masterclass().practices[index].id == practice_id:
				global.set_practice_index(index)
				return
	assert(false, "Practice not found")

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var formula_count = 0
	for lesson in global.root.masterclasses:
		for practice in lesson.practices:
			if not practice.has("formula"):
				continue
			formula_count += 1
			assert(practice.has("source_practice_id"))
			assert(practice.session.kind in ["open", "consecutive", "count", "spaced_recall"])
			if practice.practiceType == "PITCH_NAMING_DRILL":
				assert(practice.formula.response == "name")
				assert(practice.session.assessment == "keyboard")
			else:
				assert(practice.session.assessment == "self_report")
			assert(not practice.info.source_windows.is_empty())
			for window in practice.info.source_windows:
				assert(window.start >= 0 and window.end > window.start)
			var rng = RandomNumberGenerator.new()
			rng.seed = 2000 + practice.id
			for trial in 100:
				var batch = preload("res://scripts/practice_formula.gd").generate(practice.formula, rng)
				assert(not batch.is_empty())
				assert(batch.presentation == practice.formula.presentation)
			var example = preload("res://scripts/practice_formula.gd").generate(practice.formula, rng)
			midi.allNotesOff()
			midi.playMultipleNotesHarmonicly(example.question)
			var cue_count = practice.formula.get("cue_midi", []).size()
			assert(midi.noteActionQueue.size() == practice.formula.note_count + cue_count)
			if practice.formula.note_count > 1:
				var first = midi.noteActionQueue[cue_count].startTimestamp
				var second = midi.noteActionQueue[cue_count + 1].startTimestamp
				assert((first == second) == (example.presentation == "simultaneous"))
			midi.allNotesOff()

	select_practice(global, 6, 2)
	var scene = load("res://scenes/practice_pitch_identify_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.on_button_pressed(scene.ElementIndex.NEXT)
	assert(scene.score == 1)
	scene.on_button_pressed(scene.ElementIndex.INCORRECT)
	assert(scene.score == 0 and scene.assisted)
	scene.on_button_pressed(scene.ElementIndex.NEXT)
	assert(scene.score == 0 and not scene.assisted)
	scene.on_button_pressed(scene.ElementIndex.NEXT)
	assert(scene.score == 1)
	var previous_batch = scene.batch.duplicate(true)
	var previous_process_mode = scene.process_mode
	scene.show_practice_info()
	var info_screen = scene.practice_info_screen
	assert(info_screen != null)
	assert("master-class-06-p01" in info_screen.get_meta("source_text"))
	assert(not scene.get_node("Display").visible)
	assert(scene.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(info_screen.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(info_screen.find_child("PracticeInfo", true, false) == null)
	assert(info_screen.find_child("SourceInfoText", true, false).fit_content)
	scene.navigate_back()
	await process_frame
	assert(scene.practice_info_screen == null)
	assert(scene.get_node("Display").visible)
	assert(scene.process_mode == previous_process_mode)
	assert(scene.score == 1 and scene.batch == previous_batch)
	scene.queue_free()
	await process_frame

	select_practice(global, 7, 3)
	scene = load("res://scenes/practice_meditation.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.session_is_open())
	scene.on_button_pressed(scene.ElementIndex.NEXT)
	assert(scene.score == 0)
	assert(scene.find_child("BUTTON_" + str(scene.ElementIndex.FINISH), true, false) != null
		or scene.scroll_array.get_children().any(func(node): return node is Button and node.text == "Finish practice"))
	scene.queue_free()
	await process_frame

	select_practice(global, 7, 2)
	scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var answer = global.get_flat_pitch_list(scene.batch.anwser)
	var wrong = "cis" if answer[0] != "cis" else "d"
	scene.keyboard.on_key_pressed(wrong)
	assert(scene.score == 0 and scene.assisted)
	for pitch in answer:
		scene.keyboard.on_key_pressed(pitch)
	assert(scene.score == 0, "Assisted retry must not count toward verification")
	answer = global.get_flat_pitch_list(scene.batch.anwser)
	for pitch in answer:
		scene.keyboard.on_key_pressed(pitch)
	assert(scene.score == 1)
	scene.queue_free()
	await process_frame

	# Definition-scoped progress does not silently inherit legacy completion.
	var original_data = global.file_data
	global.file_data = {7: {2: 20}}
	assert(global.get_score(7, 2) == 0)
	var key = global.formula_progress_key(global.get_practice())
	global.file_data["formula_progress"] = {key: 4}
	assert(global.get_score(7, 2) == 4)
	assert(global.file_data[7][2] == 20)
	global.file_data = original_data
	global.reset_practice_index()
	global.reset_masterclass_index()
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Practice sessions passed: %d formulas, self-report correction, Info, open meditation, naming and preserved legacy progress." % formula_count)
	quit()
