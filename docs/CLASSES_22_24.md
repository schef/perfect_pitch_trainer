# Classes 22–24: source mapping and app adaptations

These standalone class objects are loaded externally by the main loader. This change does not edit the root curriculum, scripts, scenes or tests.

## Counts and stable IDs

Player and comments occupy IDs **0/1**. Source `pNN` always maps to base practice **NN + 1**. Optional variants follow every base group, retain `source_practice_id`, and have distinct `practice_uid` suffixes. Optional practices carry `optional: true` and `excluded_from_mastery: true`.

| Class | Source groups | Base IDs | Extra IDs | Total entries | Optional entries |
|---|---:|---|---|---:|---:|
| 22 | 7 | 2–8 | 9–48 | 49 | 40 |
| 23 | 3 | 2–4 | 5–12 | 13 | 8 |
| 24 | 11 | 2–12 | 13 | 14 | 5 |

Total: **76 entries**, including six player/comment entries, 21 base source groups and 49 extras. Class 24 has four optional base entries (p02/p03/p04/p09), plus its optional whole-tone extra.

## Class 22

- **p01 → 2, p02 → 3:** open simultaneous triple naming, `selection: color_mix`, all twelve pitch classes, respectively white/black counts 2/1 and 1/2. MIDI 36–84 is an app choice, not the source's unrestricted keyboard extent. Neither source group supplies a quota or a full response/correction protocol.
- **p03 → 4:** reference cycle A45, D50, G55, each followed by two targets: **A,target,target; D,target,target; G,target,target**. `reference_pattern` uses `mode: extra_targets`, `targets_per_cue: 2`, `cue_once_per_block: true`, `extra_target: false`. Main runtime support must honor these flags: six targets, cue only before the first target of each block, no third extra target. Cue registers are standard-tuning app choices. Open naming has no mastery quota.
- **p04 → 5, p05 → 6:** required manual team work adds the final B-flat (other teams) / A-sharp (guitar teams). This completes the twelve-class inventory, not just the newest diminished seventh. Each audience has five optional full-chromatic naming forms at IDs **9–13 / 14–18**: single, melodic double, harmonic double, melodic triple, harmonic triple.
- **p06 → 7, p07 → 8:** required manual review of all three diminished-seventh collections **separately**, until self-assessed mastery; no invented rounds or trial quota. Optional forms for other teams occupy **19–33**, guitar teams **34–48**. Each audience has three separate collections × five forms = 15 extras. “Five forms” does not mean five notes or a five-count gate.

The separate pitch-class pools are `[2,5,8,11]`, `[0,3,6,9]`, `[1,4,7,10]`. The final collection has C-sharp/E/G/B-flat, with A-sharp wording for guitar. Earlier collections are carried forward, not freshly enumerated by this lesson. Standard and guitar variants share enharmonic MIDI pools but preserve distinct audience contexts and UIDs. No optional formula combines the collections.

## Class 23

- **p01 → 2:** required manual keyboard consolidation, choosing earlier drills and confused tones as needed. Optional open single/double/triple naming uses all twelve pitch classes at **5–7** (harmonic double/triple are app choices).
- **p02 → 3:** guided manual guitar reference weaning; extend to B/E strings and chords, deciding yourself how many tones to place between reference returns. No fabricated fixed cadence or automatic weaning schedule.
- **p03 → 4:** required manual partner consolidation and targeted backtracking. Five optional open full-chromatic naming forms at **8–12**.

Source readiness is qualitative and explicitly **does not require 100% accuracy**. Optional banks do not replace self-directed remediation or impose a compulsory accuracy gate.

## Class 24

