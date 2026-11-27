extends SceneTree

const Formula = preload("res://scripts/practice_formula.gd")
const NAMES = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]
const WHITES = [0, 2, 4, 5, 7, 9, 11]

func _initialize():
	call_deferred("run")

func run():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 20261126
	twin.seed = rng.seed
	var generated = 0
	for selection in ["single", "white_second", "white_third", "distinct"]:
		for count in ([2, 3] if selection == "distinct" else [1 if selection == "single" else 2]):
			for presentation in ["simultaneous", "sequential"]:
				for direction in ["ascending", "descending", "random"]:
					for order in ["ascending_pitch", "presentation_order"]:
						for iteration in 100:
							var formula = {
								"pitch_classes": WHITES if selection.begins_with("white") else range(12),
								"note_count": count, "selection": selection,
								"presentation": presentation, "direction": direction,
								"response": ["sing", "name", "recall"][iteration % 3],
								"answer_order": order, "min_span": 0 if count == 1 else 1,
								"max_span": 12,
							}
							var result = Formula.generate(formula, rng)
							assert(result == Formula.generate(formula, twin), "Seeded generation differs")
							_check(formula, result)
							generated += 1
	# Exact spelling across the entire MIDI range, independent of autoloads.
	for midi in 128:
		var result = Formula.generate({"pitch_classes": [midi % 12], "midi_min": midi,
			"midi_max": midi, "selection": "single", "note_count": 1}, rng)
		assert(result.question == [[_spell(midi)]])
		assert(result.anwser == result.question)
		assert(result.notes == [midi])
	var sequential = Formula.generate({"pitch_classes": [0, 4, 7], "midi_min": 60,
		"midi_max": 67, "selection": "distinct", "note_count": 3,
		"presentation": "sequential", "direction": "descending"}, rng)
	assert(sequential.notes == [67, 64, 60])
	assert(sequential.anwser == [["g'"], ["e'"], ["c'"]])
	assert(sequential.answer_order == "presentation_order")
	_test_json_and_white_subsets(rng)
	_test_white_intervals()
	_test_cues()
	_test_four_tones()
	_test_color_mix()
	# Opt in to negative cases: push_error is required API behavior and emits
	# expected ERROR diagnostics, so the ordinary test run stays error-free.
	if "--invalid" in OS.get_cmdline_user_args():
		_test_invalid(rng)
	print("Formula tests passed: %d seeded constraint/determinism cases and 128 MIDI spellings." % generated)
	quit()

func _check(formula: Dictionary, result: Dictionary):
	assert(not result.is_empty())
	assert(result.presentation == formula.presentation)
	assert(result.response == formula.response)
	assert(result.notes.size() == formula.note_count)
	var sorted: Array = result.notes.duplicate()
	sorted.sort()
	var allowed: Array[int] = []
	for pitch_class in formula.pitch_classes:
		allowed.append(int(pitch_class))
	for i in sorted.size():
		assert(sorted[i] >= 36 and sorted[i] <= 84)
		assert(sorted[i] % 12 in allowed)
		if i > 0:
			assert(sorted[i] > sorted[i - 1])
	var span: int = sorted.back() - sorted.front()
	assert(span >= formula.min_span and span <= formula.max_span)
	if formula.selection.begins_with("white"):
		var white_pool: Array = []
		for midi in range(36, 85):
			if midi % 12 in WHITES:
				white_pool.append(midi)
		var steps = formula.white_steps if formula.selection == "white_interval" else (2 if formula.selection == "white_third" else 1)
		assert(white_pool.find(sorted[1]) - white_pool.find(sorted[0]) == steps)
	if formula.presentation == "simultaneous" or formula.direction == "ascending":
		assert(result.notes == sorted)
	elif formula.direction == "descending":
		var descending: Array = sorted.duplicate()
		descending.reverse()
		assert(result.notes == descending)
	var answers: Array = sorted if formula.presentation == "simultaneous" or formula.answer_order == "ascending_pitch" else result.notes
	_check_groups(result.question, result.notes, formula.presentation)
	_check_groups(result.anwser, answers, formula.presentation)
	assert(result.answer_order == ("ascending_pitch" if formula.presentation == "simultaneous" else formula.answer_order))

