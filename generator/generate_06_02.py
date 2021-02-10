#!/usr/bin/env python3

import json

pitchList = ["c,", "d,", "e,", "f,", "g,", "a,", "h,",
             "c", "d", "e", "f", "g", "a", "h",
             "c'", "d'", "e'", "f'", "g'", "a'", "h'",
             "c''", "d''", "e''", "f''", "g''", "a''", "h''",
             "c'''", ]

if __name__ == "__main__":
    batch = []
    for i in range(len(pitchList) - 2):
        question = [[pitchList[i], pitchList[i + 2]]]
        anwser = question
        batch.append({"id": i, "question" : question, "anwser" : anwser})
    print(json.dumps(batch))
