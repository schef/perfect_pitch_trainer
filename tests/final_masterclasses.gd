extends "res://tests/classes_15_16.gd"

# Run after the final curriculum/runtime integration is ready:
# godot --headless --path . --script res://tests/final_masterclasses.gd \
#   -- --source-dir=/independent/path/to/digital-handbook/curriculum
# Never press Back, Finish, Log session or ManualComplete. Spaced-recall writes
# are explicitly persist=false, against a detached in-memory Global.file_data.
# Runtime resources are loaded inside tests so this file can precede the engine.
const FinalPlan = preload("res://scripts/pattern_plan.gd")
const FINAL_GROUP_COUNTS = {19: 11, 20: 8, 21: 7, 22: 7, 23: 3, 24: 11}
const FINAL_DIM_SETS = [[2, 5, 8, 11], [0, 3, 6, 9]]

func final_source(lesson_id: int) -> Dictionary:
	var directory = SOURCE_DIR
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source-dir="):
			directory = argument.trim_prefix("--source-dir=")
	var path = directory.path_join("master-class-%d.json" % lesson_id)
	assert(FileAccess.file_exists(path), "Independent canonical source required: " + path)
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(document is Dictionary)
	assert(document.lesson_id == "master-class-%d" % lesson_id)
	assert(document.review_status == "text_supported_audio_unverified")
	assert(document.practices.size() == FINAL_GROUP_COUNTS[lesson_id])
	return document

func final_scene(path: String):
	assert(ResourceLoader.exists(path), "Final-class runtime is not installed: " + path)
	return load(path).instantiate()

func final_number(practice: Dictionary) -> int:
	return int(str(practice.source_practice_id).right(2))

func final_policy(practice: Dictionary) -> String:
	return JSON.stringify([practice.info.get("implementation_decisions", []),
		practice.info.get("app_adaptations", []), practice.info.get("uncertainties", [])]).to_lower()

func check_final_formula(practice: Dictionary):
	var config: Dictionary = practice.formula
	var before = config.duplicate(true)
	var count = int(config.note_count)
	assert(count in [1, 2, 3], "Four/five-note extension is manual, not a fabricated formula bank")
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 240000 + int(practice.id)
	twin.seed = rng.seed
	for example in 32:
		var batch: Dictionary = Formula.generate(config, rng)
		assert(not batch.is_empty() and batch == Formula.generate(config, twin))
		var notes = integers(batch.notes)
		assert(notes.size() == count)
		assert(notes.all(func(note): return note >= config.get("midi_min", 36) and note <= config.get("midi_max", 84)))
		if config.has("pitch_classes"):
			assert(notes.all(func(note): return note % 12 in classes(config.pitch_classes)))
		var cue = integers(batch.get("cue_notes", []))
		assert(flattened(batch.question) == cue + notes)
		assert(sorted_copy(flattened(batch.anwser)) == sorted_copy(notes))
		assert(batch.response == config.response and batch.presentation == config.presentation)
	assert(config == before, "Formula generation must not edit the curriculum")