func _check_groups(groups: Array, notes: Array, presentation: String):
	assert(groups.size() == (1 if presentation == "simultaneous" else notes.size()))
	for group in groups:
		assert(group is Array)
		assert(group.size() == (notes.size() if presentation == "simultaneous" else 1))
	for i in notes.size():
		var pitch = groups[0][i] if presentation == "simultaneous" else groups[i][0]
		assert(pitch is String and pitch == _spell(notes[i]))

func _test_json_and_white_subsets(rng: RandomNumberGenerator):
	for selection in ["single", "white_second", "white_third", "distinct"]:
		var original = {"pitch_classes": WHITES, "midi_min": 48, "midi_max": 84,
			"note_count": 1 if selection == "single" else 2, "selection": selection,
			"min_span": 0, "max_span": 24, "presentation": "sequential", "direction": "random"}
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(original))
		assert(decoded.note_count is float and decoded.pitch_classes[0] is float)
		var state = rng.state
		var expected = Formula.generate(original, rng)
		rng.state = state
		assert(Formula.generate(decoded, rng) == expected)
	# A missing D must not make C/E adjacent white keys; missing intermediate
	# pitches must not make C/G a third. Cross-octave B/D remains a third.
	for spec in [
		{"pitch_classes": [0, 4], "midi_min": 60, "midi_max": 64, "selection": "white_third", "expected": [60, 64]},
		{"pitch_classes": [11, 2], "midi_min": 59, "midi_max": 62, "selection": "white_third", "expected": [59, 62]},
		{"pitch_classes": [0, 2, 7], "midi_min": 60, "midi_max": 67, "selection": "white_second", "expected": [60, 62]},
		{"pitch_classes": [0, 4, 7], "midi_min": 60, "midi_max": 67, "selection": "white_third", "expected": [60, 64]},
	]:
		spec.note_count = 2
		for iteration in 100:
			var result = Formula.generate(spec, rng)
			assert(result.notes == spec.expected or (spec.pitch_classes == [0, 4, 7] and result.notes == [64, 67]))
			_check_groups(result.question, result.notes, "simultaneous")
			_check_groups(result.anwser, result.notes, "simultaneous")

func _spell(midi: int) -> String:
	var octave: int = int(midi / 12) - 4
	return NAMES[midi % 12] + ("'".repeat(octave) if octave >= 0 else ",".repeat(-octave))

func _test_white_intervals():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	var cases = 0
	for steps in range(1, 7):
		for presentation in ["simultaneous", "sequential"]:
			for direction in ["ascending", "descending", "random"]:
				for order in ["ascending_pitch", "presentation_order"]:
					for seed_value in 12:
						var original = {"pitch_classes": WHITES, "selection": "white_interval",
							"white_steps": steps, "note_count": 2, "min_span": 1, "max_span": 12,
							"presentation": presentation, "direction": direction,
							"answer_order": order, "response": "name"}
						var decoded: Dictionary = JSON.parse_string(JSON.stringify(original))
						assert(decoded.white_steps is float)
						rng.seed = seed_value
						twin.seed = seed_value
						var result = Formula.generate(decoded, rng)
						assert(result == Formula.generate(original, twin))
						_check(decoded, result)
						assert(result.cue_notes == [])
						if steps <= 2:
							var legacy = original.duplicate(true)
							legacy.erase("white_steps")
							legacy.selection = "white_second" if steps == 1 else "white_third"
							twin.seed = seed_value
							assert(result == Formula.generate(legacy, twin))
						cases += 1
		# Endpoints alone must still measure the full keyboard, across octaves.
		var endpoint: int = [60, 62, 64, 65, 67, 69, 71][steps]
		var sparse = {"pitch_classes": [0, endpoint % 12], "midi_min": 60,
			"midi_max": endpoint, "selection": "white_interval", "white_steps": steps, "note_count": 2}
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(sparse))
		assert(Formula.generate(decoded, rng).notes == [60, endpoint])
		# B to the next octave exercises diatonic indexing at an octave boundary.
		endpoint = [59, 60, 62, 64, 65, 67, 69][steps]
		sparse.pitch_classes = [11, endpoint % 12]
		sparse.midi_min = 59
		sparse.midi_max = endpoint
		assert(Formula.generate(JSON.parse_string(JSON.stringify(sparse)), rng).notes == [59, endpoint])
	print("White interval tests passed: %d JSON/determinism cases, steps 1–6, sparse and cross-octave endpoints." % cases)

