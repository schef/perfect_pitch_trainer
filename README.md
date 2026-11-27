# Perfect Pitch Trainer

Perfect Pitch Trainer based on David Lucas Burge's Perfect Pitch Masterclass.

## Running

This project has been migrated from Godot 3 to Godot 4 and tested with **Godot 4.7.2**.
Open `project.godot` in Godot, let the assets import, then press **F6** for the
current scene or **F5** to run the app from its splash screen. Practice scenes
require a selected lesson, so use F5 to navigate to them through the menus.

The project uses the Compatibility renderer and a 1080×1920 reference layout,
displayed in a 540×960 desktop window. The UI expands to fit taller phone screens
without letterboxing, and the background covers the available area. Progress is stored in
`user://perfectpitchtrainer.data`; running the app no longer modifies export settings.
Each screen scrolls as one full-height page: the heading, back button, and content
move together with Godot's built-in touch drag/inertia or the mouse wheel. Long
comments expand into the page instead of using a nested scrolling text panel.
Long button names wrap onto multiple lines with internal padding, and the buttons
grow vertically instead of forcing the page wider than the screen. Nine-slice
button skins keep rounded borders and shadows at a fixed size; extra bottom
padding keeps multiline lettering inside the visible artwork.
Subtle fades blend overflowing content into the background at the screen edges;
they disappear at the beginning/end of the page and do not intercept touch input.
Android's system Back button follows the on-screen back navigation (including
saving practice scores) and exits from the main menu. The on-screen back arrow
is hidden on Android without leaving an empty row; desktop builds keep it.
Touchscreen buttons avoid
sticky mouse-hover/focus highlights; the chosen instrument remains selected.

