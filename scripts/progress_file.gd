class_name ProgressFile
extends RefCounted

## Replace a same-directory temporary file, retaining the previous snapshot.
static func write(path: String, data: Dictionary) -> Error:
	var temporary = path + ".tmp"
	var stream = FileAccess.open(temporary, FileAccess.WRITE)
	if stream == null:
		return FileAccess.get_open_error()
	stream.store_var(data)
	stream.flush()
	var error = stream.get_error()
	stream.close()
	if error != OK:
		return error
	var absolute = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(absolute, ProjectSettings.globalize_path(path + ".bak"))
		if error != OK:
			return error # The old main file is untouched.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)

static func read(path: String) -> Dictionary:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var stream = FileAccess.open(candidate, FileAccess.READ)
		if stream == null:
			continue
		var value = stream.get_var()
		stream.close()
		if value is Dictionary:
			return value
	return {}
