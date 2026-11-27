extends SceneTree

# Run ONLY after Class 14 content and both pattern scenes are installed:
# godot --headless --path . --script res://tests/class_14.gd
# Read-only: never invoke Back, Finish, Save, ManualComplete or set_score.
# Invalid-input diagnostics are opt-in: append -- --invalid.
const Plan = preload("res://scripts/pattern_plan.gd")
const Formula = preload("res://scripts/practice_formula.gd")
const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, 6, 8, 10]
const C_PLUS_AB = [0, 2, 4, 5, 7, 8, 9, 11]
const A_PLUS_F = [1, 2, 4, 5, 6, 8, 9, 11]
const NAMES = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]
const SOURCE_AUDIO = "David Lucas Burge - Master Class 14 - The Perfect Pitch Ear Training SuperCourse Unlisted [T_H2Sn5RYz4].mp3"
const WINDOWS = {
	1: [[437.32, 447.9], [493.33, 509.05], [518.95, 551.91]],
	2: [[587.86, 628.67]],
	3: [[654.58, 698.42], [740.11, 807.75], [818.61, 842.27]],
	4: [[849.33, 871.93], [890.94, 944.09]],
	5: [[890.94, 931.53], [931.95, 944.09]],
	6: [[964.05, 977.58], [982.94, 998.92]],
	7: [[1000.58, 1058.2]],
	8: [[1117.76, 1144.7], [1145.5, 1176.06]],
	9: [[1187.46, 1204.49]],
	10: [[1204.87, 1210.23], [1222.25, 1241.85]],
	11: [[1243.97, 1274.61], [1332.46, 1352.98]],
	12: [[1243.97, 1274.61], [1332.46, 1352.98]],
}

func _initialize():
	call_deferred("run")

func source_id(number: int) -> String:
	return "master-class-14-p%02d" % number

func select_practice(global, practice: Dictionary):
	for ci in global.root.masterclasses.size():
		for pi in global.root.masterclasses[ci].practices.size():
			if global.root.masterclasses[ci].practices[pi] == practice:
				global.set_masterclass_index(ci)
				global.set_practice_index(pi)
				assert(global.get_masterclass().id == 14)
				return
	assert(false, "Cannot select Class 14 practice")

func check_info(practice: Dictionary, number: int):
	var info: Dictionary = practice.info
	assert(info.source_lesson_id == "master-class-14")
	assert(info.source_audio == SOURCE_AUDIO)
	assert(info.review_status == "text_supported_audio_unverified")
	assert(not str(info.purpose).is_empty())
	assert(info.source_windows.size() == WINDOWS[number].size())
	for index in info.source_windows.size():
		var window: Dictionary = info.source_windows[index]
		assert(is_equal_approx(float(window.start), WINDOWS[number][index][0]))
		assert(is_equal_approx(float(window.end), WINDOWS[number][index][1]))
		assert(not str(window.description).is_empty())
	assert(not info.get("source_instructions", []).is_empty())
	assert(info.has("completion") and info.has("correction"))

func classes_of(notes: Array) -> Array:
	var result: Array = []
	for note in notes:
		if int(note) % 12 not in result:
			result.append(int(note) % 12)
	result.sort()
	return result

func midi_groups(groups: Array) -> Array:
	var result: Array = []
	var parser = root.get_node("PitchParser")
	for group in groups:
		var notes: Array = []
		for pitch in group:
			notes.append(parser.getMidiFromPitch(pitch))
		result.append(notes)
	return result

func check_mixed_plan(config: Dictionary):
	var before = config.duplicate(true)
	for position in range(15):
		var pool: Array[int] = Plan.mixed_pool(config, position)
		assert(not pool.is_empty())
		assert(Plan.mixed_pool(config, position) == pool)
		assert(pool == (BLACK if position % 5 == 4 else WHITE), "Every pitch class of the required color is available")
	assert(config == before, "Pattern planning must not mutate source configuration")

func check_reference_plan(config: Dictionary, extra: bool):
	var before = config.duplicate(true)
	for index in range(24 if extra else 7):
		var step: Dictionary = Plan.reference_step(config, index)
		assert(step == Plan.reference_step(config, index))
		assert(step.has_all(["cue_midi", "block", "extra", "window_complete"]))
		if not extra and index == 6:
			assert(step.window_complete, "A3 then D3 ends after six targets")
			continue
		assert(not step.window_complete)
		var local: int = index % 8 if extra else index
		var expected_block = "A" if local < (4 if extra else 3) else "D"
		var expected_extra: bool = extra and local in [3, 7]
		assert(step.block == expected_block and step.extra == expected_extra)
		if expected_extra:
			assert(step.cue_midi.is_empty(), "The extra target must not replay the reference")
		else:
			assert(step.cue_midi.size() == 1)
			assert(int(step.cue_midi[0]) % 12 == (9 if expected_block == "A" else 2))
	assert(config == before)

