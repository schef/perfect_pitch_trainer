extends "res://tests/classes_15_16.gd"

# Run ONLY after Class 18 content and runtime are installed:
# godot --headless --path . --script res://tests/class_18.gd
# Optional: -- --source-dir=/independent/path/to/digital-handbook/curriculum
# Read-only: never invoke Back, Finish, ManualComplete, set_score or save_file.
const Plan18 = preload("res://scripts/pattern_plan.gd")
const STANDARD18 = [0, 2, 3, 4, 5, 6, 7, 8, 9, 11]
const GUITAR18 = [0, 1, 2, 3, 4, 5, 6, 8, 9, 11]
const ROOTS18 = [2, 4, 5, 7, 9, 11, 1, 3, 6, 8, 10]

func source18() -> Dictionary:
	var directory = SOURCE_DIR
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source-dir="):
			directory = argument.trim_prefix("--source-dir=")
	var path = directory.path_join("master-class-18.json")
	assert(FileAccess.file_exists(path), "Independent canonical source required: " + path)
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(document is Dictionary and document.practices.size() == 8)
	assert(document.lesson_id == "master-class-18")
	assert(document.review_status == "text_supported_audio_unverified")
	return document

func check_formula18(practice: Dictionary, number: int):
	var formula: Dictionary = practice.formula
	var before = formula.duplicate(true)
	var count = int(formula.note_count)
	var cue = integers(formula.get("cue_midi", []))
	var pool: Array
	if number == 2:
		assert(count == 2 and formula.presentation == "simultaneous")
		assert(cue.size() == 3 and cue == [cue[0], cue[0] + 4, cue[0] + 7])
		assert(int(cue[0]) % 12 in ROOTS18, "C major was completed in Class 17")
		pool = BLACK if int(cue[0]) % 12 in WHITE else WHITE
		assert(not practice.get("optional", false))
		assert(formula.response == "name")
		check_open(practice, "keyboard")
	else:
		assert(number in [6, 7] and practice.optional)
		assert(practice.implementation_status == "optional_adaptation")
		pool = STANDARD18 if number == 6 else GUITAR18
		assert(cue.is_empty() and count in [1, 2, 3])
		if int(practice.id) in [30, 31]:
			assert(count == 2 and formula.response == "recall")
			check_open(practice, "self_report")
			assert(practice.recall_check_mode == "sequential")
			assert(practice.recall_check_modes == ["sequential", "simultaneous"])
		else:
			assert(formula.response == "name")
			check_open(practice, "keyboard")
	assert(classes(formula.pitch_classes) == pool)
	assert(formula.selection == ("single" if count == 1 else "distinct"))
	assert(not formula.get("distinct_pitch_classes", false), "Distinct tones can repeat a pitch class in another octave")
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 180000 + int(practice.id) * 100
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
		assert(flattened(batch.anwser) == (ascending if batch.answer_order == "ascending_pitch" else notes))
		assert(batch.response == formula.response and batch.presentation == formula.presentation)
		if formula.presentation == "simultaneous":
			assert(batch.anwser.size() == 1 and batch.anwser[0].size() == count)
		else:
			assert(batch.anwser.size() == count)
			for group in batch.anwser:
				assert(group.size() == 1)
	assert(formula == before, "Formula generation must not mutate curriculum")

func assistance_batch18(notes: Array, cue: Array = []) -> Dictionary:
	# A deterministic scene-local fixture, never a replacement curriculum formula.
	var parser = root.get_node("PitchParser")
	var targets: Array = []
	var cue_pitches: Array = []
	for note in notes:
		targets.append(parser.getPitchFromMidi(int(note)))
	for note in cue:
		cue_pitches.append(parser.getPitchFromMidi(int(note)))
	var question: Array = []
	if not cue.is_empty():
		question.append(cue_pitches)
	question.append(targets)
	return {"notes": notes.duplicate(), "cue_notes": cue.duplicate(), "question": question,
		"anwser": [targets], "presentation": "simultaneous", "response": "name",
		"answer_order": "presentation_order"}

