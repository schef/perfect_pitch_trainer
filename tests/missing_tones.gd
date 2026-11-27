extends SceneTree

const Missing = preload("res://scripts/missing_tone_formula.gd")
const NAMES = ["c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h"]

func _initialize():
	call_deferred("run")

func run():
	var rng = RandomNumberGenerator.new()
	var twin = RandomNumberGenerator.new()
	var cases = 0
	for mode in ["major_scale", "whole_tone"]:
		for root in [0, 1, 48, 60, 61, 116 if mode == "major_scale" else 117]:
			var covered: Array = []
			var offsets: Array = [0, 2, 4, 5, 7, 9, 11] if mode == "major_scale" else [0, 2, 4, 6, 8, 10]
			var expected: Array[int] = []
			for offset in offsets:
				expected.append(root + offset)
			for seed_value in 512:
				var config = {"mode": mode, "root_midi": root}
				var snapshot = config.duplicate(true)
				rng.seed = seed_value
				twin.seed = seed_value
				var result = Missing.generate(config, rng)
				assert(result == Missing.generate(JSON.parse_string(JSON.stringify(config)), twin))
				assert(config == snapshot and rng.state == twin.state)
				assert(result.full_notes == expected)
				_check(result)
				if result.missing_note not in covered:
					covered.append(result.missing_note)
				cases += 1
			covered.sort()
			assert(covered == expected, "Every scale degree must be eligible for omission")
	for bounds in [[60, 72], [0, 2], [125, 127], [0, 24], [103, 127], [61, 68]]:
		var covered: Array = []
		for seed_value in 512:
			var config = {"mode": "chromatic_cluster", "cluster_low": bounds[0], "cluster_high": bounds[1]}
			var snapshot = config.duplicate(true)
			rng.seed = seed_value
			twin.seed = seed_value
			var result = Missing.generate(config, rng)
			assert(result == Missing.generate(JSON.parse_string(JSON.stringify(config)), twin))
			assert(config == snapshot and rng.state == twin.state)
			_check(result)
			assert(result.full_notes == range(bounds[0], bounds[1] + 1))
			assert(result.notes.front() == bounds[0] and result.notes.back() == bounds[1])
			assert(result.missing_note > bounds[0] and result.missing_note < bounds[1])
			assert(result.notes.size() <= 24)
			if result.missing_note not in covered:
				covered.append(result.missing_note)
			cases += 1
		covered.sort()
		assert(covered == range(bounds[0] + 1, bounds[1]))
	rng.seed = 42
	twin.seed = 42
	assert(Missing.generate({}, rng) == Missing.generate({"mode": "major_scale", "root_midi": 60}, twin))
	rng.seed = 42
	twin.seed = 42
	assert(Missing.generate({"mode": "chromatic_cluster"}, rng) == Missing.generate({"mode": "chromatic_cluster", "cluster_low": 60, "cluster_high": 72}, twin))
	# Mutating one result cannot change the reference or any future generation.
	rng.seed = 42
	var result = Missing.generate({}, rng)
	var original = result.duplicate(true)
	result.notes[0] = 127
	result.full_notes[0] = 127
	result.question[0][0] = "changed"
	result.anwser[0][0] = "changed"
	rng.seed = 42
	assert(Missing.generate({}, rng) == original)
	if "--invalid" in OS.get_cmdline_user_args():
		_test_invalid(rng)
	print("Missing tone tests passed: %d seeded JSON cases; all scale/interior omissions covered, exact question/answer spelling checked." % cases)
	quit()

func _check(result: Dictionary):
	assert(not result.is_empty())
	assert(result.presentation == "simultaneous" and result.response == "name")
	assert(result.answer_order == "ascending_pitch" and result.cue_notes == [])
	assert(result.missing_note is int)
	assert(result.full_notes.size() == result.notes.size() + 1)
	assert(result.missing_note in result.full_notes and result.missing_note not in result.notes)
	var reconstructed: Array = result.notes.duplicate()
	reconstructed.append(result.missing_note)
	reconstructed.sort()
	assert(reconstructed == result.full_notes)
	for i in result.full_notes.size():
		assert(result.full_notes[i] is int and result.full_notes[i] >= 0 and result.full_notes[i] <= 127)
		if i > 0:
			assert(result.full_notes[i] > result.full_notes[i - 1])
	assert(result.question.size() == 1 and result.question[0].size() == result.notes.size())
	for i in result.notes.size():
		assert(result.question[0][i] == _spell(result.notes[i]))
	assert(result.anwser == [[_spell(result.missing_note)]])
	assert(result.anwser[0][0] not in result.question[0])
	# Name grading compares pitch classes, independently of octave marks.
	assert(result.anwser[0][0].rstrip("',") == NAMES[result.missing_note % 12])

func _spell(midi: int) -> String:
	var octave: int = int(midi / 12) - 4
	return NAMES[midi % 12] + ("'".repeat(octave) if octave >= 0 else ",".repeat(-octave))

func _test_invalid(rng: RandomNumberGenerator):
	assert(Missing.generate({}, null).is_empty())
	for mode in [null, true, 0, "unknown", ""]:
		assert(Missing.generate({"mode": mode}, rng).is_empty())
	for field in ["root_midi", "cluster_low", "cluster_high"]:
		for value in [null, true, "60", -1, 128, 60.5, NAN, INF, -INF, 1e30]:
			assert(Missing.generate({field: value}, rng).is_empty())
	for config in [{"root_midi": 117}, {"mode": "whole_tone", "root_midi": 118},
		{"mode": "chromatic_cluster", "cluster_low": 60, "cluster_high": 59},
		{"mode": "chromatic_cluster", "cluster_low": 60, "cluster_high": 60},
		{"mode": "chromatic_cluster", "cluster_low": 60, "cluster_high": 61},
		{"mode": "chromatic_cluster", "cluster_low": 60, "cluster_high": 85}]:
		assert(Missing.generate(config, rng).is_empty())