func check_final_mixed(global, practice: Dictionary, lesson_id: int):
	var config: Dictionary = practice.mixed_pattern
	var steps: Array = config.get("pattern_steps", [])
	if not config.has("pattern_steps"):
		for position in int(config.white_count) + 1:
			steps.append({"pitch_classes": FinalPlan.mixed_pool(config, position),
				"note_count": config.get("white_note_count", 1) if position < int(config.white_count) else config.get("black_note_count", 1),
				"label": "white" if position < int(config.white_count) else "black"})
	assert(not steps.is_empty())
	for position in steps.size() * 3:
		var step: Dictionary = steps[position % steps.size()]
		assert(step.has("pitch_classes") and step.has("note_count") and step.has("label"))
		assert(not str(step.label).is_empty() and int(step.note_count) in [1, 2, 3])
		assert(classes(FinalPlan.mixed_pool(config, position)) == classes(step.pitch_classes))
	var number = final_number(practice)
	if lesson_id == 19:
		assert(number in [1, 2] and steps.size() == 3)
		assert(classes(steps[0].pitch_classes) == WHITE and classes(steps[1].pitch_classes) == WHITE)
		assert(classes(steps[2].pitch_classes) == BLACK)
		assert(int(steps[0].note_count) == 2 and int(steps[1].note_count) == 2)
		assert(int(steps[2].note_count) == (1 if number == 1 else 2))
		assert(practice.session.kind == "patterns" and practice.session.rounds == 3)
		assert(practice.session.target == 10 and practice.session.patterns_per_round == 10)
	elif lesson_id == 20:
		assert(number in [1, 2, 3, 4])
		assert(steps.size() == (3 if number in [1, 3] else 4))
		for position in steps.size():
			assert(classes(steps[position].pitch_classes) == (WHITE if position < 2 else BLACK))
			assert(int(steps[position].note_count) == (1 if number <= 2 else 2))
		if number >= 3:
			check_open(practice, "keyboard")
	elif lesson_id == 21:
		assert(number == 2 and steps.size() == 2)
		assert(classes(steps[0].pitch_classes) == WHITE and classes(steps[1].pitch_classes) == BLACK)
		assert(int(steps[0].note_count) == 1 and int(steps[1].note_count) == 1)
		check_open(practice, "keyboard")
	var scene = final_scene("res://scenes/practice_mixed_pattern.tscn")
	root.add_child(scene)
	await process_frame
	assert(scene.pattern_length() == steps.size(), "Pattern length must follow pattern_steps, not a four-example constant")
	scene.restart_patterns()
	scene.next_batch()
	for position in steps.size():
		assert(scene.pattern_position == position)
		assert(scene.batch.notes.size() == int(steps[position].note_count))
		assert(classes(scene.batch.notes).all(func(pc): return pc in classes(steps[position].pitch_classes)))
		var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
		assert(scene.check_pitch_match(answer))
		assert(not scene.check_pitch_match(answer.slice(0, answer.size() - 1)))
		assert(not scene.check_pitch_match(answer + ["c"]))
		scene.on_key_press(answer)
	assert(scene.pattern_position == 0)
	if lesson_id == 19:
		assert(scene.score == 1 and scene.patterns == 1)
		# A wrong example invalidates this whole pattern, not completed patterns.
		scene.record_response(false)
		assert(not scene.pattern_valid)
		# Restart the fixture, then verify the complete source quota without saving.
		scene.restart_patterns()
		for pattern in 30:
			for position in steps.size():
				scene.record_response(true)
			assert(scene.score == pattern + 1)
		assert(scene.patterns == 30 and scene.session_total_target() == 30)
	else:
		if practice.session.kind == "open":
			assert(scene.score == 0 and scene.session_total_target() == 0)
	await dispose_scene(scene)

func check_final_reference(practice: Dictionary, lesson_id: int):
	var config: Dictionary = practice.reference_pattern
	assert(config.targets_per_cue == 2 and config.cue_blocks.size() == 3)
	var length = 9 if lesson_id == 19 else 6
	if lesson_id == 19:
		assert(config.mode == "extra_targets" and config.get("extra_target", true))
	else:
		assert(config.cue_once_per_block and config.extra_target == false)
	var scene = final_scene("res://scenes/practice_reference_pattern.tscn")
	root.add_child(scene)
	await process_frame
	scene.restart_reference()
	for index in length:
		var block = int(index / (3 if lesson_id == 19 else 2))
		var local = index % (3 if lesson_id == 19 else 2)
		var step: Dictionary = FinalPlan.reference_step(config, index)
		assert(not step.window_complete and step.block == ["A", "D", "G"][block])
		var cue = [] if (local == 2 if lesson_id == 19 else local == 1) else [[45], [50], [55]][block]
		assert(integers(step.cue_midi) == cue)
		assert(step.extra == (lesson_id == 19 and local == 2))
		var targets = flattened(scene.batch.anwser)
		assert(targets.size() == 1 and targets[0] >= config.midi_min and targets[0] <= config.midi_max)
		if lesson_id == 19:
			assert(config.midi_min <= 40 and config.midi_max >= 88, "Include low E and notes below all references")
		assert(flattened(scene.batch.question) == cue + targets)
		assert(scene.score == 0)
		scene.next_reference()
	await dispose_scene(scene)

