# Missing source guidance supplement: classes 1–8

## Scope and source

`curriculum/source_guidance.json` adds **25 previously unrepresented canonical
source activities**. The audit compared inline `masterclasses.json` classes
1–8 against the exact canonical files
`/tera/schef_backup_old/projects/perfect_pitch/digital-handbook/curriculum/master-class-01.json`
through `master-class-08.json`, using `source_practice_id`, not title similarity.
Review status remains `text_supported_audio_unverified`; recorded performance
was not independently verified.

Only this supplement and this document are new repository files for this task.
No existing lesson JSON, class metadata, legacy practice, loader, script or test
is changed. No original historical handbook was read or reconstructed here.

## Extension schema and IDs

The root contains exactly `extensions`. Each extension contains exactly
`masterclass_id` (integer) and `practices` (array). Only classes with missing
activities receive extensions; class 1 has no missing canonical practice.
The coordinating loader can append these through its external-practice-
supplement mechanism after loading the classes. This file does not redefine
class titles, descriptions, player/comments or legacy practices.

Each added practice uses the exact canonical ID for both
`source_practice_id` and `practice_uid`; no existing UID or source ID is reused.
Numeric IDs start at each inline class's maximum existing practice ID plus one
and increase in canonical source order. Existing numeric IDs are unchanged.

| Class | Existing max ID | Added count | New numeric IDs | Exact canonical source IDs |
| --- | ---: | ---: | --- | --- |
| 1 | 1 | 0 | — | — |
| 2 | 1 | 1 | 2 | `master-class-02-p01` |
| 3 | 1 | 4 | 2–5 | `master-class-03-p01`, `master-class-03-p02`, `master-class-03-p03`, `master-class-03-p04` |
| 4 | 1 | 1 | 2 | `master-class-04-p01` |
| 5 | 2 | 3 | 3–5 | `master-class-05-p02`, `master-class-05-p03`, `master-class-05-p04` |
| 6 | 6 | 9 | 7–15 | `master-class-06-p02`, `master-class-06-p04`, `master-class-06-p06`, `master-class-06-p08`, `master-class-06-p10`, `master-class-06-p11`, `master-class-06-p12`, `master-class-06-p13`, `master-class-06-p14` |
| 7 | 5 | 5 | 6–10 | `master-class-07-p02`, `master-class-07-p03`, `master-class-07-p05`, `master-class-07-p06`, `master-class-07-p09` |
| 8 | 14 | 2 | 15–16 | `master-class-08-p04`, `master-class-08-p05` |
| **Total** | | **25** | | **25 distinct source IDs** |

## Exact source preservation

Every activity retains its exact source name, relationship, audience, skill,
source instructions, materials, presentation, response, correction, completion,
evidence, prerequisites, implementation decisions and uncertainties.
`sourceInfo` copies canonical `info` exactly. Merged `info` includes that base,
the exact source fields (including the original string `id`) and explicit app
adaptations/mapping metadata. The top-level practice `id` is the new numeric
app ID. Source SHA-256 values are copied provenance, not a claim that this task
verified audio hashes.

Visible `instructions` preserve source presentation, response, correction,
completion and uncertainties in addition to the instructions themselves.
In particular, source verification counts and error rules remain manual
instructions; they are not replaced by a one-click mastery claim.

## Manual completion means participation, not mastery

All 25 additions use:

```json
{
  "practiceType": "GUIDED_PRACTICE",
  "implementation_status": "manual_guidance",
  "session": {"kind": "manual", "target": 1, "assessment": "self_report"},
  "maxHits": 1
}
```

The single acknowledgement records self-reported review/participation only.
It does **not** verify a passed source round, twenty consecutive correct
responses, vocal/instrument technique, handbook reading, artwork completion,
or pitch mastery. No formula, MIDI note pool, synthesized partner, microphone
score, automatic physical-action check or invented test is supplied.

No blanket `optional` flags are added or audience-specific alternatives made
universally compulsory. Source audience, prerequisites and conditional roles
remain explicit: e.g. guitar thirds assume the learner can form them; class-5
meditation is an available alternative; the class-6 melodic double is the
alternative for a single-tone instrument, not another compulsory harmonic
double; an optional buddy remains optional. Demonstration examples are not
promoted into separate required scored exercises.

## Why these activities are not automated

### Class 2: own live instrument

Listen to concert F-sharp/E-flat on the learner's familiar live instrument.
The source's B-flat trumpet written G-sharp/F example is preserved verbatim;
no other written/concert mapping, register or recognition test is derived.
The instructor's descriptive hints are not universal graded sensations.

