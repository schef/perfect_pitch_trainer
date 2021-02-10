#!/usr/bin/env python3

import json
import random

pitchList = [
             "c,", "cis,", "d,", "es,", "e,", "f,", "fis,", "g,", "as,", "a,", "b,", "h,",
             "c", "cis", "d", "es", "e", "f", "fis", "g", "as", "a", "b", "h",
             "c'", "cis'", "d'", "es'", "e'", "f'", "fis'", "g'", "as'", "a'", "b'", "h'",
             "c''", "cis''", "d''", "es''", "e''", "f''", "fis''", "g''", "as''", "a''", "b''", "h''",
             "c'''", ]

if __name__ == "__main__":
    batch = []
    myid = 0
    for i in range(len(pitchList) - 1):
        for y in range(1, 12):
            try:
                question = [[pitchList[i], pitchList[i + y]]]
                anwser = question
                batch.append({"id": myid, "question" : question, "anwser" : anwser})
                myid += 1
            except:
                pass
    while(len(batch) > 50):
        random_item_from_list = random.choice(batch)
        batch.remove(random_item_from_list)
    print(json.dumps(batch))