func check_assistance18(global, practice: Dictionary, mixed: bool = false):
	assert(practice.get("semitone_assistance", false), "Class 18 naming explicitly opts into optional help")
	var midi = root.get_node("MidiPlayer")
	var before = practice.duplicate(true)
	var path = "res://scenes/practice_mixed_pattern.tscn" if mixed else "res://scenes/practice_pitch_naming_drill.tscn"
	var scene = load(path).instantiate()
	root.add_child(scene)
	await process_frame
	for name in ["HelpUp", "HelpDown", "HelpOriginal", "HelpTarget"]:
		var control = scene.find_child(name, true, false)
		assert(control != null and control.visible, "Optional semitone help needs " + name)
	for method in ["assistance_notes", "select_assistance_target", "play_neighbor", "play_original_target"]:
		assert(scene.has_method(method))
	# Both colors cross their target pitch pool, and repeated requests walk cumulatively.
	for notes in [[60, 64], [61, 66]]:
		if mixed:
			scene.restart_patterns()
		scene.batch = assistance_batch18(notes, [45, 49, 52])
		scene.assisted = false
		midi.allNotesOff()
		assert(integers(scene.assistance_notes()) == notes, "Only actual targets, never the cue chord")
		scene.select_assistance_target(0)
		assert(scene.assistance_target == 0 and scene.neighbor_offset == 0)
		assert(midi.noteActionQueue.is_empty() and not scene.assisted, "Selecting a target alone is silent and supplies no pitch evidence")
		if mixed:
			assert(scene.pattern_valid, "Silent selection alone does not invalidate a pattern")
		var score_before = scene.score
		for offset in [1, 2, 1, 0, -1]:
			midi.allNotesOff()
			scene.play_neighbor(1 if offset in [1, 2] and scene.neighbor_offset < offset else -1)
			assert(scene.assisted and (not mixed or not scene.pattern_valid), "Audible help invalidates verification for the trial/pattern")
			assert(scene.neighbor_offset == offset)
			assert(queue_notes(midi) == [notes[0] + offset], "Neighbors are chromatic, not filtered by target pool")
		midi.allNotesOff()
		scene.select_assistance_target(1)
		assert(scene.assistance_target == 1 and scene.neighbor_offset == 0 and midi.noteActionQueue.is_empty())
		scene.play_neighbor(1)
		assert(queue_notes(midi) == [notes[1] + 1] and scene.neighbor_offset == 1)
		midi.allNotesOff()
		scene.assisted = false
		if mixed:
			scene.pattern_valid = true
		scene.play_original_target()
		assert(queue_notes(midi) == [notes[1]], "Original means the selected actual target, not cue or transposed neighbor")
		assert(scene.assisted and (not mixed or not scene.pattern_valid), "Original-target help must mark assistance too")
		midi.allNotesOff()
		scene.select_assistance_target(2)
		assert(scene.assistance_target in [0, 1] and midi.noteActionQueue.is_empty(), "Index 2 is invalid for a two-target batch")
		scene.play_original_target()
		assert(queue_notes(midi) == [notes[scene.assistance_target]])
		assert(scene.score == score_before and scene.assisted, "Help grants no verification credit")
	# Valid MIDI endpoints are usable; stepping outside hardware range is a silent no-op.
	for endpoint in [0, 127]:
		scene.batch = assistance_batch18([endpoint])
		midi.allNotesOff()
		scene.select_assistance_target(0)
		scene.play_original_target()
		assert(queue_notes(midi) == [endpoint])
		assert(scene.find_child("HelpDown" if endpoint == 0 else "HelpUp", true, false).disabled, "Unavailable MIDI directions must be disabled in the UI")
		midi.allNotesOff()
		scene.play_neighbor(-1 if endpoint == 0 else 1)
		assert(midi.noteActionQueue.is_empty() and scene.neighbor_offset == 0, "Invalid boundary must not queue a note or drift state")
	assert(practice == before)
	assert(global.get_practice() == practice)
	await dispose_scene(scene)

