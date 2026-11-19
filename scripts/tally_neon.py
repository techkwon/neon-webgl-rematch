#!/usr/bin/env python3
"""Borda 4/3/2/1 tally for the Neon round -> judge-neon/scores.json (same shape as judge4/scores.json)."""
import json, os
B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = ['water', 'globe', 'store', 'city', 'blackhole']; M = ['neon', 'hydrogen', 'sonnet', 'sol']
rounds = {}; tot = {m: 0 for m in M}; nos = {m: 0 for m in M}; ballots = 0; selffirst = 0
first = {m: 0 for m in M}; missing = []
for t in T:
    rounds[t] = {m: 0 for m in M}
    for j in M:
        f = f'{B}/judge-neon/{t}/vote-{j}.json'
        if not os.path.exists(f): missing.append(f'{t}/{j}'); continue
        v = json.load(open(f)); ballots += 1
        for i, m in enumerate(v['models']):
            p = 4 - i; rounds[t][m] += p; tot[m] += p
            if m != j: nos[m] += p
        first[v['models'][0]] += 1
        if v['models'][0] == j: selffirst += 1
out = {'rounds': rounds, 'total': tot, 'total_excluding_self': nos, 'ballots': ballots, 'self_first_votes': selffirst, 'first_votes': first, 'missing': missing}
json.dump(out, open(f'{B}/judge-neon/scores.json', 'w'), indent=1)
print(json.dumps(out, ensure_ascii=False))
