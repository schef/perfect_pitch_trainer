extends SceneTree

const Store = preload("res://scripts/progress_file.gd")

func _initialize():
	call_deferred("run")

func run():
	# A unique temporary fixture, never the real user progress path.
	var path = OS.get_cache_dir().path_join("pitch-progress-test-%d-%d.data" % [OS.get_process_id(), Time.get_ticks_usec()])
	var before = {1: {2: 12}, "formula_progress": {"final": 9}, "spaced_recall_history": {"final": [{"correct": true, "streak": 9}]}}
	var after = before.duplicate(true)
	after.formula_progress.final = 10
	assert(Store.read(path).is_empty())
	assert(Store.write(path, before) == OK)
	assert(Store.read(path) == before)
	assert(Store.write(path, after) == OK)
	assert(Store.read(path) == after)
	assert(Store.read(path + ".bak") == before)
	assert(not FileAccess.file_exists(path + ".tmp"))
	assert(DirAccess.remove_absolute(path) == OK)
	assert(Store.read(path) == before, "Missing main snapshot can recover the previous backup")
	assert(DirAccess.remove_absolute(path + ".bak") == OK)
	root.get_node("MidiPlayer").synth.queue_free()
	await create_timer(0.25).timeout
	print("Progress snapshots passed: exact legacy/formula/history preservation, atomic replacement, backup recovery, no real user file writes.")
	quit()
