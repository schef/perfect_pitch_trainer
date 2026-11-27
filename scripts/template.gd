extends Node
@onready var scroll_container : ScrollContainer = $Display/ScrollContainer
@onready var title : Label = $Display/ScrollContainer/MarginContainer/VBoxContainer/Header/Title
@onready var subtitle : Label = $Display/ScrollContainer/MarginContainer/VBoxContainer/Header/Subtitle
@onready var scroll_array : VBoxContainer = $Display/ScrollContainer/MarginContainer/VBoxContainer/ScrollArray
var multiple_array = load("res://components/multiple_array.tscn")
var button = preload("res://components/button.tscn")
var label = preload("res://components/label.tscn")
var rng = RandomNumberGenerator.new()
var back_navigation_pending := false
var practice_info_screen: Node

func generate_label(index: int, text: String):
	var l = label.instantiate()
	l.name = "LABEL_" + str(index)
	l.text = text
	return l
	
func generate_button(index: int, text: String, callback: String):
	var b = button.instantiate()
	var btn
	if (text == "<-"):
		b.text = ""
		btn = load("res://assets/btn_back.tres")
		b.size_flags_horizontal = 0
		b.size_flags_vertical = 0
		b.custom_minimum_size = Vector2(150, 150)
		# Android has system Back navigation. Hidden controls are omitted from
		# container layout, so this also removes the arrow's row and spacing.
		b.visible = not OS.has_feature("android")
	else:
		b.text = text
		btn = load("res://assets/btn_v%d.tres" % [rng.randi_range(1, 3)])
	b.set_theme(btn)
	b.connect("pressed", Callable(self, callback).bind(index))
	return b
	
func generate_hbox(elements: Array):
	var ma = multiple_array.instantiate()
	for element in elements:
		ma.add_child(element)
	return ma

func find_node_by_name(root, name):
	if(root.get_name() == name): return root
	for child in root.get_children():
		if(child.get_name() == name):
			return child
		var found = find_node_by_name(child, name)
		if(found): return found
	return null

func set_label(index: int, text: String):
	var node = find_node_by_name(get_tree().get_root(), "LABEL_" + str(index))
	node.text = text

func init():
	pass

func init_header():
	pass

func init_scroll_array():
	pass

func _ready():
	init()
	init_header()
	# Full descriptions belong on the scrollable Info page, not an unbounded header.
	title.max_lines_visible = 3
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.max_lines_visible = 3
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	init_scroll_array()
	init_practice_info()

func init_practice_info():
	if Global.practice_index < 0 or not Global.get_practice().has("info"):
		return
	var info_button = generate_button(-2, "Practice info / source", "on_practice_info_pressed")
	info_button.name = "PracticeInfo"
	scroll_array.add_child(info_button)

func on_practice_info_pressed(_index: int):
	show_practice_info()

func show_practice_info():
	if is_instance_valid(practice_info_screen):
		return
	practice_info_screen = load("res://scenes/practice_info.tscn").instantiate()
	practice_info_screen.name = "PracticeInfoScreen"
	practice_info_screen.return_screen = self
	practice_info_screen.return_process_mode = process_mode
	# Keep this exercise in memory: batch, score, assisted state, keyboard input,
	# and scroll position must survive a trip to the instructions.
	MidiPlayer.allNotesOff()
	$Display.hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	practice_info_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(practice_info_screen)

func get_practice_info_text() -> String:
	var practice = Global.get_practice()
	var info = practice.info
	var lines = PackedStringArray([
		"Practice ID: " + practice.get("practice_uid", practice.get("source_practice_id", "unspecified")),
		"Source assignment: " + practice.get("source_practice_id", "unspecified"),
		"Role: " + ("Optional app adaptation; not required class verification" if practice.get("optional", false) else "Source-linked activity"),
		"Practice model: " + str(practice.get("meditation", {}).get("mode", practice.get("formula", {}).get("selection", "manual/guided" if practice.practiceType == "GUIDED_PRACTICE" else "legacy"))),
		str(info.get("purpose", "")),
		"App description: " + Global.get_description(),
		"Source: " + str(info.get("source_audio", "")),
		"Review: " + str(info.get("review_status", "unverified")), ""
	])
	for window in info.get("source_windows", []):
		lines.append("%s–%s: %s" % [source_time(window.start), source_time(window.end), window.description])
	for field in ["audience", "materials", "presentation", "response", "source_instructions", "correction", "completion", "implementation_decisions", "app_adaptations", "uncertainties"]:
		if info.has(field):
			lines.append("\n" + field.replace("_", " ").capitalize() + ":\n" + str(info[field]))
	lines.append("\nSource timestamps refer to the original recording. Audio is not bundled. Singing is self-assessed, not microphone-verified.")
	return "\n".join(lines)

func source_time(seconds: float) -> String:
	var total = int(seconds)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]

func session_is_open() -> bool:
	return Global.get_practice().get("session", {}).get("kind", "") == "open"

func session_score_text(score: int) -> String:
	if session_is_open():
		return "Open practice"
	var target = Global.get_practice().get("session", {}).get("target", Global.get_field("maxHits"))
	if Global.get_practice().get("session", {}).get("kind", "") == "count":
		return "%d/%d sung" % [score, target]
	var rounds = Global.get_practice().get("session", {}).get("rounds", 1)
	if rounds > 1:
		if score >= target * rounds:
			return "%d rounds done" % rounds
		return "R%d: %d/%d" % [int(score / target) + 1, int(score) % int(target), target]
	return "%d/%d correct" % [score, target]

func session_total_target() -> int:
	var session = Global.get_practice().get("session", {})
	return int(session.get("target", Global.get_field("maxHits"))) * int(session.get("rounds", 1))

func reset_current_round(score: int) -> int:
	var session = Global.get_practice().get("session", {})
	var target = int(session.get("target", Global.get_field("maxHits")))
	if session.get("rounds", 1) > 1 and target > 0:
		return int(score / target) * target
	return 0

func _exit_tree():
	MidiPlayer.allNotesOff()

func navigate_back():
	if is_instance_valid(practice_info_screen):
		practice_info_screen.navigate_back()
		return
	if back_navigation_pending:
		return
	back_navigation_pending = true
	# Every child screen uses -1 for its existing back button. Reuse that handler
	# so score saving and lesson selection resets behave identically.
	on_button_pressed(-1)

func on_button_pressed(_index: int):
	pass
