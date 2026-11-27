extends SceneTree

const Formula = preload("res://scripts/practice_formula.gd")
const WHITE = [0, 2, 4, 5, 7, 9, 11]

func _initialize():
	call_deferred("run")

func select_source(global, source_id: String):
	for ci in global.root.masterclasses.size():
		for pi in global.root.masterclasses[ci].practices.size():
			if global.root.masterclasses[ci].practices[pi].get("source_practice_id", "") == source_id:
				global.set_masterclass_index(ci)
				global.set_practice_index(pi)
				return
	assert(false, "Source practice not implemented: " + source_id)

func naming_scene():
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	return scene

func white_index(midi: int) -> int:
	return int(midi / 12) * 7 + WHITE.find(midi % 12)

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var expected = []
	for n in 12:
		expected.append("master-class-09-p%02d" % (n + 1))
	for n in 25:
		expected.append("master-class-10-p%02d" % (n + 1))
	var source_ids = []
	for source_id in expected:
		select_source(global, source_id)
		var practice = global.get_practice()
		assert(source_id not in source_ids)
		source_ids.append(source_id)
		assert(practice.info.review_status == "text_supported_audio_unverified")
		assert(not practice.info.source_windows.is_empty())
		var rng = RandomNumberGenerator.new()
		rng.seed = 9120
		var allowed_classes = practice.formula.pitch_classes.map(func(value): return int(value))
		for example in 100:
			var batch = Formula.generate(practice.formula, rng)
			assert(not batch.is_empty())
			var answer = global.get_flat_pitch_list(batch.anwser)
			assert(answer.size() == practice.formula.note_count, "Cue notes must never be required as answers")
			for note in batch.notes:
				assert(note % 12 in allowed_classes)
			if practice.formula.selection == "white_interval":
				assert(absi(white_index(batch.notes[1]) - white_index(batch.notes[0])) == practice.formula.white_steps)
				if practice.formula.presentation == "sequential":
					assert((batch.notes[0] < batch.notes[1]) == (practice.formula.direction == "ascending"))
			if practice.formula.has("cue_midi"):
				assert(batch.question.size() == 2)
				assert(batch.question[0].size() == practice.formula.cue_midi.size())

	# The third answer is assessed, unlike some historical Python validators.
	select_source(global, "master-class-10-p19")
	var scene = naming_scene()
	await process_frame
	scene.batch = {"question": [["c'"], ["d'"], ["e'"]],
		"anwser": [["c'"], ["d'"], ["e'"]], "presentation": "sequential"}
	assert(not scene.check_pitch_match(["c", "d", "f"]))
	assert(not scene.check_pitch_match(["c", "d"]))
	assert(not scene.check_pitch_match(["c", "d", "e", "f"]))
	assert(scene.check_pitch_match(["c", "d", "e"]))
	scene.queue_free()
	await process_frame

	# Source allows a harmonic ordering hint without treating the notes as wrong.
	select_source(global, "master-class-09-p09")
	scene = naming_scene()
	await process_frame
	scene.batch = {"question": [["c'", "e'"]], "anwser": [["c'", "e'"]],
		"presentation": "simultaneous"}
	scene.score = 5
	scene.keyboard.on_key_pressed("e")
	scene.keyboard.on_key_pressed("c")
	assert(scene.score == 5 and not scene.assisted)
	assert(scene.keyboard.textbox.text == "Reorder")
	scene.keyboard.on_key_pressed("c")
	scene.keyboard.on_key_pressed("e")
	assert(scene.score == 6)
	scene.queue_free()
	await process_frame

	# Two separately retained rounds, not a forty-consecutive reset-on-any-error.
	select_source(global, "master-class-09-p06")
	scene = naming_scene()
	await process_frame
	assert(global.get_practice().session.rounds == 2)
	assert(scene.reset_current_round(19) == 0)
	assert(scene.reset_current_round(20) == 20)
	assert(scene.reset_current_round(39) == 20)
	assert(scene.session_total_target() == 40)
	assert(scene.session_score_text(20) == "R2: 0/20")
	midi.allNotesOff()
	scene.play_question()
	assert(midi.noteActionQueue.size() == 4)
	assert(midi.noteActionQueue[0].startTimestamp < midi.noteActionQueue[3].startTimestamp)
	scene.queue_free()
	await process_frame

	# Numeric sixth verification alone does not confirm subjective familiarity.
	select_source(global, "master-class-09-p01")
	scene = naming_scene()
	await process_frame
	scene.score = 20
	scene.refresh_score()
	assert(not scene.familiarity_confirmed)
	scene.on_button_pressed(scene.ElementIndex.FAMILIAR)
	assert(scene.familiarity_confirmed)
	var original = global.file_data
	var key = global.formula_progress_key(global.get_practice())
	global.file_data = {"formula_progress": {key: 20}}
	assert(not global.is_practice_finished(9, global.get_practice().id))
	global.file_data["formula_familiarity"] = {key: true}
	assert(global.is_practice_finished(9, global.get_practice().id))
	global.file_data = original
	scene.queue_free()
	await process_frame
	global.reset_practice_index()
	global.reset_masterclass_index()
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Classes 9/10 passed: 37 source practices, 3700 generated cases, complete triple answers, harmonic reordering, separate cue rounds and familiarity.")
	quit()
