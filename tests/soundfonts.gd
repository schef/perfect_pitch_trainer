extends SceneTree

# Run after editor import. Does not overwrite saved instrument preferences.
func _initialize():
	call_deferred("run")

func run():
	var midi = root.get_node("MidiPlayer")
	var capture = AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0, capture)
	for index in midi.INSTRUMENTS.size():
		assert(midi.select_instrument(index, false))
		assert(midi.instrument_index == index)
		assert(not midi.synth.bank.presets.is_empty())
		# All lesson pitches span C2 through C6 (MIDI 36..84).
		for note in range(36, 85):
			midi.noteOn(note)
			assert(midi.synth.audio_stream_players.any(func(s): return s.playing), "%s has no voice for MIDI %d" % [midi.INSTRUMENTS[index].name, note])
			midi.noteOff(note)
			assert(midi.synth.audio_stream_players.any(func(s): return s.request_release))
			midi.allNotesOff()
			assert(midi.synth.audio_stream_players.all(func(s): return not s.playing and not s.linked.playing))
		midi.playMultipleNotesHarmonicly([["c'", "e'", "g'"]])
		capture.clear_buffer()
		await create_timer(0.5).timeout
		assert(midi.synth.channel_status[0].note_on.size() == 3)
		var frames = capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		for frame in frames:
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		assert(peak > 0.00001, "SoundFont produced no audio: " + midi.INSTRUMENTS[index].name)
		await create_timer(1.1).timeout
		assert(midi.synth.channel_status[0].note_on.is_empty())
		assert(midi.noteActionQueue.is_empty())
		# Advance any long release tails to their end, including linked stereo voices.
		for voice in midi.synth.audio_stream_players:
			if voice.playing:
				voice._update_adsr(0.1)
				voice._update_adsr(voice.release_state[-1].time + 1.0)
		assert(midi.synth.audio_stream_players.all(func(s): return not s.playing and not s.linked.playing))
		midi.allNotesOff()
		print("SoundFont passed: ", midi.INSTRUMENTS[index].name)
	# Switching an instrument must cancel pending notes and stop old voices.
	midi.playMultipleNotesMelodicly([["c'", "e'", "g'"]])
	assert(midi.select_instrument(0, false))
	assert(midi.noteActionQueue.is_empty())
	assert(midi.synth.audio_stream_players.all(func(s): return not s.playing and not s.linked.playing))
	assert(not midi.select_instrument(-1, false))
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	await create_timer(0.1).timeout
	print("SoundFont tests passed: all three files, 49 lesson pitches each, chords, releases and switching.")
	quit()
