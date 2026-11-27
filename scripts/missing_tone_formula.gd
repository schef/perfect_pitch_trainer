class_name MissingToneFormula
extends RefCounted

## One simultaneous reference set with exactly one missing MIDI pitch.
## No octave-doubled root, cues, timing, grading or global RNG dependencies.
const Formula = preload("res://scripts/practice_formula.gd")
const MAJOR = [0, 2, 4, 5, 7, 9, 11]
const WHOLE_TONE = [0, 2, 4, 6, 8, 10]

static func generate(config: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if rng == null:
		return _invalid("A random number generator is required.")
	var mode = config.get("mode", "major_scale")
	if mode not in ["major_scale", "whole_tone", "chromatic_cluster"]:
		return _invalid("Unknown mode.")
	for field in ["root_midi", "cluster_low", "cluster_high"]:
		if config.has(field) and (not Formula._is_integer(config[field]) or config[field] < 0 or config[field] > 127):
			return _invalid("%s must be a MIDI integer from 0 through 127." % field)
	var full_notes: Array[int] = []
	var first_missing: int = 0
	var last_missing: int
	if mode == "chromatic_cluster":
		var low: int = int(config.get("cluster_low", 60))
		var high: int = int(config.get("cluster_high", 72))
		if high - low < 2 or high - low > 24:
			return _invalid("Cluster width must be 2 through 24 semitones, with an interior note to omit.")
		for midi in range(low, high + 1):
			full_notes.append(midi)
		first_missing = 1
		last_missing = full_notes.size() - 2
	else:
		var root: int = int(config.get("root_midi", 60))
		var offsets: Array = MAJOR if mode == "major_scale" else WHOLE_TONE
		if root + offsets.back() > 127:
			return _invalid("Scale exceeds MIDI bounds.")
		for offset in offsets:
			full_notes.append(root + offset)
		last_missing = full_notes.size() - 1
	var omitted: int = rng.randi_range(first_missing, last_missing)
	var missing_note: int = full_notes[omitted]
	var notes: Array[int] = full_notes.duplicate()
	notes.remove_at(omitted)
	return {
		"question": Formula._pitches(notes, "simultaneous"),
		"anwser": Formula._pitches([missing_note], "simultaneous"),
		"notes": notes,
		"missing_note": missing_note,
		"full_notes": full_notes,
		"presentation": "simultaneous",
		"response": "name",
		"answer_order": "ascending_pitch",
		"cue_notes": [],
	}

static func _invalid(message: String) -> Dictionary:
	push_error("MissingToneFormula: " + message)
	return {}
