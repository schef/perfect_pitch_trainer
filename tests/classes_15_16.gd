extends SceneTree

# Run only after Class 15/16 content and recall-check runtime are installed:
# godot --headless --path . --script res://tests/classes_15_16.gd
# Optional: -- --source-dir=/path/to/digital-handbook/curriculum
# This is a read-only integration test. Never press Back, Finish or Log session.
# Canonical handbook JSON is intentionally independent of the app's curriculum.
const Formula = preload("res://scripts/practice_formula.gd")
const SOURCE_DIR = "/tera/schef_backup_old/projects/perfect_pitch/digital-handbook/curriculum"
const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, 6, 8, 10]
const CHROMATIC = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
const STANDARD_RECALL = [0, 2, 4, 5, 7, 8, 9, 11]
const GUITAR_RECALL = [1, 2, 4, 5, 6, 8, 9, 11]
const DIMINISHED = [2, 5, 8, 11]
const ROOT_VARIANTS = ["c-major", "c-sharp-major", "d-major", "e-flat-major", "e-major", "f-major", "f-sharp-major", "g-major", "a-flat-major", "a-major", "b-flat-major", "b-major"]
const NAMES = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]
const VARIANT_COUNTS = [6, 5, 12, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1]
const CANONICAL_FIELDS = ["relationship", "skill", "source_instructions", "audience", "materials", "presentation", "response", "correction", "completion", "evidence", "prerequisites"]

func _initialize():
	call_deferred("run")

func source_id(lesson: int, number: int) -> String:
	return "master-class-%d-p%02d" % [lesson, number]

func source_document(lesson: int) -> Dictionary:
	var directory = SOURCE_DIR
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source-dir="):
			directory = argument.trim_prefix("--source-dir=")
	var path = directory.path_join("master-class-%d.json" % lesson)
	assert(FileAccess.file_exists(path), "Canonical source fixture required: " + path)
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(document is Dictionary and document.practices.size() == (1 if lesson == 15 else 13))
	assert(document.review_status == "text_supported_audio_unverified")
	return document

func select_practice(global, lesson_id: int, practice: Dictionary):
	for ci in global.root.masterclasses.size():
		var lesson: Dictionary = global.root.masterclasses[ci]
		if lesson.id != lesson_id:
			continue
		for pi in lesson.practices.size():
			if lesson.practices[pi].get("practice_uid", "") == practice.practice_uid:
				global.set_masterclass_index(ci)
				global.set_practice_index(pi)
				assert(global.get_practice() == practice)
				return
	assert(false, "Practice UID not found in its source class")

func check_info(practice: Dictionary, source: Dictionary):
	assert(practice.source_practice_id == source.id)
	assert(practice.has("info") and practice.info is Dictionary)
	var info: Dictionary = practice.info
	assert(practice.sourceInfo == source.info, "Original sourceInfo must remain exact")
	# Exact independent source metadata, including descriptions, not just timestamps.
	for field in source.info:
		assert(info.has(field) and info[field] == source.info[field], "Source info mismatch: " + str(source.id) + "/" + field)
	assert(info.review_status == "text_supported_audio_unverified")
	for field in CANONICAL_FIELDS:
		assert(info.has(field) and info[field] == source[field], "Canonical source field mismatch: " + str(source.id) + "/" + field)
	# App explanations may be appended, but source caveats/decisions cannot vanish.
	for field in ["implementation_decisions", "uncertainties"]:
		assert(info.has(field))
		for item in source[field]:
			assert(item in info[field], "Missing source caveat: " + str(item))
	assert(not info.source_instructions.is_empty())
	assert(not str(practice.practice_uid).is_empty())

func integers(values: Array) -> Array:
	return values.map(func(value): return int(value))

func flattened(groups: Array) -> Array:
	var result: Array = []
	var parser = root.get_node("PitchParser")
	for group in groups:
		for pitch in group:
			result.append(parser.getMidiFromPitch(pitch))
	return result

func sorted_copy(values: Array) -> Array:
	var result = values.duplicate()
	result.sort()
	return result

