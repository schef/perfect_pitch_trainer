class_name PracticeFormula
extends RefCounted

## Runtime formula generator. Target MIDI notes follow presentation order;
## answers ascend for chords, otherwise follow answer_order. Optional cue_midi
## prepends one chord to question only; presentation still describes the target.
const SPELLINGS = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]
const WHITE_CLASSES = [0, 2, 4, 5, 7, 9, 11]
const CANDIDATE_CACHE_KEYS = 8
# Packed seven-bit MIDI tuples keep even all choose(128, 4) combinations
# below 44 MB. The total budget also bounds memory across different keys.
const CANDIDATE_CACHE_TUPLES = 11000000
static var _candidate_cache: Dictionary = {}
static var _candidate_cache_size: int = 0

static func generate(formula: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if rng == null:
		return _invalid("A random number generator is required.")
	var classes = formula.get("pitch_classes", null)
	if not classes is Array or classes.is_empty():
		return _invalid("pitch_classes must be a nonempty array.")
	var seen: Array = []
	for pitch_class in classes:
		if not _is_integer(pitch_class) or pitch_class < 0 or pitch_class > 11 or int(pitch_class) in seen:
			return _invalid("pitch_classes must contain unique integers from 0 through 11.")
		seen.append(int(pitch_class))
	classes = seen
	for field in ["midi_min", "midi_max", "note_count", "min_span", "max_span"]:
		if formula.has(field) and not _is_integer(formula[field]):
			return _invalid("%s must be an integer." % field)
	var low: int = int(formula.get("midi_min", 36))
	var high: int = int(formula.get("midi_max", 84))
	var count: int = int(formula.get("note_count", 0))
	var min_span: int = int(formula.get("min_span", 0))
	var max_span: int = int(formula.get("max_span", 48))
	if low < 0 or high > 127 or low > high or count < 1 or count > 4:
		return _invalid("Invalid MIDI bounds or note_count (expected 1 through 4).")
	if min_span < 0 or max_span < min_span:
		return _invalid("Invalid span bounds.")
	var selection = formula.get("selection", "")
	var presentation = formula.get("presentation", "simultaneous")
	var direction = formula.get("direction", "ascending")
	var response = formula.get("response", "name")
	var answer_order = formula.get("answer_order", "presentation_order" if presentation == "sequential" else "ascending_pitch")
	if selection not in ["single", "white_third", "white_second", "white_interval", "distinct", "color_mix"]:
		return _invalid("Unknown selection.")
	var white_count: int = 0
	var black_count: int = 0
	if selection == "color_mix":
		for field in ["white_count", "black_count"]:
			if not _is_integer(formula.get(field, null)):
				return _invalid("color_mix requires integer white_count and black_count.")
		white_count = int(formula.white_count)
		black_count = int(formula.black_count)
		if count != 3 or white_count not in [1, 2] or black_count != 3 - white_count or classes.size() != 12:
			return _invalid("color_mix requires three notes, all twelve pitch classes and complementary counts 1/2 or 2/1.")
	elif formula.has("white_count") or formula.has("black_count"):
		return _invalid("Color counts are only supported by color_mix.")
	var white_steps: int = 2 if selection == "white_third" else 1
	if selection == "white_interval":
		var steps = formula.get("white_steps", null)
		if not _is_integer(steps) or steps < 1 or steps > 6:
			return _invalid("white_interval requires white_steps from 1 through 6.")
		white_steps = int(steps)
	elif formula.has("white_steps"):
		return _invalid("white_steps is only supported by white_interval.")
	if (selection == "single" and count != 1) or (selection == "distinct" and count < 2):
		return _invalid("Selection does not support this note_count.")
	if selection in ["white_third", "white_second", "white_interval"]:
		if count != 2:
			return _invalid("White intervals require two notes.")
		for pitch_class in classes:
			if pitch_class not in WHITE_CLASSES:
				return _invalid("White intervals require white pitch classes only.")
	if presentation not in ["simultaneous", "sequential"] or direction not in ["ascending", "descending", "random"]:
		return _invalid("Invalid presentation or direction.")
	if response not in ["sing", "name", "recall"] or answer_order not in ["ascending_pitch", "presentation_order"]:
		return _invalid("Invalid response or answer_order.")
	var cue_notes: Array[int] = []
	if formula.has("cue_midi"):
		var cue = formula.cue_midi
		if not cue is Array or cue.is_empty() or cue.size() > 8:
			return _invalid("cue_midi must be an array of 1 through 8 MIDI integers.")
		for midi in cue:
			if not _is_integer(midi) or midi < 0 or midi > 127:
				return _invalid("cue_midi must contain integers from 0 through 127.")
			cue_notes.append(int(midi))
	classes.sort()
	# Only candidate-affecting, validated integers belong in the canonical key.
	# JSON float integers and reordered pitch classes therefore share entries.
	var key: String = str([classes, low, high, count, selection, white_steps, min_span, max_span, white_count, black_count])
	var candidates: PackedInt32Array
	if _candidate_cache.has(key):
		candidates = _candidate_cache[key]
	else:
		candidates = _enumerate_candidates(classes, low, high, count, selection, white_steps, min_span, max_span, white_count)
		while not _candidate_cache.is_empty() and (_candidate_cache.size() >= CANDIDATE_CACHE_KEYS or _candidate_cache_size + candidates.size() > CANDIDATE_CACHE_TUPLES):
			var oldest = _candidate_cache.keys()[0]
			_candidate_cache_size -= _candidate_cache[oldest].size()
			_candidate_cache.erase(oldest)
		# Entries are private packed values, never modified after insertion.
		_candidate_cache[key] = candidates
		_candidate_cache_size += candidates.size()
	if candidates.is_empty():
		return _invalid("No note combinations satisfy the formula.")
	var encoded: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	var notes: Array = []
	for index in count:
		notes.append((encoded >> (index * 7)) & 127)
	var ascending: Array = notes.duplicate()
	if presentation == "sequential":
		if direction == "descending":
			notes.reverse()
		elif direction == "random":
			for i in range(notes.size() - 1, 0, -1):
				var j = rng.randi_range(0, i)
				var previous = notes[i]
				notes[i] = notes[j]
				notes[j] = previous
	# Simultaneous answers always ascend, including when the input requests
	# presentation_order; report the effective order rather than misleading metadata.
	if presentation == "simultaneous":
		answer_order = "ascending_pitch"
	var answer_notes: Array = ascending if answer_order == "ascending_pitch" else notes
	var question: Array = _pitches(notes, presentation)
	if not cue_notes.is_empty():
		question = _pitches(cue_notes, "simultaneous") + question
	return {
		"question": question,
		"anwser": _pitches(answer_notes, presentation),
		"presentation": presentation,
		"response": response,
		"answer_order": answer_order,
		"notes": notes,
		"cue_notes": cue_notes,
	}

static func _enumerate_candidates(classes: Array, low: int, high: int, count: int, selection: String, white_steps: int, min_span: int, max_span: int, white_count: int = 0) -> PackedInt32Array:
	var candidates = PackedInt32Array()
	var pool: Array[int] = []
	for midi in range(low, high + 1):
		if midi % 12 in classes:
			pool.append(midi)
	# Reject impossible scopes before entering any combination loops.
	if pool.size() < count or min_span > high - low or max_span < count - 1:
		return candidates
	for i in pool.size():
		if count == 1:
			if min_span == 0:
				candidates.append(pool[i])
			continue
		for j in range(i + 1, pool.size()):
			if pool[j] - pool[i] > max_span:
				break
			if selection in ["white_third", "white_second", "white_interval"] and _white_index(pool[j]) - _white_index(pool[i]) != white_steps:
				continue
			var pair: int = pool[i] | (pool[j] << 7)
			if count == 2:
				if pool[j] - pool[i] >= min_span:
					candidates.append(pair)
				continue
			for k in range(j + 1, pool.size()):
				if pool[k] - pool[i] > max_span:
					break
				var triple: int = pair | (pool[k] << 14)
				if count == 3:
					if selection == "color_mix" and int(pool[i] % 12 in WHITE_CLASSES) + int(pool[j] % 12 in WHITE_CLASSES) + int(pool[k] % 12 in WHITE_CLASSES) != white_count:
						continue
					if pool[k] - pool[i] >= min_span:
						candidates.append(triple)
					continue
				for l in range(k + 1, pool.size()):
					if pool[l] - pool[i] > max_span:
						break
					if pool[l] - pool[i] >= min_span:
						candidates.append(triple | (pool[l] << 21))
	return candidates

static func _is_integer(value: Variant) -> bool:
	if value is int:
		return true
	# JSON decodes numbers as floats. Guard conversion against NaN, infinity,
	# fractions, booleans and values outside the signed 64-bit integer range.
	return value is float and is_finite(value) and value == floor(value) and value >= -9223372036854775808.0 and value < 9223372036854775808.0

static func _white_index(midi: int) -> int:
	return int(midi / 12) * 7 + WHITE_CLASSES.find(midi % 12)

static func _pitches(notes: Array, presentation: String) -> Array:
	var pitches: Array[String] = []
	for midi in notes:
		var octave: int = int(midi / 12) - 4
		var marks: String = "'".repeat(octave) if octave >= 0 else ",".repeat(-octave)
		pitches.append(SPELLINGS[midi % 12] + marks)
	if presentation == "simultaneous":
		return [pitches]
	var groups: Array = []
	for pitch in pitches:
		groups.append([pitch])
	return groups

static func _invalid(message: String) -> Dictionary:
	push_error("PracticeFormula: " + message)
	return {}