func check_mixed18(global, practice: Dictionary, number: int):
	var midi = root.get_node("MidiPlayer")
	assert(practice.practiceType == "MIXED_PATTERN" and not practice.has("formula"))
	assert(practice.session.kind == "patterns" and practice.session.rounds == 3)
	assert(practice.session.target == 10 and practice.session.patterns_per_round == 10)
	var config: Dictionary = practice.mixed_pattern
	assert(config.white_count == 3 and config.white_note_count == 2)
	assert(config.black_note_count == (1 if number == 3 else 2))
	assert(not practice.info.implementation_decisions.is_empty(), "Pattern error/help policy must be disclosed as an app choice")
	for position in 20:
		assert(Plan18.mixed_pool(config, position) == (BLACK if position % 4 == 3 else WHITE))
	var scene = load("res://scenes/practice_mixed_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.pattern_length() == 4 and scene.session_total_target() == 30)
	scene.restart_patterns()
	# Inherited ordering guidance supplies no answer sound or failed-pattern penalty.
	scene.batch = assistance_batch18([60, 64])
	midi.allNotesOff()
	scene.on_key_press(["e", "c"])
	assert(scene.pattern_position == 0 and scene.pattern_valid and not scene.assisted)
	assert(scene.keyboard.textbox.text == "Reorder" and midi.noteActionQueue.is_empty())
	scene.next_batch()
	var responses = 0
	for position in 4:
		assert(scene.pattern_position == position)
		var count = 2 if position < 3 else int(config.black_note_count)
		assert(scene.batch.notes.size() == count)
		assert(classes(scene.batch.notes).all(func(pc): return pc in (BLACK if position == 3 else WHITE)))
		assert(scene.batch.presentation == "simultaneous")
		var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
		assert(answer.size() == count and scene.check_pitch_match(answer))
		assert(not scene.check_pitch_match(answer.slice(0, count - 1)))
		assert(not scene.check_pitch_match(answer + ["c"]))
		for slot in count:
			var wrong = answer.duplicate()
			wrong[slot] = NAMES[(NAMES.find(str(answer[slot])) + 1) % 12]
			assert(not scene.check_pitch_match(wrong), "Inherited naming checks every target slot")
		if count == 2:
			var batch_before = scene.batch.duplicate(true)
			scene.on_key_press(answer.slice(0, 1))
			assert(scene.pattern_position == position and scene.batch == batch_before and scene.score == 0)
		responses += count
		scene.on_key_press(answer)
		assert(scene.score == (1 if position == 3 else 0), "One response is one example, not one named tone")
	assert(responses == (7 if number == 3 else 8))
	assert(scene.patterns == 1 and scene.pattern_position == 0)
	var correct: Array = global.get_flat_pitch_list(scene.batch.anwser)
	var wrong_second = correct.duplicate()
	wrong_second[1] = NAMES[(NAMES.find(str(correct[1])) + 1) % 12]
	var batch_before = scene.batch.duplicate(true)
	scene.on_key_press(wrong_second)
	assert(not scene.pattern_valid and scene.pattern_position == 0 and scene.batch == batch_before)
	for position in 4:
		scene.on_key_press(global.get_flat_pitch_list(scene.batch.anwser))
	assert(scene.score == 1 and scene.patterns == 1, "Wrong second name invalidates whole pattern, not previous completed patterns")
	scene.play_neighbor(1)
	assert(scene.assisted and not scene.pattern_valid)
	for position in 4:
		scene.record_response(true)
	assert(scene.score == 1 and scene.patterns == 1, "An assisted pattern earns no new credit")
	for pattern in range(2, 31):
		for position in 4:
			scene.record_response(true)
		assert(scene.score == pattern and scene.patterns == pattern)
		if pattern == 10:
			assert(scene.session_score_text(scene.score) == "R2: 0/10")
		elif pattern == 20:
			assert(scene.session_score_text(scene.score) == "R3: 0/10")
	assert(scene.session_score_text(scene.score).to_lower() == "3 rounds done")
	await dispose_scene(scene)
	await check_assistance18(global, practice, true)

func check_reference18(practice: Dictionary):
	assert(practice.practiceType == "REFERENCE_PATTERN")
	check_open(practice, "keyboard")
	var config: Dictionary = practice.reference_pattern
	assert(config.mode == "extra_targets" and config.targets_per_cue == 3)
	assert(config.cue_blocks.size() == 3)
	# Legacy Class 14/17 two-block fallback must not be changed by the new array.
	assert(Plan18.reference_step({"mode": "extra_targets"}, 4).cue_midi == [50])
	assert(Plan18.reference_step({"mode": "extra_targets", "cue_d_midi": 50}, 4).cue_midi == [50])
	var legacy = {"mode": "extra_targets", "cue_a_label": "A", "cue_a_midi": 45, "cue_b_label": "G", "cue_b_midi": 55}
	for index in 16:
		var step = Plan18.reference_step(legacy, index)
		assert(step.block == ("A" if index % 8 < 4 else "G"))
		assert(integers(step.cue_midi) == ([] if index % 4 == 3 else [45 if index % 8 < 4 else 55]))
	assert(Plan18.reference_step({"mode": "blocks", "targets_per_cue": 3}, 6).window_complete)
	var scene = load("res://scenes/practice_reference_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.restart_reference()
	for index in 36:
		var local = index % 12
		var block = int(local / 4)
		var step = Plan18.reference_step(config, index)
		assert(not step.window_complete and step.block == ["A", "D", "G"][block])
		assert(step.extra == (local in [3, 7, 11]))
		assert(integers(step.cue_midi) == ([] if step.extra else [[45], [50], [55]][block]))
		assert(scene.step_index == index and flattened(scene.batch.anwser).size() == 1)
		assert(flattened(scene.batch.question) == integers(step.cue_midi) + flattened(scene.batch.anwser))
		assert(scene.score == 0)
		scene.next_reference()
	assert(scene.score == 0)
	await dispose_scene(scene)

func check_completion18(global, practices: Array):
	var saved = global.file_data
	var fake = {18: {}, "formula_progress": {}}
	global.file_data = fake
	assert(not global.is_masterclass_finished(18))
	for practice in practices:
		if practice.get("optional", false):
			continue
		var amount = 30 if practice.get("session", {}).get("kind", "") == "patterns" else maxi(1, int(practice.get("maxHits", 0)))
		if practice.has("formula"):
			fake.formula_progress[global.formula_progress_key(practice)] = amount
		else:
			fake[18][practice.id] = amount
	for practice in practices:
		if practice.get("optional", false):
			assert(not global.is_practice_finished(18, practice.id))
	assert(global.is_masterclass_finished(18), "Twelve optional naming/recall adaptations must not block required completion")
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
	var document = source18()
	var lesson = global.get_masterclass_by_id(18)
	assert(lesson != null)
	var practices: Array = lesson.practices
	assert(practices.size() == 32, "Thirty activities plus Player and Comments")
	assert(practices[0].id == 0 and practices[1].id == 1)
	var groups: Dictionary = {}
	var ids: Array = []
	var uids: Array = []
	for practice in practices:
		assert(int(practice.id) not in ids)
		ids.append(int(practice.id))
		if int(practice.id) in [0, 1]:
			continue
		var sid: String = practice.source_practice_id
		assert(sid.begins_with("master-class-18-p"))
		assert(not str(practice.practice_uid).is_empty() and practice.practice_uid not in uids)
		uids.append(practice.practice_uid)
		if not groups.has(sid):
			groups[sid] = []
		groups[sid].append(practice)
	assert(sorted_copy(ids) == range(32) and groups.size() == 8 and uids.size() == 30)
	var formulas = 0
	var manuals = 0
	var mixed = 0
	var references = 0
	var optional_naming = 0
	var optional_recall = 0
	var app_decisions: Array = []
	for source in document.practices:
		var number = int(str(source.id).right(2))
		assert(groups.has(source.id))
		var variants: Array = groups[source.id]
		assert(variants.size() == (11 if number == 2 else 7 if number in [6, 7] else 1))
		var base_found = false
		var roots: Array = []
		var forms: Array = []
		for practice in variants:
			select_practice(global, 18, practice)
			check_info(practice, source)
			for decision in practice.info.implementation_decisions:
				app_decisions.append(str(decision).to_lower())
			for decision in practice.info.get("app_adaptations", []):
				app_decisions.append(str(decision).to_lower())
			if int(practice.id) == number + 1:
				base_found = true
			if practice.has("formula"):
				check_formula18(practice, number)
				formulas += 1
				if number == 2:
					assert(int(practice.id) == 3 or int(practice.id) in range(10, 20))
					var pc = int(practice.formula.cue_midi[0]) % 12
					assert(pc not in roots)
					roots.append(pc)
					await check_naming_scene(global, practice)
					await check_assistance18(global, practice)
				elif practice.formula.response == "recall":
					assert(int(practice.id) == (30 if number == 6 else 31))
					optional_recall += 1
					await check_recall_scene(global, practice)
				else:
					assert(int(practice.id) in (range(20, 25) if number == 6 else range(25, 30)))
					var form = str([int(practice.formula.note_count), practice.formula.presentation])
					assert(form not in forms)
					forms.append(form)
					optional_naming += 1
					await check_naming_scene(global, practice)
					await check_assistance18(global, practice)
			else:
				assert(int(practice.id) == number + 1 and not practice.get("optional", false))
				if number in [1, 6, 7, 8]:
					await check_manual_scene(practice)
					manuals += 1
					if number == 8:
						for field in ["pitch_classes", "pairs", "confusion_pairs", "required_pairs"]:
							assert(not practice.has(field), "Personal confusion examples must not become mandatory pairs")
				elif number in [3, 4]:
					await check_mixed18(global, practice, number)
					mixed += 1
				elif number == 5:
					await check_reference18(practice)
					references += 1
				else:
					assert(false, "Unexpected Class 18 activity")
		assert(base_found, "Source pNN retains numeric base ID NN+1")
		if number == 2:
			assert(roots == ROOTS18, "Six remaining white roots, then C#/Eb/F#/Ab/Bb fixed major chords")
		elif number in [6, 7]:
			var expected: Array = []
			for form in [[1, "sequential"], [2, "sequential"], [3, "sequential"], [2, "simultaneous"], [3, "simultaneous"]]:
				expected.append(str(form))
			assert(sorted_copy(forms) == sorted_copy(expected), "Exactly five optional identification forms per ambiguous meditation source")
	assert(formulas == 23 and manuals == 4 and mixed == 2 and references == 1)
	assert(optional_naming == 10 and optional_recall == 2)
	# Keep implementation policy in Info, separate from exact source assertions.
	var policy = " ".join(app_decisions)
	assert("cumulative" in policy or "successive" in policy or "current comparison tone" in policy, "Info must disclose cumulative neighbor walking as an app choice")
	assert("127" in policy and "0" in policy, "Info must disclose the app's hardware MIDI boundary policy")
	assert("target" in policy and ("select" in policy or "chosen" in policy), "Info must explain the app's target-selection policy")
	check_completion18(global, practices)
	assert(global.root == original_root, "No curriculum mutation")
	assert(global.file_data == progress and disk_progress_snapshot(global) == disk, "No in-memory or persisted progress writes")
	global.file_data = original_data
	global.set_masterclass_index(ci)
	global.set_practice_index(pi)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Class 18 passed: 32 entries / 30 activities / 8 exact source groups; 23 formulas x 80 twin-seeded cases; 11 fixed major chords; 7/8-response mixed patterns counted as four examples and 3x10 complete patterns; A/D/G 12-step references with unchanged legacy fallback; cumulative chromatic semitone assistance with safe MIDI boundaries; 4 manual guides; 10 optional naming and 2 optional recall adaptations do not block completion; no curriculum or progress writes.")
	quit()
