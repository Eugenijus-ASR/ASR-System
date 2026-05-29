#!/bin/bash
export LC_ALL=C
. ./path.sh

rm -rf exp/tri3/decode_test data/lang_test exp/tri3/graph

utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang_tmp data/lang

cut -d' ' -f2- data/train/text | tr ' ' '\n' | sort | uniq -c | awk '{print $1, $2}' > data/local/lm/counts.txt

python3 -c "
import math, sys
with open('data/local/lm/counts.txt') as f:
    lines = f.readlines()
counts = [l.split() for l in lines if len(l.split()) == 2]
total = sum(int(c) for c, w in counts) + 2
print('\\data\\')
print(f'ngram 1={len(counts)+2}\\n')
print('\\1-grams:')
print(f'{-math.log10(1/total):.4f} <s> 0.0')
print(f'{-math.log10(1/total):.4f} </s> 0.0')
for c, w in counts:
    print(f'{-math.log10(int(c)/total):.4f} {w} 0.0')
print('\\end\\')
" > data/local/lm/stable.arpa

arpa2fst --write-symbol-table=data/lang/words.txt data/local/lm/stable.arpa data/lang/G.fst

utils/mkgraph.sh data/lang exp/tri3 exp/tri3/graph

steps/decode_fmllr.sh --nj 15 --cmd "run.pl" exp/tri3/graph data/test exp/tri3/decode_test

local/score.sh exp/tri3/decode_test data/lang/words.txt

grep WER exp/tri3/decode_test/wer.LMWT* | utils/best_wer.sh
