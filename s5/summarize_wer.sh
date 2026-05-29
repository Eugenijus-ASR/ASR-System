#!/bin/bash
# Surenka visus WER rezultatus i viena lentele - tinkama 4.6 skyriui

export LC_ALL=C

echo "============================================================"
echo "  ASR rezultatu suvestine"
echo "============================================================"
printf "%-25s %-12s %-10s %-10s %-10s %-10s\n" "Modelis" "Geriausias %WER" "Subs" "Del" "Ins" "lmwt"
printf "%-25s %-12s %-10s %-10s %-10s %-10s\n" "-------" "-------" "----" "---" "---" "----"

for d in exp/tri3/decode_test_unigram \
         exp/tri3/decode_test_bigram \
         exp/tri3/decode_test_trigram \
         exp/tri3/decode_test_bigram_wiki \
         exp/tri3/decode_test_trigram_wiki; do
    name=$(basename "$d" | sed 's/^decode_test_//')
    if [ ! -d "$d" ]; then
        printf "%-25s %s\n" "$name" "(praleista)"
        continue
    fi
    best=$(grep "%WER" "$d"/wer.* 2>/dev/null | utils/best_wer.sh 2>/dev/null | head -1)
    if [ -z "$best" ]; then
        printf "%-25s %s\n" "$name" "(WER nesukurtas)"
        continue
    fi
    # Pavyzdys: %WER 51.29 [ 19062 / 37174, 4123 ins, 1124 del, 13815 sub ]
    wer=$(echo "$best" | grep -oP '%WER \K[0-9.]+')
    ins=$(echo "$best" | grep -oP '[0-9]+ ins' | grep -oP '[0-9]+')
    del=$(echo "$best" | grep -oP '[0-9]+ del' | grep -oP '[0-9]+')
    sub=$(echo "$best" | grep -oP '[0-9]+ sub' | grep -oP '[0-9]+')
    # lmwt is failo pavadinimo (paskutinis '.' atskiriamas skaicius)
    lmwt_file=$(grep -l "$best" "$d"/wer.* 2>/dev/null | head -1)
    lmwt=$(basename "$lmwt_file" 2>/dev/null | sed 's/wer\.//')
    printf "%-25s %-12s %-10s %-10s %-10s %-10s\n" "$name" "$wer" "$sub" "$del" "$ins" "$lmwt"
done

echo ""
echo "============================================================"
echo "  Korpuso ir leksikono statistika"
echo "============================================================"
if [ -f data/local/lm/wiki/corpus_stats.txt ]; then
    cat data/local/lm/wiki/corpus_stats.txt
else
    echo "(corpus_stats.txt dar nesukurtas - paleiskite prepare_wiki_corpus.sh)"
fi
