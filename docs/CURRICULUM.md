# Formula curriculum and source mapping

`masterclasses.json` replaces the nine real static drills in masterclasses 5–7
with formulas, adds the missing class 6 close two-tone drill, and adds class 8.
Class 0 remains an unchanged legacy fixture, including its `practiceBatch`
and historic `anwser` spelling. No audio or full transcripts are bundled.

## Sources and review status

The source specifications are `digital-handbook/curriculum/master-class-05.json`
through `master-class-08.json` in the source handbook workspace. Each generated
drill has a `source_practice_id` matching the specification's stable string ID.
Its `info` preserves the source purpose, lesson/audio identifiers, source time
windows, and `text_supported_audio_unverified` review status. These references
identify evidence; they do **not** imply that the audio has been independently
checked. Class 8's player points to source video `qBSU79M_Hmk`.

`source_instructions`, `correction`, `completion`, `implementation_decisions`,
and `uncertainties` are copied from the corresponding spec, with explicitly
labeled app decisions appended where needed. These fields also appear inside
`info`, so the Info UI can display actual instructions and qualifications,
not just a summary. `completion` records the source rule; `session` records
the app's executable completion policy. A source practice ID is provenance,
not an alternative numeric progress identity.

## Formula schema and runtime contract

Every formula has these explicit fields:

| Field | Meaning |
| --- | --- |
| `pitch_classes` | Array of MIDI pitch classes, C = 0 through B = 11. |
| `midi_min`, `midi_max` | Inclusive absolute MIDI bounds; currently 36–84. |
| `note_count` | Number of notes per example, 1–3. |
| `selection` | `single`, `white_third`, `white_second`, or `distinct`. |
| `min_span`, `max_span` | Inclusive limits on highest minus lowest MIDI note, in semitones; defaults 0 and 48. |
| `presentation` | `simultaneous` plays one chord; `sequential` plays individual notes in order. |
| `direction` | `ascending`, `descending`, or `random` presentation order. It does not turn a simultaneous chord into a sequence. |
| `response` | `sing`, `name`, or `recall`. |
| `answer_order` | `ascending_pitch` or `presentation_order`. |

`white_second` selects adjacent white keys; `white_third` selects white keys
with exactly one intervening white key. These are diatonic relationships, not
fixed chromatic intervals. `distinct` selects distinct **absolute MIDI notes**:
two notes may share a pitch class in different octaves. Distinct does not mean
distinct pitch classes. MIDI bounds, pitch-class membership, note count and
span constraints all apply to the selected example.

The runtime generates examples rather than indexing the old packaged batches.
Sequential melodic doubles use presentation-order answers; harmonic naming
and sung unlocking use original bottom-up pitch order. Naming is listening
and naming, **not singing**. Recall presents a named target without sounding
it first: imagine, sing, then play a reference to check. The finite playback
register is not an octave-specific requirement on the user's voice.

`session` is `{kind, target, assessment}`:

- `kind: "consecutive"`, `target: 20`: twenty consecutive correct examples,
  with an error resetting the streak. Assistance is training, not credited
  verification. `maxHits` remains 20 for compatibility.
- `kind: "open"`, `target: 0`: no invented numeric threshold; `maxHits` is 0.
  An explicit Finish saves completion of the app session, not proof of a
  historical verification round or mastery of absolute pitch.
- `assessment: "self_report"`: singing/recall is checked by the learner;
  neither Next nor reference playback establishes correctness. No automatic
  microphone grading or cents tolerance is implied.
- `assessment: "keyboard"`: entered note names are checked by the app for
  naming drills; this does not assess a sung performance.

Formula-specific progress identities isolate revised exercises from old
counters while retaining the legacy saved data. The runtime, not this JSON,
implements generation, answer validation, self-report controls, explicit open
session completion, and progress storage.

## Stable numeric IDs and coverage

Existing masterclass and practice numeric IDs are preserved. The old batches'
individual example IDs disappear only from the nine converted real drills;
class 0 retains them. Do not renumber practices to match the source p-number.

| App class/practice | Source practice | Definition |
| --- | --- | --- |
| 5/2 | master-class-05-p01 | Simultaneous white thirds; sing bottom-up; open. |
| 6/2 | master-class-06-p01 | Simultaneous adjacent white seconds; sing. |
| 6/3 (new) | master-class-06-p03 | Two chromatic notes close, span ≤12; sing. |
| 6/4 | master-class-06-p05 | Two chromatic notes wide, span ≥13; sing. |
| 6/5 | master-class-06-p07 | Three chromatic notes close, span ≤12; sing. |
| 6/6 | master-class-06-p09 | Three chromatic notes wide, span ≥13; sing. |
| 7/2 | master-class-07-p01 | Name single white notes. |
| 7/3 | master-class-07-p04 | C/D/E recall meditation; open. |
| 7/4 | master-class-07-p07 | C/D/E sequential random doubles; name in played order. |
| 7/5 | master-class-07-p08 | C/D/E simultaneous doubles; name bottom-up. |

Both 7/4 and 7/5 now correctly use `PITCH_NAMING_DRILL`; legacy questions
had confused melodic and harmonic presentation and/or sung versus named
responses. In particular 6/2 and 7/2 no longer use unintended chromatic pools.
Other class 6 singing and class 7 naming drills use twenty-consecutive sessions.

Class 8 numeric IDs are deliberately independent of source numbering:

| Practice | Source | Coverage |
| --- | --- | --- |
| 0 | lesson audio | Player. |
| 1 | lesson coverage, p04/p05 | Comments, uncertainty, manual capo instructions. |
| 2, 3, 4 | p01, p02, p03 | Ascending, descending, then strict harmonic white-third naming. |
| 5 | p08 | C/D/E/F recall meditation, twenty consecutive self-reported correct. |
| 6, 7, 8 | p10, p11, p12 | C/D/E/F team singles, melodic doubles, harmonic doubles. |
| 9, 10, 11 | p13, p14, p15 | A/B/C#/D team equivalents. |
| 12, 13 | p07, p06 | Opening C and A recall respectively; open sessions. |
| 14 | p09 | A/B/C#/D recall meditation, twenty consecutive self-reported correct. |

All source p-numbers in the class 8 table have prefix `master-class-08-`.
There are **23 formula drills**: nine converted, one new class 6 drill and
thirteen class 8 drills. The class 8 lesson contains fifteen practices total,
including player and comments. This is not a claim of complete automated
coverage of the earlier lessons or of physical guitar-string recognition.

## App adaptations and limitations

- MIDI 36–84 is a finite app playback range, not an exact range prescribed by
  these lessons. Timing, distribution and response deadlines are not source
  claims. Random sequential order is a product choice, not a recovered full
  stimulus sequence.
- Close keyboard work is defined physically as one-hand reach in the source.
  The inclusive twelve-semitone maximum in 6/3 and 6/5 is a disclosed one-hand
  approximation, not an exact quotation or universal hand-span model.
- Two-wide is explicitly greater than an octave, hence minimum span 13.
  Three-wide directly prescribes two notes in one hand and one in the other;
  the same numeric minimum in 6/6 is a transparent contextual interpretation,
  not a separately stated three-wide cutoff. Its twenty-correct rule follows
  the source session convention rather than a locally repeated count.
- Distinct MIDI-note sampling excludes exact unison repeats but permits
  octave duplicates. The source does not specify an exhaustive repeat-note
  or randomization policy for team examples.
- Synthesized playback and keyboard entry replace instrument/partner actions.
  Physical one-/two-hand placement and guitar technique are not simulated.
  Keyboard entry checks names; self-report checks subjective singing accuracy.
- Class 8 strict harmonic thirds are required for the credited round. Rocking
  tones back and forth is optional assistance, not a separate passed drill.
- Class 8 capo work is manual in comments: make the E string sound F, determine
  all new sounding string pitches, practice random singles then simultaneous
  pairs until familiar; then repeat with E sounding A. No fret number, full
  shifted tuning, or twenty-correct gate is invented.

## Historical progress caution

