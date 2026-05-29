#!/bin/bash
# ============================================================
#  Pridedi OOV zodzius is data/my_train + data/my_test
#  i data/local/dict_wiki_med leksikona ir perkuria reikalingas FST.
#  Reikia paleisti PRIES magistras_map_adapt.sh.
# ============================================================
. ./path.sh
set -e

DICT=data/local/dict_wiki_med
PHONES=$DICT/nonsilence_phones.txt
LEX=$DICT/lexicon.txt
LEXP=$DICT/lexiconp.txt

ARPA=data/local/lm/trigram_wiki_med.arpa.gz
LANG=data/lang_wiki_med
LANG_TRIGRAM=data/lang_trigram_wiki_med
GRAPH=exp/tri3/graph_trigram_wiki_med

for f in $LEX $PHONES data/my_train/text data/my_test/text $ARPA exp/tri3/final.mdl; do
    [ ! -e "$f" ] && echo "KLAIDA: nera $f" && exit 1
done

echo "============================================================"
echo "  ETAPAS 1: OOV zodziu surinkimas"
echo "============================================================"
awk '{print $1}' $LEX | sort -u > /tmp/lex_words.txt
awk '{ for (i=2;i<=NF;i++) print $i }' data/my_train/text data/my_test/text | sort -u > /tmp/my_words.txt
comm -23 /tmp/my_words.txt /tmp/lex_words.txt > /tmp/oov_words.txt
N_OOV=$(wc -l < /tmp/oov_words.txt)
echo "  OOV zodziu surasta: $N_OOV"
echo "  Sarasa /tmp/oov_words.txt"
echo ""
echo "  Pirmieji 20 OOV:"
head -20 /tmp/oov_words.txt | sed 's/^/    /'

echo ""
echo "============================================================"
echo "  ETAPAS 2: Pridejimas i leksikoną (grafem-skaldymas)"
echo "============================================================"
ADDED=0
PYTHONIOENCODING=utf-8 python3 - <<EOF
import sys
phones = set(open("$PHONES", encoding="utf-8").read().split())
added = []
with open("/tmp/oov_words.txt", encoding="utf-8") as f:
    for line in f:
        w = line.strip()
        if not w:
            continue
        chars = list(w)
        if all(c in phones for c in chars):
            added.append(w + " " + " ".join(chars))
        else:
            sys.stderr.write(f"  Praleidziu (turi nelietuviska simbolu): {w}\n")
with open("$LEX", "a", encoding="utf-8") as out:
    for line in added:
        out.write(line + "\n")
print(f"  Pridejta i leksikona: {len(added)}")
EOF

# Atnaujinti lexiconp.txt
awk '{printf "%s 1.0", $1; for(i=2;i<=NF;i++) printf " %s", $i; printf "\n"}' \
    $LEX > $LEXP

LEX_NEW=$(wc -l < $LEX)
echo "  Naujas leksikono dydis: $LEX_NEW"

echo ""
echo "============================================================"
echo "  ETAPAS 3: data/lang_wiki_med perkurimas"
echo "============================================================"
rm -rf $LANG data/local/lang_wiki_med_tmp
utils/prepare_lang.sh $DICT "<UNK>" data/local/lang_wiki_med_tmp $LANG | tail -5

echo ""
echo "============================================================"
echo "  ETAPAS 4: data/lang_trigram_wiki_med perkurimas (su esamu ARPA)"
echo "============================================================"
rm -rf $LANG_TRIGRAM
cp -r $LANG $LANG_TRIGRAM
LAST_ID=$(tail -n 1 $LANG_TRIGRAM/words.txt | awk '{print $2}')
grep -q "^#0 " $LANG_TRIGRAM/words.txt || echo "#0 $((LAST_ID + 1))" >> $LANG_TRIGRAM/words.txt
utils/format_lm.sh $LANG_TRIGRAM $ARPA $LEX $LANG_TRIGRAM | tail -3

echo ""
echo "============================================================"
echo "  ETAPAS 5: exp/tri3/graph_trigram_wiki_med perkurimas"
echo "============================================================"
echo "  (uztruks ~5-10 min)"
rm -rf $GRAPH
utils/mkgraph.sh $LANG_TRIGRAM exp/tri3 $GRAPH 2>&1 | tail -5

echo ""
echo "============================================================"
echo "  BAIGTA"
echo "============================================================"
echo "  Leksikonas: $LEX ($LEX_NEW eilutes)"
echo "  Lang: $LANG"
echo "  Lang trigram: $LANG_TRIGRAM"
echo "  HCLG: $GRAPH/HCLG.fst ($(du -h $GRAPH/HCLG.fst | cut -f1))"
echo ""
echo "Toliau galite leisti:"
echo "  ./magistras_map_adapt.sh"
