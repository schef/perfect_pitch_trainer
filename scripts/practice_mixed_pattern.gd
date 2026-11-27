extends "res://scripts/practice_pitch_naming_drill.gd"

const Plan = preload("res://scripts/pattern_plan.gd")
const Formula = preload("res://scripts/practice_formula.gd")
var patterns = 0
var pattern_position = 0
var pattern_valid = true

func init():
	# Retain completed patterns across sessions, not an unfinished five-tone attempt.
	patterns = clampi(int(Global.get_score(Global.get_masterclass().id, Global.get_practice().id)), 0, session_total_target())
	score = patterns

func pattern_length() -> int:
	if Global.get_practice().mixed_pattern.has("pattern_steps"):
		return Global.get_practice().mixed_pattern.pattern_steps.size()
	return int(Global.get_practice().mixed_pattern.white_count) + 1

func example_note_count() -> int:
	var config = Global.get_practice().mixed_pattern
	if config.has("pattern_steps"):
		return int(config.pattern_steps[pattern_position].note_count)
	return int(config.get("white_note_count", 1) if pattern_position < pattern_length() - 1 else config.get("black_note_count", 1))

func example_label() -> String:
	var config = Global.get_practice().mixed_pattern
	if config.has("pattern_steps"):
		return str(config.pattern_steps[pattern_position].get("label", "target"))
	return "white" if pattern_position < pattern_length() - 1 else "black"

func refresh_score():
	set_label(ElementIndex.SCORE_STATUS, session_score_text(patterns))
	var label = scroll_array.get_node_or_null("PatternStatus")
	if label:
		label.text = "Example %d/%d — %s (%d tone(s)). %s" % [pattern_position + 1, pattern_length(),
			example_label(),
			example_note_count(),
			"All %d examples must be fully correct without help." % pattern_length() if pattern_valid else "Correction pattern: no credit; earlier complete patterns retained."]

func init_scroll_array():
	super.init_scroll_array()
	var label = Label.new()
	label.name = "PatternStatus"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 30)
	scroll_array.add_child(label)
	if session_is_open():
		var finish = generate_button(1000, "Finish session", "on_button_pressed")
		finish.name = "PatternFinish"
		scroll_array.add_child(finish)

func next_batch():
	var config = Global.get_practice().mixed_pattern
	var count = example_note_count()
	batch = Formula.generate({"selection": "single" if count == 1 else "distinct", "note_count": count,
		"pitch_classes": Plan.mixed_pool(config, pattern_position),
		"midi_min": config.midi_min, "midi_max": config.midi_max,
		"presentation": "simultaneous", "response": "name"}, Global.rng)
	assisted = false
	reset_semitone_help()
	hide_debug()
	refresh_score()
	play_question()

func record_response(correct: bool):
	if not correct:
		pattern_valid = false
		assisted = true
		refresh_score()
		return
	if assisted:
		pattern_valid = false
	pattern_position += 1
	if pattern_position == pattern_length():
		if pattern_valid:
			patterns = mini(patterns + 1, session_total_target())
		pattern_position = 0
		pattern_valid = true
	assisted = false
	score = patterns
	refresh_score()

func mark_assisted():
	pattern_valid = false
	assisted = true
	refresh_score()

func restart_patterns():
	patterns = 0
	score = 0
	pattern_position = 0
	pattern_valid = true
	assisted = false
	refresh_score()

func show_debug():
	mark_assisted()
	super.show_debug()

func on_key_press(pitch_list):
	if pitch_list.size() != Global.get_flat_pitch_list(batch.anwser).size():
		return
	if check_pitch_match(pitch_list):
		record_response(true)
		keyboard.clear_text(true)
		next_batch()
	elif right_notes_wrong_order(pitch_list):
		keyboard.clear_text(false)
		keyboard.textbox.text = "Reorder"
	else:
		record_response(false)
		MidiPlayer.allNotesOff()
		var guessed = []
		for pitch in pitch_list:
			guessed.append(pitch + "'")
		MidiPlayer.playMultipleNotesHarmonicly([guessed, batch.anwser[0]])
		keyboard.clear_text(false)

func on_button_pressed(index: int):
	if index == 1000 and session_is_open():
		Global.set_score(1)
		Global.reset_practice_index()
		get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
	elif index == ElementIndex.RESTART:
		restart_patterns()
		next_batch()
	elif index == ElementIndex.PLAY_C:
		mark_assisted()
		super.on_button_pressed(index)
	else:
		super.on_button_pressed(index)

func mark_help_used():
	mark_assisted()
