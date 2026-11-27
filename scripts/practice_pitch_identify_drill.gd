extends "res://scripts/template.gd"

var batch
var score = 0
var assisted = false

enum ElementIndex {
	BACK = -1,
	CHECK = 0,
	NEXT,
	PLAY_C,
	REPEAT,
	RESTART,
	DEBUG,
	DEBUG_LABEL,
	SCORE,
	SCORE_STATUS,
	INCORRECT,
	FINISH,
	}

func refresh_score():
	set_label(ElementIndex.SCORE_STATUS, session_score_text(score))

func play_question():
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesHarmonicly(batch["question"])

func play_anwser():
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesMelodicly(batch["anwser"])
	
func show_debug():
	assisted = true
	set_label(ElementIndex.DEBUG_LABEL, str(batch))

func hide_debug():
	set_label(ElementIndex.DEBUG_LABEL, "")

func next_batch():
	batch = Global.get_random_practice_batch()
	assisted = false
	hide_debug()
	refresh_score()
	play_question()
	
func _ready():
	super._ready()
	next_batch()

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.CHECK, "Check", "on_button_pressed"),
		generate_button(ElementIndex.NEXT, "I got it right", "on_button_pressed"),
		]))
	scroll_array.add_child(generate_button(ElementIndex.INCORRECT, "Incorrect / correct", "on_button_pressed"))
	if session_is_open():
		scroll_array.add_child(generate_button(ElementIndex.FINISH, "Finish practice", "on_button_pressed"))
	scroll_array.add_child(generate_hbox([
		generate_button(ElementIndex.PLAY_C, "Play C", "on_button_pressed"),
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
			if not session_is_open() and not assisted:
				score += 1
			next_batch()
		ElementIndex.INCORRECT:
			score = 0
			assisted = true
			refresh_score()
			play_anwser()
		ElementIndex.FINISH:
			Global.set_score(1)
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.REPEAT:
			play_question()
		ElementIndex.PLAY_C:
			assisted = true
			MidiPlayer.playMultipleNotesHarmonicly([["c'"]])
		ElementIndex.RESTART:
			score = 0
			next_batch()
		ElementIndex.DEBUG:
			show_debug()