func check_final_count(practice: Dictionary):
	assert(practice.practiceType == "MEDITATION")
	assert(practice.session.kind == "count" and practice.session.target == 10 and practice.maxHits == 10)
	assert(practice.formula.response == "recall" and int(practice.formula.note_count) == 1)
	assert(classes(practice.formula.pitch_classes) in FINAL_DIM_SETS)
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = final_scene("res://scenes/practice_meditation.tscn")
	root.add_child(scene)
	await process_frame
	assert(scene.has_method("record_count_attempt"), "Count sessions need an explicit I-sang-one action")
	assert(scene.score == 0 and midi.noteActionQueue.is_empty())
	for attempt in 10:
		# An incorrect/corrective attempt is still one sung tone, not a streak reset.
		scene.assisted = attempt % 2 == 1
		assert(scene.record_count_attempt())
		assert(scene.score == attempt + 1, "Ten attempts, NOT ten correct consecutive recalls")
		if attempt == 4:
			scene.on_button_pressed(scene.ElementIndex.INCORRECT)
			assert(scene.score == 5, "Correction must not erase already sung attempts")
	assert(not scene.record_count_attempt() and scene.score == 10, "Count target is capped")
	await dispose_scene(scene)

func check_final_missing(global, practice: Dictionary):
	assert(practice.has("missing_tone") and not practice.has("formula"))
	check_open(practice, "keyboard")
	assert(not final_policy(practice).is_empty(), "Omission/register policy belongs in app decisions")
	var formula_path = "res://scripts/missing_tone_formula.gd"
	assert(ResourceLoader.exists(formula_path), "MissingToneFormula runtime is required")
	var missing_formula = load(formula_path)
	var config: Dictionary = practice.missing_tone
	var before = config.duplicate(true)
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 240300 + int(practice.id)
	twin.seed = rng.seed
	var omitted: Array = []
	for example in 64:
		var batch: Dictionary = missing_formula.generate(config, rng)
		assert(batch == missing_formula.generate(config, twin))
		check_missing_batch(batch, final_number(practice))
		if final_number(practice) == 3 and int(practice.id) == 4:
			assert(classes(batch.full_notes) == WHITE, "The base scale is C major; whole-tone is an optional variant")
		if int(batch.missing_note) not in omitted:
			omitted.append(int(batch.missing_note))
	assert(omitted.size() > 1, "Narrated omissions are examples, not fixed answers")
	assert(config == before)
	var scene = final_scene("res://scenes/practice_missing_tone.tscn")
	root.add_child(scene)
	await process_frame
	check_missing_batch(scene.batch, final_number(practice))
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == 1 and scene.check_pitch_match(answer))
	assert(not scene.check_pitch_match(global.get_flat_pitch_list(scene.batch.question)), "Name only the absent tone, not the sounded cluster")
	assert(not scene.check_pitch_match(answer + ["c"]))
	assert(scene.score == 0 and scene.session_total_target() == 0)
	await dispose_scene(scene)