func _test_cues():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	var cases = 0
	for cue in [[57, 61, 64], [59, 63, 66], [0], [127], [64, 57, 64], [0, 127, 0, 127, 60, 60, 61, 62]]:
		for presentation in ["simultaneous", "sequential"]:
			for direction in ["ascending", "descending", "random"]:
				for order in ["ascending_pitch", "presentation_order"]:
					for count in [1, 2, 3, 4]:
						var original = {"pitch_classes": WHITES, "selection": "single" if count == 1 else "distinct",
							"note_count": count, "min_span": 0, "max_span": 12,
							"presentation": presentation, "direction": direction, "response": "recall",
							"answer_order": order, "cue_midi": cue}
						var decoded: Dictionary = JSON.parse_string(JSON.stringify(original))
						rng.seed = cases
						twin.seed = cases
						var result = Formula.generate(decoded, rng)
						assert(result == Formula.generate(original, twin))
						var target_formula = original.duplicate(true)
						target_formula.erase("cue_midi")
						twin.seed = cases
						var target = Formula.generate(target_formula, twin)
						_check(target_formula, target)
						assert(result.notes == target.notes and result.anwser == target.anwser)
						assert(result.presentation == target.presentation and result.answer_order == target.answer_order)
						assert(result.response == target.response and rng.state == twin.state)
						assert(result.cue_notes == cue)
						for midi in result.cue_notes:
							assert(midi is int)
						_check_groups([result.question[0]], cue, "simultaneous")
						assert(result.question.slice(1) == target.question)
						cases += 1
	print("Cue tests passed: %d JSON/determinism cases; target notes and answers unchanged." % cases)

func _test_four_tones():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	rng.seed = 20261127
	twin.seed = rng.seed
	var started = Time.get_ticks_msec()
	for iteration in 1000:
		var formula = {"pitch_classes": WHITES, "note_count": 4, "selection": "distinct",
			"midi_min": 36, "midi_max": 84, "min_span": 3, "max_span": 48,
			"presentation": "simultaneous" if iteration % 2 == 0 else "sequential",
			"direction": ["ascending", "descending", "random"][iteration % 3],
			"answer_order": "ascending_pitch" if iteration % 4 < 2 else "presentation_order",
			"response": ["sing", "name", "recall"][iteration % 3]}
		var result = Formula.generate(formula, rng)
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(formula))
		decoded.pitch_classes.reverse()
		assert(result == Formula.generate(decoded, twin), "Four-tone JSON/seed determinism differs")
		_check(formula, result)
		assert(result.cue_notes == [])
		if formula.presentation == "simultaneous":
			assert(result.anwser.size() == 1 and result.anwser[0].size() == 4)
		else:
			assert(result.question.size() == 4 and result.anwser.size() == 4)
	var elapsed = Time.get_ticks_msec() - started
	# Distinct means MIDI pitches, not pitch classes: this pool has exactly one tuple.
	var octaves = {"pitch_classes": [0], "midi_min": 48, "midi_max": 84,
		"note_count": 4, "selection": "distinct", "min_span": 36, "max_span": 36}
	assert(Formula.generate(octaves, rng).notes == [48, 60, 72, 84])
	assert(Formula.generate(octaves, rng).anwser == [["c", "c'", "c''", "c'''"]])
	# Caller mutation must not poison the immutable cached candidate data.
	var result = Formula.generate(octaves, rng)
	result.notes[0] = 127
	result.anwser[0][0] = "changed"
	assert(Formula.generate(octaves, rng).notes == [48, 60, 72, 84])
	# Presentation, cue and response do not create candidate cache entries.
	var cache_size = Formula._candidate_cache.size()
	octaves.presentation = "sequential"
	octaves.direction = "descending"
	octaves.response = "recall"
	octaves.cue_midi = [60, 64, 67]
	result = Formula.generate(octaves, rng)
	assert(result.notes == [84, 72, 60, 48] and result.question.size() == 5)
	assert(Formula._candidate_cache.size() == cache_size)
	# All 49 chromatic pitches are eligible: choose(49, 4) = 211876.
	var chromatic = {"pitch_classes": range(12), "midi_min": 36, "midi_max": 84,
		"note_count": 4, "selection": "distinct", "min_span": 0, "max_span": 48}
	started = Time.get_ticks_msec()
	Formula.generate(chromatic, rng)
	var cold_ms = Time.get_ticks_msec() - started
	var found_full_pool = false
	for candidates in Formula._candidate_cache.values():
		if candidates.size() == 211876:
			found_full_pool = true
	assert(found_full_pool)
	started = Time.get_ticks_msec()
	for iteration in 1000:
		Formula.generate(chromatic, rng)
	var warm_ms = Time.get_ticks_msec() - started
	# More scopes than the key cap exercise eviction without changing seeded output.
	for midi in 12:
		Formula.generate({"pitch_classes": [midi], "midi_min": midi,
			"midi_max": midi, "note_count": 1, "selection": "single"}, rng)
		assert(Formula._candidate_cache.size() <= Formula.CANDIDATE_CACHE_KEYS)
		assert(Formula._candidate_cache_size <= Formula.CANDIDATE_CACHE_TUPLES)
	rng.seed = 42
	twin.seed = 42
	assert(Formula.generate(chromatic, rng) == Formula.generate(chromatic, twin))
	print("Four-tone tests passed: 1000 white-pool JSON/determinism cases in %d ms; chromatic cold %d ms, 1000 cached calls %d ms; octaves and cache bounds valid." % [elapsed, cold_ms, warm_ms])

