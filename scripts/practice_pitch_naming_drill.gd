extends "res://scripts/template.gd"

var batch
var score = 0
var keyboard
var assisted = false
var familiarity_confirmed = false
var assistance_target = 0
var neighbor_offset = 0

enum ElementIndex {
	BACK = -1,
	NEXT = 0,
	PLAY_C,
	REPEAT,
	RESTART,
	DEBUG,
	DEBUG_LABEL,
	SCORE,
	SCORE_STATUS,
	FAMILIAR,
	FINISH,
	HELP_UP,
	HELP_DOWN,
	HELP_ORIGINAL,
	HELP_TARGET,
	}

func refresh_score():
	set_label(ElementIndex.SCORE_STATUS, session_score_text(score))
	var familiar_button = scroll_array.get_node_or_null("FamiliarityButton")
	if familiar_button:
		familiar_button.disabled = score < session_total_target()
		familiar_button.text = "Confirmed" if familiarity_confirmed else "Sounds familiar"

func play_question():
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesHarmonicly(batch["question"])

func play_anwser():
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesHarmonicly(batch["anwser"])
	
func show_debug():
	assisted = true
	set_label(ElementIndex.DEBUG_LABEL, str(batch))

func hide_debug():
	set_label(ElementIndex.DEBUG_LABEL, "")

func next_batch():
	batch = Global.get_random_practice_batch()
	assisted = false
	reset_semitone_help()
	hide_debug()
	refresh_score()
	play_question()

func check_pitch_match(pitch_list):
	var anwser_list = Global.get_flat_pitch_list(Global.get_field_from_object(batch, "anwser"))
	if len(pitch_list) != len(anwser_list):
		return false
	for i in len(pitch_list):
		if pitch_list[i] != anwser_list[i]:
			return false
	return true

func right_notes_wrong_order(pitch_list) -> bool:
	if batch.get("presentation", "") != "simultaneous" or not Global.get_practice().get("session", {}).get("allow_harmonic_reordering", false):
		return false
	var expected = Global.get_flat_pitch_list(batch.anwser)
	var guessed = pitch_list.duplicate()
	expected.sort()
	guessed.sort()
	return expected == guessed

func assistance_notes() -> Array[int]:
	var notes: Array[int] = []
	if not batch is Dictionary:
		return notes
	if batch.has("notes"):
		for value in batch.notes:
			notes.append(int(value))
	else:
		for group in batch.get("anwser", []):
			for pitch in group:
				notes.append(PitchParser.getMidiFromPitch(pitch))
	return notes

func reset_semitone_help():
	assistance_target = 0
	neighbor_offset = 0
	refresh_semitone_help()

func refresh_semitone_help():
	var notes = assistance_notes()
	var control = scroll_array.get_node_or_null("HelpTarget")
	if control:
		control.text = "Help tone %d/%d" % [assistance_target + 1, notes.size()]
	if not notes.is_empty() and assistance_target < notes.size():
		var current = notes[assistance_target] + neighbor_offset
		var up = scroll_array.get_node_or_null("HelpUp")
		var down = scroll_array.get_node_or_null("HelpDown")
		if up:
			up.disabled = current >= 127
		if down:
			down.disabled = current <= 0
	var status = scroll_array.get_node_or_null("HelpStatus")
	if status:
		status.text = "Neighbor steps are cumulative; selecting a tone resets the walk. Help is not verification credit. Offset: %+d semitone(s)." % neighbor_offset

func select_assistance_target(index: int):
	if index < 0 or index >= assistance_notes().size():
		return
	MidiPlayer.allNotesOff()
	assistance_target = index
	neighbor_offset = 0
	refresh_semitone_help()

func mark_help_used():
	assisted = true

func play_neighbor(delta: int) -> bool:
	MidiPlayer.allNotesOff()
	var notes = assistance_notes()
	if delta not in [-1, 1] or notes.is_empty() or assistance_target >= notes.size():
		return false
	var note = notes[assistance_target] + neighbor_offset + delta
	if note < 0 or note > 127:
		return false
	neighbor_offset += delta
	mark_help_used()
	MidiPlayer.playMultipleNotesHarmonicly([[PitchParser.getPitchFromMidi(note)]])
	refresh_semitone_help()
	return true

func play_original_target():
	MidiPlayer.allNotesOff()
	var notes = assistance_notes()
	if notes.is_empty() or assistance_target >= notes.size():
		return
	neighbor_offset = 0
	mark_help_used()
	MidiPlayer.playMultipleNotesHarmonicly([[PitchParser.getPitchFromMidi(notes[assistance_target])]])
	refresh_semitone_help()