| Source → ID | Implementation | Important boundary |
|---|---|---|
| p01 → 2 | `MEDITATION`, single all-class recall, open, `maxHits: 0` | Sing before sounding target; compare errors gently, live and inwardly; no source quota or microphone grade. |
| p02 → 3 | Optional guided manual register / four-/five-note expansion | Engine supports at most four notes; no fake five-note bank or required piano range. |
| p03 → 4 | Optional `MISSING_TONE`, `major_scale`, `root_midi: 60` | Seven unique scale notes, one omitted; six sounded together. No octave-doubled root. App voicing is not the exact spoken C-to-C example. |
| p04 → 5 | Optional `MISSING_TONE`, `chromatic_cluster`, bounds 60–72 | One interior omission only; both bounds sound. Bounds/voicing and interior-only rule are app choices, not general source requirements. |
| p05 → 6 | Guided manual actual-guitar A-string tuning | Tune first, then check with fork/tuner; no fake cents measurement. |
| p06 → 7 | Guided manual unfamiliar-guitar tuning | Preserve non-guitarist audience; no generated substitute for physical tuning. |
| p07 → 8 | Guided manual sung sharp/flat judgment | No microphone assessment, target schedule or numeric tolerance. |
| p08 → 9 | Guided manual changed-timbre practice | Points to existing instrument settings or external synthesizer; no automatic switching or claim of demonstrated universal ability. |
| p09 → 10 | Optional guided source-example discussion | **DO NOT access piano strings or modify an instrument based on app instructions. Consult a qualified piano technician for a safe alternative.** Source lacks instrument-care/access guidance; its example is not an executable procedure. |
| p10 → 11 | Guided manual meditation / slow score imagery | No reconstruction of a referenced handbook score or ear teaser; no invented duration. |
| p11 → 12 | `SPACED_RECALL`, single all-class recall | Persistent **20 consecutive correct** checked self-reports, potentially across days. |
| p03 whole-tone variant → 13 | Optional `MISSING_TONE`, `whole_tone`, `root_midi: 60` | Six unique scale notes, one omitted; five sounded. Source option, separate UID, no doubled root. |

Missing-tone naming is open (`target: 0`), without semitone/note-help controls. Spoken omissions and registers are examples, not audio-verified pitches. Clusters preserve top/bottom to support the source listening strategy; the generalized bounds of a source bank remain unknown.

### Final recall runtime contract

`session: {kind: "spaced_recall", target: 20, assessment: "self_report", rounds: 1}` and `maxHits: 20` are intentional. Main implements the new scene; this data does not itself implement persistence or enforcement.

1. Show/select one target without sounding it; learner sings from memory.
2. Require a sounding `referenceCheck` before accepting a correct self-report.
3. Persist the consecutive-correct streak across days; incorrect reports reset it. Store local attempt/check timestamps for audit, not as proof of accurate singing.
4. Log one attempt and close; **no auto-next**. Return at leisure, with no arbitrary minimum spacing.
5. Completion means **twenty correct in a row**, not ten, not twenty correct eventually. No invented tuning tolerance, octave requirement, automated microphone grade or compulsory randomization. Generated MIDI36–84 target suggestions are app conveniences.

## Provenance and unresolved source questions

Each sourced practice has a root-level `sourceInfo` exactly equal to its canonical source practice's `info`, including every optional variant. This immutable source-only object is distinct from the enriched `info`, which preserves original purpose, lesson/audio identity, source windows and `text_supported_audio_unverified` review status, supplemented by source practice fields and explicit `app_adaptations`. Source fields also appear at practice root for consumers; `source_practice_id` remains unchanged across variants. Original instructions, evidence, completion wording, implementation decisions and uncertainties are retained, not rewritten as audio-verified findings.

Every non-player/comment activity has an explicit runtime `session`:

- `GUIDED_PRACTICE`: `{kind: "manual", target: 1, assessment: "self_report"}`, `maxHits: 1`. This records participation, not verified correctness.
- `PITCH_NAMING_DRILL`, `MISSING_TONE` and `REFERENCE_PATTERN`: `{kind: "open", target: 0, assessment: "keyboard"}`, `maxHits: 0`. The runtime assessment name is `keyboard`, not `pitch_class`; pitch-class naming describes the task rather than the schema value.
- `MEDITATION`: `{kind: "open", target: 0, assessment: "self_report"}`, `maxHits: 0`.
- `SPACED_RECALL`: `{kind: "spaced_recall", target: 20, assessment: "self_report", rounds: 1}`, `maxHits: 20`.

Schema normalization covers **70 sourced activities**: class 22 has 47, class 23 has 11 and class 24 has 12. Entry and optional counts above are unchanged. Class 22's reference target bounds remain MIDI36–84, explicitly an app choice.

- Class 22 opening text is anomalous/unrelated. Hand assignment is not a color restriction: the E-flat/B/D example still has two whites and one black. Source does not restate a verification protocol, earlier pattern spellings or complete inherited team trial procedures.
- Class 23 title transcript says “D3”; source identity is class 23. No fixed new count, time limit or reference-return interval is specified.
- Class 24 does not establish vocal tolerance, octave requirement, exact final checking device, a mandatory register range, score content, or safe piano-string access. Its later explicit “20 in a row” qualifies earlier “20 times correctly.”
- Optional advanced teasers and illustrative note labels are not recording-transcription tests. No audio verification is asserted anywhere.

Validation checks parse all three JSON files, confirm contiguous IDs and stable base mappings, globally unique UIDs, exact source metadata/field preservation, optional/mastery flags, formula pools and counts, reference flags, and final recall session configuration. Runtime scene/loader integration remains owned by the main session.