func _test_color_mix():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	var cases = 0
	for white_count in [1, 2]:
		for presentation in ["simultaneous", "sequential"]:
			for direction in ["ascending", "descending", "random"]:
				for order in ["ascending_pitch", "presentation_order"]:
					for seed_value in 100:
						var formula = {"pitch_classes": range(12), "selection": "color_mix", "note_count": 3,
							"white_count": white_count, "black_count": 3 - white_count,
							"min_span": 2, "max_span": 12, "presentation": presentation,
							"direction": direction, "answer_order": order, "response": "name"}
						var snapshot = formula.duplicate(true)
						var decoded: Dictionary = JSON.parse_string(JSON.stringify(formula))
						decoded.pitch_classes.reverse()
						rng.seed = seed_value
						twin.seed = seed_value
						var result = Formula.generate(formula, rng)
						assert(result == Formula.generate(decoded, twin))
						assert(formula == snapshot)
						_check(formula, result)
						var whites = 0
						for midi in result.notes:
							whites += int(midi % 12 in WHITES)
						assert(whites == white_count)
						cases += 1
	# Exhaustively compare the cached tuples with a small brute-force domain.
	for white_count in [1, 2]:
		var formula = {"pitch_classes": range(12), "selection": "color_mix", "note_count": 3,
			"white_count": white_count, "black_count": 3 - white_count,
			"midi_min": 60, "midi_max": 66, "min_span": 3, "max_span": 5}
		Formula.generate(formula, rng)
		var key = str([range(12), 60, 66, 3, "color_mix", 1, 3, 5, white_count, 3 - white_count])
		assert(Formula._candidate_cache.has(key))
		var expected = PackedInt32Array()
		for a in range(60, 67):
			for b in range(a + 1, 67):
				for c in range(b + 1, 67):
					if c - a >= 3 and c - a <= 5 and int(a % 12 in WHITES) + int(b % 12 in WHITES) + int(c % 12 in WHITES) == white_count:
						expected.append(a | (b << 7) | (c << 14))
		assert(Formula._candidate_cache[key] == expected)
		assert(Formula._candidate_cache.size() <= Formula.CANDIDATE_CACHE_KEYS)
		assert(Formula._candidate_cache_size <= Formula.CANDIDATE_CACHE_TUPLES)
	print("Color mix tests passed: %d seeded JSON cases and exhaustive cache membership for both count splits." % cases)

