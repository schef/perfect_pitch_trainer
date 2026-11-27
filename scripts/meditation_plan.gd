class_name MeditationPlan
extends RefCounted

## Source-guided note plans, not scored questions or prescribed timings.
const WHITE = [0, 2, 4, 5, 7, 9, 11]
const BLACK = [1, 3, 6, 8, 10]

static func build(config: Dictionary) -> Array[int]:
	for field in ["anchor_midi", "midi_min", "midi_max"]:
		var value = config.get(field, {"anchor_midi": 60, "midi_min": 48, "midi_max": 84}[field])
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or float(value) < 0 or float(value) > 127:
			return _invalid("Invalid MIDI setting: " + field)
	var low = int(config.get("midi_min", 48))
	var high = int(config.get("midi_max", 84))
	var anchor = int(config.get("anchor_midi", 60))
	if low > high or anchor < low or anchor > high:
		return _invalid("Anchor/range is invalid")
	var notes: Array[int] = []
	match config.get("mode", ""):
		"first_recall":
			notes.append(anchor)
		"listen_imagine":
			if anchor + 2 > high:
				return _invalid("C/D-style comparison exceeds range")
			notes.assign([anchor, anchor + 2, anchor])
		"bottom_anchor", "top_anchor":
			var direction = 1 if config.mode == "bottom_anchor" else -1
			if anchor + 12 * direction < low or anchor + 12 * direction > high:
				return _invalid("Anchor window exceeds range")
			notes.append(anchor)
			for distance in range(1, 13):
				notes.append(anchor + distance * direction)
				notes.append(anchor)
		"keyboard_progression", "random_recall":
			var collection = config.get("collection", "white" if config.mode == "keyboard_progression" else "mixed")
			if collection not in ["white", "black", "mixed"]:
				return _invalid("Unknown meditation collection")
			for note in range(low, high + 1):
				if collection == "mixed" or (collection == "white" and note % 12 in WHITE) or (collection == "black" and note % 12 in BLACK):
					notes.append(note)
		_:
			return _invalid("Unknown meditation mode")
	if notes.is_empty():
		return _invalid("Empty meditation collection")
	return notes

static func _invalid(message: String) -> Array[int]:
	push_error("MeditationPlan: " + message)
	return []
