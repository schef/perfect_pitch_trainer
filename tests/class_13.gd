extends SceneTree

# Run only after Class 13 content and MEDITATION_GUIDE are installed:
# godot --headless --path . --script res://tests/class_13.gd
# Read-only: never press Finish, Back, Save, or ManualComplete.
const Plan = preload("res://scripts/meditation_plan.gd")
const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, 6, 8, 10]
const INTERACTIVE = [2, 3, 5, 6, 7, 9]
const MODES = {2: "listen_imagine", 3: "keyboard_progression", 5: "bottom_anchor", 6: "first_recall", 7: "top_anchor", 9: "random_recall"}

func _initialize():
	call_deferred("run")

func source_id(number: int) -> String:
	return "master-class-13-p%02d" % number

func select_source(global, number: int) -> Dictionary:
	for ci in global.root.masterclasses.size():
		for pi in global.root.masterclasses[ci].practices.size():
			var practice: Dictionary = global.root.masterclasses[ci].practices[pi]
			if practice.get("source_practice_id", "") == source_id(number):
				global.set_masterclass_index(ci)
				global.set_practice_index(pi)
				assert(global.get_masterclass().id == 13)
				return practice
	assert(false, "Missing source assignment: " + source_id(number))
	return {}

func base_config(mode: String, anchor: int = 60) -> Dictionary:
	return {"mode": mode, "anchor_midi": anchor, "midi_min": 48, "midi_max": 84, "collection": "mixed" if mode == "random_recall" else "white"}

func check_plan(config: Dictionary, expected: Array):
	var before = config.duplicate(true)
	var result: Array[int] = Plan.build(config)
	assert(result == expected, "Unexpected plan for " + str(config))
	assert(Plan.build(config) == result, "Plan building must be deterministic")
	assert(config == before, "Plan building must not mutate its configuration")
	for note in result:
		assert(note >= config.midi_min and note <= config.midi_max)

func check_plans():
	var parser = root.get_node("PitchParser")
	for note in range(0, 128):
		assert(parser.getMidiFromPitch(parser.getPitchFromMidi(note)) == note, "Reference conversion must roundtrip every MIDI octave")
	check_plan(base_config("listen_imagine"), [60, 62, 60])
	check_plan(base_config("first_recall"), [60])
	var bottom: Array = [60]
	var top: Array = [72]
	for step in range(1, 13):
		bottom.append(60 + step)
		bottom.append(60)
		top.append(72 - step)
		top.append(72)
	assert(bottom.size() == 25 and top.size() == 25)
	check_plan(base_config("bottom_anchor"), bottom)
	check_plan(base_config("top_anchor", 72), top)
	for mode in ["bottom_anchor", "top_anchor"]:
		var plan: Array[int] = Plan.build(base_config(mode, 60 if mode == "bottom_anchor" else 72))
		var distinct: Array = []
		for i in plan.size():
			if i % 2 == 0:
				assert(plan[i] == plan[0], "Return to the anchor after every comparison")
			elif plan[i] not in distinct:
				distinct.append(plan[i])
		assert(distinct.size() == 12, "Each chromatic comparison occurs exactly once")
	for collection in ["white", "black", "mixed"]:
		var config = base_config("keyboard_progression")
		config.collection = collection
		var expected: Array = []
		for note in range(48, 85):
			if collection == "mixed" or note % 12 in (WHITE if collection == "white" else BLACK):
				expected.append(note)
		check_plan(config, expected)
	check_plan(base_config("random_recall"), range(48, 85))
	# A numeric root is an app choice, not a fixed C-only source requirement.
	check_plan(base_config("listen_imagine", 61), [61, 63, 61])
	check_plan(base_config("first_recall", 73), [73])
	check_plan(base_config("bottom_anchor", 72), _anchor_plan(72, 1))
	check_plan(base_config("top_anchor", 60), _anchor_plan(60, -1))
	# Opt-in negative cases intentionally emit engine error diagnostics.
	if "--invalid" not in OS.get_cmdline_user_args():
		return
	var invalid: Array = [{}, {"mode": "not_a_mode"}]
	for field in ["midi_min", "midi_max", "anchor_midi"]:
		for value in ["60", true, 60.5, null]:
			var config = base_config("first_recall")
			config[field] = value
			invalid.append(config)
	for bounds in [[-1, 84], [48, 128], [85, 48]]:
		var config = base_config("first_recall")
		config.midi_min = bounds[0]
		config.midi_max = bounds[1]
		invalid.append(config)
	for config in [base_config("first_recall", 47), base_config("first_recall", 85), base_config("listen_imagine", 84), base_config("bottom_anchor", 73), base_config("top_anchor", 59)]:
		invalid.append(config)
	var bad_collection = base_config("keyboard_progression")
	bad_collection.collection = "unknown"
	invalid.append(bad_collection)
	for config in invalid:
		var before: Dictionary = config.duplicate(true)
		assert(Plan.build(config).is_empty(), "Invalid configuration must not silently clamp or invent targets: " + str(config))
		assert(config == before)
	print("Meditation invalid-config tests passed: %d expected errors." % invalid.size())

