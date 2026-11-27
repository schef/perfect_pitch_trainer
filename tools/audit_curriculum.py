"""Audit app coverage against a local, independently maintained source curriculum."""

import argparse
from collections import Counter
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_lessons():
    root = json.loads((ROOT / "masterclasses.json").read_text())
    lessons = root["masterclasses"]
    for resource in root.get("external_masterclasses", []):
        lessons.append(json.loads((ROOT / resource.removeprefix("res://")).read_text()))
    for resource in root.get("external_practice_supplements", []):
        supplement = json.loads((ROOT / resource.removeprefix("res://")).read_text())
        for extension in supplement["extensions"]:
            lesson = next(c for c in lessons if c["id"] == extension["masterclass_id"])
            lesson["practices"].extend(extension["practices"])
    return lessons


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    lessons = load_lessons()
    errors, missing, deferred, rows, uids = [], [], [], [], set()
    class_ids = [c["id"] for c in lessons]
    if len(class_ids) != len(set(class_ids)):
        errors.append("Duplicate masterclass IDs")
    for number in range(1, 25):
        source = json.loads((args.source_dir / f"master-class-{number:02d}.json").read_text())
        expected = {p["id"]: p for p in source["practices"]}
        matches = [c for c in lessons if c["id"] == number]
        if len(matches) != 1:
            errors.append(f"Expected exactly one class {number}")
            continue
        activities = matches[0]["practices"]
        ids = [p["id"] for p in activities]
        if len(ids) != len(set(ids)):
            errors.append(f"Class {number}: duplicate numeric practice IDs")
        found, counts = set(), Counter()
        for practice in activities:
            source_id = practice.get("source_practice_id")
            if not source_id:
                continue
            if source_id not in expected:
                errors.append(f"Class {number}: unknown/misplaced source assignment {source_id}")
                continue
            found.add(source_id)
            uid = practice.get("practice_uid", source_id)
            if uid in uids:
                errors.append(f"Duplicate activity UID: {uid}")
            uids.add(uid)
            for field, value in expected[source_id]["info"].items():
                if practice.get("info", {}).get(field) != value:
                    errors.append(f"{uid}: mismatched source Info field {field}")
            if practice.get("implementation_status") == "deferred":
                deferred.append(uid)
                counts["deferred"] += 1
            elif practice.get("optional", False):
                counts["optional"] += 1
            elif practice["practiceType"] == "GUIDED_PRACTICE":
                counts["manual"] += 1
            else:
                counts["interactive"] += 1
        absent = sorted(set(expected) - found)
        missing.extend(absent)
        rows.append({"masterclass": number, "source_assignments": len(expected),
                     "represented": len(found), "missing": absent,
                     "activity_counts": dict(counts), "entries": len(activities)})
    result = {"notice": "Coverage and exact source citations only; not audio verification or automatic assessment of manual work.",
              "classes": rows, "source_assignments": sum(r["source_assignments"] for r in rows),
              "represented": sum(r["represented"] for r in rows), "missing": missing,
              "deferred": deferred, "errors": errors,
              "total_app_entries_including_tests_utilities": sum(len(c["practices"]) for c in lessons)}
    if args.write:
        destination = ROOT / "docs/CURRICULUM_COVERAGE.json"
        destination.write_text(json.dumps(result, indent=2) + "\n")
        lines = ["# Numbered-course coverage audit", "", result["notice"], "",
                 f"Represented: **{result['represented']}/{result['source_assignments']} source assignments**.",
                 f"Missing: **{len(missing)}**. Explicitly deferred: **{len(deferred)}**. Validation errors: **{len(errors)}**.",
                 "", "Multiple app variants can refer to one source assignment. Optional adaptations are not source requirements and do not block completion.",
                 "", "| Class | Source coverage | Interactive | Manual | Optional | Pending |", "| --- | --- | ---: | ---: | ---: | ---: |"]
        for row in rows:
            count = row["activity_counts"]
            lines.append(f"| {row['masterclass']:02d} | {row['represented']}/{row['source_assignments']} | "
                         f"{count.get('interactive', 0)} | {count.get('manual', 0)} | {count.get('optional', 0)} | {count.get('deferred', 0)} |")
        if deferred:
            lines += ["", "## Still unresolved", ""] + [f"- `{uid}`" for uid in deferred]
            lines += ["", "These class-12 guitar-team variants have no settled source note collection. They are shown as pending, not generated from guessed pitches."]
        if missing:
            lines += ["", "## Missing source assignments", ""] + [f"- `{uid}`" for uid in missing]
        if errors:
            lines += ["", "## Validation errors", ""] + [f"- {message}" for message in errors]
        lines += ["", "Manual logs record participation, not verified correctness. Final recall is checked self-report, not microphone grading. All source interpretations remain text-supported/audio-unverified."]
        (ROOT / "docs/CURRICULUM_COVERAGE.md").write_text("\n".join(lines) + "\n")
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if missing or errors else 0)


if __name__ == "__main__":
    main()
