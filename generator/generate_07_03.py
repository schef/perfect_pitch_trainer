#!/usr/bin/env python3

import json
import random

pitchList = [
             "c,", "d,", "e,",
             "c", "d", "e",
             "c'", "d'", "e'",
             "c''", "d''", "e''",
             "c'''", ]

if __name__ == "__main__":
    batch = []
    myid = 0
    for i in pitchList:
        question = [[i]]
        anwser = question
        batch.append({"id": myid, "question" : question, "anwser" : anwser})
        myid += 1
    while(len(batch) > 50):
        random_item_from_list = random.choice(batch)
        batch.remove(random_item_from_list)
    print(json.dumps(batch))
