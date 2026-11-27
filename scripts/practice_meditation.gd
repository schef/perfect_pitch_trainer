extends "res://scripts/template.gd"

var batch
var score = 0
var assisted = false
var recall_check_mode = ""

enum ElementIndex {
	BACK = -1,
	CHECK = 0,
	NEXT,
	PLAY_C,
	RESTART,
	CHALLENGE,
	CHALLENGE_STATUS,
	SCORE,
	SCORE_STATUS,
	DEBUG_LABEL,
	DEBUG,
	INCORRECT,
	FINISH,
	CHECK_MODE,
	}

func init():
	recall_check_mode = Global.get_practice().get("recall_check_mode", "")
	if is_count_practice():
		score = clampi(int(Global.get_score(Global.get_masterclass().id, Global.get_practice().id)), 0, session_total_target())

func is_count_practice() -> bool:
	return Global.get_practice().get("session", {}).get("kind", "") == "count"

func record_count_attempt() -> bool:
	if not is_count_practice() or score >= session_total_target():
		return false
	score += 1
	show_score()
	return true

func show_score():
	set_label(ElementIndex.SCORE_STATUS, session_score_text(score))
	var finish = scroll_array.get_node_or_null("CountFinish")
	if finish:
		finish.disabled = score < session_total_target()

func show_question():
	var questions = []
	for b in Global.get_field_from_object(batch, "question"):
		questions.append(", ".join(PackedStringArray(b)))
	var question = "\n".join(PackedStringArray(questions))
	set_label(ElementIndex.CHALLENGE_STATUS, question)

func play_question():
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesHarmonicly(Global.get_field_from_object(batch, "question"))

func play_anwser():
	MidiPlayer.allNotesOff()
	if not recall_check_mode.is_empty():
		var notes = []
		for group in batch["anwser"]:
			notes.append_array(group)
		if recall_check_mode == "sequential":
			MidiPlayer.playMultipleNotesMelodicly([notes])
		else:
			MidiPlayer.playMultipleNotesHarmonicly([notes])
		return
	MidiPlayer.playMultipleNotesHarmonicly(Global.get_field_from_object(batch, "anwser"))

func toggle_check_mode():
	if Global.get_practice().get("recall_check_modes", []).is_empty():
		return
	MidiPlayer.allNotesOff()
	recall_check_mode = "simultaneous" if recall_check_mode == "sequential" else "sequential"
	var control = scroll_array.get_node_or_null("RecallCheckMode")
	if control:
		control.text = "Check: together" if recall_check_mode == "simultaneous" else "Check: sequence"

func show_debug():
	assisted = true
	set_label(ElementIndex.DEBUG_LABEL, str(batch))

func hide_debug():
	set_label(ElementIndex.DEBUG_LABEL, "")

func next_batch():
	batch = Global.get_random_practice_batch()
	assisted = false
	hide_debug()
	show_score()
	show_question()
	
func _ready():
	super._ready()
	next_batch()

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	scroll_array.add_child(generate_hbox([
		generate_label(ElementIndex.CHALLENGE, "Sing"),
		generate_label(ElementIndex.CHALLENGE_STATUS, "D"),
		]))
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.CHECK, "Check", "on_button_pressed"),
		generate_button(ElementIndex.NEXT, "I sang one" if is_count_practice() else "I got it right", "on_button_pressed"),
		]))
	scroll_array.add_child(generate_button(ElementIndex.INCORRECT, "Incorrect / correct", "on_button_pressed"))
	if session_is_open() or is_count_practice():
		var finish = generate_button(ElementIndex.FINISH, "Finish practice", "on_button_pressed")
		if is_count_practice():
			finish.name = "CountFinish"
			scroll_array.add_child(finish)
		else:
			scroll_array.add_child(finish)
	if not recall_check_mode.is_empty():
		var control = generate_button(ElementIndex.CHECK_MODE, "Check: together" if recall_check_mode == "simultaneous" else "Check: sequence", "on_button_pressed")
		control.name = "RecallCheckMode"
		scroll_array.add_child(control)
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.PLAY_C, "Play C", "on_button_pressed"),
		generate_button(ElementIndex.RESTART, "Restart", "on_button_pressed"),
		]))
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.DEBUG, "Debug", "on_button_pressed")
		]))
	scroll_array.add_child(generate_hbox([
		generate_label(ElementIndex.SCORE, "Score"),
		generate_label(ElementIndex.SCORE_STATUS, "3/20"),
		]))
	var debug_label = generate_label(ElementIndex.DEBUG_LABEL, "")
	debug_label.theme = load("res://assets/font_small.tres")
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll_array.add_child(debug_label)

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK:
			if not session_is_open():
				Global.set_score(score)
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.CHECK:
			play_anwser()
		ElementIndex.NEXT:
			if is_count_practice():
				record_count_attempt()
				if score < session_total_target():
					next_batch()
				return
			if not session_is_open() and not assisted:
				score += 1
			next_batch()
		ElementIndex.INCORRECT:
			if not is_count_practice():
				score = 0
			assisted = true
			show_score()
			play_anwser()
		ElementIndex.FINISH:
			if is_count_practice() and score < session_total_target():
				return
			Global.set_score(score if is_count_practice() else 1)
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.PLAY_C:
			assisted = true
			MidiPlayer.playMultipleNotesHarmonicly([["c'"]])
		ElementIndex.RESTART:
			score = 0
			next_batch()
		ElementIndex.DEBUG:
			show_debug()
		ElementIndex.CHECK_MODE:
			toggle_check_mode()
