#!/bin/bash
# ============================================================
#  Wiki + Medicinos korpusu prijungimas
#  Sukuria:
#    data/local/lm/train_text_wiki_med.txt   (CV + Wiki + Med)
#    data/local/dict_wiki_med/lexicon.txt    (praplestas leksikonas)
#    data/lang_wiki_med                      (nauja lang direktorija)
# ============================================================
export LC_ALL=C
. ./path.sh

set -e

CV_TEXT=data/local/lm/train_text.txt
WIKI_TEXT=data/local/lm/wiki/wiki_text_dedup.txt
MED_TEXT=data/local/lm/medicinos/medicinos_korpusas.txt
TEST_TEXT=data/test/text
OUT_TEXT=data/local/lm/train_text_wiki_med.txt

DICT_SRC=data/local/dict_wiki      # esamas leksikonas (CV + Wiki)
DICT_DST=data/local/dict_wiki_med  # naujas (CV + Wiki + Med)
LANG_TMP=data/local/lang_wiki_med_tmp
LANG_DST=data/lang_wiki_med
STATS=data/local/lm/medicinos/corpus_stats.txt

for f in $CV_TEXT $WIKI_TEXT $MED_TEXT $TEST_TEXT $DICT_SRC/lexicon.txt; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f" && exit 1
done

echo "============================================================"
echo "  ETAPAS 1: Medicinos teksto dedup ir filtras"
echo "============================================================"

# Dedup ir filtruoti pagal min ilgi
awk 'NF>=4 && !seen[$0]++' $MED_TEXT > data/local/lm/medicinos/medicinos_dedup.txt
MED_LINES=$(wc -l < data/local/lm/medicinos/medicinos_dedup.txt)
MED_WORDS=$(wc -w < data/local/lm/medicinos/medicinos_dedup.txt)
echo "  Medicinos po dedup: $MED_LINES sakiniu, $MED_WORDS zodziu"

echo ""
echo "============================================================"
echo "  ETAPAS 2: Sukuriamas SUJUNGTAS treniravimo korpusas"
echo "============================================================"
cat $CV_TEXT $WIKI_TEXT data/local/lm/medicinos/medicinos_dedup.txt > $OUT_TEXT
TOTAL_LINES=$(wc -l < $OUT_TEXT)
TOTAL_WORDS=$(wc -w < $OUT_TEXT)
TOTAL_VOCAB=$(tr ' ' '\n' < $OUT_TEXT | sort -u | wc -l)
CV_LINES=$(wc -l < $CV_TEXT)
WIKI_LINES=$(wc -l < $WIKI_TEXT)

echo "  CV     : $CV_LINES sakiniu"
echo "  Wiki   : $WIKI_LINES sakiniu"
echo "  Medicinos: $MED_LINES sakiniu"
echo "  ---"
echo "  Visi   : $TOTAL_LINES sakiniu, $TOTAL_WORDS zodziu, $TOTAL_VOCAB unikaliu zodziu"

echo ""
echo "============================================================"
echo "  ETAPAS 3: OOV analize"
echo "============================================================"
awk '{ for (i=2;i<=NF;i++) print $i }' $TEST_TEXT | sort -u > /tmp/test_vocab.txt
TEST_VOCAB=$(wc -l < /tmp/test_vocab.txt)
tr ' ' '\n' < $OUT_TEXT | sort -u > /tmp/wiki_med_vocab.txt
OOV=$(comm -23 /tmp/test_vocab.txt /tmp/wiki_med_vocab.txt | wc -l)
OOV_PCT=$(awk "BEGIN{printf \"%.2f\", 100*$OOV/$TEST_VOCAB}")

echo "  Testo unikaliu zodziu : $TEST_VOCAB"
echo "  OOV (CV+Wiki+Med)     : $OOV ($OOV_PCT %)"

