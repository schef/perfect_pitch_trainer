# Masterclasses 19–21: curriculum mapping

## Source and file contract

Only the exact JSON specifications in
`/tera/schef_backup_old/projects/perfect_pitch/digital-handbook/curriculum/master-class-{19,20,21}.json`
were used as source specifications. Review status remains
`text_supported_audio_unverified`; this work does not verify the audio.
The old handbook and old Python generators were not used.

The new external files are `curriculum/masterclass_19.json`,
`curriculum/masterclass_20.json`, and `curriculum/masterclass_21.json`.
Each root contains exactly `id`, `title`, `description`, and `practices`.
The application loader is responsible for appending these classes; no loader,
engine, tests, or `masterclasses.json` edits are included here.

Player ID 0 and comments ID 1 are retained. Video IDs are respectively
`Cpsnj4ggEEk`, `ROkVjvrjiFc`, and `oWv7whaGHjQ`.
Source pNN keeps numeric base ID NN+1. Extra variants use IDs after all base
slots, but display immediately alongside their source group, not sorted by
numeric ID. Each `practice_uid` is unique; variants retain the same exact
`source_practice_id` and `source_practice_group`. Optional variants have
distinct `-optional-...` UIDs, `optional: true`, and zero-target open sessions;
they must never gate class completion.

Every source-backed practice carries the exact source `name`, relationship,
audience, skill, instructions, materials, presentation, response, correction,
completion, evidence, prerequisites, implementation decisions and uncertainties.
`sourceInfo` is an exact copy of source `info`; merged `info` starts with that
base and adds the source fields and mapping metadata. Source completion and
uncertainties also appear in visible instructions, alongside explicit
`app_adaptations`. Source SHA-256 values are copied, not claimed to be audio
checks performed here.

## Counts

| Class | Source groups | Required source-backed entries | Optional app entries | Player/comments | Total entries |
| --- | ---: | ---: | ---: | ---: | ---: |
| 19 | 11 | 31 | 0 | 2 | 33 |
| 20 | 8 | 8 | 5 | 2 | 15 |
| 21 | 7 | 7 | 10 | 2 | 19 |
| **Total** | **26** | **46** | **15** | **6** | **67** |

“Required” here means non-optional curriculum representation, not verified
mastery: manual entries record participation only, and open entries have no
invented numeric verification gate.

## Class 19

| Source | Mapping and completion |
| --- | --- |
| p01 | `MIXED_PATTERN`: two white harmonic doubles, then one black single; 3 rounds × 10 complete patterns. |
| p02 | Same structure with a black harmonic double; 3 × 10 patterns. |
| p03 | Open `REFERENCE_PATTERN`, `extra_targets`, cue blocks A45/D50/G55, `targets_per_cue: 2`. |
| p04, p05 | Separate standard/guitar manual meditation continuations. No new collection, format, duration or count is invented. |
| p06, p07 | Each audience has two isolated four-tone sets × five forms = ten naming variants per source activity. |
| p08, p09 | Each audience has two isolated single-recall meditation variants, each counting ten sung tones. |
| p10, p11 | Separate standard/guitar manual grounding/backtracking guidance, no invented readiness threshold. |

Mixed config is `white_count: 2`, `white_note_count: 2`, and
`black_note_count: 1` or `2`. Counting complete patterns follows the stated
continued convention. Discarding only the current pattern on actual wrong
pitches and retaining earlier totals is an explicitly labeled app policy;
source does not locally restate reset rules.

The reference cycle is exactly
`A,t,A,t,t,D,t,D,t,t,G,t,G,t,t`: nine targets, with one uncued extra after
each pair of anchored targets. Full typical guitar playback is MIDI 40–88,
including low E40 and pitches below the references. The source requires the
entire guitar range, including low notes; the finite upper bound and typical
six-string tuning are app defaults, not prescribed instrument specifications.
There is no invented verification quota.