func _test_invalid(rng: RandomNumberGenerator):
	var color = {"pitch_classes": range(12), "note_count": 3, "selection": "color_mix", "white_count": 1, "black_count": 2}
	for field in ["white_count", "black_count"]:
		var absent = color.duplicate(true)
		absent.erase(field)
		assert(Formula.generate(absent, rng).is_empty())
		for value in [null, true, "1", 0, 3, 1.5, NAN, INF, -INF, 1e30]:
			var invalid = color.duplicate(true)
			invalid[field] = value
			assert(Formula.generate(invalid, rng).is_empty())
	for override in [{"white_count": 2}, {"black_count": 1}, {"note_count": 2}, {"note_count": 4},
		{"pitch_classes": WHITES}, {"midi_min": 60, "midi_max": 62},
		{"selection": "distinct"}, {"selection": "single", "note_count": 1}]:
		var invalid = color.duplicate(true)
		invalid.merge(override, true)
		assert(Formula.generate(invalid, rng).is_empty())
	var base = {"pitch_classes": [0, 2, 4, 5, 7, 9, 11], "note_count": 2, "selection": "distinct"}
	for override in [{"pitch_classes": []}, {"pitch_classes": [0, 0]}, {"pitch_classes": [12]},
		{"pitch_classes": [0.5]}, {"note_count": 0}, {"note_count": 5}, {"note_count": 2.5},
		{"pitch_classes": [true]}, {"pitch_classes": [0, 0.0]}, {"note_count": true},
		{"midi_min": NAN}, {"midi_max": INF}, {"min_span": 1e30},
		{"midi_min": -1}, {"midi_max": 128}, {"midi_min": 85, "midi_max": 36},
		{"min_span": -1}, {"min_span": 10, "max_span": 2}, {"selection": "unknown"},
		{"selection": "single"}, {"selection": "white_second", "pitch_classes": [1, 3]},
		{"presentation": "unknown"}, {"direction": "unknown"}, {"response": "unknown"},
		{"answer_order": "unknown"}, {"midi_min": 61, "midi_max": 61},
		{"min_span": 49}, {"midi_min": 60, "midi_max": 60},
		{"note_count": 4, "min_span": 9223372036854775807, "max_span": 9223372036854775807},
		{"note_count": 4, "pitch_classes": range(12), "midi_min": 0, "midi_max": 127, "min_span": 128, "max_span": 9223372036854775807},
		{"note_count": 4, "midi_min": 60, "midi_max": 62},
		{"note_count": 4, "max_span": 2},
		{"note_count": 4, "selection": "single"},
		{"note_count": 4, "selection": "white_second"},
		{"note_count": 4, "selection": "white_third"},
		{"selection": "white_second", "pitch_classes": [0, 4], "midi_min": 60, "midi_max": 64},
		{"selection": "white_third", "pitch_classes": [0, 7], "midi_min": 60, "midi_max": 67}]:
		var formula = base.duplicate(true)
		formula.merge(override, true)
		assert(Formula.generate(formula, rng).is_empty())
	for steps in [null, true, "2", 0, 7, 1.5, NAN, INF, -INF, 1e30]:
		var formula = base.duplicate(true)
		formula.selection = "white_interval"
		formula.white_steps = steps
		assert(Formula.generate(formula, rng).is_empty())
	for override in [{"selection": "white_interval"}, {"white_steps": 1},
		{"selection": "white_second", "white_steps": 1}, {"selection": "white_third", "white_steps": 2},
		{"selection": "white_interval", "white_steps": 2, "note_count": 1},
		{"selection": "white_interval", "white_steps": 2, "note_count": 3},
		{"selection": "white_interval", "white_steps": 2, "note_count": 4},
		{"selection": "white_interval", "white_steps": 2, "pitch_classes": [0, 1]},
		{"selection": "white_interval", "white_steps": 3, "pitch_classes": [0, 4], "midi_min": 60, "midi_max": 64}]:
		var formula = base.duplicate(true)
		formula.merge(override, true)
		assert(Formula.generate(formula, rng).is_empty())
	for cue in [null, true, "60", [], [true], ["60"], [-1], [128], [60.5], [NAN], [INF], [-INF], [1e30], range(9)]:
		var formula = base.duplicate(true)
		formula.cue_midi = cue
		assert(Formula.generate(formula, rng).is_empty())
	assert(Formula.generate({}, rng).is_empty())
	assert(Formula.generate(base, null).is_empty())