func check_formula(global, practice: Dictionary, number: int):
	var formula: Dictionary = practice.formula
	var before = formula.duplicate(true)
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 1400 + number
	twin.seed = rng.seed
	if number == 2:
		assert(formula.cue_midi.map(func(value): return int(value)) == [60, 64, 67, 72], "C–E–G–C includes the upper C")
		assert(classes_of(formula.pitch_classes) == BLACK)
		assert(formula.note_count == 1)
	if number in [4, 5]:
		assert(formula.note_count == 4 and formula.presentation == "simultaneous")
		assert(classes_of(formula.pitch_classes) == WHITE)
	if number in [11, 12]:
		assert(classes_of(formula.pitch_classes) == (C_PLUS_AB if number == 11 else A_PLUS_F))
	for example in 80:
		var batch: Dictionary = Formula.generate(formula, rng)
		assert(not batch.is_empty() and batch == Formula.generate(formula, twin))
		assert(batch.notes.size() == formula.note_count)
		assert(global.get_flat_pitch_list(batch.anwser).size() == formula.note_count)
		var seen: Array = []
		var allowed_classes = formula.pitch_classes.map(func(value): return int(value))
		for note in batch.notes:
			assert(int(note) % 12 in allowed_classes)
			assert(note >= formula.get("midi_min", 36) and note <= formula.get("midi_max", 84))
			assert(note not in seen, "Exact MIDI notes are distinct; octave-equivalent pitch classes need not be")
			seen.append(note)
		if number == 2:
			assert(midi_groups(batch.question)[0] == [60, 64, 67, 72])
			assert(batch.question.size() == 2 and batch.anwser.size() == 1)
	assert(formula == before)

func dispose_scene(scene):
	root.get_node("MidiPlayer").allNotesOff()
	scene.queue_free()
	await process_frame
	root.get_node("MidiPlayer").allNotesOff()

func check_four_answers(global, practice: Dictionary):
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	# A deliberately small valid pool forces an octave duplication, not merely
	# a probabilistic hope that one occurs during random sampling.
	var formula: Dictionary = practice.formula.duplicate(true)
	formula.midi_min = 60
	formula.midi_max = 72
	formula.pitch_classes = [0, 4, 7]
	formula.min_span = 0
	formula.max_span = 12
	var rng = RandomNumberGenerator.new()
	rng.seed = 1404
	scene.batch = Formula.generate(formula, rng)
	assert(scene.batch.notes == [60, 64, 67, 72], "Octave duplication is permitted in white harmonic fours")
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == 4 and scene.check_pitch_match(answer))
	var wrong = answer.duplicate()
	wrong[3] = "cis" if answer[3] != "cis" else "d"
	assert(not scene.check_pitch_match(wrong), "The fourth pitch must be assessed")
	assert(not scene.check_pitch_match(answer.slice(0, 3)))
	assert(not scene.check_pitch_match(answer + ["c"]))
	await dispose_scene(scene)

