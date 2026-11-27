extends "res://scripts/practice_pitch_naming_drill.gd"

const Missing = preload("res://scripts/missing_tone_formula.gd")

func next_batch():
	batch = Missing.generate(Global.get_practice().missing_tone, Global.rng)
	assisted = false
	reset_semitone_help()
	hide_debug()
	refresh_score()
	play_question()