func _anchor_plan(anchor: int, direction: int) -> Array:
	var result: Array = [anchor]
	for step in range(1, 13):
		result.append(anchor + direction * step)
		result.append(anchor)
	return result

func check_info(practice: Dictionary):
	var info: Dictionary = practice.info
	assert(info.source_lesson_id == "master-class-13")
	assert(info.review_status == "text_supported_audio_unverified")
	assert(not str(info.source_audio).is_empty())
	assert(not str(info.purpose).is_empty())
	assert(not info.source_windows.is_empty())
	for window in info.source_windows:
		assert(window.start >= 0 and window.end > window.start)
		assert(not str(window.description).is_empty())
	assert(not info.get("source_instructions", []).is_empty())
	assert(info.has("completion") and info.has("correction"))

func check_no_prescribed_counts(value: Variant):
	if value is Dictionary:
		for key in value:
			if str(key).to_lower() in ["bpm", "tempo", "seconds", "duration_seconds", "deadline", "trial_count", "rounds"]:
				assert(value[key] == null, "Do not invent numerical duration, tempo, rounds or deadlines")
			check_no_prescribed_counts(value[key])
	elif value is Array:
		for item in value:
			check_no_prescribed_counts(item)

func visible_text(node: Node) -> String:
	var result = ""
	if node is Label or node is RichTextLabel or node is Button:
		result += str(node.text) + "\n"
	for child in node.get_children():
		result += visible_text(child)
	return result

func assert_silent(midi):
	assert(midi.noteActionQueue.is_empty(), "Only an explicit Play reference action may queue audio")
	assert(midi.synth.audio_stream_players.all(func(player): return not player.playing and not player.linked.playing))

