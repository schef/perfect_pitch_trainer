extends "res://scripts/practice_meditation.gd"

var reference_checked = false
var attempt_recorded = false

func init():
	super.init()
	score = clampi(int(Global.get_score(Global.get_masterclass().id, Global.get_practice().id)), 0, 20)

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	var target = generate_label(ElementIndex.CHALLENGE_STATUS, "")
	target.name = "LABEL_" + str(ElementIndex.CHALLENGE_STATUS)
	scroll_array.add_child(target)
	scroll_array.add_child(generate_button(ElementIndex.CHECK, "Check", "on_button_pressed"))
	var correct = generate_button(ElementIndex.NEXT, "Correct", "on_button_pressed")
	correct.name = "RecallCorrect"
	correct.disabled = true
	scroll_array.add_child(correct)
	var incorrect = generate_button(ElementIndex.INCORRECT, "Incorrect", "on_button_pressed")
	incorrect.name = "RecallIncorrect"
	incorrect.disabled = true
	scroll_array.add_child(incorrect)
	scroll_array.add_child(generate_label(ElementIndex.SCORE_STATUS, ""))
	var note = Label.new()
	note.name = "SpacedRecallStatus"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 30)
	note.text = "One recall attempt: imagine and sing first, then Check before reporting. "
	note.text += "Return from time to time; the app imposes no minimum delay and does not verify spacing, voice, cents or octave accuracy. "
	note.text += "The streak persists across days. Incorrect resets it. Reports are self-assessed, not microphone-graded."
	scroll_array.add_child(note)

func next_batch():
	batch = Global.get_random_practice_batch()
	assisted = false
	reference_checked = false
	attempt_recorded = false
	show_score()
	show_question()

func _ready():
	super._ready()
	refresh_attempt()

func refresh_attempt():
	show_score()
	var ready = reference_checked and not attempt_recorded and score < 20
	scroll_array.get_node("RecallCorrect").disabled = not ready
	scroll_array.get_node("RecallIncorrect").disabled = not ready
	if score >= 20:
		scroll_array.get_node("SpacedRecallStatus").text = "20 consecutive checked self-reports logged. This records the course task, not independent certification of absolute pitch."

func play_anwser():
	if attempt_recorded or score >= 20:
		return
	super.play_anwser()
	reference_checked = true
	refresh_attempt()

func record_attempt(correct: bool, persist: bool = true) -> bool:
	if not reference_checked or attempt_recorded or score >= 20 or (correct and assisted):
		return false
	score = mini(score + 1, 20) if correct else 0
	attempt_recorded = true
	Global.set_score(score, false, false)
	if not Global.file_data.has("spaced_recall_history"):
		Global.file_data["spaced_recall_history"] = {}
	var id = Global.get_practice().get("practice_uid", Global.get_practice().source_practice_id)
	var history = Global.file_data.spaced_recall_history.get(id, [])
	history.append({"at": Time.get_unix_time_from_system(), "correct": correct,
		"streak": score, "reference_checked": true, "assessment": "self_report"})
	if history.size() > 512:
		history.pop_front()
	Global.file_data.spaced_recall_history[id] = history
	if persist:
		Global.save_file()
	refresh_attempt()
	return true

func on_button_pressed(index: int):
	if index == ElementIndex.CHECK:
		play_anwser()
		return
	if index == ElementIndex.NEXT or index == ElementIndex.INCORRECT:
		if not record_attempt(index == ElementIndex.NEXT):
			return
	elif index != ElementIndex.BACK:
		return
	Global.reset_practice_index()
	get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