func check_mixed_scene(global, practice: Dictionary):
	assert(practice.practiceType == "MIXED_PATTERN")
	assert(not practice.has("formula"), "Do not encode 150 separate streak trials as a formula")
	assert(practice.session.kind == "patterns")
	assert(practice.session.rounds == 3 and practice.session.target == 10)
	assert(practice.session.patterns_per_round == 10)
	var config: Dictionary = practice.mixed_pattern
	assert(config.white_count == 4)
	check_mixed_plan(config)
	var scene = load("res://scenes/practice_mixed_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.session_total_target() == 30, "Completion is 30 patterns, grouped as three tens")
	scene.restart_patterns()
	scene.next_batch()
	assert(scene.patterns == 0 and scene.score == 0 and scene.pattern_position == 0 and scene.pattern_valid)
	for position in 5:
		assert(scene.pattern_position == position)
		assert(scene.batch.notes.size() == 1)
		assert(int(scene.batch.notes[0]) % 12 in (BLACK if position == 4 else WHITE))
		assert(scene.batch.question.size() == 1 and scene.batch.anwser.size() == 1, "Mixed singles have no reference cue")
		scene.on_key_press(global.get_flat_pitch_list(scene.batch.anwser))
		assert(scene.score == (1 if position == 4 else 0), "All five unassisted tones are required for one credit")
	assert(scene.patterns == 1 and scene.pattern_position == 0)
	# Wrong answers require correction of the same target, not a skip.
	var original_batch = scene.batch.duplicate(true)
	scene.record_response(false)
	assert(not scene.pattern_valid and scene.pattern_position == 0 and scene.batch == original_batch)
	assert(scene.score == 1 and scene.patterns == 1)
	for position in 5:
		scene.record_response(true)
	assert(scene.score == 1 and scene.patterns == 1, "A failed pattern earns no credit but preserves prior valid patterns (app choice)")
	assert(scene.pattern_position == 0 and scene.pattern_valid)
	scene.mark_assisted()
	assert(not scene.pattern_valid)
	for position in 5:
		scene.record_response(true)
	assert(scene.score == 1 and scene.patterns == 1, "Assisted patterns cannot earn credit")
	# Exercise the actual keyboard callback, not just the helper API.
	var expected: Array = global.get_flat_pitch_list(scene.batch.anwser)
	var wrong: Array = [NAMES[(NAMES.find(expected[0]) + 1) % 12]]
	scene.on_key_press(wrong)
	assert(not scene.pattern_valid and scene.pattern_position == 0)
	assert(scene.score == 1 and scene.patterns == 1)
	for position in 5:
		scene.record_response(true)
	assert(scene.score == 1)
	# Prior successful work survives both failed patterns. Only 29 more patterns
	# are needed, not a fresh streak of 150 correct tones.
	for pattern in range(2, 31):
		for position in 5:
			scene.record_response(true)
		assert(scene.patterns == pattern and scene.score == pattern)
		if pattern == 9:
			assert(scene.session_score_text(scene.score) == "R1: 9/10")
		elif pattern == 10:
			assert(scene.session_score_text(scene.score) == "R2: 0/10")
		elif pattern == 20:
			assert(scene.session_score_text(scene.score) == "R3: 0/10")
	assert(scene.score == 30)
	var text: String = scene.session_score_text(scene.score).to_lower()
	assert(text == "3 rounds done", "Thirty successful patterns complete three rounds, not a 150-tone streak")
	var status = scene.find_child("PatternStatus", true, false)
	assert(status != null and "5" in str(status.text), "Progress explains the five-tone pattern unit")
	scene.restart_patterns()
	assert(scene.score == 0 and scene.patterns == 0 and scene.pattern_position == 0 and scene.pattern_valid)
	await dispose_scene(scene)
	# Previously completed patterns survive a later session; no disk writes needed.
	var saved_data = global.file_data
	var class_id = global.get_masterclass().id
	var prior_patterns = {}
	prior_patterns[class_id] = {}
	prior_patterns[class_id][practice.id] = 12
	global.file_data = prior_patterns
	scene = load("res://scenes/practice_mixed_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.patterns == 12 and scene.score == 12 and scene.pattern_position == 0)
	assert(scene.pattern_valid, "Only prior complete patterns resume, never a half-finished attempt")
	await dispose_scene(scene)
	global.file_data = saved_data

func check_reference_scene(practice: Dictionary, extra: bool):
	assert(practice.practiceType == "REFERENCE_PATTERN")
	assert(practice.session.kind == "open" and practice.session.target == 0)
	# Names are keyboard-checked; ending the open session is a learner decision.
	assert(practice.session.assessment == "keyboard")
	var config: Dictionary = practice.reference_pattern
	assert((str(config.mode) == "extra_targets") == extra)
	check_reference_plan(config, extra)
	var scene = load("res://scenes/practice_reference_pattern.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var finish = scene.find_child("ReferenceFinish", true, false)
	assert(finish != null and finish.visible and not finish.disabled, "Open sessions can finish without a verification gate")
	scene.restart_reference()
	assert(scene.step_index == 0)
	for index in range(16 if extra else 6):
		assert(scene.step_index == index)
		var step: Dictionary = Plan.reference_step(config, index)
		var question: Array = midi_groups(scene.batch.question)
		var answer: Array = midi_groups(scene.batch.anwser)
		assert(answer.size() == 1 and answer[0].size() == 1)
		assert(question.size() == (1 if step.extra else 2))
		if not step.extra:
			assert(question[0] == step.cue_midi, "Playback question must include exactly the planned cue")
		assert(question.back() == answer[0], "Only the target belongs to the answer")
		assert(scene.score == 0, "Reference navigation must not fabricate verified progress")
		scene.next_reference()
	if not extra:
		assert(scene.step_index == 6 and scene.step.window_complete)
		for attempt in 3:
			scene.next_reference()
			assert(scene.step.window_complete, "Two completed blocks must stop, not silently cycle")
			assert(root.get_node("MidiPlayer").noteActionQueue.is_empty(), "Completed reference windows must not queue new audio")
	assert(scene.score == 0)
	scene.restart_reference()
	assert(scene.step_index == 0 and scene.score == 0)
	await dispose_scene(scene)

func check_recall(practice: Dictionary, number: int):
	assert(practice.session.kind == "open" and practice.session.target == 0)
	assert(practice.session.assessment == "self_report")
	assert(practice.maxHits == 0)
	assert(practice.has("formula"))
	assert(practice.formula.response == "recall" and practice.formula.note_count == 1)
	assert(classes_of(practice.formula.pitch_classes) == (C_PLUS_AB if number == 9 else A_PLUS_F))
	assert(not practice.formula.has("cue_midi"))

func disk_progress_snapshot(global) -> Dictionary:
	var path: String = global.FILE_PATH
	var exists = FileAccess.file_exists(path)
	return {"exists": exists, "hash": FileAccess.get_sha256(path) if exists else "", "mtime": FileAccess.get_modified_time(path) if exists else 0}

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_root = global.root.duplicate(true)
	var original_progress = global.file_data.duplicate(true)
	var original_disk = disk_progress_snapshot(global)
	var original_class: int = global.get_masterclass_index()
	var original_practice: int = global.get_practice_index()
	var assignments: Dictionary = {}
	var unique_uids: Array = []
	var class_practices: Array = []
	for lesson in global.root.masterclasses:
		if lesson.id != 14:
			continue
		class_practices = lesson.practices
		for practice in lesson.practices:
			var id: String = practice.get("source_practice_id", "")
			if not id.begins_with("master-class-14-"):
				continue
			var uid: String = practice.get("practice_uid", "")
			assert(not uid.is_empty() and uid not in unique_uids, "Each actual practice has its own stable UID")
			unique_uids.append(uid)
			if not assignments.has(id):
				assignments[id] = []
			assignments[id].append(practice)
	assert(class_practices.size() == 22, "Twenty actual practices plus Player and Comments")
	assert(assignments.size() == 12 and unique_uids.size() == 20)
	for number in range(1, 13):
		assert(assignments.has(source_id(number)))
		var variants: Array = assignments[source_id(number)]
		assert(variants.size() == (5 if number in [11, 12] else 1))
		var forms: Array = []
		for practice in variants:
			select_practice(global, practice)
			check_info(practice, number)
			if practice.has("formula") and number not in [9, 10]:
				check_formula(global, practice, number)
			if number in [11, 12]:
				var form: String = str([practice.formula.note_count, practice.formula.presentation])
				assert(form not in forms, "Team forms must not duplicate one another")
				forms.append(form)
				assert(int(practice.formula.note_count) in [1, 2, 3])
				var count: int = int(practice.formula.note_count)
				var suffix = "single" if count == 1 else ("harmonic" if practice.formula.presentation == "simultaneous" else "melodic") + ("-double" if count == 2 else "-triple")
				assert(practice.practice_uid == source_id(number) + "-" + suffix, "Team variants retain their stable app UID and shared source ID")
				assert(practice.session.rounds == (2 if practice.formula.note_count > 1 and practice.formula.presentation == "simultaneous" else 1))
			else:
				assert(practice.practice_uid == source_id(number))
			if number == 3:
				await check_mixed_scene(global, practice)
			elif number in [7, 8]:
				await check_reference_scene(practice, number == 8)
			elif number in [9, 10]:
				check_recall(practice, number)
			elif number == 5:
				await check_four_answers(global, practice)
		if number in [11, 12]:
			assert(forms.size() == 5)
	# These invalid inputs intentionally emit expected ERROR diagnostics and must
	# not contaminate the normal read-only smoke test's engine-error output.
	if "--invalid" in OS.get_cmdline_user_args():
		assert(Plan.mixed_pool({"white_count": 0}, 0).is_empty())
		assert(Plan.reference_step({}, -1).is_empty())
	assert(global.root == original_root, "Tests and local pattern state must not mutate curriculum")
	assert(global.file_data == original_progress, "Read-only tests must not modify in-memory progress")
	assert(disk_progress_snapshot(global) == original_disk, "Read-only tests must not save progress")
	global.set_masterclass_index(original_class)
	global.set_practice_index(original_practice)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Class 14 passed: 20 practices / 12 source IDs, exact C–E–G–C cue, complete five-tone patterns, 30-pattern completion with retained prior credit, reference windows/cycles, four-note assessment, expanded recall/team pools, no progress writes.")
	quit()
