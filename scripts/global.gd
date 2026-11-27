extends Node

const VERSION = "2.0.0"

var root
var rng
var masterclass_index = -1
var practice_index = -1
const FILE_PATH = "user://perfectpitchtrainer.data"
var file_data = {}
var practice_owners = {}

var color_finished = Color("578754")

func load_root():
	root = JSON.parse_string(FileAccess.get_file_as_string("res://masterclasses.json"))
	for path in root.get("external_masterclasses", []):
		if not str(path).begins_with("res://curriculum/") or not FileAccess.file_exists(path):
			push_error("Missing curriculum file: " + str(path))
			continue
		var lesson = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not lesson is Dictionary or not lesson.has("id") or not lesson.get("practices") is Array:
			push_error("Invalid curriculum file: " + str(path))
			continue
		if get_masterclass_by_id(lesson.id) != null:
			push_error("Duplicate curriculum ID: " + str(lesson.id))
			continue
		var insert_at = root.masterclasses.size()
		for index in root.masterclasses.size():
			if root.masterclasses[index].id == 255:
				insert_at = index
				break
		root.masterclasses.insert(insert_at, lesson)
	for path in root.get("external_practice_supplements", []):
		if not str(path).begins_with("res://curriculum/") or not FileAccess.file_exists(path):
			push_error("Missing practice supplement: " + str(path))
			continue
		var supplement = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not supplement is Dictionary or not supplement.get("extensions") is Array:
			push_error("Invalid practice supplement: " + str(path))
			continue
		for extension in supplement.extensions:
			var lesson = get_masterclass_by_id(extension.masterclass_id)
			if lesson == null:
				push_error("Supplement references missing class: " + str(extension.masterclass_id))
				continue
			for practice in extension.practices:
				if get_practice_by_id(extension.masterclass_id, practice.id) != null:
					push_error("Duplicate supplemental practice: " + str(practice.id))
					continue
				lesson.practices.append(practice)
	# Source metadata is substantial; avoid repeated deep-dictionary comparisons
	# across the full course when reading/writing formula progress.
	practice_owners.clear()
	for lesson in root.masterclasses:
		for practice in lesson.practices:
			var uid = practice.get("practice_uid", practice.get("source_practice_id", ""))
			if not str(uid).is_empty():
				practice_owners[uid] = int(lesson.id)
	
func load_rng():
	rng = RandomNumberGenerator.new()
	rng.randomize()
		
func _ready():
	# Handle Android Back ourselves instead of letting SceneTree exit immediately.
	get_tree().quit_on_go_back = false
	load_root()
	load_rng()
	load_file()

func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		navigate_back()

func navigate_back():
	var scene = get_tree().current_scene
	if scene != null and scene.has_method("navigate_back"):
		scene.navigate_back()
	else:
		# The splash screen has no parent menu.
		get_tree().quit()
	
func get_root():
	return root
	
func get_masterclass():
	return get_root()["masterclasses"][masterclass_index]

func get_practice():
	return get_masterclass()["practices"][practice_index]

func get_self():
	if (masterclass_index != -1 and practice_index != -1):
		return get_practice()
	elif (masterclass_index != -1 and practice_index == -1):
		return get_masterclass()
	else:
		return get_root()

func get_field(field):
	return get_self()[field]

func get_field_from_object(object, field):
	return object[field]
		
func get_title():
	return get_field("title")

func get_description():
	return get_field("description")
	
func get_masterclasses():
	return get_field("masterclasses")

func get_practices():
	return get_field("practices")

func get_masterclass_index():
	return masterclass_index

func set_masterclass_index(index: int):
	masterclass_index = index
	
func reset_masterclass_index():
	masterclass_index = -1
	
func set_practice_index(index: int):
	practice_index = index
	
func get_practice_index():
	return practice_index

func reset_practice_index():
	practice_index = -1

func get_random_number_in_range(minNum: int, maxNum: int):
	return rng.randi_range(minNum, maxNum)

func get_random_practice_batch():
	if get_practice().has("formula"):
		return preload("res://scripts/practice_formula.gd").generate(get_field("formula"), rng)
	var batch = get_field("practiceBatch")
	return batch[Global.get_random_number_in_range(0, len(batch) - 1)]

