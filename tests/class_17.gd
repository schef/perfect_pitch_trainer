extends "res://tests/classes_15_16.gd"

# Run ONLY after Class 17 content/runtime are installed:
# godot --headless --path . --script res://tests/class_17.gd
# Optional: -- --source-dir=/path/to/digital-handbook/curriculum
# Reuse read-only source/scene helpers, never the parent run(). No Back, Finish,
# ManualComplete, Log session, set_score or save_file calls are permitted here.
const Plan17 = preload("res://scripts/pattern_plan.gd")
const STANDARD17 = [0, 2, 4, 5, 6, 7, 8, 9, 11]
const GUITAR17 = [0, 1, 2, 4, 5, 6, 8, 9, 11]

func source17() -> Dictionary:
	var directory = SOURCE_DIR
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source-dir="):
			directory = argument.trim_prefix("--source-dir=")
	var path = directory.path_join("master-class-17.json")
	assert(FileAccess.file_exists(path), "Independent canonical source required: " + path)
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(document is Dictionary and document.practices.size() == 11)
	assert(document.lesson_id == "master-class-17")
	assert(document.review_status == "text_supported_audio_unverified")
	return document

func check_formula17(practice: Dictionary, number: int):
	var formula: Dictionary = practice.formula
	var before = formula.duplicate(true)
	var count = int(formula.note_count)
	var pool = STANDARD17 if number in [7, 10] else GUITAR17 if number in [8, 11] else BLACK
	assert(classes(formula.pitch_classes) == pool)
	assert(count == 2 if number in [2, 7, 8] else count == 4 if number in [4, 5] else count in [1, 2, 3])
	assert(formula.selection == ("single" if count == 1 else "distinct"))
	assert(not formula.get("distinct_pitch_classes", false), "Distinct MIDI tones need not have distinct pitch classes")
	assert(formula.response == ("recall" if number in [7, 8] else "sing" if number == 4 else "name"))
	var cue = integers(formula.get("cue_midi", []))
	assert(cue == ([60, 64, 67, 72] if number == 2 else []))
	if number in [2, 4, 5]:
		assert(formula.presentation == "simultaneous")
		assert(practice.session.rounds == 1 and practice.session.target == 20)
		if number in [4, 5]:
			assert(practice.info.completion.details.items_per_round == null)
			assert(not practice.info.implementation_decisions.is_empty(), "Inherited twenty-item size must be disclosed")
	elif number in [7, 8]:
		check_open(practice, "self_report")
		assert(practice.recall_check_mode == "sequential")
		assert(practice.recall_check_modes == ["sequential", "simultaneous"])
	else:
		check_open(practice, "keyboard")
		assert(practice.optional and practice.implementation_status == "optional_adaptation")
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 170000 + int(practice.id) * 100
	twin.seed = rng.seed
	for example in 80:
		var batch: Dictionary = Formula.generate(formula, rng)
		assert(not batch.is_empty() and batch == Formula.generate(formula, twin))
		var notes = integers(batch.notes)
		assert(notes.size() == count)
		var seen: Array = []
		for note in notes:
			assert(note not in seen and note % 12 in pool)
			assert(note >= formula.get("midi_min", 36) and note <= formula.get("midi_max", 84))
			seen.append(note)
		var ascending = sorted_copy(notes)
		assert(ascending.back() - ascending.front() >= formula.get("min_span", 0))
		assert(ascending.back() - ascending.front() <= formula.get("max_span", 48))
		assert(integers(batch.cue_notes) == cue)
		assert(flattened(batch.question) == cue + notes)
		assert(flattened(batch.anwser) == (ascending if batch.answer_order == "ascending_pitch" else notes), "Cues are never answer slots")
		assert(batch.response == formula.response and batch.presentation == formula.presentation)
		if formula.presentation == "sequential":
			assert(batch.question.size() == count and batch.anwser.size() == count)
			for group in batch.anwser:
				assert(group.size() == 1)
		else:
			assert(batch.anwser.size() == 1 and batch.anwser[0].size() == count)
	assert(formula == before)

