extends SceneTree

# Run after class content and GUIDED_PRACTICE are installed:
# godot --headless --path . --script res://tests/classes_11_12.gd
# Read-only: never press Save, Back, Finish, or ManualComplete.
const Formula = preload("res://scripts/practice_formula.gd")
const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, 6, 8, 10]
const A_MAJOR = [1, 2, 4, 6, 8, 9, 11]
const NAMES = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]

func _initialize():
	call_deferred("run")

func source_id(lesson: int, number: int) -> String:
	return "master-class-%02d-p%02d" % [lesson, number]

func is_guided(lesson: int, number: int) -> bool:
	return (lesson == 11 and number >= 23) or (lesson == 12 and number >= 15 and number <= 24)

func select_source(global, id: String):
	for ci in global.root.masterclasses.size():
		for pi in global.root.masterclasses[ci].practices.size():
			if global.root.masterclasses[ci].practices[pi].get("source_practice_id", "") == id:
				global.set_masterclass_index(ci)
				global.set_practice_index(pi)
				return global.get_practice()
	assert(false, "Missing source assignment: " + id)
	return {}

func expected_count(lesson: int, number: int) -> int:
	if lesson == 11:
		return [2, 2, 2, 3, 3, 3, 3, 1, 1, 1, 1, 1, 1, 2, 2, 3, 3, 1, 2, 2, 3, 3][number - 1]
	if number >= 25:
		return 1
	return [1, 2, 2, 2, 2, 3, 3, 3, 3, 1, 2, 2, 3, 3][number - 1]

func expected_classes(lesson: int, number: int) -> Array:
	if (lesson == 11 and number in [8, 9, 10]) or (lesson == 12 and number >= 25):
		return range(12)
	if lesson == 12:
		return BLACK
	return A_MAJOR if number == 12 or number >= 18 else WHITE

func cue_root(lesson: int, number: int) -> int:
	if lesson == 11:
		return {8: 9, 9: 1, 10: 3}.get(number, -1)
	return {25: 2, 26: 6, 27: 8, 28: 10}.get(number, -1)

func check_info(practice: Dictionary, lesson: int):
	var info: Dictionary = practice.info
	assert(info.review_status == "text_supported_audio_unverified")
	assert(info.source_lesson_id == "master-class-%02d" % lesson)
	assert(not str(info.source_audio).is_empty())
	assert(not str(info.purpose).is_empty())
	assert(not info.source_windows.is_empty())
	for window in info.source_windows:
		assert(window.start >= 0 and window.end > window.start)
		assert(not str(window.description).is_empty())
	assert(not info.get("source_instructions", []).is_empty())
	assert(info.has("completion") and info.has("correction"))

func check_no_invented_tempo(value: Variant):
	if value is Dictionary:
		for key in value:
			if str(key).to_lower() in ["bpm", "tempo", "seconds", "trial_count"]:
				assert(value[key] == null, "Source does not prescribe a numerical tempo/duration/trial count")
			check_no_invented_tempo(value[key])
	elif value is Array:
		for item in value:
			check_no_invented_tempo(item)

func check_formula(practice: Dictionary, lesson: int, number: int):
	var formula: Dictionary = practice.formula
	var classes: Array = formula.pitch_classes.map(func(value): return int(value))
	classes.sort()
	assert(classes == expected_classes(lesson, number), "Incorrect target pool: " + practice.source_practice_id)
	assert(formula.note_count == expected_count(lesson, number))
	var rounds = 2 if (lesson == 11 and number in [8, 9, 10, 15, 17, 20, 22]) or (lesson == 12 and number in [12, 14, 25, 26, 27, 28]) else 1
	assert(practice.session.rounds == rounds)
	var root_class = cue_root(lesson, number)
	if root_class >= 0:
		var cue_classes: Array = []
		for note in formula.cue_midi:
			if int(note) % 12 not in cue_classes:
				cue_classes.append(int(note) % 12)
		cue_classes.sort()
		var expected = [root_class] if (lesson == 11 and number == 8) or (lesson == 12 and number == 25) else [root_class, (root_class + 4) % 12, (root_class + 7) % 12]
		expected.sort()
		assert(cue_classes == expected, "Cue must be the specified single tone or MAJOR chord")
		if expected.size() == 1:
			assert(formula.cue_midi.size() == 1)
	else:
		assert(not formula.has("cue_midi"))
	if lesson == 11 and number in [1, 2, 3]:
		assert(formula.get("min_span", 0) <= 12 and formula.get("max_span", 48) > 12, "Wide includes close; do not force every double beyond an octave")
	if (lesson == 11 and number in [4, 5]) or (lesson == 12 and number in [6, 7]):
		assert(formula.max_span <= 12, "One-hand physical approximation must fit an octave")
	if (lesson == 11 and number in [6, 7]) or (lesson == 12 and number in [8, 9]):
		assert(formula.get("max_span", 48) > 12, "Do not invent a one-hand limit for two-hand triples")
	if (lesson == 11 and number == 2) or (lesson == 12 and number == 4):
		assert(formula.presentation == "sequential" and formula.direction == "ascending")
	if (lesson == 11 and number == 3) or (lesson == 12 and number == 5):
		assert(formula.presentation == "sequential" and formula.direction == "descending")
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 111200 + lesson * 100 + number
	twin.seed = rng.seed
	var saw_close = false
	var saw_wide = false
	for example in 100:
		var batch = Formula.generate(formula, rng)
		assert(not batch.is_empty() and batch == Formula.generate(formula, twin))
		assert(batch.notes.size() == formula.note_count)
		var sorted: Array = batch.notes.duplicate()
		sorted.sort()
		for i in sorted.size():
			assert(sorted[i] >= formula.get("midi_min", 36) and sorted[i] <= formula.get("midi_max", 84))
			assert(int(sorted[i]) % 12 in classes)
			if i > 0:
				assert(sorted[i] > sorted[i - 1])
		var span: int = sorted.back() - sorted.front()
		assert(span >= formula.get("min_span", 0) and span <= formula.get("max_span", 48))
		saw_close = saw_close or span <= 12
		saw_wide = saw_wide or span > 12
		if formula.presentation == "simultaneous" or formula.get("direction", "ascending") == "ascending":
			assert(batch.notes == sorted)
		elif formula.get("direction", "ascending") == "descending":
			sorted.reverse()
			assert(batch.notes == sorted)
		var answer_notes: Array = batch.notes.duplicate()
		if batch.answer_order == "ascending_pitch":
			answer_notes.sort()
		var expected_answer: Array = []
		for note in answer_notes:
			expected_answer.append(NAMES[int(note) % 12])
		assert(root.get_node("Global").get_flat_pitch_list(batch.anwser) == expected_answer)
		if root_class >= 0:
			assert(batch.question.size() == 2 and batch.question[0].size() == formula.cue_midi.size())
			assert(batch.anwser.size() == 1 and batch.anwser[0].size() == 1)
	if lesson == 11 and number in [1, 2, 3]:
		assert(saw_close and saw_wide, "Seeded wide double sample must retain close as well as wide possibilities")

