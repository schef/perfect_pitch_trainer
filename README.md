# Perfect Pitch Trainer

Perfect Pitch Trainer based on David Lucas Burge's Perfect Pitch Masterclass.

## Running

This project has been migrated from Godot 3 to Godot 4 and tested with **Godot 4.7.2**.
Open `project.godot` in Godot, let the assets import, then press **F6** for the
current scene or **F5** to run the app from its splash screen. Practice scenes
require a selected lesson, so use F5 to navigate to them through the menus.

The project uses the Compatibility renderer and a portrait 1080×1920 viewport,
displayed in a 540×960 desktop window. Progress is stored in
`user://perfectpitchtrainer.data`; running the app no longer modifies export settings.

## Headless checks

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/soundfonts.gd
```

The smoke test opens all 30 practices, checks keyboard answers, and exercises
the SoundFont player. The SoundFont test loads all three instruments, checks
all 49 pitches used by lessons, captures non-silent audio, and tests chords,
note releases, and instrument switching. Neither test modifies saved progress
or instrument preferences. Check the output for script errors as well as the
final success message.

## Instruments (SF2)

Open **More → Settings → Instrument** and use the buttons to choose **Piano**,
**Hammond**, or **Trumpet**. The selected button stays highlighted using the
app's original button artwork. The choice is remembered in `user://soundfont.cfg`.
Changing instruments or leaving a practice stops active and queued notes.

The app reads the three bundled SF2 files in `assets/soundfonts/` directly using
the MIT-licensed [Godot MIDI Player 4](https://bitbucket.org/arlez80/godot-midi-player-g4)
addon. Playback is entirely GDScript plus Godot audio nodes: no FluidSynth
installation, external process, native extension, or MIDI file is needed.
SoundFonts load synchronously when selected, which can briefly pause the UI.
The first preset in each file is used, with up to 32 sample voices.

The legacy OGG samples, SimpleSampler addon, Godot 3 import cache, and old APK
builds have been removed. `.sf2` files are explicitly included in exports;
tests, development tools, signing keys, and build outputs are excluded.

**Before distributing:** confirm the licenses and attribution requirements of
the supplied SoundFonts. They are not automatically covered by the app's or
addon's license. See `assets/soundfonts/README.md` and `addons/midi/UPSTREAM.md`.

## Android

Install export templates matching your Godot version and configure the Android
SDK/JDK in Editor Settings before exporting. Review the existing Android preset
and configure signing locally. To build an installable debug APK:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --export-debug Android apk/perfect_pitch_trainer_1.7.0-debug.apk
```

The debug APK has been built with Godot 4.7.2 and checked for valid signing,
ZIP alignment, and inclusion of all three SoundFonts. It targets ARM32/ARM64
devices with Android 7.0 or newer. Device playback and release signing have not
been validated. The unfinished Experiments screen does not automatically
activate the microphone.

## Repository layout

- `addons/midi/`: vendored GDScript SoundFont player and its license.
- `assets/`, `components/`, `scenes/`, `scripts/`: application resources and code.
- `masterclasses.json`: lesson content; `generator/` contains its batch-generation tools.
- `tests/`: headless regression checks.
- `neovim_python_plugins/`: optional JSON-editing helper, not part of the app.
- `keystore/`: existing local signing material; preserved and excluded from exports.
- `apk/`: export destination; generated packages are ignored by Git.

Godot caches and generated build outputs should not be committed. Godot 4
`.import` sidecar files and `.gd.uid` files are source metadata and should be kept.
