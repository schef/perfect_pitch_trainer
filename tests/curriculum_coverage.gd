extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var directory = "/tera/schef_backup_old/projects/perfect_pitch/digital-handbook/curriculum"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--source-dir="):
			directory = argument.trim_prefix("--source-dir=")
	var global = root.get_node("Global")
	var original_data = global.file_data.duplicate(true)
	var uids = []
	var covered = 0
	var deferred = 0
	for number in range(1, 25):
		var path = directory.path_join("master-class-%02d.json" % number)
		assert(FileAccess.file_exists(path))
		var source = JSON.parse_string(FileAccess.get_file_as_string(path))
		var expected = {}
		for practice in source.practices:
			expected[practice.id] = practice
		var lesson = global.get_masterclass_by_id(number)
		assert(lesson != null)
		var numeric_ids = []
		var represented = []
		for practice in lesson.practices:
			assert(int(practice.id) not in numeric_ids)
			numeric_ids.append(int(practice.id))
			if not practice.has("source_practice_id"):
				continue
			var source_id = practice.source_practice_id
			assert(expected.has(source_id), "Unknown/misplaced source assignment")
			var uid = practice.get("practice_uid", source_id)
			assert(uid not in uids, "Every actual activity must have a unique identity")
			uids.append(uid)
			for key in expected[source_id].info:
				assert(practice.info.get(key) == expected[source_id].info[key], "Source Info must remain exact: " + source_id)
			if source_id not in represented:
				represented.append(source_id)
			if practice.get("implementation_status", "") == "deferred":
				assert(number == 12 and not practice.has("formula"), "Unresolved collections must not be guessed")
				deferred += 1
		assert(represented.size() == expected.size(), "No source assignment may silently disappear")
		covered += represented.size()
	assert(covered == 241 and deferred == 5)
	assert(global.file_data == original_data)
	root.get_node("MidiPlayer").synth.queue_free()
	await create_timer(0.25).timeout
	print("Whole-course coverage passed: 241/241 numbered source assignments, unique activity identities, exact source Info, five explicitly unresolved variants, no progress writes.")
	quit()