func check_missing_batch(batch: Dictionary, number: int):
	assert(batch.has("notes") and batch.has("full_notes") and batch.has("missing_note"))
	var full = integers(batch.full_notes)
	var sounded = integers(batch.notes)
	var missing = int(batch.missing_note)
	assert(missing in full and missing not in sounded)
	assert(sounded.size() + 1 == full.size())
	var expected = full.duplicate()
	expected.erase(missing)
	assert(sorted_copy(sounded) == sorted_copy(expected))
	assert(flattened(batch.question) == sounded, "Actual audible question must exclude the answer")
	assert(batch.question.size() == 1, "Missing-tone scale/cluster is one combined sound")
	assert(flattened(batch.anwser) == [missing], "Answer contains only the omitted tone")
	if number == 3:
		# Whole-tone is allowed as an optional variant; C major is the source base.
		var pcs = classes(full)
		assert(pcs == WHITE or pcs == [0, 2, 4, 6, 8, 10] or pcs == [1, 3, 5, 7, 9, 11])
	else:
		assert(number == 4 and full.size() >= 3)
		var ordered = sorted_copy(full)
		for index in range(1, ordered.size()):
			assert(ordered[index] == ordered[index - 1] + 1)
		assert(missing > ordered.front() and missing < ordered.back(), "Internal omission preserves the bounding notes")

func check_final_spaced(global, practice: Dictionary):
	assert(practice.practiceType == "SPACED_RECALL" and final_number(practice) == 11)
	assert(practice.maxHits == 20 and practice.session.target == 20)
	assert(practice.session.kind == "spaced_recall", "Twenty consecutive recalls retained across visits, not an elapsed-hours gate")
	assert(int(practice.formula.note_count) == 1 and practice.formula.response == "recall")
	var detached = global.file_data
	global.file_data = {}
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = final_scene("res://scenes/practice_spaced_recall.tscn")
	root.add_child(scene)
	await process_frame
	assert(scene.has_method("record_attempt"))
	assert(scene.score == 0 and not scene.reference_checked and not scene.attempt_recorded)
	assert(midi.noteActionQueue.is_empty(), "Recall must not autoplay the target")
	assert(not scene.record_attempt(true, false) and scene.score == 0, "Cannot self-report before checking the reference")
	for attempt in 3:
		scene.play_anwser()
		assert(scene.reference_checked and not midi.noteActionQueue.is_empty())
		assert(scene.record_attempt(true, false))
		assert(scene.score == attempt + 1 and scene.attempt_recorded)
		var history = global.file_data.duplicate(true)
		assert(not scene.record_attempt(true, false) and global.file_data == history, "Double-click cannot record twice")
		midi.allNotesOff()
		scene.next_batch()
		assert(not scene.reference_checked and not scene.attempt_recorded and midi.noteActionQueue.is_empty())
	scene.play_anwser()
	assert(scene.record_attempt(false, false) and scene.score == 0)
	assert(global.get_score(24, practice.id) == 0, "Wrong recall resets persisted-in-memory streak too")
	for attempt in 22:
		scene.next_batch()
		scene.play_anwser()
		scene.record_attempt(true, false)
		assert(scene.score == mini(attempt + 1, 20))
	assert(global.get_score(24, practice.id) == 20)
	await dispose_scene(scene)
	# Re-entry loads the streak without playing the reference or saving anything.
	midi.allNotesOff()
	scene = final_scene("res://scenes/practice_spaced_recall.tscn")
	root.add_child(scene)
	await process_frame
	assert(scene.score == 20 and midi.noteActionQueue.is_empty())
	assert(not scene.reference_checked and not scene.attempt_recorded)
	await dispose_scene(scene)
	global.file_data = detached

