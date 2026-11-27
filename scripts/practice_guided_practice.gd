extends "res://scripts/template.gd"

# Guidance is deliberately not a generated/assessed pitch drill.
enum ElementIndex { BACK = -1, COMPLETE = 0 }

func init_header():
	title.text = Global.get_title()
	subtitle.text = Global.get_description()

func add_text(text: String, node_name: String):
	var body = RichTextLabel.new()
	body.name = node_name
	body.text = text
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 32)
	scroll_array.add_child(body)

func init_scroll_array():
	var practice = Global.get_practice()
	var deferred = practice.get("implementation_status", "") == "deferred"
	scroll_array.add_child(generate_button(ElementIndex.BACK, "<-", "on_button_pressed"))
	if deferred:
		add_text("Pending source clarification. This assignment is not generated or scored. "
			+ "The missing note collection must be resolved before training it. "
			+ "Do not substitute a guessed pitch pool.", "DeferredNotice")
	else:
		add_text("Manual practice on your instrument or with a partner. "
			+ "The app does not generate, time, transpose, or assess this assignment. "
			+ "Logging a session is not verification of correct performance.", "ManualNotice")
	var info = practice.get("info", {})
	var lines = PackedStringArray(["Practice ID: " + practice.get("source_practice_id", ""),
		"", Global.get_description(), "", str(info.get("purpose", "")), "", "Instructions:"])
	for step in info.get("source_instructions", []):
		lines.append("• " + str(step))
	for field in ["audience", "materials", "presentation", "response", "correction", "completion", "implementation_decisions", "app_adaptations", "uncertainties"]:
		if info.has(field):
			lines.append("\n" + field.replace("_", " ").capitalize() + ":")
			var value = info[field]
			lines.append(JSON.stringify(value, "  ") if value is Dictionary or value is Array else str(value))
	lines.append("\nUse Practice info / source for the original recording and timestamps.")
	add_text("\n".join(lines), "GuidedInstructions")
	if not deferred:
		var complete = generate_button(ElementIndex.COMPLETE, "Log session", "on_button_pressed")
		complete.name = "ManualComplete"
		scroll_array.add_child(complete)

func on_button_pressed(index: int):
	if index == ElementIndex.COMPLETE and Global.get_practice().get("implementation_status", "") != "deferred":
		Global.set_score(1)
	elif index != ElementIndex.BACK:
		return
	Global.reset_practice_index()
	get_tree().change_scene_to_file("res://scenes/masterclass.tscn")