func check_interactive(global, practice: Dictionary, number: int):
	assert(practice.practiceType == "MEDITATION_GUIDE")
	assert(practice.session.kind == "open" and practice.session.target == 0)
	assert(practice.session.assessment == "self_report")
	assert(practice.maxHits == 0)
	var original = practice.duplicate(true)
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = load("res://scenes/practice_meditation_guide.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert_silent(midi)
	assert(scene.config.mode == MODES[number])
	assert(scene.targets == Plan.build(scene.config))
	assert(not scene.targets.is_empty())
	assert(scene.config.anchor_midi == (72 if number == 7 else 60))
	assert(scene.config.midi_min == 48 and scene.config.midi_max == 84)
	assert(scene.position >= 0 and scene.position < scene.targets.size())
	assert(scene.current_note() == scene.config.anchor_midi)
	for name in ["MeditationPrompt", "MeditationStatus", "MeditationNext", "MeditationPrevious", "MeditationPlay", "MeditationFinish"]:
		assert(scene.find_child(name, true, false) != null, "Missing named control: " + name)
	var finish = scene.find_child("MeditationFinish", true, false)
	assert(finish.visible and not finish.disabled, "Open work may finish without compulsory rounds")
	var completion_text = (str(finish.text) + " " + visible_text(scene)).to_lower()
	assert("verified" not in completion_text or "not verified" in completion_text or "unverified" in completion_text, "Self-report must not claim verified pitch recognition")
	assert("100%" not in completion_text)
	# RichTextLabel creates a stopped internal effects Timer even without BBCode.
	# Only active timers could impose a deadline; an inert engine child is harmless.
	assert(scene.find_children("*", "Timer", true, false).all(func(timer): return timer.is_stopped()), "Meditation has no active timer or deadline")
	scene.next_target()
	assert_silent(midi)
	# Traverse to both boundaries without requiring playback or recording results.
	for step in range(scene.targets.size() + 1):
		scene.next_target()
		assert_silent(midi)
	assert(scene.position == scene.targets.size() - 1)
	assert(finish.visible and not finish.disabled)
	if number == 5:
		var status = str(scene.find_child("MeditationStatus", true, false).text).to_lower()
		assert("set" in status and ("choose" in status or "optional" in status or "quota" in status))
	if number == 7:
		var text = visible_text(scene).to_lower()
		assert("app" in text and "source" in text and "endpoint" in text)
	for step in range(scene.targets.size() + 1):
		scene.previous_target()
		assert_silent(midi)
	assert(scene.position == 0)
	scene.previous_target()
	assert(scene.position == 0 and scene.current_note() == scene.targets[0])
	assert_silent(midi)
	if number == 3:
		for collection in ["black", "mixed", "white"]:
			scene.change_collection(collection)
			assert(scene.config.collection == collection)
			assert(scene.targets == Plan.build(scene.config))
			assert_silent(midi)
	if number == 9:
		for attempt in 30:
			scene.choose_random_target()
			assert(scene.current_note() in range(48, 85))
			assert(scene.current_note() in scene.targets)
			assert_silent(midi)
	if number in [2, 5, 6, 7]:
		var anchor_before: int = scene.config.anchor_midi
		scene.shift_anchor(1)
		assert(scene.config.anchor_midi == anchor_before + 1)
		assert(scene.targets == Plan.build(scene.config))
		assert_silent(midi)
		scene.shift_anchor(-1)
		assert(scene.config.anchor_midi == anchor_before)
		assert_silent(midi)
	var reference: int = scene.current_note()
	scene.play_reference()
	assert(midi.noteActionQueue.size() == 1, "Explicit reference is exactly one note, not a cue or batch")
	assert(midi.noteActionQueue[0].midi == reference)
	midi.allNotesOff()
	assert(global.get_practice() == original, "Local root/collection/navigation changes must not alter source definitions")
	scene.queue_free()
	await process_frame
	assert_silent(midi)

func check_guided(practice: Dictionary):
	assert(practice.practiceType == "GUIDED_PRACTICE")
	assert(practice.session.kind == "manual" and practice.session.target == 1)
	assert(practice.session.assessment == "self_report")
	var midi = root.get_node("MidiPlayer")
	midi.allNotesOff()
	var scene = load("res://scenes/practice_guided_practice.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert_silent(midi)
	assert(scene.find_child("Keyboard", true, false) == null)
	scene.queue_free()
	await process_frame

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_progress: Dictionary = global.file_data.duplicate(true)
	var original_root: Dictionary = global.root.duplicate(true)
	var original_class: int = global.get_masterclass_index()
	var original_practice: int = global.get_practice_index()
	check_plans()
	var seen: Array = []
	for lesson in global.root.masterclasses:
		for practice in lesson.practices:
			var id: String = practice.get("source_practice_id", "")
			if id.begins_with("master-class-13-"):
				assert(id not in seen, "Duplicate source ID: " + id)
				seen.append(id)
	assert(seen.size() == 10, "Class 13 has exactly ten source assignments")
	var interactive = 0
	var guided = 0
	for number in range(1, 11):
		assert(source_id(number) in seen)
		var practice = select_source(global, number)
		assert(not practice.has("formula") and not practice.has("practiceBatch"), "Meditation and guided work must not fabricate scored batches")
		check_info(practice)
		check_no_prescribed_counts(practice)
		if number == 7:
			var info_text = JSON.stringify(practice.info).to_lower()
			assert("app" in info_text and ("choice" in info_text or "window" in info_text), "Top-anchor octave window must be identified as an app choice, not a source endpoint")
		if number in INTERACTIVE:
			await check_interactive(global, practice, number)
			interactive += 1
		else:
			await check_guided(practice)
			guided += 1
	assert(interactive == 6 and guided == 4)
	assert(global.file_data == original_progress, "Read-only tests must not change progress")
	assert(global.root == original_root, "Source definitions must remain unchanged")
	global.set_masterclass_index(original_class)
	global.set_practice_index(original_practice)
	midi.allNotesOff()
	midi.synth.queue_free()
	await process_frame
	print("Class 13 passed: ten stable source IDs, six open meditation guides, four guided assignments, deterministic bounded plans, silent navigation, explicit one-note references, no progress writes.")
	quit()
