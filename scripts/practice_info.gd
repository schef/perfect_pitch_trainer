extends "res://scripts/template.gd"

var return_screen: Node
var return_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var source_url := ""

func init_header():
	title.text = "Practice info"
	subtitle.text = Global.get_title()

func init_practice_info():
	# This is the destination, not another practice with its own Info button.
	pass

func init_scroll_array():
	scroll_array.add_child(generate_button(-1, "<-", "on_button_pressed"))
	var info = Global.get_practice().get("info", {})
	if not info.get("source_windows", []).is_empty():
		for candidate in Global.get_masterclass().practices:
			if candidate.practiceType == "PLAYER" and candidate.get("link", "").begins_with("https://"):
				source_url = candidate.link
				source_url += ("&" if "?" in source_url else "?") + "t=" + str(int(info.source_windows[0].start)) + "s"
				break
	if not source_url.is_empty():
		var source_button = generate_button(0, "Open source recording", "on_button_pressed")
		source_button.name = "OpenSourceRecording"
		scroll_array.add_child(source_button)
	var body = RichTextLabel.new()
	body.name = "SourceInfoText"
	body.text = get_practice_info_text()
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.theme = load("res://assets/font_small.tres")
	body.add_theme_color_override("default_color", Color("630e46"))
	scroll_array.add_child(body)
	set_meta("source_text", body.text)

func on_button_pressed(index: int):
	if index == -1:
		if is_instance_valid(return_screen):
			return_screen.get_node("Display").show()
			return_screen.process_mode = return_process_mode
			return_screen.practice_info_screen = null
			queue_free()
		else:
			get_tree().change_scene_to_file("res://scenes/practice_%s.tscn" % Global.get_field("practiceType").to_lower())
	elif index == 0 and not source_url.is_empty():
		OS.shell_open(source_url)