### Class 3: explore, read, listen again

The four activities remain distinct: individual-tone/octave exploration,
live major-chord comparison, reading, and listening again after reading.
Discussed tones are not randomized mandatory recognition pools; the related
A-flat-major demonstration is not an additional required test. No chord
voicing, register, score or exact timing is guessed.

**The original historical Perfect Pitch handbook is not bundled.** The user
needs access to their own original assigned handbook for p03. Generated
transcription-based handbook material is **not claimed identical** to the
original and is not substituted for it. No edition, pages, reconstructed
reading or fabricated excerpt is supplied. Reviewing the guidance does not
certify that the original was available or read. The subsequent listening
activity preserves the original listen–read–listen sequence.

### Class 4: physical drawing and 13 tone occurrences

The learner listens chromatically from C through the next C and draws a
personal chart with real art supplies. There are 13 tone occurrences because
both Cs are included, not 13 different pitch classes. The app does not create
or judge the drawing, enforce universal colors, or turn an introductory
analogy into a permanent visual code. The source leaves starting octave and
written-versus-concert treatment unresolved for this assignment; neither is
inferred from other lessons.

### Class 5: strings, thirds, reference-first meditation

Open-string identity requires the learner's actual six guitar strings. Source
tuning is unspecified, so no tuning or full string-pitch list is manufactured.
The thirds exercise sounds pitches simultaneously on different strings and
sings bottom-up: three/four semitones describe interval distance, not required
same-string fingering. It does not inherit the keyboard white-key constraint.

The separate instrumental meditation starts by **hearing** instrument C/D,
then imagining/singing/checking. Instrument-relative notes need not be concert
C/D. Source transposing-instrument examples remain examples; no general
mapping or octave-specific playback is calculated.

### Class 6: physical guitar, recall-first meditation and actual partner roles

Five guitar activities cover seconds, two close, two wide, three close and
three wide. Approximate phrases such as “within an octave or so” remain
approximate. No tuning, fixed fingering, keyboard two-hand technique, octave-
duplication policy, extreme range or strict numeric span cutoff is invented.
Source twenty-consecutive verification wording remains manual, including
where it is inherited through the session convention rather than locally
repeated.

Meditation p11 is **recall-first C/D**, not class-5 reference-first listening:
no sounded starting tone before the initial recall, then instrument checking
and wrong/right comparison. No round is required and the later team A/B
substitution is not silently imported into this solo paragraph.

The three team activities require an actual partner: single naming,
simultaneous double naming bottom-up, and the sequential alternative in played
order. Instrument C/D and explicit guitar A/B roles are preserved without
guessed concert mappings. Source short turns, role switching, verification
counts and correction remain instructions for the people practicing, not
automated assessment. The single-tone-instrument alternative does not imply
that every team must complete both double variants.

### Class 7: real strings, opening recall and partner tasks

Open-string singing/unlocking and open-string identification remain separate.
Tuning is unknown; incidental finger clues are allowed, a buddy is optional,
and subjective familiarity is not replaced with twenty correct. String
identity is not collapsed into generic pitch-class scoring.

Session-opening C (guitar A) recall happens before any tones in the physical
practice session. This guidance does not enforce app-wide timing or sound a
reference first. Initial errors are expected; no cents-based “closest” metric
is added for the team estimate variant.

Partner single naming uses instrument C/D/E or guitar A/B/C-sharp. The source
twenty-consecutive unaided verification remains manual; clue-assisted training
cannot count toward it, but the unresolved non-error assisted-attempt
reset/pause policy is not invented. Subsequent named-tone singing is a
different, explicitly no-round activity after identification practice, with
relative pitch allowed.

### Class 8: physical capo and self-determined sounding pitches

The two activities physically capo so the source E string sounds F, then A
after familiarity with F. The learner determines the other strings and repeats
single/pair drills with new sounding names. No exact capo fret, complete
shifted tuning or written/concert/MIDI inventory is derived; later lesson-9
enumerations are not imported. Optional helper testing and subjective comfort
stay optional/unscored, and the source reminder to sing A before session
start is retained.

## Validation boundary

Validation checks JSON structure, exact missing-ID coverage, unchanged source
fields and sourceInfo, unique new UIDs, absence of existing source-ID/UID reuse,
numeric-ID uniqueness after simulated merge, sequential allocation after the
inline class maximum, and manual-only sessions without generated formulas.
This structural audit does not claim runtime loader tests, audio verification,
external handbook access, actual partner participation or physical instrument
performance. The coordinating session owns loader integration.