func check_final_optional_gate(global, lesson_id: int, practices: Array):
	var saved = global.file_data
	global.file_data = {lesson_id: {}, "formula_progress": {}, "formula_familiarity": {}}
	for practice in practices:
		if practice.get("optional", false):
			continue
		var session: Dictionary = practice.get("session", {})
		var amount = maxi(1, int(practice.get("maxHits", 0)))
		amount = maxi(amount, int(session.get("target", 0)) * int(session.get("rounds", 1)))
		if session.get("kind", "") == "patterns":
			amount = int(session.patterns_per_round) * int(session.rounds)
		if practice.has("formula"):
			var key = global.formula_progress_key(practice)
			global.file_data.formula_progress[key] = amount
			global.file_data.formula_familiarity[key] = true
		else:
			global.file_data[lesson_id][practice.id] = amount
	assert(global.is_masterclass_finished(lesson_id), "Explicit optional adaptations must not gate required source completion")
	global.file_data = saved

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_root = global.root.duplicate(true)
	var original_data = global.file_data
	var original_snapshot = original_data.duplicate(true)
	var disk = disk_progress_snapshot(global)
	var ci = global.get_masterclass_index()
	var pi = global.get_practice_index()
	global.file_data = {} # No live progress is exposed to scene-local tests.
	var class_ids: Array = []
	for lesson in global.root.masterclasses:
		assert(typeof(lesson.id) in [TYPE_INT, TYPE_FLOAT] and float(lesson.id) == int(lesson.id))
		assert(int(lesson.id) not in class_ids, "Duplicate class ID after external curriculum merge")
		class_ids.append(int(lesson.id))
	for lesson_id in range(1, 25):
		assert(lesson_id in class_ids)
	assert(255 in class_ids and class_ids.find(24) < class_ids.find(255), "External classes precede More/255")
	var all_uids: Array = []
	var coverage: Dictionary = {}
	var tested: Dictionary = {"mixed": 0, "reference": 0, "count": 0, "missing": 0, "spaced": 0, "manual": 0}
	for lesson_id in range(19, 25):
		var document = final_source(lesson_id)
		var lesson = global.get_masterclass_by_id(lesson_id)
		var groups: Dictionary = {}
		var ids: Array = []
		for practice in lesson.practices:
			assert(typeof(practice.id) in [TYPE_INT, TYPE_FLOAT] and float(practice.id) == int(practice.id))
			assert(int(practice.id) not in ids)
			ids.append(int(practice.id))
			if int(practice.id) in [0, 1]:
				continue
			assert(practice.has("source_practice_id") and practice.has("practice_uid"))
			assert(not str(practice.practice_uid).is_empty() and practice.practice_uid not in all_uids)
			all_uids.append(practice.practice_uid)
			var sid: String = practice.source_practice_id
			if not groups.has(sid):
				groups[sid] = []
			groups[sid].append(practice)
		assert(0 in ids and 1 in ids)
		assert(groups.size() == FINAL_GROUP_COUNTS[lesson_id])
		coverage[lesson_id] = groups.size()
		for source in document.practices:
			assert(groups.has(source.id) and not groups[source.id].is_empty())
			var base_found = false
			var diminished_pools: Array = []
			for practice in groups[source.id]:
				select_practice(global, lesson_id, practice)
				check_info(practice, source)
				var number = final_number(practice)
				base_found = base_found or int(practice.id) == number + 1
				if lesson_id == 24 and number == 2:
					assert(practice.practiceType == "GUIDED_PRACTICE" and practice.get("optional", false), "Four/five-note polishing is optional manual guidance")
				if lesson_id == 24 and number in [5, 6, 7, 8, 9, 10] and int(practice.id) == number + 1:
					assert(practice.practiceType == "GUIDED_PRACTICE", "Tuning, voice, timbre and score-reading assignments remain manual")
				if practice.has("optional"):
					assert(practice.optional is bool)
				assert(practice.get("implementation_status", "") != "deferred", "App-guided manual practice is not a deferred/unimplemented activity")
				for field in ["bpm", "tempo_bpm", "voice_grading", "automatic_voice_grading", "hours_required"]:
					assert(not practice.has(field) and not practice.get("session", {}).has(field), "No fabricated source timing or automatic voice assessment")
				if practice.has("formula"):
					check_final_formula(practice)
					if lesson_id == 21 and number in [6, 7]:
						assert(classes(practice.formula.pitch_classes) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11], "Class 21 adds to the accumulated inventory; the diminished-eight drill does not replace it")
					if lesson_id == 19 and number in [6, 7, 8, 9]:
						var pool = classes(practice.formula.pitch_classes)
						assert(pool in FINAL_DIM_SETS, "Class 19 collections must remain separate")
						if pool not in diminished_pools:
							diminished_pools.append(pool)
				match str(practice.practiceType):
					"MIXED_PATTERN":
						await check_final_mixed(global, practice, lesson_id)
						tested.mixed += 1
					"REFERENCE_PATTERN":
						if lesson_id in [19, 22]:
							await check_final_reference(practice, lesson_id)
							tested.reference += 1
					"MISSING_TONE":
						assert(lesson_id == 24 and number in [3, 4])
						await check_final_missing(global, practice)
						tested.missing += 1
					"SPACED_RECALL":
						await check_final_spaced(global, practice)
						tested.spaced += 1
					"GUIDED_PRACTICE":
						await check_manual_scene(practice)
						tested.manual += 1
					_:
						if practice.get("session", {}).get("kind", "") == "count":
							await check_final_count(practice)
							tested.count += 1
						elif practice.has("formula") and practice.formula.response == "name":
							await check_naming_scene(global, practice)
					# Color-constrained triples must name all three targets, not a
					# generic chromatic triple or three independent random draws.
				if lesson_id == 22 and number in [1, 2]:
					await check_final_color_mix(global, practice, number)
			assert(base_found, "Every source retains numeric base ID pNN -> NN+1")
			if lesson_id == 19 and int(str(source.id).right(2)) in [6, 7, 8, 9]:
				assert(diminished_pools.size() == 2, "Both separate diminished collections must be available")
		check_final_optional_gate(global, lesson_id, lesson.practices)
	assert(tested.mixed >= 7 and tested.reference >= 2 and tested.count >= 4)
	assert(tested.missing >= 2 and tested.spaced == 1 and tested.manual > 0)
	assert(global.root == original_root, "Tests must not mutate loaded curriculum")
	assert(global.file_data.is_empty(), "Only detached spaced-recall fixtures may update in-memory progress")
	assert(disk_progress_snapshot(global) == disk, "No progress files may be written")
	assert(original_data == original_snapshot)
	global.file_data = original_data
	global.set_masterclass_index(ci)
	global.set_practice_index(pi)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Final masterclasses passed: unique classes 1..24 before More/255; exact independent canonical source groups %s; globally unique final-class UIDs; semantic runtime checks %s; optional adaptations do not gate mastery; no curriculum or disk-progress writes." % [str(coverage), str(tested)])
	quit()

