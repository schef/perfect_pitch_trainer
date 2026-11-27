class_name PatternPlan
extends RefCounted

static func mixed_pool(config: Dictionary, position: int) -> Array[int]:
	if config.has("pattern_steps"):
		var steps = config.pattern_steps
		var notes: Array[int] = []
		if steps.is_empty():
			return notes
		for value in steps[posmod(position, steps.size())].pitch_classes:
			notes.append(int(value))
		return notes
	var count = int(config.get("white_count", 4))
	if count < 1:
		return []
	var key = "white_pitch_classes" if posmod(position, count + 1) < count else "black_pitch_classes"
	var result: Array[int] = []
	for value in config.get(key, []):
		result.append(int(value))
	return result

static func reference_step(config: Dictionary, index: int) -> Dictionary:
	var per_cue = int(config.get("targets_per_cue", 3))
	var mode = config.get("mode", "blocks")
	if per_cue < 1 or index < 0 or mode not in ["blocks", "extra_targets"]:
		return {}
	var length = per_cue + (1 if mode == "extra_targets" and config.get("extra_target", true) else 0)
	var blocks = config.get("cue_blocks", [])
	if blocks.is_empty():
		blocks = [{"label": config.get("cue_a_label", "A"), "midi": config.get("cue_a_midi", 45)},
			{"label": config.get("cue_b_label", "D"), "midi": config.get("cue_b_midi", config.get("cue_d_midi", 50))}]
	if mode == "blocks" and index >= length * blocks.size():
		return {"cue_midi": [], "block": blocks[-1].label, "extra": false, "window_complete": true}
	var local = index % (length * blocks.size())
	var current = blocks[int(local / length)]
	var block = current.label
	var extra = mode == "extra_targets" and config.get("extra_target", true) and local % length == per_cue
	var cue: Array[int] = []
	if not extra and (not config.get("cue_once_per_block", false) or local % length == 0):
		cue.append(int(current.midi))
	return {"cue_midi": cue, "block": block, "extra": extra, "window_complete": false}