func get_flat_pitch_list(pitch_list):
	var flat_list = []
	for list in pitch_list:
		for l in list:
			flat_list.append(PitchParser.getPitchBase(l))
	return flat_list

func save_file():
	var error = preload("res://scripts/progress_file.gd").write(FILE_PATH, file_data)
	if error != OK:
		push_error("Could not save progress: %s" % error)

func load_file():
	file_data = preload("res://scripts/progress_file.gd").read(FILE_PATH)

func set_score(score: int, familiarity_confirmed: bool = false, persist: bool = true):
	var masterclass_id = get_masterclass()["id"]
	var practice_id = get_practice()["id"]
	if get_practice().has("formula"):
		if not file_data.has("formula_progress"):
			file_data["formula_progress"] = {}
		file_data["formula_progress"][formula_progress_key(get_practice())] = score
		if get_practice().get("session", {}).get("requires_familiarity", false):
			if not file_data.has("formula_familiarity"):
				file_data["formula_familiarity"] = {}
			file_data["formula_familiarity"][formula_progress_key(get_practice())] = familiarity_confirmed
		if persist:
			save_file()
		return
	if (!file_data.has(masterclass_id)):
		file_data[masterclass_id] = {}
	file_data[masterclass_id][practice_id] = score
	if persist:
		save_file()

func get_score(masterclass_id, practice_id):
	var practice = get_practice_by_id(masterclass_id, practice_id)
	if practice.has("formula"):
		return file_data.get("formula_progress", {}).get(formula_progress_key(practice), 0)
	if (!file_data.has(masterclass_id)):
		return 0
	if (!file_data[masterclass_id].has(practice_id)):
		return 0
	else:
		return file_data[masterclass_id][practice_id]

func get_masterclass_by_id(masterclass_id) -> Variant:
	for masterclass in get_root()["masterclasses"]:
		if masterclass["id"] == masterclass_id:
			return masterclass
	return null
	
func get_practice_by_id(masterclass_id, practice_id) -> Variant:
	for practice in get_masterclass_by_id(masterclass_id)["practices"]:
		if practice["id"] == practice_id:
			return practice
	return null

func is_practice_finished(masterclass_id, practice_id):
	var practice = get_practice_by_id(masterclass_id, practice_id)
	if practice.get("implementation_status", "") == "deferred":
		return false
	if practice.has("session") and practice.session.kind == "open":
		return get_score(masterclass_id, practice_id) >= 1
	if practice.has("session") and practice.session.kind == "consecutive":
		var numerical_pass = get_score(masterclass_id, practice_id) >= practice.session.target * practice.session.get("rounds", 1)
		var familiarity = not practice.session.get("requires_familiarity", false) or file_data.get("formula_familiarity", {}).get(formula_progress_key(practice), false)
		return numerical_pass and familiarity
	if practice.has("session") and practice.session.kind == "patterns":
		return get_score(masterclass_id, practice_id) >= practice.session.patterns_per_round * practice.session.rounds
	var max_hits = get_practice_by_id(masterclass_id, practice_id)["maxHits"]
	var score = Global.get_score(masterclass_id, practice_id)
	if (score >= max_hits):
		return true
	return false

func formula_progress_key(practice: Dictionary) -> String:
	# Leave old counters intact, but do not present them as verified formula progress.
	var definition = JSON.stringify([practice.formula, practice.get("session", {})])
	return "%s:%s:%s" % [get_masterclass_id_for_practice(practice), practice.id, definition.sha256_text()]

func get_masterclass_id_for_practice(practice: Dictionary) -> int:
	var uid = practice.get("practice_uid", practice.get("source_practice_id", ""))
	if practice_owners.has(uid):
		return practice_owners[uid]
	for masterclass in root.masterclasses:
		for candidate in masterclass.practices:
			if candidate == practice:
				return masterclass.id
	return -1

func is_masterclass_finished(masterclass_id):
	for practice in get_masterclass_by_id(masterclass_id)["practices"]:
		if practice.get("optional", false):
			continue
		if (!is_practice_finished(masterclass_id, practice["id"])):
			return false
	return true