func check_black_four(global, practice: Dictionary):
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var formula: Dictionary = practice.formula.duplicate(true)
	# Four distinct MIDI notes, only three black pitch classes: an octave repeat
	# is forced rather than left to chance across eighty random examples.
	formula.pitch_classes = [1, 3, 6]
	formula.midi_min = 61
	formula.midi_max = 73
	formula.min_span = 0
	formula.max_span = 12
	var rng = RandomNumberGenerator.new()
	rng.seed = 1705
	scene.batch = Formula.generate(formula, rng)
	assert(integers(scene.batch.notes) == [61, 63, 66, 73])
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == 4 and scene.check_pitch_match(answer))
	for position in 4:
		var wrong = answer.duplicate()
		wrong[position] = NAMES[(NAMES.find(str(answer[position])) + 1) % 12]
		assert(not scene.check_pitch_match(wrong), "All four targets, including fourth, are assessed")
	assert(not scene.check_pitch_match(answer.slice(0, 3)))
	assert(not scene.check_pitch_match(answer + ["c"]))
	await dispose_scene(scene)

func check_singing17(practice: Dictionary):
	assert(practice.practiceType == "PITCH_IDENTIFY_DRILL")
	assert(practice.session.assessment == "self_report", "Singing is not microphone-verified")
	var scene = load("res://scenes/practice_pitch_identify_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.batch.notes.size() == 4)
	scene.on_button_pressed(scene.ElementIndex.REPEAT)
	assert(scene.score == 0, "Listening alone earns no singing credit")
	await dispose_scene(scene)

func check_mixed17(global, practice: Dictionary):
	assert(practice.practiceType == "MIXED_PATTERN" and not practice.has("formula"))
	assert(practice.session.kind == "patterns" and practice.session.rounds == 3)
	assert(practice.session.target == 10 and practice.session.patterns_per_round == 10)
	var config: Dictionary = practice.mixed_pattern
	assert(config.white_count == 3)
	assert(not practice.info.implementation_decisions.is_empty(), "Pattern-level error policy is an app choice")
	for position in 20:
		assert(Plan17.mixed_pool(config, position) == (BLACK if position % 4 == 3 else WHITE), "Four-tone cycle, not old modulo five")
	var scene = load("res://scenes/practice_mixed_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.pattern_length() == 4 and scene.session_total_target() == 30)
	scene.restart_patterns()
	scene.next_batch()
	for position in 4:
		assert(scene.pattern_position == position)
		assert(scene.batch.notes.size() == 1)
		assert(int(scene.batch.notes[0]) % 12 in (BLACK if position == 3 else WHITE))
		scene.on_key_press(global.get_flat_pitch_list(scene.batch.anwser))
		assert(scene.score == (1 if position == 3 else 0))
	assert(scene.patterns == 1 and scene.pattern_position == 0, "No fifth white tone appended")
	var batch = scene.batch.duplicate(true)
	scene.record_response(false)
	assert(not scene.pattern_valid and scene.pattern_position == 0 and scene.batch == batch)
	for position in 4:
		scene.record_response(true)
	assert(scene.score == 1 and scene.patterns == 1 and scene.pattern_valid)
	var expected: Array = global.get_flat_pitch_list(scene.batch.anwser)
	scene.on_key_press([NAMES[(NAMES.find(str(expected[0])) + 1) % 12]])
	assert(not scene.pattern_valid and scene.pattern_position == 0 and scene.score == 1)
	for position in 4:
		scene.on_key_press(global.get_flat_pitch_list(scene.batch.anwser))
	assert(scene.score == 1 and scene.patterns == 1, "Wrong keyboard input invalidates only current pattern")
	scene.mark_assisted()
	for position in 4:
		scene.record_response(true)
	assert(scene.score == 1)
	for pattern in range(2, 31):
		for position in 4:
			scene.record_response(true)
		assert(scene.score == pattern and scene.patterns == pattern)
		if pattern == 10:
			assert(scene.session_score_text(scene.score) == "R2: 0/10")
		elif pattern == 20:
			assert(scene.session_score_text(scene.score) == "R3: 0/10")
	assert(scene.session_score_text(scene.score).to_lower() == "3 rounds done")
	var status = scene.find_child("PatternStatus", true, false)
	assert(status != null and "4" in str(status.text))
	await dispose_scene(scene)

func check_reference17(practice: Dictionary):
	assert(practice.practiceType == "REFERENCE_PATTERN")
	check_open(practice, "keyboard")
	var config: Dictionary = practice.reference_pattern
	assert(config.mode == "extra_targets" and config.targets_per_cue == 3)
	assert(config.cue_a_label == "A" and config.cue_b_label == "G")
	assert(config.cue_a_midi == 45 and config.cue_b_midi == 55)
	# Retain Class 14's legacy cue_d_midi/default, independently of new labels.
	assert(Plan17.reference_step({"mode": "extra_targets", "cue_d_midi": 50}, 4).cue_midi == [50])
	assert(Plan17.reference_step({"mode": "extra_targets"}, 4).cue_midi == [50])
	var scene = load("res://scenes/practice_reference_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.restart_reference()
	for index in 24:
		var step = Plan17.reference_step(config, index)
		var local = index % 8
		assert(not step.window_complete and step.block == ("A" if local < 4 else "G"))
		assert(step.extra == (local in [3, 7]))
		assert(integers(step.cue_midi) == ([] if step.extra else [45 if local < 4 else 55]))
		assert(scene.step_index == index and flattened(scene.batch.anwser).size() == 1)
		assert(flattened(scene.batch.question) == integers(step.cue_midi) + flattened(scene.batch.anwser))
		assert(scene.score == 0)
		scene.next_reference()
	assert(scene.score == 0)
	await dispose_scene(scene)

func check_first_recall17(practice: Dictionary):
	assert(practice.practiceType == "MEDITATION_GUIDE" and not practice.has("formula"))
	check_open(practice, "self_report")
	assert(practice.meditation.mode == "first_recall")
	assert(practice.meditation.anchor_midi == (60 if practice.id == 10 else 57))
	for key in ["consistency_threshold", "required_streak", "time_limit", "readiness_score"]:
		assert(not practice.meditation.has(key) and not practice.session.has(key))
	var before = practice.duplicate(true)
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = load("res://scenes/practice_meditation_guide.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.current_note() == practice.meditation.anchor_midi)
	assert(midi.noteActionQueue.is_empty(), "Imagine/sing before any reference audio")
	scene.next_target()
	assert(midi.noteActionQueue.is_empty())
	scene.shift_anchor(1)
	assert(midi.noteActionQueue.is_empty() and practice == before, "Optional root changes stay local and silent")
	var instructions = scene.find_child("MeditationInstructions", true, false)
	assert(instructions != null)
	for instruction in practice.info.source_instructions:
		assert(str(instruction) in instructions.text)
	assert(scene.find_child("MeditationFinish", true, false) is Button)
	await dispose_scene(scene)

func check_required_completion17(global, practices: Array):
	var saved = global.file_data
	var fake = {17: {}, "formula_progress": {}}
	global.file_data = fake
	assert(not global.is_masterclass_finished(17))
	for practice in practices:
		if practice.get("optional", false):
			continue
		var amount = 1
		if practice.get("session", {}).get("kind", "") == "patterns":
			amount = 30
		elif practice.has("formula"):
			amount = 20
		else:
			amount = maxi(1, int(practice.get("maxHits", 0)))
		if practice.has("formula"):
			fake.formula_progress[global.formula_progress_key(practice)] = amount
		else:
			fake[17][practice.id] = amount
	for practice in practices:
		if practice.get("optional", false):
			assert(not global.is_practice_finished(17, practice.id))
	assert(global.is_masterclass_finished(17), "Optional team examples must not block required completion")
	global.file_data = saved

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_root = global.root.duplicate(true)
	var original_data = global.file_data
	var progress = original_data.duplicate(true)
	var disk = disk_progress_snapshot(global)
	var ci = global.get_masterclass_index()
	var pi = global.get_practice_index()
	var document = source17()
	var lesson = global.get_masterclass_by_id(17)
	assert(lesson != null)
	var practices: Array = lesson.practices
	assert(practices.size() == 24, "Twenty-two activities plus Player and Comments")
	assert(practices[0].id == 0 and practices[1].id == 1)
	var groups: Dictionary = {}
	var ids: Array = []
	var uids: Array = []
	for practice in practices:
		assert(practice.id not in ids)
		ids.append(int(practice.id))
		if int(practice.id) in [0, 1]:
			continue
		var sid: String = practice.source_practice_id
		assert(sid.begins_with("master-class-17-p"))
		assert(not str(practice.practice_uid).is_empty() and practice.practice_uid not in uids)
		uids.append(practice.practice_uid)
		if not groups.has(sid):
			groups[sid] = []
		groups[sid].append(practice)
	assert(sorted_copy(ids) == range(24) and groups.size() == 11 and uids.size() == 22)
	var formulas = 0
	var manuals = 0
	var first_recalls = 0
	var optionals = 0
	for source in document.practices:
		var number = int(str(source.id).right(2))
		assert(groups.has(source.id))
		var variants: Array = groups[source.id]
		assert(variants.size() == (6 if number in [10, 11] else 2 if number == 9 else 1))
		var forms: Array = []
		var base_found = false
		for practice in variants:
			select_practice(global, 17, practice)
			check_info(practice, source)
			if int(practice.id) == number + 1:
				base_found = true
			if practice.get("optional", false):
				optionals += 1
				assert(number in [10, 11] and practice.has("formula"))
				assert(practice.implementation_status == "optional_adaptation")
				assert(int(practice.id) in (range(14, 19) if number == 10 else range(19, 24)))
				var form = str([int(practice.formula.note_count), practice.formula.presentation])
				assert(form not in forms)
				forms.append(form)
			else:
				assert(practice.id == number + 1 or (number == 9 and practice.id == 13))
			if practice.has("formula"):
				check_formula17(practice, number)
				formulas += 1
				if number in [7, 8]:
					await check_recall_scene(global, practice)
				elif number == 4:
					await check_singing17(practice)
				else:
					await check_naming_scene(global, practice)
					if number == 5:
						await check_black_four(global, practice)
			elif number in [1, 10, 11]:
				assert(not practice.get("optional", false))
				await check_manual_scene(practice)
				manuals += 1
			elif number == 3:
				await check_mixed17(global, practice)
			elif number == 6:
				await check_reference17(practice)
			elif number == 9:
				await check_first_recall17(practice)
				first_recalls += 1
			else:
				assert(false, "Unexpected Class 17 activity")
		assert(base_found, "Source pNN keeps numeric base ID NN+1")
		if number in [10, 11]:
			assert(forms.size() == 5)
			var expected_forms: Array = []
			for form in [[1, "sequential"], [2, "sequential"], [3, "sequential"], [2, "simultaneous"], [3, "simultaneous"]]:
				expected_forms.append(str(form))
			assert(sorted_copy(forms) == sorted_copy(expected_forms), "Exactly single, melodic double/triple and harmonic double/triple")
	assert(formulas == 15 and manuals == 3 and first_recalls == 2 and optionals == 10)
	check_required_completion17(global, practices)
	assert(global.root == original_root)
	assert(global.file_data == progress and disk_progress_snapshot(global) == disk, "No progress writes, including manual visits")
	global.file_data = original_data
	global.set_masterclass_index(ci)
	global.set_practice_index(pi)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Class 17 passed: 22 activities / 11 exact source groups; 15 formulas x 80 twin-seeded cases; black harmonic fours and all answer slots; four-tone mixed cycles with retained completed patterns; A/G references; silent recall mode toggles and first recall; three manual guides; ten optional nine-class team forms do not block completion; no progress writes.")
	quit()