Standard set 1 is B/D/F/A-flat, pitch classes `[2,5,8,11]`; set 2 is
F-sharp/A/C/E-flat, `[0,3,6,9]`. Guitar uses the enharmonically identical
sets G-sharp/B/D/F and D-sharp/F-sharp/A/C. Never combine these pools in
class 19 target generation. For each set, forms are single, melodic double,
melodic triple, harmonic double and harmonic triple. Singles appear once,
not as duplicate “harmonic singles.” Each variant uses one round of 20
consecutive examples: **one round per form is local source instruction;
size 20 and consecutive/error-reset behavior are explicitly inherited app
verification conventions, not locally restated source numbers**. No source
ordering of the old/new collections is asserted.

For p08/p09, `MEDITATION`, `session.kind: count`, `target: 10`,
`assessment: self_report`, `maxHits: 10`, and single-recall formula preserve
a task count, **not a correctness streak**. The main counter advances only
on explicit “I sang one” confirmation; audible checking is optional.
Wrong self-checks never reset the count and correctness never gates it.
Who selects/prompts tones is unknown in the source; silently displaying
random named targets from the selected set is an explicit app choice.
No microphone or cents-tolerance assessment is implied.

## Class 20

All four mixed sequences use explicit `pattern_steps` objects with
`pitch_classes`, `note_count`, and `label: white|black`. No fallback
`white_count` substitutes for these sequences:

| Source | Exact steps | App completion |
| --- | --- | --- |
| p01 | W1, W1, B1 | Open; quota scope ambiguous. |
| p02 | W1, W1, B1, B1 | 3 × 10 complete patterns; quota stated immediately after this activity. |
| p03 | W2, W2, B2 | Open; no local harmonic quota. |
| p04 | W2, W2, B2, B2 | Open; no local harmonic quota. |

The source's “three verification rounds of ten” might cover both single
drills or more keyboard assignments. Applying it to p02 is the narrow local
mapping, not resolution of that wider uncertainty. Both harmonic drills
are called “fourth” in the transcript; source evidence is preserved and
appearance order is retained without correcting the historical wording.

p05/p06 use naming formulas with `cue_midi: [45]` and `note_count: 2`,
sequential or simultaneous respectively. Spoken E-flat/B-flat and E/B are
examples, not a restricted target pool. Both remain open: **the source
does state two verification rounds of twenty**, but separate/shared mode
scope is unresolved. This wording remains in exact source completion,
Info and visible instructions; open policy does not silently erase it.

p07 is required manual meditation-triples guidance because the pitch pool,
technique, audience beyond local guitar placement and quota are not
defined. No new automatic three-note meditation collection is invented.

p08 is required manual partner continuation using only the two previous
diminished collections together. “Eight tones all at once” means pool union,
not a prescribed simultaneous eight-note chord. Precise forms and quota
are undefined. The inherited reconstructed union is
`[0,2,3,5,6,8,9,11]`, the same sounding pool for both audiences.
Five **optional**, open naming forms offer single, melodic doubles/triples
and harmonic doubles/triples. They are convenient app realizations, not
newly prescribed source forms. Backtracking to familiar C/A-major scales
with added tones remains manual guidance.

## Class 21

| Source | Mapping |
| --- | --- |
| p01 | Required manual ordinary major/minor chord-flavor guidance, not constituent-note scoring or an invented exhaustive chord bank. |
| p02 | Explicit W1,B1 mixed steps; open, no invented twenty-item quota. |
| p03 | Required manual spoken A/D formula; no guessed cycle boundary. |
| p04 | A45 cue then three sequential target notes; open. |
| p05 | A45 cue then three simultaneous target notes; open. |
| p06 | Required manual standard-team C-sharp addition plus five optional open naming variants. |
| p07 | Required manual guitar-team G-natural addition plus five optional open naming variants. |

The source's A/D return-to-A wording is ambiguous; the exact spoken formula
is retained without automatic looping. The source states **three rounds of
ten for “this A string drill”** but does not unambiguously assign separate
quotas to p04/p05 or exclude p03. Both three-target modes therefore remain
open with the source quota and uncertainty visible for manual interpretation.

