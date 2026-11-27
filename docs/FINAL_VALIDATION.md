# Completed numbered-course implementation

Validated on Linux with Godot 4.7.2. All numbered classes **1–24** are loaded,
including source-linked manual guidance for earlier assignments previously
mentioned only in comments. The five supplemental recordings remain source
archive material, not additional numbered classes.

## Coverage

- **241/241** numbered source assignments represented, with exact source Info.
- **449 app entries**, including players, comments, optional variants, test
  fixtures and utilities; this is not 449 independent source exercises.
- **287 formula-based variants**, plus explicit sequence, meditation,
  missing-tone and manual interactions.
- **Five class-12 guitar-team variants remain pending**, without a guessed pool.
- Manual acknowledgements record participation, not measured accuracy.
- Optional adaptations are labeled and do not block required completion.

See [CURRICULUM_COVERAGE.md](CURRICULUM_COVERAGE.md) and its JSON companion for
the per-class audit. Source support remains **text-supported/audio-unverified**.
No test certifies the instructor's empirical claims or a user's absolute pitch.

## Checked behavior

- Complete examples/patterns, not individual note counts, earn mixed-pattern credit.
- Separate diminished collections are not accidentally combined or substituted
  for the accumulated familiar inventory.
- Class 21's corrected accumulated collection has eleven tones for both audiences;
  the final class-22 addition completes the chromatic collection.
- Generated missing-tone questions omit precisely the scored answer. Cluster
  endpoint preservation is disclosed as an app choice.
- Ten sung tones counts attempts, not ten consecutive correct responses.
- Final recall requires an explicit reference check before self-report, persists
  a twenty-consecutive streak across visits, rejects duplicate recordings and
  resets on an incorrect report. There is no invented minimum spacing or voice
  tolerance. Local timestamps do not independently prove that a user sang.
- Atomic progress replacement and the previous backup preserve legacy counters,
  formula data and recall histories. Tests use isolated snapshots, not real
  progress writes.

## Tests run

All fourteen complete-course regression suites passed without script errors:

- `classes_09_10.gd`, `classes_11_12.gd`, `class_13.gd`, `class_14.gd`
- `classes_15_16.gd`, `class_17.gd`, `class_18.gd`
- `formulas.gd`, `soundfonts.gd`, `missing_tones.gd`, `progress_file.gd`
- `curriculum_coverage.gd`, `final_masterclasses.gd`, `practice_sessions.gd`

Whole-course coverage tests use the independently maintained local source
specifications; pass `-- --source-dir=/path/to/digital-handbook/curriculum`
when running outside the development environment.

Additional checks passed:

- Smoke test: all **449** entries open, keyboard answers, audio lifecycle.
- Three portrait layout sizes: **540×960, 540×1206, 720×1600**.
- Practice Info navigation: preserves the underlying exercise and scroll state.
- Linux resource-pack export, exported-pack smoke/layout/Info behavior.
- Python coverage audit, Ruff on the audit tool, and `git diff --check`.

Concurrent UI changes already present in the working tree were preserved, not
reverted. An earlier exported Info test emitted a nonfatal inherited-node warning
about the old `Display/MarginContainer` path. Release builds use a fresh import
and export cache so stale inherited layouts are not reused.

## Development handoff (before v2.0.0)

Open `project.godot` and use F5. The locally tested resource pack is
`/tmp/opencode/perfect-pitch-complete.pck`; no new APK or standalone executable
release had been built at that handoff. The then-existing releases did not yet
contain this updated source tree, and changes were still uncommitted.

## v2.0.0 release verification

All 18 test scripts passed against a fresh release snapshot, including the
449-entry smoke test, complete-course coverage, progress snapshots, full-page
scrolling, wrapped button layouts, Android Back navigation, and the new
original-design Practice Info page with exercise-state preservation.

Android (version code 4), Linux x86_64, and Windows x86_64 builds were produced
from that snapshot. Direct-download artifacts and platform validation details
are recorded in the v2.0.0 GitHub release notes. Development documentation and
audit tools are excluded from application exports; the runtime curriculum JSON
files remain included.

Audio verification, unresolved source interpretation, and SoundFont/course-content
redistribution permissions are separate from runtime/source-coverage validation.
