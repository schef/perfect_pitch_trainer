extends Node

const SynthPlayer = preload("res://addons/midi/MidiPlayer.gd")
const INSTRUMENTS = [
	{"name": "Piano", "path": "res://assets/soundfonts/Yamaha Upright Lite.sf2"},
	{"name": "Hammond", "path": "res://assets/soundfonts/Hammond B3.sf2"},
	{"name": "Trumpet", "path": "res://assets/soundfonts/Papelmedia_Trumpet.sf2"},
]
const SETTINGS_PATH = "user://soundfont.cfg"

signal instrument_changed(index: int)

var synth: SoundFontMidiPlayer
var instrument_index := -1

const NOTE_DURATION = 1000
class NoteAction:
	var midi: int
	var status: bool
	var startTimestamp: int
	var timeout: int
	
var noteActionQueue = []

func _ready():
	synth = SynthPlayer.new()
	synth.name = "SoundFontSynth"
	synth.max_polyphony = 32
	synth.volume_db = -12.0
	add_child(synth)
	var settings = ConfigFile.new()
	settings.load(SETTINGS_PATH)
	var selected = settings.get_value("audio", "instrument", 0)
	if not selected is int or selected < 0 or selected >= INSTRUMENTS.size():
		selected = 0
	if not select_instrument(selected, false) and selected != 0:
		select_instrument(0, false)

func select_instrument(index: int, persist := true) -> bool:
	if index < 0 or index >= INSTRUMENTS.size():
		return false
	if index == instrument_index:
		return true
	var result = SoundFont.new().read_file(INSTRUMENTS[index].path)
	if result.error != OK:
		push_error("Could not load SoundFont: %s" % INSTRUMENTS[index].path)
		return false
	var new_bank = Bank.new()
	new_bank.read_soundfont(result.data)
	if new_bank.presets.is_empty():
		push_error("SoundFont has no playable presets: %s" % INSTRUMENTS[index].path)
		return false
	allNotesOff()
	synth.bank = new_bank
	# These single-instrument files need not use General MIDI program zero.
	var preset_number: int = new_bank.presets.keys()[0]
	synth.channel_status[0].program = preset_number & 127
	synth.channel_status[0].bank = preset_number >> 7
	instrument_index = index
	if persist:
		var settings = ConfigFile.new()
		settings.set_value("audio", "instrument", index)
		var error = settings.save(SETTINGS_PATH)
		if error != OK:
			push_warning("Could not save instrument preference: %s" % error_string(error))
	instrument_changed.emit(index)
	return true

func getMillis():
	return Time.get_ticks_msec()

func millisPassed(timestamp: int):
	return getMillis() - timestamp

func _process(_delta):
	for n in noteActionQueue:
		if !n.status and getMillis() >= n.startTimestamp:
			n.status = true
			noteOn(n.midi)
		elif n.status and millisPassed(n.startTimestamp) >= n.timeout:
			n.status = false
			noteOff(n.midi)
	for i in range(len(noteActionQueue) - 1, -1, -1):
		var n = noteActionQueue[i]
		if !n.status and millisPassed(n.startTimestamp) >= n.timeout:
			noteActionQueue.remove_at(i)

func noteOn(note):
	_send_note(MIDI_MESSAGE_NOTE_ON, note, 100)

func noteOff(note):
	_send_note(MIDI_MESSAGE_NOTE_OFF, note, 0)

func _send_note(message: int, note: int, velocity: int):
	if synth.bank == null or note < 0 or note > 127:
		return
	var event = InputEventMIDI.new()
	event.channel = 0
	event.message = message
	event.pitch = note
	event.velocity = velocity
	synth.receive_raw_midi_message(event)

func playMultipleNotesMelodicly(pitchList):
	print("playMultipleNotesMelodicly", pitchList)
	var currentTime = getMillis()
	for subPitchList in pitchList:
		for pitch in subPitchList:
			var n = NoteAction.new()
			n.midi = PitchParser.getMidiFromPitch(pitch)
			n.status = false
			n.startTimestamp = currentTime
			n.timeout = NOTE_DURATION
			currentTime = currentTime + NOTE_DURATION
			noteActionQueue.append(n)
		currentTime += NOTE_DURATION

func playMultipleNotesHarmonicly(pitchList):
	print("playMultipleNotesHarmonicly", pitchList)
	var currentTime = getMillis()
	for subPitchList in pitchList:
		for pitch in subPitchList:
			var n = NoteAction.new()
			n.midi = PitchParser.getMidiFromPitch(pitch)
			n.status = false
			n.startTimestamp = currentTime
			n.timeout = NOTE_DURATION
			noteActionQueue.append(n)
		currentTime += NOTE_DURATION

func allNotesOff():
	noteActionQueue.clear()
	if is_instance_valid(synth):
		synth.stop()
