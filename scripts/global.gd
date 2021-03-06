extends Node

const VERSION = "1.7.0"
const EXPORT_PATH = "apk/perfect_pitch_trainer_"

var root
var rng
var masterclass_index = -1
var practice_index = -1
const FILE_PATH = "user://perfectpitchtrainer.data"
var file_data = {}

var color_finished = Color("578754")

func load_root():
	var file = File.new()
	file.open("res://masterclasses.json", file.READ)
	var json = file.get_as_text()
	root = JSON.parse(json).result
	file.close()
	
func load_rng():
	rng = RandomNumberGenerator.new()
	rng.randomize()
		
func _ready():
	load_root()
	load_rng()
	load_file()
	set_version()
	
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
	var batch = get_field("practiceBatch")
	return batch[Global.get_random_number_in_range(0, len(batch) - 1)]

func get_flat_pitch_list(pitch_list):
	var flat_list = []
	for list in pitch_list:
		for l in list:
			flat_list.append(PitchParser.getPitchBase(l))
	return flat_list

func save_file():
	var f = File.new()
	f.open(FILE_PATH, File.WRITE)
	f.store_var(file_data)
	f.close()

func load_file():
	var f = File.new()
	if f.file_exists(FILE_PATH):
		f.open(FILE_PATH, File.READ)
		file_data = f.get_var()
		f.close()

func set_score(score: int):
	var masterclass_id = get_masterclass()["id"]
	var practice_id = get_practice()["id"]
	if (!file_data.has(masterclass_id)):
		file_data[masterclass_id] = {}
	file_data[masterclass_id][practice_id] = score
	save_file()

func get_score(masterclass_id, practice_id):
	if (!file_data.has(masterclass_id)):
		return 0
	if (!file_data[masterclass_id].has(practice_id)):
		return 0
	else:
		return file_data[masterclass_id][practice_id]

func get_masterclass_by_id(masterclass_id):
	for masterclass in get_root()["masterclasses"]:
		if masterclass["id"] == masterclass_id:
			return masterclass
	return null
	
func get_practice_by_id(masterclass_id, practice_id):
	for practice in get_masterclass_by_id(masterclass_id)["practices"]:
		if practice["id"] == practice_id:
			return practice
	return null

func is_practice_finished(masterclass_id, practice_id):
	var max_hits = get_practice_by_id(masterclass_id, practice_id)["maxHits"]
	var score = Global.get_score(masterclass_id, practice_id)
	if (score >= max_hits):
		return true
	return false

func is_masterclass_finished(masterclass_id):
	for practice in get_masterclass_by_id(masterclass_id)["practices"]:
		if (!is_practice_finished(masterclass_id, practice["id"])):
			return false
	return true

func set_version():
	var preset = ConfigFile.new()
	preset.load("res://export_presets.cfg")
	preset.set_value("preset.0.options", "version/name", VERSION)
	preset.set_value("preset.0", "export_path", EXPORT_PATH + VERSION)
	preset.save("res://export_presets.cfg")
	property_list_changed_notify()