Preserving old data and numeric IDs does **not** establish historical
correctness. Earlier counters may represent Next clicks, wrong pools,
reversed presentation, or an incorrect response mode. Mark legacy progress as
legacy/unverified; never silently reinterpret it as twenty consecutive
correct answers to the revised formula. Open-ended introductory singing and
recall must not acquire an invented twenty-correct prerequisite through
migration. Retain old records for history while tracking revised formulas
separately.

## MC9–10 extension: current counts and source mapping

This appended section extends (and updates the totals in) the historical
MC5–8 coverage above without renumbering or replacing any earlier practice.
The added authorities are the source handbook's
`digital-handbook/curriculum/master-class-09.json` and
`digital-handbook/curriculum/master-class-10.json`, not older Python reports.
Their status remains `text_supported_audio_unverified`; audio has not been
independently verified. Players use source videos `yvqndQRUzFs` (MC9) and
`LaZDtxJQxb4` (MC10). No audio or full transcripts are bundled.

There are now **60 formula drills**: the existing 23 plus **12 MC9** and
**25 MC10** drills. MC9 contains **14 practices total** and MC10 contains
**27**, including each lesson's player (0) and comments (1). All 37 new
source practice IDs are individually exposed, including the guitar-oriented
recall/team pools and both chord-cue drills. New source `pNN` maps to numeric
practice `NN + 1`; this rule applies only to the new classes and does not
renumber MC5–8. Source Info base fields are preserved exactly, and source
instructions, correction, completion, implementation decisions and uncertainties
are mirrored inside `info` as well as at practice level. App decisions are
appended to the source implementation decisions, not substituted for them.

| App class/practice | Source practice | Coverage |
| --- | --- | --- |
| 9/0, 9/1 | Lesson audio / coverage | Player and comments. |
| 9/2 | master-class-09-p01 | Ascending melodic white sixths; name in played order. |
| 9/3 | master-class-09-p02 | Descending melodic white sixths; name in played order. |
| 9/4 | master-class-09-p03 | Strict simultaneous white sixths; name bottom-up. |
| 9/5 | master-class-09-p04 | C/D/E/F/G single-tone recall meditation. |
| 9/6 | master-class-09-p05 | A/B/C#/D/E single-tone recall meditation. |
| 9/7 | master-class-09-p06 | A-major cue before each single chromatic target; name target; two rounds. |
| 9/8 | master-class-09-p07 | C/D/E/F/G team melodic singles. |
| 9/9 | master-class-09-p08 | C/D/E/F/G team melodic doubles. |
| 9/10 | master-class-09-p09 | C/D/E/F/G team harmonic doubles. |
| 9/11 | master-class-09-p10 | A/B/C#/D/E team melodic singles. |
| 9/12 | master-class-09-p11 | A/B/C#/D/E team melodic doubles. |
| 9/13 | master-class-09-p12 | A/B/C#/D/E team harmonic doubles. |
| 10/0, 10/1 | Lesson audio / coverage | Player and comments. |
| 10/2 | master-class-10-p01 | White seconds, ascending melodic. |
| 10/3 | master-class-10-p02 | White seconds, descending melodic. |
| 10/4 | master-class-10-p03 | White seconds, strict harmonic. |
| 10/5 | master-class-10-p04 | White fifths, ascending melodic. |
| 10/6 | master-class-10-p05 | White fifths, descending melodic. |
| 10/7 | master-class-10-p06 | White fifths, strict harmonic. |
| 10/8 | master-class-10-p07 | White fourths, ascending melodic. |
| 10/9 | master-class-10-p08 | White fourths, descending melodic. |
| 10/10 | master-class-10-p09 | White fourths, strict harmonic. |
| 10/11 | master-class-10-p10 | White sevenths, ascending melodic. |
| 10/12 | master-class-10-p11 | White sevenths, descending melodic. |
| 10/13 | master-class-10-p12 | White sevenths, strict harmonic. |
| 10/14 | master-class-10-p13 | B-major cue before each single chromatic target; name target; two rounds. |
| 10/15 | master-class-10-p14 | C/D/E/F/G/A single-tone recall meditation. |
| 10/16 | master-class-10-p15 | A/B/C#/D/E/F# single-tone recall meditation. |
| 10/17 | master-class-10-p16 | C/D/E/F/G/A team melodic singles. |
| 10/18 | master-class-10-p17 | C/D/E/F/G/A team melodic doubles. |
| 10/19 | master-class-10-p18 | C/D/E/F/G/A team harmonic doubles. |
| 10/20 | master-class-10-p19 | C/D/E/F/G/A team melodic triples. |
| 10/21 | master-class-10-p20 | C/D/E/F/G/A team harmonic triples. |
| 10/22 | master-class-10-p21 | A/B/C#/D/E/F# team melodic singles. |
| 10/23 | master-class-10-p22 | A/B/C#/D/E/F# team melodic doubles. |
| 10/24 | master-class-10-p23 | A/B/C#/D/E/F# team harmonic doubles. |
| 10/25 | master-class-10-p24 | A/B/C#/D/E/F# team melodic triples. |
| 10/26 | master-class-10-p25 | A/B/C#/D/E/F# team harmonic triples. |

### New formula and session contracts

- `selection: "white_interval"` with `white_steps` selects two white keys
  separated by that many diatonic steps, not a fixed semitone distance. MC9's
  first three drills use **5 steps: sixths**, not thirds. MC10's first twelve
  drills use **1, 4, 3, 6 steps** in groups of three: seconds, fifths, fourths,
  sevenths. Each group presents ascending sequential, descending sequential,
  then strict simultaneous pairs. Answers name pitches, not interval quality;
  melodic answers follow played order, harmonic answers are lower-first.
  B–F remains eligible in the white-fifths group. Source examples are not a
  fixed pool or an additional compulsory sequence between interval families.
- Team `note_count` is the source singles/doubles/triples count. Melodic
  presentation is sequential with random direction; harmonic presentation is
  simultaneous with lower-first answers. `distinct` retains the existing
  adaptation: distinct **absolute MIDI notes**, allowing octave-duplicate pitch
  classes but excluding the same exact MIDI note within an example. Source
  repeat policy, precise register and randomization distribution are unspecified.