func check_final_color_mix(global, practice: Dictionary, number: int):
	check_open(practice, "keyboard")
	# Use the public generator: color_mix may be a dedicated config rather than
	# a generic formula. Do not require an author's particular config key names.
	for example in 80:
		var batch: Dictionary = global.get_random_practice_batch()
		assert(batch.notes.size() == 3 and batch.presentation == "simultaneous")
		assert(flattened(batch.question) == integers(batch.notes))
		assert(sorted_copy(flattened(batch.anwser)) == sorted_copy(integers(batch.notes)))
		var white_count = 0
		var black_count = 0
		for note in batch.notes:
			if int(note) % 12 in WHITE:
				white_count += 1
			else:
				assert(int(note) % 12 in BLACK)
				black_count += 1
		assert(white_count == (2 if number == 1 else 1))
		assert(black_count == (1 if number == 1 else 2))
	var scene = final_scene("res://scenes/practice_pitch_naming_drill.tscn")
	root.add_child(scene)
	await process_frame
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == 3 and scene.check_pitch_match(answer))
	for index in 3:
		var wrong = answer.duplicate()
		wrong[index] = NAMES[(NAMES.find(str(answer[index])) + 1) % 12]
		assert(not scene.check_pitch_match(wrong))
	assert(scene.session_total_target() == 0 and scene.score == 0)
	await dispose_scene(scene)
