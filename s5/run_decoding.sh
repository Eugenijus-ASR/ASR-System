nano run_decoding.sh#!/bin/bash
export LC_ALL=C
. ./path.sh

utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang_tmp data/lang

cut -d' ' -f2- data/train/text | awk '{print "<s>", $0, "</s>"}' > data/local/lm/corpus_proper.txt

python3 -c "
import sys
from collections import Counter
bigrams = Counter()
unigrams = Counter()
with open('data/local/lm/corpus_proper.txt') as f:
    for line in f:
        w = line.split()
        unigrams.update(w)
        for i in range(len(w)-1):
            bigrams[(w[i], w[i+1])] += 1
print('\\data\\')
print(f'ngram 1={len(unigrams)}')
print(f'ngram 2={len(bigrams)}\\n')
print('\\1-grams:')
for w, c in unigrams.items(): print(f'-1.0 {w} 0.0')
print('\\2-grams:')
for p, c in bigrams.items(): print(f'-0.5 {p[0]} {p[1]}')
print('\\end\\')
" > data/local/lm/better.arpa

utils/format_lm.sh data/lang data/local/lm/better.arpa data/local/dict/lexicon.txt data/lang_test

rm -rf exp/tri3/graph
utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph

steps/decode_fmllr.sh --nj 15 --cmd "run.pl" exp/tri3/graph data/test exp/tri3/decode_test

local/score.sh exp/tri3/decode_test data/lang_test/words.txt

grep WER exp/tri3/decode_test/wer.LMWT* | utils/best_wer.sh