# Lyginimui - is anksciau Wiki only
tr ' ' '\n' < <(cat $CV_TEXT $WIKI_TEXT) | sort -u > /tmp/wiki_only_vocab.txt
OOV_WIKI=$(comm -23 /tmp/test_vocab.txt /tmp/wiki_only_vocab.txt | wc -l)
echo "  (Lyginimui) OOV CV+Wiki: $OOV_WIKI"

echo ""
echo "============================================================"
echo "  ETAPAS 4: Praplestas leksikonas (data/local/dict_wiki_med)"
echo "============================================================"
mkdir -p $DICT_DST
cp $DICT_SRC/nonsilence_phones.txt $DICT_DST/
cp $DICT_SRC/silence_phones.txt $DICT_DST/
cp $DICT_SRC/optional_silence.txt $DICT_DST/
cp $DICT_SRC/extra_questions.txt $DICT_DST/

awk '{print $1}' $DICT_SRC/lexicon.txt | sort -u > /tmp/lex_wiki_vocab.txt
NEW_WORDS=$(comm -23 /tmp/wiki_med_vocab.txt /tmp/lex_wiki_vocab.txt | wc -l)
echo "  Naujai pridedamu zodziu (Med): $NEW_WORDS"

cp $DICT_SRC/lexicon.txt $DICT_DST/lexicon.txt
comm -23 /tmp/wiki_med_vocab.txt /tmp/lex_wiki_vocab.txt > /tmp/new_med_words.txt
PYTHONIOENCODING=utf-8 python3 - <<EOF >> $DICT_DST/lexicon.txt
phones = set(open("$DICT_DST/nonsilence_phones.txt", encoding="utf-8").read().split())
with open("/tmp/new_med_words.txt", encoding="utf-8") as f:
    for line in f:
        w = line.strip()
        if not w:
            continue
        chars = list(w)
        if all(c in phones for c in chars):
            print(w + " " + " ".join(chars))
EOF

LEX_OLD=$(wc -l < $DICT_SRC/lexicon.txt)
LEX_NEW=$(wc -l < $DICT_DST/lexicon.txt)
echo "  Leksikonas pries (Wiki): $LEX_OLD"
echo "  Leksikonas po (Wiki+Med): $LEX_NEW (+$((LEX_NEW - LEX_OLD)) eilutes)"

if [ -f $DICT_SRC/lexiconp.txt ]; then
  awk '{printf "%s 1.0", $1; for(i=2;i<=NF;i++) printf " %s", $i; printf "\n"}' \
      $DICT_DST/lexicon.txt > $DICT_DST/lexiconp.txt
fi

echo ""
echo "============================================================"
echo "  ETAPAS 5: data/lang_wiki_med sukurimas"
echo "============================================================"
rm -rf $LANG_TMP $LANG_DST
utils/prepare_lang.sh $DICT_DST "<UNK>" $LANG_TMP $LANG_DST

echo ""
echo "============================================================"
echo "  STATISTIKOS SUVESTINE"
echo "============================================================"
{
  echo "CV sakiniu                      : $CV_LINES"
  echo "Wiki sakiniu                    : $WIKI_LINES"
  echo "Medicinos sakiniu (po dedup)    : $MED_LINES"
  echo "Visi sakiniu                    : $TOTAL_LINES"
  echo "Visi zodziu                     : $TOTAL_WORDS"
  echo "Unikaliu zodziu                 : $TOTAL_VOCAB"
  echo "Testo unikaliu zodziu           : $TEST_VOCAB"
  echo "OOV (CV+Wiki) - is anksciau     : $OOV_WIKI"
  echo "OOV (CV+Wiki+Med) - dabar       : $OOV ($OOV_PCT %)"
  echo "Leksikonas Wiki only            : $LEX_OLD"
  echo "Leksikonas Wiki+Med             : $LEX_NEW"
} | tee $STATS

echo ""
echo "Pasiruosimas baigtas. Toliau:"
echo "  ./magistras_trigram_wiki_med.sh"