func on_key_press(pitch_list):
	if (len(pitch_list) == len(Global.get_flat_pitch_list(Global.get_field_from_object(batch, "anwser")))):
		if (check_pitch_match(pitch_list)):
			if not assisted:
				score = mini(score + 1, session_total_target())
			keyboard.clear_text(true)
			next_batch()
		elif right_notes_wrong_order(pitch_list):
			keyboard.clear_text(false)
			keyboard.textbox.text = "Reorder"
		else:
			familiarity_confirmed = false
			assisted = true
			var comparison = []
			var cue = Global.get_practice().get("formula", {}).get("cue_midi", [])
			var cue_pitches = []
			for note in cue:
				cue_pitches.append(PitchParser.getPitchFromMidi(int(note)))
			if not cue_pitches.is_empty():
				comparison.append(cue_pitches)
			for pitch in pitch_list:
				comparison.append([pitch + "'"])
			if not cue_pitches.is_empty():
				comparison.append(cue_pitches)
			comparison.append_array(batch["anwser"])
			MidiPlayer.allNotesOff()
			MidiPlayer.playMultipleNotesHarmonicly(comparison)
			keyboard.clear_text(false)
			score = reset_current_round(score)
		refresh_score()
	
func _ready():
	super._ready()
	keyboard = find_node_by_name(get_tree().get_root(), "Keyboard")
	keyboard.register_on_key_press_callback(self, "on_key_press")
	next_batch()

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	var keyboard = load("res://components/keyboard.tscn").instantiate()
	scroll_array.add_child(keyboard)
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.PLAY_C, "Play cue" if Global.get_practice().get("formula", {}).has("cue_midi") else "Play C", "on_button_pressed"),
		generate_button(ElementIndex.REPEAT, "Repeat", "on_button_pressed"),
		]))
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.RESTART, "Restart", "on_button_pressed"),
		generate_button(ElementIndex.DEBUG, "Debug", "on_button_pressed"),
		]))
	scroll_array.add_child(generate_hbox([
		generate_label(ElementIndex.SCORE, "Score"),
		generate_label(ElementIndex.SCORE_STATUS, "3/20"),
		]))
	if Global.get_practice().get("session", {}).get("requires_familiarity", false):
		var familiar_button = generate_button(ElementIndex.FAMILIAR, "Sounds familiar", "on_button_pressed")
		familiar_button.name = "FamiliarityButton"
		familiar_button.disabled = true
		scroll_array.add_child(familiar_button)
	if session_is_open() and Global.get_practice().practiceType in ["PITCH_NAMING_DRILL", "MISSING_TONE"]:
		var finish = generate_button(ElementIndex.FINISH, "Finish session", "on_button_pressed")
		finish.name = "NamingFinish"
		scroll_array.add_child(finish)
	if Global.get_practice().get("semitone_assistance", false):
		var target = generate_button(ElementIndex.HELP_TARGET, "Help tone", "on_button_pressed")
		target.name = "HelpTarget"
		scroll_array.add_child(target)
		for entry in [[ElementIndex.HELP_UP, "Up ½ step", "HelpUp"], [ElementIndex.HELP_DOWN, "Down ½ step", "HelpDown"], [ElementIndex.HELP_ORIGINAL, "Original tone", "HelpOriginal"]]:
			var control = generate_button(entry[0], entry[1], "on_button_pressed")
			control.name = entry[2]
			scroll_array.add_child(control)
		var status = Label.new()
		status.name = "HelpStatus"
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.add_theme_font_size_override("font_size", 28)
		scroll_array.add_child(status)
	var debug_label = generate_label(ElementIndex.DEBUG_LABEL, "")
	debug_label.theme = load("res://assets/font_small.tres")
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_array.add_child(debug_label)

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK:
			if not session_is_open():
				Global.set_score(score, familiarity_confirmed)
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.REPEAT:
			play_question()
		ElementIndex.PLAY_C:
			assisted = true
			MidiPlayer.allNotesOff()
			var reference = []
			for note in Global.get_practice().get("formula", {}).get("cue_midi", []):
				reference.append(PitchParser.getPitchFromMidi(int(note)))
			MidiPlayer.playMultipleNotesHarmonicly([reference] if not reference.is_empty() else [["c'"]])
		ElementIndex.RESTART:
			score = 0
			familiarity_confirmed = false
			next_batch()
		ElementIndex.FAMILIAR:
			if score >= session_total_target():
				familiarity_confirmed = true
				refresh_score()
		ElementIndex.FINISH:
			if session_is_open():
				Global.set_score(1)
				Global.reset_practice_index()
				get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.HELP_UP:
			play_neighbor(1)
		ElementIndex.HELP_DOWN:
			play_neighbor(-1)
		ElementIndex.HELP_ORIGINAL:
			play_original_target()
		ElementIndex.HELP_TARGET:
			var count = assistance_notes().size()
			if count > 0:
				select_assistance_target((assistance_target + 1) % count)
		ElementIndex.DEBUG:
			show_debug()