func classes(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var pc = int(value) % 12
		if pc not in result:
			result.append(pc)
	result.sort()
	return result

func check_open(practice: Dictionary, assessment: String):
	assert(practice.session.kind == "open" and practice.session.target == 0)
	assert(practice.session.assessment == assessment)
	assert(practice.maxHits == 0, "An open source assignment must not acquire an invented quota")

func check_formula(practice: Dictionary, number: int):
	var formula: Dictionary = practice.formula
	var before = formula.duplicate(true)
	var count = int(formula.note_count)
	var pool = BLACK if number == 1 else WHITE if number == 2 else STANDARD_RECALL if number == 7 else GUITAR_RECALL if number == 8 else DIMINISHED if number in [9, 10] else CHROMATIC
	assert(classes(formula.pitch_classes) == pool)
	if number in [9, 10]:
		assert(count in [1, 2, 3])
	else:
		assert(count == (1 if number in [1, 2, 4, 5, 6] else 2))
	assert(formula.selection == ("single" if count == 1 else "distinct"))
	assert(formula.response == ("recall" if number in [7, 8] else "name"))
	var cue: Array = integers(formula.get("cue_midi", []))
	if number in [1, 2, 3]:
		assert(cue.size() == 3, "One fixed major chord, not a randomized list of roots")
		assert(cue == [cue[0], cue[0] + 4, cue[0] + 7], "Major third must be +4, including C#/E#")
	elif number in [4, 5, 6]:
		assert(cue.size() == 1 and int(cue[0]) % 12 == {4: 7, 5: 11, 6: 4}[number])
		assert(not practice.info.implementation_decisions.is_empty(), "Reference-string register is an app choice")
	else:
		assert(cue.is_empty(), "Recall and diminished forms have no reference cue")
	if number in [3, 4, 5, 6]:
		check_open(practice, "keyboard")
	if number == 3:
		assert(formula.presentation == "sequential")
		assert(formula.answer_order == "presentation_order")
		assert(not practice.info.implementation_decisions.is_empty(), "Order of unspecified remaining roots must be disclosed")
	if number in [7, 8]:
		check_open(practice, "self_report")
		assert(practice.recall_check_mode == "sequential")
		assert(practice.recall_check_modes == ["sequential", "simultaneous"])
	if number in [1, 2, 9, 10]:
		assert(practice.session.rounds == 1 and practice.session.target == 20)
		assert(practice.session.assessment == "keyboard")
		assert(not practice.info.implementation_decisions.is_empty(), "Inherited round size must be disclosed")
	if number in [9, 10]:
		var details: Dictionary = practice.info.completion.details
		assert(details.rounds_per_form == null and details.items_per_round == null)
		assert(details.single_and_melodic_rounds == 1 and details.harmonic_rounds == null)
		assert(not practice.info.uncertainties.is_empty(), "Harmonic one-versus-two-round ambiguity must remain visible")
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 151600 + number * 100 + int(practice.id)
	twin.seed = rng.seed
	# Every variant owns independent RNGs; no reliance on Global's RNG state.
	for example in 80:
		var batch: Dictionary = Formula.generate(formula, rng)
		assert(not batch.is_empty() and batch == Formula.generate(formula, twin))
		var notes: Array = integers(batch.notes)
		assert(notes.size() == count and classes(notes).size() <= count)
		var seen: Array = []
		for note in notes:
			assert(note not in seen and note % 12 in pool)
			assert(note >= formula.get("midi_min", 36) and note <= formula.get("midi_max", 84))
			seen.append(note)
		var ascending = sorted_copy(notes)
		assert(ascending.back() - ascending.front() >= formula.get("min_span", 0))
		assert(ascending.back() - ascending.front() <= formula.get("max_span", 48))
		assert(integers(batch.cue_notes) == cue)
		assert(flattened(batch.question) == cue + notes, "Cue precedes exactly the played target sequence")
		var expected_answer: Array = ascending if batch.answer_order == "ascending_pitch" else notes
		assert(flattened(batch.anwser) == expected_answer, "Answer order must reflect actual presentation")
		assert(batch.response == formula.response and batch.presentation == formula.presentation)
		if formula.presentation == "sequential":
			assert(batch.question.size() == count + (0 if cue.is_empty() else 1))
			assert(batch.anwser.size() == count)
			for group in batch.anwser:
				assert(group.size() == 1)
			if formula.get("direction", "ascending") == "ascending":
				assert(notes == ascending)
			elif formula.direction == "descending":
				ascending.reverse()
				assert(notes == ascending)
		else:
			assert(batch.anwser.size() == 1 and batch.anwser[0].size() == count)
	assert(formula == before, "Generation must not mutate curriculum formulas")

func dispose_scene(scene):
	root.get_node("MidiPlayer").allNotesOff()
	scene.queue_free()
	await process_frame
	root.get_node("MidiPlayer").allNotesOff()

func check_naming_scene(global, practice: Dictionary):
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	if practice.session.kind == "open":
		var finish = scene.find_child("NamingFinish", true, false)
		assert(finish is Button and finish.visible and not finish.disabled, "Open naming can finish at zero; no impossible twenty-answer gate")
		assert(scene.session_total_target() == 0 and scene.score == 0)
		# A scene-local sentinel proves advancement even if RNG draws the same notes.
		scene.batch = scene.batch.duplicate(true)
		scene.batch["test_previous_prompt"] = true
		var correct: Array = global.get_flat_pitch_list(scene.batch.anwser)
		scene.on_key_press(correct)
		assert(not scene.batch.has("test_previous_prompt") and scene.score == 0, "Correct open responses advance without graded credit")
		assert(not finish.disabled)
		# Do NOT press NamingFinish: it logs a session, not verified mastery.
	var answer: Array = global.get_flat_pitch_list(scene.batch.anwser)
	assert(answer.size() == practice.formula.note_count)
	assert(scene.check_pitch_match(answer))
	assert(not scene.check_pitch_match(answer.slice(0, answer.size() - 1)))
	assert(not scene.check_pitch_match(answer + ["cis"]))
	# Exercise every answer slot, especially the third of melodic/harmonic triples.
	for position in answer.size():
		var wrong = answer.duplicate()
		wrong[position] = NAMES[(NAMES.find(str(answer[position])) + 1) % 12]
		assert(not scene.check_pitch_match(wrong), "Every target must be assessed")
	var original_batch = scene.batch.duplicate(true)
	var wrong = answer.duplicate()
	wrong[-1] = "cis" if answer[-1] != "cis" else "d"
	scene.on_key_press(wrong)
	assert(scene.score == 0 and scene.assisted and scene.batch == original_batch, "Incorrect input cannot pass automatically")
	var before_score = scene.score
	scene.on_button_pressed(scene.ElementIndex.REPEAT)
	assert(scene.score == before_score, "Listening is not successful identification")
	assert(scene.find_child("ManualComplete", true, false) == null)
	await dispose_scene(scene)

func queue_notes(midi) -> Array:
	var result: Array = []
	for action in midi.noteActionQueue:
		result.append(int(action.midi))
	return result

func check_recall_scene(global, practice: Dictionary):
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var source_before = practice.duplicate(true)
	var scene = load("res://scenes/practice_meditation.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.recall_check_mode == "sequential")
	assert(midi.noteActionQueue.is_empty(), "New recall prompts must not reveal their sound")
	var control = scene.find_child("RecallCheckMode", true, false)
	assert(control is Button and control.visible and not control.disabled)
	assert(scene.batch.notes.size() == 2)
	var expected = flattened(scene.batch.anwser)
	scene.play_anwser()
	assert(queue_notes(midi) == expected and midi.noteActionQueue.size() == 2)
	assert(midi.noteActionQueue[1].startTimestamp > midi.noteActionQueue[0].startTimestamp)
	var prompt = scene.batch.duplicate(true)
	# Exercise the actual mode button signal, not only a helper assignment.
	control.pressed.emit()
	assert(scene.recall_check_mode == "simultaneous" and scene.batch == prompt)
	assert(midi.noteActionQueue.is_empty(), "Changing check mode stops sound without autoplay")
	scene.play_anwser()
	assert(queue_notes(midi) == expected and midi.noteActionQueue.size() == 2)
	assert(midi.noteActionQueue[0].startTimestamp == midi.noteActionQueue[1].startTimestamp)
	scene.toggle_check_mode()
	assert(scene.recall_check_mode == "sequential" and midi.noteActionQueue.is_empty())
	assert(scene.score == 0)
	scene.on_button_pressed(scene.ElementIndex.NEXT)
	assert(scene.score == 0 and midi.noteActionQueue.is_empty(), "Self-report in open recall is not measured progress")
	assert(practice == source_before, "Recall mode belongs to scene state, not curriculum")
	assert(global.get_practice() == practice)
	await dispose_scene(scene)

func check_manual_scene(practice: Dictionary):
	assert(practice.practiceType == "GUIDED_PRACTICE")
	assert(not practice.has("formula"), "Guidance is not a made-up generated test")
	assert(practice.session.kind == "manual" and practice.session.assessment == "self_report")
	for field in ["bpm", "tempo_bpm", "time_limit", "turn_order", "health_score", "readiness_score"]:
		assert(not practice.has(field) and not practice.session.has(field), "Source guidance must not become invented timing, turns or a health test")
	assert(practice.get("implementation_status", "") != "deferred")
	var scene = load("res://scenes/practice_guided_practice.tscn").instantiate()
	root.get_node("MidiPlayer").allNotesOff()
	root.add_child(scene)
	await process_frame
	var notice = scene.find_child("ManualNotice", true, false)
	var instructions = scene.find_child("GuidedInstructions", true, false)
	assert(notice != null and "not verification" in str(notice.text).to_lower())
	assert(instructions != null and practice.source_practice_id in instructions.text)
	for step in practice.info.source_instructions:
		assert(str(step) in instructions.text)
	assert(scene.find_child("ManualComplete", true, false) is Button)
	assert(root.get_node("MidiPlayer").noteActionQueue.is_empty())
	# Do NOT emit ManualComplete: logging deliberately writes progress.
	await dispose_scene(scene)

func disk_progress_snapshot(global) -> Dictionary:
	var path: String = global.FILE_PATH
	var exists = FileAccess.file_exists(path)
	return {"exists": exists, "hash": FileAccess.get_sha256(path) if exists else "", "mtime": FileAccess.get_modified_time(path) if exists else 0}

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_root = global.root.duplicate(true)
	# Preserve the original object as well as a deep snapshot. Nothing is saved.
	var original_file_data = global.file_data
	var progress_snapshot = global.file_data.duplicate(true)
	var original_disk = disk_progress_snapshot(global)
	var original_class = global.get_masterclass_index()
	var original_practice = global.get_practice_index()
	var all_uids: Array = []
	var formulas = 0
	var manuals = 0
	for lesson_id in [15, 16]:
		var document = source_document(lesson_id)
		var matches: Array = []
		for lesson in global.root.masterclasses:
			if lesson.id == lesson_id:
				matches.append(lesson)
		assert(matches.size() == 1, "Class lookup is by stable class ID")
		var practices: Array = matches[0].practices
		assert(practices.size() == (3 if lesson_id == 15 else 43))
		assert(practices[0].id == 0 and practices[1].id == 1, "Player and Comments retain IDs 0 and 1")
		var numeric_ids: Array = []
		var groups: Dictionary = {}
		for practice in practices:
			assert(practice.id not in numeric_ids)
			numeric_ids.append(practice.id)
			if practice in [practices[0], practices[1]]:
				continue
			var sid: String = practice.get("source_practice_id", "")
			assert(sid.begins_with("master-class-%d-p" % lesson_id))
			var uid: String = practice.get("practice_uid", "")
			assert(not uid.is_empty() and uid not in all_uids)
			all_uids.append(uid)
			if not groups.has(sid):
				groups[sid] = []
			groups[sid].append(practice)
		assert(groups.size() == document.practices.size())
		for source in document.practices:
			var number = int(str(source.id).right(2))
			assert(groups.has(source.id))
			var variants: Array = groups[source.id]
			assert(variants.size() == (1 if lesson_id == 15 else VARIANT_COUNTS[number - 1]))
			var roots: Array = []
			var forms: Array = []
			for practice in variants:
				select_practice(global, lesson_id, practice)
				check_info(practice, source)
				if lesson_id == 15 or number >= 11:
					assert(practice.practice_uid == source.id)
					if lesson_id == 15:
						assert(practice.id == 2, "Class 15 readiness guidance has source-base ID 2")
					await check_manual_scene(practice)
					manuals += 1
					continue
				assert(practice.has("formula"))
				check_formula(practice, number)
				formulas += 1
				if number in [1, 2, 3]:
					var pc = int(practice.formula.cue_midi[0]) % 12
					assert(pc not in roots, "Each fixed root occurs once, never probabilistically sampled")
					assert(practice.practice_uid == source.id + "-" + ROOT_VARIANTS[pc])
					roots.append(pc)
				elif number in [9, 10]:
					var count = int(practice.formula.note_count)
					var suffix = "single" if count == 1 else ("harmonic" if practice.formula.presentation == "simultaneous" else "melodic") + ("-double" if count == 2 else "-triple")
					assert(suffix not in forms and practice.practice_uid == source.id + "-" + suffix)
					forms.append(suffix)
				else:
					assert(practice.practice_uid == source.id)
				if number in [7, 8]:
					await check_recall_scene(global, practice)
				else:
					await check_naming_scene(global, practice)
			if lesson_id == 16:
				if number == 1:
					assert(roots == [2, 4, 5, 7, 9, 11])
				elif number == 2:
					assert(roots == [1, 3, 6, 8, 10])
				elif number == 3:
					assert(roots.slice(0, 4) == [2, 7, 4, 0] and sorted_copy(roots) == CHROMATIC)
				elif number in [9, 10]:
					assert(sorted_copy(forms) == sorted_copy(["single", "melodic-double", "melodic-triple", "harmonic-double", "harmonic-triple"]))
	assert(formulas == 38 and manuals == 4 and all_uids.size() == 42)
	assert(global.root == original_root, "Read-only tests must not mutate curriculum definitions")
	assert(global.file_data == progress_snapshot, "No in-memory progress writes")
	assert(disk_progress_snapshot(global) == original_disk, "No persisted progress writes")
	global.file_data = original_file_data
	global.set_masterclass_index(original_class)
	global.set_practice_index(original_practice)
	midi.allNotesOff()
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Classes 15/16 passed: readiness guidance; 41 activities / 13 source groups; 38 formulas x 80 twin-seeded cases; 23 fixed major chords; exact source info; all target slots assessed; recall sequential/together checks with no autoplay; four manual guidance scenes; no curriculum or progress writes.")
	quit()
