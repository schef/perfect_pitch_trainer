extends "res://scripts/template.gd"

const Plan = preload("res://scripts/meditation_plan.gd")
const NAMES = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
var config: Dictionary
var targets: Array[int] = []
var position = 0

enum ElementIndex { BACK = -1, PLAY = 0, NEXT, PREVIOUS, RANDOM, ANCHOR_DOWN, ANCHOR_UP, WHITE, BLACK, MIXED, FINISH, REPEAT }

func init():
	# Selecting a different root/collection must never mutate curriculum definitions.
	config = Global.get_practice().meditation.duplicate(true)
	targets = Plan.build(config)
	if not targets.is_empty():
		var starting_note = int(config.get("anchor_midi", 60))
		if config.mode in ["keyboard_progression", "random_recall"] and starting_note in targets:
			position = targets.find(starting_note)

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func button_control(index: int, text: String, node_name: String):
	var control = generate_button(index, text, "on_button_pressed")
	control.name = node_name
	return control

func init_scroll_array():
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	var prompt = generate_label(100, "")
	prompt.name = "MeditationPrompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_array.add_child(prompt)
	var status = Label.new()
	status.name = "MeditationStatus"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 30)
	scroll_array.add_child(status)
	scroll_array.add_child(button_control(ElementIndex.PLAY, "Play tone", "MeditationPlay"))
	scroll_array.add_child(generate_hbox([
		button_control(ElementIndex.PREVIOUS, "Previous", "MeditationPrevious"),
		button_control(ElementIndex.NEXT, "Next", "MeditationNext")]))
	if config.mode in ["keyboard_progression", "random_recall"]:
		scroll_array.add_child(button_control(ElementIndex.RANDOM, "Random tone", "MeditationRandom"))
	if config.mode == "keyboard_progression":
		for entry in [[ElementIndex.WHITE, "White notes"], [ElementIndex.BLACK, "Black notes"], [ElementIndex.MIXED, "Mixed notes"]]:
			scroll_array.add_child(generate_button(entry[0], entry[1], "on_button_pressed"))
	if config.mode in ["bottom_anchor", "top_anchor", "first_recall"]:
		scroll_array.add_child(generate_hbox([
			generate_button(ElementIndex.ANCHOR_DOWN, "Root −", "on_button_pressed"),
			generate_button(ElementIndex.ANCHOR_UP, "Root +", "on_button_pressed")]))
	if config.mode in ["bottom_anchor", "top_anchor", "listen_imagine"]:
		scroll_array.add_child(button_control(ElementIndex.REPEAT, "Repeat plan", "MeditationRepeat"))
	var instructions = RichTextLabel.new()
	instructions.name = "MeditationInstructions"
	instructions.bbcode_enabled = false
	instructions.fit_content = true
	instructions.scroll_active = false
	instructions.add_theme_font_size_override("normal_font_size", 30)
	var info = Global.get_practice().info
	var text = PackedStringArray(["Open meditation: no score, timer, or required number of sets.",
		"Play tone only when you choose to listen or check. Navigation is silent.",
		"Playback octaves are app references, not vocal grading requirements.", ""])
	for instruction in info.get("source_instructions", []):
		text.append("• " + str(instruction))
	text.append("\nCorrection: " + str(info.get("correction", "")))
	if config.mode == "top_anchor":
		text.append("\nThe one-octave descending window is an app choice. The source gives no required lower endpoint or full-set criterion.")
	if config.mode == "first_recall":
		text.append("\nImagine and sing before playing a reference. The app has not sounded a starting tone. Previous sounds outside this screen cannot be detected.")
		text.append("Root changes apply to this session only and do not establish consistency. Change your reference only when you judge yourself ready, as the source instructs.")
	if config.mode == "keyboard_progression":
		text.append("\nChoose black or mixed only when appropriate for your familiarity. The app does not assess readiness or force progression.")
	instructions.text = "\n".join(text)
	scroll_array.add_child(instructions)
	scroll_array.add_child(button_control(ElementIndex.FINISH, "Finish session", "MeditationFinish"))

func _ready():
	super._ready()
	refresh()

func current_note() -> int:
	return targets[position] if not targets.is_empty() else -1

func refresh():
	if targets.is_empty():
		return
	var note = current_note()
	scroll_array.get_node("MeditationPrompt").text = "%s%d" % [NAMES[note % 12], int(note / 12) - 1]
	var status = "Open practice — position %d of %d; not a correctness score." % [position + 1, targets.size()]
	if config.mode == "bottom_anchor" and position == targets.size() - 1:
		status = "End of the described bottom-anchor set. Repeat or finish when you choose; no set quota."
	elif config.mode == "top_anchor" and position == targets.size() - 1:
		status = "End of this app window, not a source-prescribed endpoint. Repeat or finish freely."
	scroll_array.get_node("MeditationStatus").text = status
	var previous = scroll_array.find_child("MeditationPrevious", true, false)
	var next = scroll_array.find_child("MeditationNext", true, false)
	previous.disabled = position == 0
	next.disabled = position == targets.size() - 1

func play_reference():
	if current_note() < 0:
		return
	MidiPlayer.allNotesOff()
	MidiPlayer.playMultipleNotesHarmonicly([[PitchParser.getPitchFromMidi(current_note())]])

func next_target():
	if targets.is_empty():
		return
	MidiPlayer.allNotesOff()
	position = mini(position + 1, targets.size() - 1)
	refresh()

func previous_target():
	if targets.is_empty():
		return
	MidiPlayer.allNotesOff()
	position = maxi(position - 1, 0)
	refresh()

func choose_random_target():
	if config.mode not in ["keyboard_progression", "random_recall"] or targets.is_empty():
		return
	MidiPlayer.allNotesOff()
	position = Global.rng.randi_range(0, targets.size() - 1)
	refresh()

func shift_anchor(delta: int):
	var anchor = int(config.get("anchor_midi", 60)) + delta
	var low = int(config.get("midi_min", 48))
	var high = int(config.get("midi_max", 84))
	if config.mode == "bottom_anchor":
		high -= 12
	elif config.mode == "top_anchor":
		low += 12
	elif config.mode == "listen_imagine":
		high -= 2
	if anchor < low or anchor > high:
		return
	MidiPlayer.allNotesOff()
	config.anchor_midi = anchor
	targets = Plan.build(config)
	position = 0
	refresh()

func change_collection(collection: String):
	if config.mode != "keyboard_progression" or collection not in ["white", "black", "mixed"]:
		return
	MidiPlayer.allNotesOff()
	config.collection = collection
	targets = Plan.build(config)
	position = 0
	refresh()

func on_button_pressed(index: int):
	match index:
		ElementIndex.BACK, ElementIndex.FINISH:
			if index == ElementIndex.FINISH:
				# Completion means the learner ended an open session, never verification.
				Global.set_score(1)
			Global.reset_practice_index()
			get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
		ElementIndex.PLAY:
			play_reference()
		ElementIndex.NEXT:
			next_target()
		ElementIndex.PREVIOUS:
			previous_target()
		ElementIndex.RANDOM:
			choose_random_target()
		ElementIndex.ANCHOR_DOWN:
			shift_anchor(-1)
		ElementIndex.ANCHOR_UP:
			shift_anchor(1)
		ElementIndex.WHITE:
			change_collection("white")
		ElementIndex.BLACK:
			change_collection("black")
		ElementIndex.MIXED:
			change_collection("mixed")
		ElementIndex.REPEAT:
			MidiPlayer.allNotesOff()
			position = 0
			refresh()
