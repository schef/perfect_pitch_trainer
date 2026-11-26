# Godot MIDI Player 4

Vendored from https://bitbucket.org/arlez80/godot-midi-player-g4
at commit `252157b64e9a94686b363b3cce53f195cb828aa2` (4.5.0).
See `LICENSE.txt` for the upstream MIT license.

Local changes:
- Renamed the global `MidiPlayer` class to `SoundFontMidiPlayer` to avoid
  colliding with this application's existing `MidiPlayer` autoload.
- Free removed voices when rebuilding the polyphony pool (avoids orphan nodes).
- Stop both linked stereo channels at the end of the release envelope.

This addon is used directly at runtime; its editor plugin need not be enabled.