func check_triple_scene(global, practice: Dictionary):
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var rng = RandomNumberGenerator.new()
	rng.seed = 1112
	scene.batch = Formula.generate(practice.formula, rng)
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == 3 and scene.check_pitch_match(answer))
	var wrong: Array = answer.duplicate()
	wrong[2] = NAMES[(NAMES.find(answer[2]) + 1) % 12]
	assert(not scene.check_pitch_match(wrong), "Every triple must assess its third answer")
	assert(not scene.check_pitch_match(answer.slice(0, 2)))
	assert(not scene.check_pitch_match(answer + ["c"]))
	scene.queue_free()
	await process_frame
	root.get_node("MidiPlayer").allNotesOff()

func check_guided_scene(practice: Dictionary, deferred: bool):
	assert(practice.practiceType == "GUIDED_PRACTICE")
	assert(not practice.has("formula") and not practice.has("practiceBatch"), "Manual work must not fabricate a playable note pool")
	check_no_invented_tempo(practice)
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = load("res://scenes/practice_guided_practice.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(midi.noteActionQueue.is_empty(), "Guided work must not autoplay audio")
	assert(midi.synth.audio_stream_players.all(func(player): return not player.playing and not player.linked.playing))
	assert(scene.get("keyboard") == null)
	assert(scene.find_child("Keyboard", true, false) == null)
	var complete = scene.find_child("ManualComplete", true, false)
	var notice = scene.find_child("DeferredNotice", true, false)
	if deferred:
		assert(complete == null or not complete.visible or complete.disabled, "Unknown guitar pool must not be finishable")
		assert(notice != null)
		assert(notice.visible and not str(notice.text).is_empty())
	else:
		assert(complete != null)
		assert(scene.find_child("ManualNotice", true, false) != null)
		assert(complete.visible and not complete.disabled)
		var text = str(complete.text).to_lower()
		assert("done" in text or "record" in text or "complete" in text or "log" in text)
		assert("verified" not in text or "not verified" in text, "Manual record is not verified ear-training accuracy")
	scene.queue_free()
	await process_frame

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_data = global.file_data.duplicate(true)
	var original_masterclass = global.get_masterclass_index()
	var original_practice = global.get_practice_index()
	var seen: Array = []
	for masterclass in global.root.masterclasses:
		for practice in masterclass.practices:
			var id: String = practice.get("source_practice_id", "")
			if id.begins_with("master-class-11-") or id.begins_with("master-class-12-"):
				assert(id not in seen, "Duplicate source ID: " + id)
				seen.append(id)
	assert(seen.size() == 54)
	var formulas = 0
	var guided = 0
	for lesson in [11, 12]:
		for number in range(1, 27 if lesson == 11 else 29):
			var id = source_id(lesson, number)
			assert(id in seen, "Unexpected or missing source ID: " + id)
			var practice: Dictionary = select_source(global, id)
			assert(global.get_masterclass().id == lesson)
			assert(practice.id == number + 1, "Each source gets its own new numeric practice ID")
			check_info(practice, lesson)
			if is_guided(lesson, number):
				await check_guided_scene(practice, lesson == 12 and number >= 20)
				guided += 1
			else:
				check_formula(practice, lesson, number)
				if practice.formula.note_count == 3:
					await check_triple_scene(global, practice)
				formulas += 1
	assert(formulas == 40 and guided == 14)
	assert(global.file_data == original_data, "Read-only tests must not alter progress")
	global.file_data = original_data
	global.set_masterclass_index(original_masterclass)
	global.set_practice_index(original_practice)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Classes 11/12 passed: 54 unique source assignments, 40 formulas / 4000 seeded cases, every triple assessed, 14 read-only guided screens, no autoplay or deferred completion.")
	quit()