- Cue drills use all twelve pitch classes, `selection: "single"`, one target
  and `response: "name"`. `cue_midi: [57, 61, 64]` (A3/C#4/E4) for MC9 and
  `[59, 63, 66]` (B3/D#4/F#4) for MC10 precede every new target. These are
  **app voicings**, not recovered physical guitar shapes. MC9 permits any
  A-major voicing and demonstrates A/E/A/C#/E; the app does not claim to
  reproduce that demonstration. MC10 specifies no B-major voicing. The cue is
  not part of the target answer; targets are not restricted to a major scale.
- Cue sessions are `{kind: "consecutive", target: 20, assessment: "keyboard",
  rounds: 2}`. These mean **two separately tracked twenty-correct rounds**,
  not forty uninterrupted correct answers. An error restarts the current
  round. `maxHits` remains **20 for every new drill**, including cues; separate
  round progress belongs to the runtime, not a fabricated `maxHits: 40`.
  All other new sessions explicitly use `rounds: 1` (the default).
- MC9 p01–p03 also set `requires_familiarity: true`: explicit confirmation of
  comfort/ownership of the sounds is required beyond the twenty-correct streak.
  Loose harmonic sixths are optional assistance before strict simultaneous
  verification, not a fourth source drill or credited assisted example.
- Every harmonic naming drill in MC9–10 sets
  `allow_harmonic_reordering: true`. Correct pitch classes in the wrong order
  receive a “right notes, wrong order” hint and an opportunity to reorder,
  rather than immediately counting as an error. Bottom-up order is still the
  required final answer (MC9 segments 3–8). The runtime implements this policy.
- Meditation is single-note `response: "recall"`, with consecutive target 20,
  one round and `assessment: "self_report"`: imagine before reference playback,
  sing, check, then self-report. MC9 uses C/D/E/F/G and A/B/C#/D/E; MC10 adds A
  and F# respectively. The twenty-correct rule is **inherited**: the current
  lessons say continue/add a tone rather than restating the meditation round
  count. This uncertainty is retained in each practice and its Info. No numeric
  singing tolerance or octave-specific vocal requirement is supplied.

All new drills retain the disclosed finite MIDI 36–84 playback range, not a
source-prescribed range. Synthesized playback, keyboard naming and random
sampling are digital-partner adaptations, not physical guitar technique or
claims about original timing, distribution, instrument reach or vocal thresholds.
MC10 source harmonic team assignments require simultaneous-tone capability;
single-tone instrumentalists may omit harmonic examples. The app can play these
examples, but does not erase that source accommodation. Runtime behavior and
separate-round/familiarity progress storage are implemented outside these data
and documentation files.

## MC11–12 extension: complete source exposure, qualified implementation

This appended section updates the historical totals above without replacing
earlier content or renumbering earlier classes. Authorities are the source
handbook's `digital-handbook/curriculum/master-class-11.json` (26 assignments)
and `master-class-12.json` (28 assignments). Their review status remains
`text_supported_audio_unverified`; source windows and evidence quotes are not
independent audio verification. Players use the source video IDs extracted from
the source audio filenames. No audio or full transcripts are bundled.

All **54 source assignments** have individual stable `source_practice_id`
values. In each new class player is numeric 0, comments 1, and source `pNN`
maps to numeric **NN + 1**. MC11 has **28 entries** including 22 formulas and
4 manual-guidance entries; MC12 has **30 entries** including 18 formulas,
5 manual-guidance entries and 5 deferred entries. Thus these classes add
**40 executable formulas**, **9 manual-guidance assignments**, and **5 deferred
assignments**, bringing the historical 60-formula total to **100 formulas**.
Complete source exposure does not mean complete automatic verification.

Each entry preserves every original base `info` field exactly and also carries
an exact base copy in `sourceInfo`. Source instructions, correction, completion,
evidence, audience, materials, presentation, response and prerequisites are
copied at practice level and mirrored into `info`. Source implementation
decisions and uncertainties are retained, with explicit app adaptations and
qualifications appended rather than substituted. This applies to guided and
deferred entries too: their Info must show the written note set or unresolved
null guitar set, and the original source completion criterion even when the
app cannot verify it. The source SHA-256 is retained for provenance.

### MC11 coverage

| Source practice(s) | Numeric practice(s) | Coverage |
| --- | --- | --- |
| p01–p03 | 2–4 | White doubles: harmonic, ascending melodic, descending melodic; close and wide allowed. |
| p04–p05 | 5–6 | One-hand white triples, harmonic and random melodic; span ≤12 is an approximation. |
| p06–p07 | 7–8 | Two-hand white triples, harmonic and random melodic; broad span 0–48. |
| p08 | 9 | Synthesized single A-string cue `[45]`, then any chromatic target. |
| p09 | 10 | C#-major cue `[61,65,68]`, then any chromatic target. |
| p10 | 11 | D#-major cue `[63,67,70]`, then any chromatic target. |
| p11 | 12 | C-major meditation, all seven tones including B: pitch classes `[0,2,4,5,7,9,11]`. |
| p12 | 13 | A-major meditation, all seven tones including G#: `[9,11,1,2,4,6,8]`. |
| p13–p17 | 14–18 | C-major team singles, melodic doubles, harmonic doubles, melodic triples, harmonic triples. |
| p18–p22 | 19–23 | A-major team equivalents in the same order. |
| p23–p24 | 24–25 | Manual long-sustaining and short-sounding partner variations. |
| p25 | 26 | Manual uninterrupted constant-speed recognition; no invented numerical BPM. |
| p26 | 27 | Manual ordinary instrument playing after ear training; no invented minimum duration. |

All source IDs in this table have prefix `master-class-11-`. White doubles
use unrestricted span 0–48 within the app register because the source explicitly
permits closer spacing; their title does not justify a mandatory wide cutoff.
Two-hand triples similarly have no invented minimum span or hand allocation.
The transcript's C# / D# major chord names remain explicitly uncertain pending
audio review. Their close-position synthesized voicings are app choices, not
claims about source guitar shapes or fingerings.

### MC12 coverage

| Source practice(s) | Numeric practice(s) | Coverage |
| --- | --- | --- |
| p01 | 2 | Black singles. |
| p02 | 3 | One-hand black harmonic doubles, approximate span ≤12. |
| p03 | 4 | Wide black harmonic doubles, contextual span ≥13. |
| p04–p05 | 5–6 | Black ascending and descending sequential doubles. |
| p06–p07 | 7–8 | One-hand black triples, harmonic and random melodic, approximate span ≤12. |
| p08–p09 | 9–10 | Two-hand black triples, harmonic and random melodic, broad span 0–48. |
| p10–p14 | 11–15 | Nontransposing team singles, melodic doubles, harmonic doubles, melodic triples, harmonic triples. |
| p15–p19 | 16–20 | Manual transposing-instrument team equivalents; written/concert offset is not implemented. |
| p20–p24 | 21–25 | Deferred A-based team-guitar equivalents; five-tone pool is unresolved and not guessed. |
| p25 | 26 | Synthesized single D-string cue `[50]`, then any chromatic target. |
| p26 | 27 | F#-major cue `[54,58,61]`, then any chromatic target. |
| p27 | 28 | G#-major cue `[56,60,63]`, then any chromatic target. |
| p28 | 29 | A#-major cue `[58,62,65]`, then any chromatic target. |

All source IDs in this table have prefix `master-class-12-`. The executable
black-key branch uses only pitch classes **`[1,3,6,8,10]`**; white keys are not
mixed into this assignment. The source prefers C#, F#, Eb, Ab, Bb and permits
enharmonic names. Written names on transposing instruments need not sound as
concert black keys: manual guidance requires the actual instrument and its
written/concert offset, not an assumed automatic concert-pitch conversion.
The unknown A-based guitar complement remains null in the copied materials.

The wide harmonic-double minimum of 13 is explicitly a contextual interpretation
of preceding greater-than-an-octave wide-double work, not a newly quoted numeric
cutoff. Two-hand triples do not inherit an invented mandatory wide minimum.
F#-, G#- and A#-major cues are **major**, not copied legacy minor voicings.
Their enharmonic app pitches represent F#/A#/C#, G#/B#/D#, and A#/C##/E#;
keyboard names may display B# as C, C## as D and E# as F. These finite app
voicings are not source-prescribed physical guitar shapes. Single-string cues
are synthesized references, not recordings or real-string recognition tests.

### Completion, guided acknowledgement and physical limitations

- Every formula uses MIDI 36–84, consecutive target 20 and `maxHits: 20`.
  Naming assessment is `keyboard`; meditation/recall assessment is
  `self_report`. Source round counts are copied, not flattened: MC11 solo
  keyboard and meditation require one round, team melodic one and team
  harmonic doubles/triples two. MC12 solo black-key and nontransposing team
  melodic drills require one round, team harmonic doubles/triples two.
- All seven new cue drills repeat their cue before every chromatic target and
  require two separately tracked twenty-correct rounds. This count is inherited
  from prior assignments, not explicitly repeated locally. Errors restart the
  current round, not all previously completed rounds. The cue is not an answer.
- Every harmonic naming formula sets `allow_harmonic_reordering: true`:
  correct pitch classes in the wrong order receive a hint and an opportunity
  to reorder before an error. Final harmonic naming remains bottom-up;
  sequential answers follow played order. Where not assigned ascending or
  descending, random melodic order is an app adaptation.
- All 14 non-formula entries use `practiceType: "GUIDED_PRACTICE"` and
  `maxHits: 1`. Nine have `implementation_status: "manual_guidance"` and
  `session: {kind: "manual", assessment: "self_report", target: 1}`.
  Five unresolved guitar assignments have `implementation_status: "deferred"`
  and `session: {kind: "deferred", assessment: "self_report", target: 1}`.
  None has a formula. Their retained source completion rules are documentary,
  not an executable app verification policy. A logged acknowledgement or guided
  session is not a passed verification round, verified performance or mastery;
  deferred menu entries remain pending, not completed formula drills.
- MC11 duration variations use medium dynamic and unlimited identification
  time; neither seconds nor response deadlines are specified. Speed practice
  is a separate uninterrupted run: do not stop or slow for missed names, say
  “don't know” and continue as needed. Numeric tempo, trial count and threshold
  are unknown; six tones is an example, not a required pool. Do not apply the
  ordinary stop-and-correct sequence during that run. Follow-up ordinary
  instrument playing has no invented duration requirement.
- One-hand span ≤12 is a disclosed numerical approximation, **not a universal
  physical reach guarantee**. Comfortable reach depends on the learner,
  fingering and instrument; do not force an uncomfortable stretch. Playback
  does not enforce actual hand placement, hand allocation, fingering,
  instrument technique or physical guitar voicing. Broad two-hand spans do not
  prove a particular example is ergonomically playable.
- Distinct sampling means distinct absolute MIDI notes, excluding exact repeats
  but permitting octave-duplicate pitch classes. The source does not specify
  repeat policy, precise register or randomization distribution. MIDI limits,
  keyboard entry and synthesized playback are app choices, not source timing
  or vocal thresholds. Recall means imagine before sounding, sing, check and
  self-report; no microphone grading or invented cents tolerance is claimed.
- Source harmonic tasks require simultaneous-tone capability; the continued
  accommodation permits single-tone instrumentalists to omit them. A digital
  partner's ability to play chords does not remove this qualification.

These changes are data and documentation only. Guided rendering, deferred
menu treatment, acknowledgement logging, formula generation and round/reordering
enforcement belong to the runtime; their implementation is not proof of source
audio verification or automatic assessment of manual instrument work.

## MC13 extension: learner-paced meditation, not verification

Authority: `digital-handbook/curriculum/master-class-13.json`. All **10 source
activities** are exposed with stable root `source_practice_id` values. Player is
0 and links to source video `rNSNEJNpw6U`; comments are 1; source `pNN` maps to
numeric **NN + 1**. MC13 therefore contains **12 entries**: player, comments,
**6 interactive meditation guides** and **4 manual guides**. It adds **zero
formulas**, leaving the preceding 100-formula total unchanged. Earlier classes
and their completion policies are not rewritten by this extension.

| Source practice | Numeric ID | Coverage |
| --- | --- | --- |
| p01 | 2 | Manual instructor C/D demonstration only; follow source audio, not a synthetic reenactment. |
| p02 | 3 | `listen_imagine`: basic known C/D listening and imagination; no required sung answer. |
| p03 | 4 | `keyboard_progression`: named white, black and mixed collections; learner-controlled stage changes. |
| p04 | 5 | Manual physical single-string guitar guidance; D string and partial fretboard are examples. |
| p05 | 6 | `bottom_anchor`: dynamic ascending comparisons, including the octave and final lower anchor. |
| p06 | 7 | `first_recall`: configurable current anchor, imagined and sung before any reference playback. |
| p07 | 8 | `top_anchor`: descending anchored comparisons within a disclosed bounded app window. |
| p08 | 9 | Manual flexible chord/interval adaptations, not a mandatory chord checklist or label quiz. |
| p09 | 10 | `random_recall`: self-selected named notes; optional user-requested random selection only. |
| p10 | 11 | Manual normal music practice after meditation; qualitative few minutes, not an exact timer. |

All table source IDs have prefix `master-class-13-`. Every assignment retains
its exact original base `info` values and an exact `sourceInfo` copy. Audience,
materials, presentation, response, instructions, correction, source completion,
evidence, prerequisites, decisions and uncertainties are retained at practice
level and in `info`. App adaptations are explicitly distinguished from those
source facts; the source SHA-256 is retained. All raw source material remains
**`text_supported_audio_unverified`**: windows and transcript quotations are
provenance, not independent listening verification.

### Configuration and completion contract

- Interactive entries use `practiceType: "MEDITATION_GUIDE"`,
  `implementation_status: "interactive_guidance"`, `maxHits: 0`, and
  `session: {kind: "open", target: 0, assessment: "self_report"}`. There are no
  numeric verification targets, compulsory repetitions, pass scores, graded
  vocal responses or verification rounds. The zero target means open-ended
  practice, not instant mastery. These entries contain neither `formula` nor
  `practiceBatch`; the runtime meditation algorithm uses `meditation` config.
  Finishing explicitly logs one user-ended session, not a score, passed set,
  quota or mastery claim.
- Manual entries use `practiceType: "GUIDED_PRACTICE"`,
  `implementation_status: "manual_guidance"`, `maxHits: 1`, and
  `session: {kind: "manual", target: 1, assessment: "self_report"}`. This single
  acknowledgement logs review/practice only, not verified performance or
  mastery. Source completion text stays documentary rather than becoming an
  executable numeric assessment.
- Every meditation has `mode`, `anchor_midi`, `midi_min: 48` and `midi_max: 84`.
  The default anchor is MIDI 60, except top-anchor MIDI 72. Registers, MIDI
  bounds and synthesized app playback are disclosed app choices, not source
  requirements. Own-instrument C may be a transposing-instrument C rather than
  concert C. Anchor controls allow the currently studied pitch to be selected.
- Playback/checks occur only on learner request: **no automatic reference** on
  entry, note changes or anchor changes; no forced silence interval, response
  deadline, microphone grading or cents tolerance. First recall begins in
  silence so the learner can imagine and sing before requesting the reference.
  A morning practice suggestion does not impose a schedule or days per root.
- Keyboard progression has stages `white`, `black`, `mixed` and corresponding
  runtime collections of pitch classes `[0,2,4,5,7,9,11]`, `[1,3,6,8,10]`, and
  all twelve. Config starts with `collection: "white"`; a learner button changes
  stage. Later recall uses `collection: "mixed"`. The only meditation config
  keys are `mode`, `anchor_midi`, `midi_min`, `midi_max`, and optional `collection`.
  Stage progression is subjective familiarity, not a scored gate;
  C/G/B motions remain examples rather than a required route.
- Bottom-anchor runtime comparisons through offset 12 represent the **explicit source octave**:
  dynamically generate anchor, anchor+1, anchor, anchor+2, …, anchor+12, anchor.
  The upper octave is a separate study tone and the lower anchor ends the set.
  This is a complete finite set, but there is **no compulsory set count** and
  no numeric mastery target. Changing anchor regenerates the sequence within
  app bounds; a chosen register must accommodate its octave.
- Top-anchor runtime comparisons through offset 12 form an **app-chosen bounded comparison window**,
  not a source endpoint or required complete octave set. The copied source
  `materials.lower_bound` remains null. The source only demonstrates C/B/C/Bb
  and continued descent; it does not prescribe the full lower limit, set count
  or verification criterion. Do not label the app window as the complete
  source-prescribed drill.
- Later recall preserves **self-selected named-note controls**, not mandatory
  generic random prompts. An optional random button is a user convenience;
  D/G#/B/C# are examples, not a compulsory pool. Reduce checks only with
  confidence; check when doubtful and never suppress needed checks or use a
  score threshold to remove all checking. Initial listen–imagine practice
  still finishes by playing after imagining to check.

Physical guitar string/fret work and chord/interval voicings remain manual.
The app does not enforce technique, invent mandatory fret limits, choose exact
unspecified fourth voicings, or turn every optional harmony into a passed task.
Normal music practice follows meditation without an invented numeric duration.
Only data and documentation are supplied here; rendering, named-note/anchor
controls, user-requested playback and dynamic meditation sequences belong to
the runtime implementation.

## MC14 extension: mixed patterns, shifting references and outside-scale tones

Authority: `digital-handbook/curriculum/master-class-14.json` in the source
handbook workspace. Player video: `T_H2Sn5RYz4`. Source review status remains
`text_supported_audio_unverified`; retained quotes/windows are evidence
references, not independently checked audio. No audio is bundled.

Class 14 contains **22 entries**: **20 source-activity entries** plus player
and comments. The twelve source activities are all exposed; p11 and p12 each
expand into five selectable team forms. There are **16 formula drills** (six
solo/meditation plus ten team), **two REFERENCE_PATTERN** entries, **one
MIXED_PATTERN**, and **one manual GUIDED_PRACTICE**. Existing classes, numeric
IDs, old `sourceInfo`, and app progress data are not replaced or migrated.

| App practice | Source suffix | Actual app form |
| --- | --- | --- |
| 0, 1 | player / comments | Lesson audio and coverage/limitations. |
| 2 | p01 | Manual ongoing tone-color listening guidance. |
| 3 | p02 | C–E–G–C cue, black single target; name; one round of 20. |
| 4 | p03 | Four white singles then one black; count successful patterns. |
| 5 | p04 | Four simultaneous white MIDI notes; unlock and sing bottom-up. |
| 6 | p05 | Same four-note harmonic task; name all pitches bottom-up. |
| 7 | p06 | A-major cue, two sequential chromatic targets; name; two rounds. |
| 8 | p07 | Three A-reference/target pairs then three D-reference/target pairs. |
| 9 | p08 | Same reference groups with one extra target after each; repeat. |
| 10 | p09 | Open single-tone recall: C major plus A flat. |
| 11 | p10 | Open single-tone recall: A major plus F natural. |
| 12 | p11 | Team C-major/A-flat singles. |
| 13 | p12 | Team A-major/F-natural singles. |
| 14–17 | p11 | Melodic double, harmonic double, melodic triple, harmonic triple. |
| 18–21 | p12 | Melodic double, harmonic double, melodic triple, harmonic triple. |

All source suffixes above have prefix `master-class-14-`. Base source pNN
maps to numeric NN+1; extra forms do not renumber those base entries. Every
new entry has a stable unique `practice_uid`. Single-variant activities use
the source ID itself; each expanded team source uses suffixes `-single`,
`-melodic-double`, `-harmonic-double`, `-melodic-triple`, `-harmonic-triple`.
Player/comments have their own lesson-scoped UIDs. `source_practice_id`
continues to identify provenance and deliberately repeats across team forms;
it must not be used alone to merge their progress. Numeric IDs and legacy
records remain intact; stable UIDs distinguish new selectable variants.

### Executable counting and open reference sessions

- p03 uses `mixed_pattern` with white pitch classes `[0,2,4,5,7,9,11]`, black
  classes `[1,3,6,8,10]`, `white_count: 4`, and MIDI 36–84. Its session is
  `{kind: "patterns", target: 10, rounds: 3, assessment: "keyboard",
  patterns_per_round: 10, error_policy: "discard_current_pattern"}`.
  An all-five-correct pattern earns one count; ten successful patterns make
  a verification round. **maxHits 30 counts patterns, not tones.** Correct an
  error and discard only the current pattern, retaining prior pattern and
  round counts. That retention is an explicit app policy: the source does
  not specify whether errors reset prior counts. No consecutive-pattern or
  consecutive-round requirement is invented. Unequal tone representation
  and taking more than one sitting remain allowed.
- p07/p08 use `reference_pattern` with `mode: "blocks"` / `"extra_targets"`,
  `cue_a_midi: 45`, `cue_d_midi: 50`, `targets_per_cue: 3`, and MIDI 36–84.
  Their scenes internally generate chromatic targets; no formula is needed.
  Both use `{kind: "open", target: 0, assessment: "keyboard"}` and maxHits 0.
  The p07 source endpoint has **six targets**: `(A,t) ×3; (D,t) ×3`.
  Whole-block replay is optional app practice, not a source cycling command.
  The p08 repeated cycle has **eight targets**:
  `A,t,A,t,A,t,t,D,t,D,t,D,t,t`, then returns to A. No score/round gate is
  added. Finish logs the app session; p08 mastery remains self-assessed.
- p09/p10 are open MEDITATION formula recall sessions with self-report,
  target/maxHits 0. Show the named target without playing it first; imagine,
  sing, and request a reference to check. No fixed repetition or accuracy
  threshold is imported into these ongoing meditation assignments.

### Source preservation and disclosed adaptations

Each activity preserves source Info base fields exactly in `sourceInfo` and
`info`; `info` additionally exposes audience, materials, presentation,
response, source instructions, correction, completion, evidence,
prerequisites and uncertainties. Source completion remains documentary;
`session` records app policy. App adaptations are separately labeled and
appended to implementation decisions. Team `variant` and `info.actual_form`
identify what the selected entry actually plays without rewriting the
broader source presentation. The source explicitly distinguishes the five
continued forms; separate entries, labels, random melodic order, and finite
sampling are app organization choices, not additional source assignments.

The standard meditation/team pool is `[0,2,4,5,7,8,9,11]`; the guitar pool is
`[9,11,1,2,4,5,6,8]`. Every team form, including singles, uses its full pool.
The guitar team transposition remains qualified: the team paragraph itself
names C major/A flat, while A major/F natural is inferred from “these same
tones” and the immediately preceding guitar meditation instruction.
Harmonic doubles/triples require two rounds; singles and melodic forms one.
Twenty-example sizes where unstated, consecutiveness, and current-round
reset behavior follow the disclosed inherited verification convention
(MC6 segments 104, 108–113), not newly stated class-14 rules. The p02 round
of 20 is explicit; p04/p05 each prescribe one round but omit its size, and
p06 prescribes two rounds but omits their size. Do not transfer the p03
pattern-counting rule to these exercises.

Formula targets use the inclusive finite app range MIDI 36–84, not a
source-prescribed register. `distinct` selects distinct absolute MIDI notes,
not distinct pitch classes: octave duplications are allowed. The white
harmonic fours span the broad range with no invented close/wide cutoff.
Singing is self-assessed and bottom-up, without microphone grading or vocal
octave requirements; naming is keyboard note-name entry, not singing.
Melodic answers follow played order; harmonic answers are bottom-up.
Cue registers `[60,64,67,72]` for C–E–G–C, `[57,61,64]` for A major, and
A2/D3 for the reference patterns are app voicings. Synthesized playback does
not assess instrument fingering, real guitar-string technique, or a
partner's performance. Random sampling and exclusion of exact repeated MIDI
notes within distinct examples are disclosed app choices.

Manual p01 adds no measurable color criterion or forced suppression of
relative pitch; acknowledgement records review, not performance. Source
carry-forward guidance remains attached to the lesson: practice daily,
relax and enjoy listening; optional two-session days must not tire the ear
or replace the next day's session. Instructor analogies and promises are
not additional exercises or scientifically validated app claims.

## Masterclass 15: readiness guidance, not a health test

Source `master-class-15.json` contains one guidance activity. Class 15 has
player 0 (video `sxJDC_P1TQE`), comments 1, and manual p01 at numeric ID 2.
There is no new note drill, tone collection, verification assignment, or
automatic reissue of earlier drills. Be rested and alert for ordinary
practice; general nourishment/exercise/recreation/relaxation/meditation
advice is not a prescribed regimen. Manual acknowledgement means only
review/practice, not a readiness score or health assessment. The lecture's
drug, brain damage, recovery, and eligibility claims remain attributed
instructor claims, not established medical facts. No abstinence task,
recovery timer, health test, or perfect-pitch eligibility gate is created.

## Masterclass 16: expanded references, doubles and diminished teams

Source `master-class-16.json` contains 13 source groups. Class 16 has **43
entries** (IDs 0–42): player 0 (video `iLccgkEvaoE`), comments 1, **38
formula activities**, and three manual partner activities. Base p01–p13
retain numeric IDs 2–14 respectively; **p13 is ID 14**, not an extra form.
Each activity has a unique `practice_uid`. `source_practice_id` and
`source_practice_group` group variants; `source_order` records the original
group order, not a new count or an invented prerequisite gate.

| Source group | Base ID | Extra IDs | Playable allocation |
| --- | --- | --- | --- |
| p01 white-root majors | 2: D | 15–19: E, F, G, A, B | Six major cues; black single targets `[1,3,6,8,10]` |
| p02 black-root majors | 3: C-sharp | 20–23: E-flat, F-sharp, A-flat, B-flat | Five major cues; white single targets `[0,2,4,5,7,9,11]` |
| p03 guitar majors | 4: D | 24–34: G, E, C, B, F, B-flat, C-sharp, E-flat, F-sharp, A-flat, A | All twelve roots exactly once; two sequential chromatic targets |
| p04/p05/p06 string references | 5/6/7 | None | G/B/E cues `[55]`/`[59]`/`[64]`, then one chromatic target |
| p07/p08 meditation doubles | 8/9 | None | Open recall with the two scale-plus-added-tone pools |
| p09 restricted standard team | 10: single | 35–38 | Melodic double/triple, harmonic double/triple |
| p10 restricted guitar team | 11: single | 39–42 | Melodic double/triple, harmonic double/triple |
| p11 speed / p12 standard grounding / p13 guitar grounding | 12/13/14 | None | Manual actual-partner guidance |

### Cues and completion policies

White/black refers to the **major-chord root**, not all chord tones. Every
major cue is a valid root-position triad with MIDI root `48 + pitch class`
and intervals `[0,4,7]`. The chosen register/voicing is an app adaptation.
`cue_midi` is a reference only and is never included in target answers.
Keyboard p01/p02 use one round of twenty consecutive examples per chord,
with errors resetting only the current round. This is the inherited
class-14 app convention (ultimately MC6 segments 104, 108–113), **not a
count/reset rule newly stated in class 16**. Source round counts and sizes
remain unknown/null in documentary `completion`.

Guitar p03 remains **open**: source completion is unspecified, so no
per-chord quota is invented. The required initial order is D, G, E, C;
the last eight roots in the table are merely the app's listing, because
the source permits any remaining order. Two randomly sampled chromatic
targets follow the fixed chord cue sequentially and are named in played
order. After the major assignment, G, B and E are separate open drills
in that order. High E / MIDI 64 is an app voicing choice: the source does
not say which E string it intends, and that uncertainty is preserved.

### Meditation and restricted team pools

Meditation p07 uses C major plus A-flat `[0,2,4,5,7,8,9,11]`; p08 uses
A major plus F-natural `[1,2,4,5,6,8,9,11]`. The guitar inheritance remains
qualified by the source uncertainty and its later scale reminder. Both
formulas select two distinct absolute MIDI notes, use random order and
`response: recall`, and remain open/self-assessed: imagine, sing, then
check. No target sounds before recall, no microphone grading is implied,
and no accuracy tolerance or quota is invented. `recall_check_mode` is
`sequential` by app default; `recall_check_modes` offers both `sequential`
and `simultaneous`, since the source does not settle melodic versus harmonic
doubles. These fields supply the UI's user-selectable check-mode contract.

Every p09/p10 form uses **only `[2,5,8,11]`**: D, F, A-flat/G-sharp, B.
The standard and guitar spellings are enharmonic, not different pools.
Singles and melodic doubles/triples are sequential; harmonic doubles and
triples are simultaneous and named bottom-up. There is **one app round
for every form, including harmonic forms**, not an automatic carry-over of
class 14's two-round harmonic rule. Source harmonic round-scope uncertainty
remains documented. Twenty-example size, consecutiveness and current-round
reset are explicitly inherited app conventions, not restated local facts.
Harmonic answer reordering hints are app assistance, not verified performance.

All formula targets use the finite app range MIDI 36–84. Random sampling,
span 0–48, and `distinct` absolute-MIDI selection are disclosed adaptations:
exact repeated MIDI notes are excluded within distinct examples, but octave
duplicates of a pitch class are allowed. Synthesized references do not
assess instrument fingering or physical guitar technique.

### Manual partner work and source retention

Speed recognition p11 requires an actual partner: once the diminished
drill is going quite well, use the same four tones fairly fast at an even
rate. Name immediately if known; otherwise let the tone pass without
stopping. Practice this occasionally and briefly; most work stays
unhurried. No BPM, response deadline, timed score, accuracy threshold, or
verification count is supplied or invented. Presenter/listener role
ambiguity remains in the source uncertainty.

Grounding p12/p13 also requires an actual partner and the previously
learned alternate pitch singing format: C major plus A-flat, or guitar
A major plus F-natural. The local source does not re-teach turn order;
the app invents no new turn rules, duration, count, or pass gate. Manual
acknowledgement records review/practice only. Avoid prolonged diminished
pattern listening, ground with the familiar scale, keep sessions short,
then return to instrument practice rather than compulsively identifying
every tone in daily life.

For classes 15–16, source `info` is copied exactly into `sourceInfo` and
retained as the base of the expanded `info`. Audience, materials,
presentation, response, source instructions, correction, completion,
evidence, prerequisites and uncertainties remain available at the activity
and Info levels. App adaptations are separately labeled and appended to
implementation decisions; source completion is never overwritten with
app session policy. Lesson carry-forward guidance, open questions, audio
names and SHA-256 provenance are retained. Review status remains
`text_supported_audio_unverified`, not a claim of independent audio review.
All pre-existing class 0–14 and More bytes are preserved by insertion;
this documentation section is append-only.

**Class 16 harmonic-round source clarification:** p09/p10 explicitly assign
one round to singles and melodic doubles/triples only. Harmonic round scope
is unresolved: “all the same as before” could alternatively inherit class
14's two-round harmonic rule. Neither one nor two harmonic rounds is newly
established by class 16. All ten variants retain the corrected source
instructions, completion and uncertainties, including `rounds_per_form:
null`, `single_and_melodic_rounds: 1`, `harmonic_rounds: null`, and
`items_per_round: null`. The runtime's one-round harmonic session is
**explicit app policy only**, not a source requirement or resolution of
that ambiguity; the alternative interpretation is disclosed in each
variant's Info adaptations.

**Class 16 display order versus identity:** numeric IDs are stable progress
identities, not menu positions. The practices array groups each source
assignment's variants contiguously: all six white-root cues precede all
five black-root cues; all twelve guitar chord cues (D, G, E, C, then the
remaining eight) precede G/B/E string drills; p09's five restricted forms
precede p10's five forms. Menu ID order is
`0,1,2,15–19,3,20–23,4,24–34,5,6,7,8,9,10,35–38,11,39–42,12,13,14`.
No ID is renumbered. Consumers/tests must not assume numeric sorting of
the array; source-group progression determines display order.

## Class 17: expanded collections and qualified team continuation

Class 17 maps the **11 source groups** in
`digital-handbook/curriculum/master-class-17.json` to **24 menu entries**:
player and comments; 3 manual guided activities; 2 opening-recall guides;
1 mixed-pattern activity; 1 reference-pattern activity; and 15 formulas
(5 source-core formulas and 10 **optional app examples**). Review status
remains `text_supported_audio_unverified`; no independent audio verification
is claimed. Each source-linked variant preserves the exact source ID and
`sourceInfo`, audio name, SHA-256, source order and source-group identity.
Its unique `practice_uid` distinguishes reused source IDs. Expanded `info`
retains source instructions, materials, evidence, correction, completion,
prerequisites and uncertainties; separately labeled adaptations are appended
to implementation decisions rather than replacing unknown source facts.

### Stable identities and source-group menu order

Player/comments retain IDs 0/1. Base source p01–p11 identities are IDs 2–12.
The second p09 opening-recall variant has ID 13; standard optional team
examples have IDs 14–18 and guitar optional examples IDs 19–23. The display
order is **`0,1,2,3,4,5,6,7,8,9,10,13,11,14,15,16,17,18,12,19,20,21,22,23`**.
Both opening-recall variants stay together, and each team's optional examples
immediately follow its required manual continuation guide. Source groups
remain contiguous. IDs are persistent identities, not sorted menu positions;
no existing class 0–16 or More content is reserialized or renumbered.

### Source-core keyboard, guitar and recall activities

- **p01 / ID 2:** manual partner speed recognition at a constant speed;
  answer immediately without deliberation. No BPM, timed score, deadline or
  verification target is invented. Class 16's skip rule is not locally
  restated. Logging participation does not verify recognition performance.
- **p02 / ID 3:** C-major cue followed by two **simultaneous** black-key
  targets from `[1,3,6,8,10]`, not successive singles. Source completion is
  one round of twenty. The cue `[60,64,67,72]` is the class-14 app voicing,
  including upper C; neither that doubled root nor its octave is prescribed
  by this local source. Allow the home-base feeling rather than forcing it
  away. Distinct absolute-MIDI selection and bottom-up naming are app policy.
- **p03 / ID 4:** **three white singles, one black single (3W1B)**, with
  white pool `[0,2,4,5,7,9,11]`, black pool `[1,3,6,8,10]` and
  `white_count: 3`. This is not the older modulo-five/four-white pattern.
  Three rounds of ten mean thirty complete four-tone patterns, forty tones
  per round; `maxHits: 30` counts patterns, not tones. The source mapping's
  ten-pattern interpretation is retained. The class-14 app policy discards
  only the current pattern after error/assistance, retaining earlier complete
  patterns and rounds; local correct-pattern/reset rules remain unspecified.
  Optional finger counting runs fourth, third, second, thumb, with thumb
  marking black. The runtime must use the generic `white_count + 1` length.
- **p04/p05 / IDs 5/6:** slow black harmonic fours, first unlock and sing,
  then identify actual tones. Four **distinct absolute MIDI notes** across
  MIDI 36–84 allow octave duplications of pitch classes; they are not four
  distinct pitch classes. One app round of twenty per version is inherited,
  not a newly specified local size. Singing count is not independently
  restated, the one-round-per-version reading is inferred, and singing
  direction/reset details remain unresolved. Bottom-up responses are an app
  convention; singing is self-reported, not microphone graded.
- **p06 / ID 7:** open guitar reference pattern
  `A,t,A,t,A,t,t,G,t,G,t,G,t,t`, repeating with three alternating targets plus
  one extra uncued target per block. This is **A/G, not A/D**. Configuration
  uses `mode: extra_targets`, `cue_a_midi: 45`, `cue_b_midi: 55`, labels `A`
  and `G`, `targets_per_cue: 3`, and random chromatic targets MIDI 36–84.
  Open keyboard assessment imposes no verification quota or mastery score.
- **p07/p08 / IDs 8/9:** open meditation doubles add F-sharp to the standard
  collection and C-natural to the guitar collection. Standard pool is
  `[0,2,4,5,6,7,8,9,11]` (C major plus A-flat and F-sharp); guitar pool is
  `[0,1,2,4,5,6,8,9,11]` (A major plus F-natural and C-natural). The guitar
  addition deliberately departs from mechanically transposing the standard
  addition down a minor third. Imagine, sing, then explicitly check two
  distinct notes; no target audio precedes recall and no quota is invented.
  Formulas remain sequential/random with `response: recall`. Root-level
  `recall_check_mode: sequential` and
  `recall_check_modes: [sequential, simultaneous]` expose an app choice,
  **not formula fields** or a resolution of the source's unstated format.
- **p09 / IDs 10/13:** `MEDITATION_GUIDE` first-recall variants use standard
  C at MIDI 60 or guitar A at MIDI 57. UIDs end in `-standard-reference` and
  `-guitar-reference`. Both begin silently, without autoplay, and use open
  self-assessment. MIDI 48–84 is a selectable app register. Changing the
  root is optional only when C/A feels subjectively pretty consistent;
  otherwise continue without worry. There is no numerical readiness
  criterion, cents tolerance, success streak or required next root.

All formula target registers are MIDI 36–84. Synthesized playback, random
sampling, span 0–48 and finite register are app adaptations, not prescribed
singing octaves or guitar technique. Distinct selection excludes an exact
repeated MIDI note within an example but permits the same pitch class in
different octaves. Runtime consecutive verification for p02/p04/p05 uses
the inherited current-round-only reset convention; completed rounds remain.
Harmonic reordering hints are assistance, not unassisted verified answers.

### Required team source guidance versus OPTIONAL digital examples

**p10 / ID 11 and p11 / ID 12 remain required manual continuation guides.**
The source asks team players to add F-sharp or C-natural and continue as
before. It does **not** settle whether all earlier team forms, diminished
subsets, or both are reissued. Local counts, corrections and range remain
unknown. The earlier restricted four-tone diminished-seventh assignment
must not silently absorb the new tone, and “continue as before” must not be
presented as an explicit new assignment of every earlier form. Source
`completion.kind: inherited_unspecified` and all uncertainties are unchanged.
Manual acknowledgement records review/participation, not scored mastery.

For convenience, each manual guide is followed by five **OPTIONAL digital
app examples**: single, melodic double, harmonic double, melodic triple,
harmonic triple. Standard examples use the full standard nine-tone pool
above; guitar examples use the full guitar nine-tone pool. **Neither uses
the old diminished subset.** These are explicitly app choices, not Burge
prescriptions or evidence that all five forms were assigned by class 17.
Each has `optional: true`, `implementation_status: optional_adaptation`,
`session: {kind: open, target: 0, assessment: keyboard}` and `maxHits: 0`.
UIDs use the source p10/p11 ID plus `-optional-single`,
`-optional-melodic-double`, `-optional-harmonic-double`,
`-optional-melodic-triple` or `-optional-harmonic-triple`. Sequential naming
follows presentation order; simultaneous naming is bottom-up. These
presentation/sampling policies are optional app adaptations with no
verification quota. **Optional example completion is not required for class
completion; class-status aggregation must skip optional entries.** Source
scope and completion unknowns stay visible in each example's Info.

### Legacy traps intentionally not ported

The old Python class-17 omissions/mismatches are not authoritative source
content: its missing F-sharp in the standard extended collection and wrong
white-tone handling are not ported. Harmonic fours here use black keys,
standard meditation/team examples include F-sharp, guitar reference blocks
are A/G rather than A/D, and the mixed pattern is 3W1B rather than an old
modulo-five sequence. The source JSON and its unresolved caveats take
precedence over those legacy shortcuts. This section is append-only; no
earlier curriculum documentation is rewritten.

## MC18 extension: semitone aid, harmonic patterns and three reference blocks

Authority: `digital-handbook/curriculum/master-class-18.json` in the source
handbook workspace. Player video: `fzuFmulqaAQ`. Review status remains
`text_supported_audio_unverified`; transcript windows and quotations are
provenance, not independent audio verification. Classes 1–17 are unchanged.

MC18 has **32 entries (IDs 0–31)**: player, comments and **30 activity
entries** covering all **eight source groups**. There are **23 formulas**
(11 core chord-cue drills, 10 optional naming examples, 2 optional recall
examples), **two MIXED_PATTERN**, **one REFERENCE_PATTERN** and **four
required manual GUIDED_PRACTICE** entries. Display order keeps each source
group's variants together despite the extra-ID allocation.

| Source group | Numeric IDs | Coverage |
| --- | --- | --- |
| player / comments | 0 / 1 | Source audio and coverage/limitations. |
| p01 | 2 | Required manual partner semitone-comparison guidance. |
| p02 | 3, 10–19 | Eleven separate fixed major cues, each followed by an opposite-color harmonic double. |
| p03 | 4 | Three white harmonic doubles, then one black single. |
| p04 | 5 | Three white harmonic doubles, then one black harmonic double. |
| p05 | 6 | Three A/D/G reference blocks, each with three cued targets and one uncued extra. |
| p06 | 7, 20–24, 30 | Required standard continuation guide, five optional naming forms, optional recall doubles. |
| p07 | 8, 25–29, 31 | Required guitar continuation guide, five optional naming forms, optional recall doubles. |
| p08 | 9 | Required learner-specific confusion-pair guidance, without a fixed recipe. |

Base pNN maps to NN+1. Source IDs have prefix `master-class-18-` and repeat
only for variants of the same source group. Every entry has a distinct stable
`practice_uid`. p02 UIDs append `-d-major`, `-e-major`, `-f-major`,
`-g-major`, `-a-major`, `-b-major`, `-c-sharp-major`, `-e-flat-major`,
`-f-sharp-major`, `-a-flat-major` or `-b-flat-major`. Optional p06/p07 UIDs
append `-optional-single`, `-optional-melodic-double`,
`-optional-harmonic-double`, `-optional-melodic-triple`,
`-optional-harmonic-triple` or `-optional-recall-doubles`.

Each activity retains the exact original base `info` values, an exact
`sourceInfo` copy, source SHA-256, source instructions, materials,
presentation, response, correction, completion, evidence, prerequisites,
implementation decisions and uncertainties. Source fields appear at practice
level and in Info; named `app_adaptations` are separate from source claims.

### Unlimited neighboring-semitone assistance

p01 permits repeated requests for up/down half steps without a fixed hint
maximum. All **24 MC18 naming/pattern/reference entries** expose
`semitone_assistance: true`: eleven chord-cue drills, ten optional naming
forms, two mixed patterns and the reference cycle. This flag is intended for
actual learner-requested controls, not documentation-only help. Select a
component of a multi-note target, request as many neighboring comparisons as
needed, and continue judging the unchanged original target.

The app's explicit choices are cumulative comparison steps, component
selection, original-target replay, and MIDI 0–127 playback boundaries.
Comparison tones may leave the target pool/register; disable an unavailable
boundary direction rather than wrapping. **The source does not specify
return, boundary or verification-credit handling.** Conservative app policy
withholds verification credit for an assisted attempt, retries a fresh
unassisted example/current pattern, and retains earlier counts. This is not a
source rule, penalty score or cap on help. Open sessions have no verification
credit to earn. Recall checks remain learner-requested checking, not pitch
verification or a prescribed harmonic vocal response.

### Fixed major cues and complete mixed patterns

- **p02:** D, E, F, G, A and B major each cue **two black targets**; C-sharp,
  E-flat, F-sharp, A-flat and B-flat major each cue **two white targets**.
  C major is already done. Numeric ID 3 is D; IDs 10–19 are the remaining ten.
  Every task is separate. Harmonic presentation is **inherited from class 17**;
  MC18 locally says “two tones” without restating it or verification sizes.
  Preserve `completion.kind: inherited_unspecified`. All eleven sessions are
  `{kind: open, target: 0, assessment: keyboard}`, maxHits zero—do not import
  class 17's 20-hit gate. Finite default root-position triads use
  `root = 48 + root pitch class`, then `[root, root+4, root+7]`. These major
  voicings, their registers and black-root ordering after C-sharp are app
  choices, not exact source voicings. Target formulas span MIDI 36–84.
- **p03/p04:** `mixed_pattern` has `white_count: 3`, `white_note_count: 2`,
  white pitch classes `[0,2,4,5,7,9,11]`, black classes `[1,3,6,8,10]`,
  MIDI 36–84 and `black_note_count: 1` / `2`. Each white example is a
  simultaneous harmonic double; p04's final black example is also a
  simultaneous double. p03 has seven named tones and p04 eight across four
  examples, but **one full four-example pattern earns one count**.
  Sessions use `{kind: patterns, target: 10, rounds: 3,
  patterns_per_round: 10, assessment: keyboard,
  error_policy: discard_current_pattern}` and `maxHits: 30`.
  Thirty counts patterns, not component pitches. Discard only the current
  invalid pattern, correcting/retrying while retaining prior counts; this
  reset policy is an app choice because the source does not restate it.
  No consecutive-pattern/round requirement is inferred.

### Three-block guitar cycle: twelve targets before wrapping

p05 uses `reference_pattern.mode: extra_targets`,
`cue_blocks: [{label: A, midi: 45}, {label: D, midi: 50},
{label: G, midi: 55}]`, `targets_per_cue: 3` and MIDI 36–84. The source cycle
is `A,t,A,t,A,t,t,D,t,D,t,D,t,t,G,t,G,t,G,t,t`, then back to A.
There are **twelve target steps**: three cued targets plus one uncued extra
per block. General indexing must use the configured block count and wrap
after 12, not a hard-coded old two-block/eight-target cycle. Reference MIDI
registers and chromatic digital sampling are app choices, not physical
guitar-string grading. The session is open keyboard naming with target and
maxHits zero; there is no invented round, score or stopping quota.

### Ambiguous continuation: required guidance, OPTIONAL realizations

p06/p07 add E-flat (standard) / D-sharp (guitar), the **same sounding pitch**.
Standard ten-tone collection is `[0,2,3,4,5,6,7,8,9,11]`: C major plus
A-flat, F-sharp and E-flat. Guitar is `[0,1,2,3,4,5,6,8,9,11]`: A major plus
F-natural, C-natural and D-sharp. This is not a further minor-third
transposition or the old restricted diminished-seventh pool.

The source paragraph begins as meditation, then names melodic singles,
doubles and triples and harmonic doubles and triples, with verification
rounds “the same as before.” Its meditation/partner scope and inherited
counts are unresolved. **IDs 7/8 remain required manual guidance** with all
uncertainties visible; do not assert required verification of all five
digital forms or invent a new compulsory solo harmonic-meditation protocol.
Manual sessions use `{kind: manual, target: 1, assessment: self_report}`,
maxHits 1. That acknowledgement logs review/practice, not verified mastery.

Each required guide is followed by five **OPTIONAL naming examples**:
single, melodic double, harmonic double, melodic triple, harmonic triple.
They use `optional: true`, `implementation_status: optional_adaptation`,
open keyboard assessment and target/maxHits zero. Sequential examples are
answered in presentation order; simultaneous examples are named bottom-up.
No numeric verification rule is inferred from “same as before.”

Optional recall-double entries 30/31 adapt the earlier class-16/17 workflow
to each expanded pool without resolving the paragraph's role. They are open
self-report MEDITATION formulas with `response: recall`, sequential/random
presentation and target/maxHits zero. Root-level `recall_count: 2`,
`recall_check_mode: sequential` and
`recall_check_modes: [sequential, simultaneous]` expose check-playback options,
not mandatory vocal harmony or formula fields. Show targets silently;
imagine and sing before requesting a check. **All twelve optional entries
are excluded from class-completion gating.**

p08 remains manual personal confusion repair. The learner chooses the pair
their ear needs; E-flat/A-flat and C-sharp/F-sharp are examples, not compulsory
pairs. No fixed alternation, repetitions, duration, quota, test threshold or
school-story group drill is inferred.

Across MC18, random distinct absolute MIDI sampling excludes exact within-
example repetitions but permits octave-duplicate pitch classes. Finite
MIDI 36–84 registers, span 0–48, cue voicings, answer ordering and synthesized
playback are disclosed app choices, not source-prescribed vocal octaves or
physical-instrument technique. No microphone grading or cents tolerance is
claimed. This extension changes data and appends documentation only; runtime
controls, pattern generation, optional gating and generalized reference
indexing are implemented separately, not certified by the data itself.

### Inherited MC9 harmonic naming-order guidance

All **17 MC18 harmonic-naming entries** set
`session.allow_harmonic_reordering: true`: the eleven fixed-major cue/double
drills, four optional harmonic double/triple naming examples, and both mixed
patterns. This continues **MC9's right-notes/wrong-order hint**, not a newly
stated local MC18 rule. Correct pitches entered in the wrong order receive a
silent **Reorder** hint and another chance to name bottom-up, without replay
or extra sound. For mixed patterns, that right-set/wrong-order response does
not invalidate the pattern; actual wrong pitches still invalidate the current
pattern under its existing error policy. Single and sequential examples are
unchanged. Semitone comparisons remain a separate, sound-producing assistance
path with their separately disclosed credit policy.

All MC18 naming/mixed/reference entries retain root-level
`semitone_assistance: true`. Optional recall-double playback choices remain
root-level `recall_check_mode` / `recall_check_modes`, never formula fields.