## Headless checks

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/soundfonts.gd
godot --headless --path . --script res://tests/layout.gd
godot --headless --path . --script res://tests/formulas.gd
godot --headless --path . --script res://tests/practice_sessions.gd
godot --headless --path . --script res://tests/practice_info.gd
godot --headless --path . --script res://tests/classes_09_10.gd
godot --headless --path . --script res://tests/classes_11_12.gd
godot --headless --path . --script res://tests/class_13.gd
godot --headless --path . --script res://tests/class_14.gd
godot --headless --path . --script res://tests/classes_15_16.gd
godot --headless --path . --script res://tests/class_17.gd
godot --headless --path . --script res://tests/class_18.gd
godot --headless --path . --script res://tests/final_masterclasses.gd -- --source-dir=/path/to/digital-handbook/curriculum
godot --headless --path . --script res://tests/curriculum_coverage.gd -- --source-dir=/path/to/digital-handbook/curriculum
godot --headless --path . --script res://tests/missing_tones.gd
godot --headless --path . --script res://tests/progress_file.gd
godot --headless --path . --script res://tests/navigation.gd
```

The smoke test opens every practice, checks keyboard answers, and exercises
the SoundFont player. The SoundFont test loads all three instruments, checks
all 49 pitches used by lessons, captures non-silent audio, and tests chords,
note releases, and instrument switching. Neither test modifies saved progress
or instrument preferences. Check the output for script errors as well as the
final success message.

## Formula-based practices

Classes 5–7 now generate challenges from explicit note, spacing, presentation,
and response rules rather than fixed example batches. Classes 8–10 add white-key
interval naming, expanded team note collections, and recall practice. Classes
9–10 include guitar-source major-chord cue naming as a disclosed synthesized
adaptation. Existing numeric
practice IDs are retained; class 0 still tests legacy batches.

Use **Practice info / source** inside a migrated drill to see its permanent
source-practice ID, instructions, correction/completion rules, original recording
timestamps, and disclosed app adaptations. **Open source recording** opens the
lesson's external video at the first cited timestamp; it requires network access.
The Info button uses the original artwork and opens a full-page information
screen, not a system popup. Its back arrow and Android Back return to the same
exercise with the current question, score, keyboard input and scroll position
preserved. Audio stops while the instructions are open.
No original recordings or transcripts are bundled. Source interpretations are
text-supported and have not been independently audio-verified.

Singing/recall sessions use explicit self-reported correct/incorrect controls;
the app does not assess a microphone signal. Naming uses checked pitch-class
input. Meditation without a source verification round uses an explicit Finish
button, not an invented numeric target. Revised formula progress is tracked
separately from old counters, which remain stored but cannot establish correct
performance on the revised exercises. See [docs/CURRICULUM.md](docs/CURRICULUM.md)
for mappings, formula/session schemas, and limitations.

Classes 11–12 add wide/close white and black naming, full-scale recall/team work,
and source-linked guitar cue exercises. **Manual** entries provide instrument or
partner instructions without pretending to assess them. **Pending** entries have
no guessed note pool, cannot be logged as completed, and remain visibly unresolved.
Logging a manual session records participation, not a source verification round.
Speed and duration variations stay manual because no numerical tempo or duration
is established by the source. Transposing-instrument work stays manual until a
written/concert-pitch configuration exists; the ambiguous class-12 guitar team
collection is deferred. See the curriculum document for exact coverage.

Class 13 uses a separate **open meditation guide**, not a scored naming quiz.
Navigation, collection/root changes, and optional random selection are silent;
only **Play tone** sounds a reference. The bottom-anchor plan follows the described
chromatic comparisons through the upper octave and back to the anchor. The
top-anchor octave window is an app boundary, not a source-prescribed endpoint.
Keyboard collections can be switched from white to black to mixed without a
fabricated readiness score. First-tone recall starts without automatic playback.
Finishing records an open session, not accuracy or completion of a required quota.
Physical guitar technique, flexible chord adaptations, normal music follow-up,
and the instructor's original demonstration remain source-linked manual guidance.

Class 14 adds four-tone singing/naming, cue exercises, and a mixed four-white/
one-black pattern. Only an entirely correct, unassisted five-tone pattern earns
credit. Ten such patterns form a round; three rounds complete the app task.
The source does not settle whether an error erases earlier correct patterns:
the disclosed app policy discards the current pattern but retains previous ones,
including across sessions. This is not a 150-consecutive-answer streak.
A/D-reference blocks and extra uncued targets use separate open sequence screens.
Team variants have unique `practice_uid` values while retaining their shared
source-assignment ID. Four-tone generators allow octave-equivalent pitch classes
at different MIDI pitches; naming validates every response, including the fourth.

Class 15 contains readiness guidance, not a fabricated test or health regimen.
Class 16 provides separately named fixed major-cue drills, open guitar cue work,
and restricted diminished-seventh recognition forms. Cue blocks are not randomly
mixed into a different exercise. Meditation doubles have a learner-selectable
**Check: sequence / Check: together** control because the source does not settle
that detail; switching the control is silent and does not alter the saved
curriculum. Speed recognition and partner grounding remain manual guidance,
without invented BPM, deadlines, or turn quotas. Local completion ambiguities
and inherited round-size conventions remain visible in Info.

Class 17 uses three-white/one-black patterns (four responses per pattern), black
harmonic fours with permitted octave duplicates, A/G-reference cycles, and the
new F-sharp or C-natural meditation additions. Its team-continuation scope is
unclear: required guidance preserves that uncertainty, while five open examples
per extended collection are explicitly optional app adaptations. Optional entries
are labeled and do not block class completion. They do not inherit an invented
verification quota or silently reuse the earlier diminished four-note set.

Class 18 extends the mixed cycle to three harmonic white doubles followed by
either a black single or black double. Credit belongs to the complete four-example
pattern, not to individual notes. The reference cycle now supports A/D/G blocks.
Neighbor assistance can step up or down by semitones for a selected target,
excluding cue notes and without restricting comparison notes to the target pool.
The cumulative walk, MIDI boundaries, optional original-tone replay, and exclusion
of helped attempts from verification are disclosed app choices. Required guidance
retains the meditation-versus-identification ambiguity; related open examples are
optional and do not turn unknown source quotas into mandatory scores.

### Complete numbered course

All numbered classes **1–24** are loaded. New classes 19–24 live separately under
`curriculum/`, referenced by `external_masterclasses` in `masterclasses.json`.
`external_practice_supplements` adds source-linked live-instrument, drawing,
reading, and partner assignments that earlier classes previously mentioned only
in comments. Manual entries are explicit guidance, not automated assessments.
Existing numeric IDs and saved legacy records are retained.

Later lessons include separate diminished collections, explicit mixed-color
patterns, color-constrained triples, and generated missing-tone scale/cluster
questions. Ten sung tones is modeled as an **attempt count**, not ten consecutive
correct answers. Unspecified quotas, reference cycles and trial formats remain
open or manual; related app-chosen variants are labeled optional.

The final spaced-recall task retains a streak of **20 checked, self-reported
correct recalls** across visits. It requires Check before reporting and records
one attempt per visit, with local timestamps. Incorrect resets the streak. It
does not enforce a made-up minimum interval, measure singing, prescribe a cents
tolerance, or certify absolute pitch. Progress is written through a same-directory
temporary snapshot with a previous `.bak` snapshot; a recovered backup may omit
the latest attempts. No original audio is bundled.

Read [docs/CURRICULUM_COVERAGE.md](docs/CURRICULUM_COVERAGE.md) for the complete
source-assignment audit and unresolved variants, plus
[docs/CLASSES_19_21.md](docs/CLASSES_19_21.md),
[docs/CLASSES_22_24.md](docs/CLASSES_22_24.md), and
[docs/SOURCE_GUIDANCE.md](docs/SOURCE_GUIDANCE.md).

Recheck coverage against your local source specifications:

```sh
python tools/audit_curriculum.py --source-dir /path/to/digital-handbook/curriculum --write
```

Coverage means an assignment is represented with source evidence; it is not a
claim that manual or pending work is automated, or that the machine transcripts
have been audio-verified. Five ambiguous class-12 guitar-team variants remain
explicitly pending without a guessed note pool. Supplementary recordings remain
in the source archive; this curriculum targets the 24 numbered master classes.
See [docs/FINAL_VALIDATION.md](docs/FINAL_VALIDATION.md) for the tested scope,
handoff details and remaining limitations.

Class 9 sixths also require the learner's explicit familiarity confirmation after
the numerical round. The A-/B-major cue practices use two separate rounds of
twenty: a later error resets the current round, not a previously completed round.
Harmonic right-notes/wrong-order responses in classes 9–10 receive a reordering
hint; melodic naming must still follow the played sequence. None of these rules
establishes microphone-assessed singing or audio-verified source interpretation.

The layout test checks three portrait sizes, including the 1080×2412 phone
aspect ratio, full-page heading movement, touch-emulated swipes from the page
padding, and single-scroll comments. Also check an exported resource pack: export conversion can
change inherited Control layouts even when the source scene works:

```sh
godot --headless --path . --export-pack Android /tmp/pitch-layout.pck
godot --headless --path . --main-pack /tmp/pitch-layout.pck --script "$PWD/tests/layout.gd"
```

If inherited layouts remain stale after a scene change, clear the generated
`.godot/exported/` cache and export again.

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
godot --headless --path . --export-debug Android apk/perfect_pitch_trainer_2.0.0-debug.apk
```

The debug APK has been built with Godot 4.7.2 and checked for valid signing,
ZIP alignment, and inclusion of all three SoundFonts. It targets ARM32/ARM64
devices with Android 7.0 or newer. Device playback and release signing have not
been validated. The unfinished Experiments screen does not automatically
activate the microphone.

## Desktop builds

Install the Godot 4.7.2 Linux and Windows export templates. Both presets produce
standalone x86_64 executables with the game data and SoundFonts embedded:

```sh
mkdir -p builds/linux-x86_64 builds/windows-x86_64
godot --headless --path . --export-release "Linux x86_64"
godot --headless --path . --export-release "Windows x86_64"
```

- Linux: `builds/linux-x86_64/perfect_pitch_trainer_2.0.0.x86_64`
- Windows: `builds/windows-x86_64/perfect_pitch_trainer_2.0.0.exe`

Linux startup is tested locally; Windows startup is tested under Wine, not on
a native Windows machine. The Windows executable is unsigned. Check the
SoundFonts' redistribution licenses before sharing either build publicly.
The `builds/` directory is ignored by Git and excluded from all exports.

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