For p06/p07 the complete team inventory, form and completion count are not
freshly restated. Following the consequential correction in
[`FINAL_SOURCE_REVIEW.md`](FINAL_SOURCE_REVIEW.md), all ten optional naming
examples use the **accumulated full team collection**, not the restricted
class-20 diminished exercise, as their parent inventory:

- Standard accumulated ten through class 18: C major plus A-flat, F-sharp
  and E-flat, `[0,2,3,4,5,6,7,8,9,11]`. Add C-sharp (1).
- Guitar accumulated ten through class 18: A major plus F-natural, C-natural
  and D-sharp, `[0,1,2,3,4,5,6,8,9,11]`. Add G-natural (7).
- **Both resulting pools contain eleven pitch classes:**
  `[0,1,2,3,4,5,6,7,8,9,11]`. Only B-flat/A-sharp (10) remains absent.
  Standard E/G and guitar C-sharp/E remain learned tones; the restricted
  diminished drill never erased them from the accumulated collection.

Review evidence uses raw transcript timestamps in seconds: class 20
**192.06–225.98** restricts its special drill to eight tones and explicitly
leaves out other tones; **227.12–247.06** returns to the full scales with
added tones for grounding. Class 21 **395.18–401.00** adds standard C-sharp
or guitar G-natural, then **401.08–410.20** says “only one more tone” remains.
This supports the ten-plus-one reconstruction, not replacing the accumulated
inventory with the restricted diminished subset. See the review document's
classes 14/16/17/18 evidence chain for earlier additions.

This is an explicit cross-lesson textual reconstruction, not a claim that
class 21 enumerates a fresh complete inventory or that audio was verified.
Exact source instructions, materials, uncertainties, evidence and sourceInfo
remain unchanged, including the uncertainty about the locally unstated full
inventory. Each audience still has five optional open forms, no new inferred
verification quota, and no class-completion gate. IDs, UIDs, groups, ordering
and counts are unchanged; class 20's restricted eight-tone bank remains correct.

## Shared adaptation boundaries

- All new naming, mixed and reference tasks enable semitone assistance.
  Unlimited comparison requests, component selection, MIDI boundary handling
  and conservative assisted-attempt credit policy are labeled app choices
  inherited from the earlier assistance workflow, not new local source rules.
- All new keyboard naming sessions enable harmonic reordering. Right-set,
  wrong-order answers receive a silent reorder opportunity without replay;
  they do not invalidate a mixed pattern. Actual wrong pitches do.
- Harmonic answers are bottom-up; melodic answers follow presentation order.
  MIDI 36–84 for other generated tasks and guitar MIDI 40–88 are finite app
  playback choices. Multi-note sampling uses distinct absolute MIDI notes,
  allows octave-duplicate pitch classes, and spans at most 48 semitones.
- Source aliases h/B-natural and b/B-flat are resolved by MIDI pitch class
  (11 and 10 respectively); diminished enharmonic spellings never create
  extra pitch classes. No unrelated major-scale tones enter restricted pools.
- Manual guidance uses the class-15 `manual`, target 1, self-report logging
  convention. Acknowledgement is participation, never health/readiness
  testing, vocal/instrument performance grading, or proof of pitch mastery.

## Validation

Validate JSON decoding, root keys, all 26 source IDs, exact source fields
and sourceInfo copies, unique numeric IDs/UIDs, contiguous source-group
display order, stable base IDs, optional zero-target sessions, isolated
class-19 pools, class-20 explicit mixed steps, correct A-string cue and
target counts, and reconstructed eleven-tone class-21 inventories for both
audiences. The source-review correction preserves all ten optional formulas'
open/zero-target sessions, all 19 class-21 entries, IDs, UIDs and source-group
order, as well as exact canonical source fields. `source_guidance.json` is
unchanged. Runtime behavior
requires the coordinating session's engine support for count-based singing,
explicit mixed steps and three-target cue formulas; this change does not
modify or claim to execute those engine features.
