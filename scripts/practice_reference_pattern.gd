extends "res://scripts/practice_pitch_naming_drill.gd"

const Plan = preload("res://scripts/pattern_plan.gd")
const Formula = preload("res://scripts/practice_formula.gd")
var step_index = 0
var step: Dictionary

func init_scroll_array():
	super.init_scroll_array()
	var label = Label.new()
	label.name = "ReferenceStatus"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 30)
	scroll_array.add_child(label)
	var finish = generate_button(1000, "Finish session", "on_button_pressed")
	finish.name = "ReferenceFinish"
	scroll_array.add_child(finish)
	# This task uses A/D references, not the inherited generic C assistance.
	for node in scroll_array.find_children("*", "Button", true, false):
		if node.text == "Play C":
			node.text = "Play cue"

func refresh_score():
	set_label(ElementIndex.SCORE_STATUS, "Open practice")
	var label = scroll_array.get_node_or_null("ReferenceStatus")
	if label and not step.is_empty():
		if step.window_complete:
			var config = Global.get_practice().reference_pattern
			label.text = "End of the %s/%s block. Repeat or finish freely; no invented verification gate." % [config.get("cue_a_label", "A"), config.get("cue_b_label", "D")]
		else:
			label.text = "%s block — %s. Source cue register is an app choice." % [step.block,
				"extra target without a new cue" if step.extra else "reference then target"]

func next_batch():
	var config = Global.get_practice().reference_pattern
	step = Plan.reference_step(config, step_index)
	if step.is_empty() or step.window_complete:
		MidiPlayer.allNotesOff()
		refresh_score()
		return
	var formula = {"selection": "single", "note_count": 1, "pitch_classes": range(12),
		"midi_min": config.midi_min, "midi_max": config.midi_max,
		"presentation": "simultaneous", "response": "name"}
	if not step.cue_midi.is_empty():
		formula.cue_midi = step.cue_midi
	batch = Formula.generate(formula, Global.rng)
	assisted = false
	reset_semitone_help()
	hide_debug()
	refresh_score()
	play_question()

func next_reference():
	step_index += 1
	next_batch()

func restart_reference():
	step_index = 0
	next_batch()

func play_question():
	if step.is_empty() or step.window_complete:
		return
	super.play_question()

func on_key_press(pitch_list):
	if step.is_empty() or step.window_complete or pitch_list.size() != 1:
		return
	if check_pitch_match(pitch_list):
		keyboard.clear_text(true)
		next_reference()
	else:
		assisted = true
		var comparison = []
		if not step.cue_midi.is_empty():
			comparison.append([PitchParser.getPitchFromMidi(step.cue_midi[0])])
		comparison.append([pitch_list[0] + "'"])
		comparison.append_array(batch.anwser)
		MidiPlayer.allNotesOff()
		MidiPlayer.playMultipleNotesHarmonicly(comparison)
		keyboard.clear_text(false)

func on_button_pressed(index: int):
	if index == 1000:
		Global.set_score(1)
		Global.reset_practice_index()
		get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
	elif index == ElementIndex.BACK:
		# Merely opening a sequence must not log a completed open session.
		Global.reset_practice_index()
		get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
	elif index == ElementIndex.RESTART:
		restart_reference()
	elif index == ElementIndex.PLAY_C:
		if not step.is_empty() and not step.cue_midi.is_empty():
			MidiPlayer.allNotesOff()
			MidiPlayer.playMultipleNotesHarmonicly([[PitchParser.getPitchFromMidi(step.cue_midi[0])]])
	else:
		super.on_button_pressed(index)
