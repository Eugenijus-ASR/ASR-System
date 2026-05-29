#!/bin/bash
# ============================================================
#  Wikipedia korpuso prijungimo skriptas
#  Sukuria:
#    data/local/lm/train_text_wiki.txt    (CV + Wiki sakiniai)
#    data/local/dict_wiki/lexicon.txt     (praplestas leksikonas)
#    data/lang_wiki                       (nauja lang direktorija)
#  Statistika spausdinama i ekrana ir saugoma corpus_stats.txt
# ============================================================
export LC_ALL=C
. ./path.sh

set -e

WIKI_RAW=data/local/lm/wiki/wiki_text_raw.txt
TRAIN_TEXT=data/local/lm/train_text.txt
TEST_TEXT=data/test/text
OUT_TEXT=data/local/lm/train_text_wiki.txt

DICT_SRC=data/local/dict
DICT_DST=data/local/dict_wiki
LANG_TMP=data/local/lang_wiki_tmp
LANG_DST=data/lang_wiki
STATS=data/local/lm/wiki/corpus_stats.txt

for f in $WIKI_RAW $TRAIN_TEXT $TEST_TEXT $DICT_SRC/lexicon.txt $DICT_SRC/nonsilence_phones.txt; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f" && exit 1
done

echo "============================================================"
echo "  ETAPAS 1: Wiki teksto pirminis valymas (deduplicate, sutvarkyti)"
echo "============================================================"

# Dedupe Wiki sentences (kai kurie kartojasi tarp straipsniu)
awk 'NF>=4 && !seen[$0]++' $WIKI_RAW > data/local/lm/wiki/wiki_text_dedup.txt
WIKI_LINES=$(wc -l < data/local/lm/wiki/wiki_text_dedup.txt)
WIKI_WORDS=$(wc -w < data/local/lm/wiki/wiki_text_dedup.txt)
echo "  Wiki po dedup ir filtro: $WIKI_LINES sakiniu, $WIKI_WORDS zodziu"

echo ""
echo "============================================================"
echo "  ETAPAS 2: Sukuriamas prapletas treniravimo korpusas"
echo "============================================================"
cat $TRAIN_TEXT data/local/lm/wiki/wiki_text_dedup.txt > $OUT_TEXT
TOTAL_LINES=$(wc -l < $OUT_TEXT)
TOTAL_WORDS=$(wc -w < $OUT_TEXT)
TOTAL_VOCAB=$(tr ' ' '\n' < $OUT_TEXT | sort -u | wc -l)
CV_LINES=$(wc -l < $TRAIN_TEXT)
CV_WORDS=$(wc -w < $TRAIN_TEXT)
CV_VOCAB=$(tr ' ' '\n' < $TRAIN_TEXT | sort -u | wc -l)

echo "  CV     : $CV_LINES sakiniu, $CV_WORDS zodziu, $CV_VOCAB unikaliu zodziu"
echo "  CV+Wiki: $TOTAL_LINES sakiniu, $TOTAL_WORDS zodziu, $TOTAL_VOCAB unikaliu zodziu"

echo ""
echo "============================================================"
echo "  ETAPAS 3: OOV analize testavimo aibei"
echo "============================================================"
# Test set words (be utterance ID)
awk '{ for (i=2;i<=NF;i++) print $i }' $TEST_TEXT | sort -u > /tmp/test_vocab.txt
TEST_VOCAB=$(wc -l < /tmp/test_vocab.txt)
tr ' ' '\n' < $TRAIN_TEXT | sort -u > /tmp/cv_vocab.txt
tr ' ' '\n' < $OUT_TEXT | sort -u > /tmp/wiki_vocab.txt

OOV_CV=$(comm -23 /tmp/test_vocab.txt /tmp/cv_vocab.txt | wc -l)
OOV_WIKI=$(comm -23 /tmp/test_vocab.txt /tmp/wiki_vocab.txt | wc -l)
OOV_CV_PCT=$(awk "BEGIN{printf \"%.2f\", 100*$OOV_CV/$TEST_VOCAB}")
OOV_WIKI_PCT=$(awk "BEGIN{printf \"%.2f\", 100*$OOV_WIKI/$TEST_VOCAB}")

echo "  Testo unikaliu zodziu       : $TEST_VOCAB"
echo "  OOV pries (tik CV)          : $OOV_CV ($OOV_CV_PCT %)"
echo "  OOV po (CV + Wiki)          : $OOV_WIKI ($OOV_WIKI_PCT %)"

echo ""
echo "============================================================"
echo "  ETAPAS 4: Praplestas leksikonas (data/local/dict_wiki)"
echo "============================================================"
mkdir -p $DICT_DST
# Kopijuojame fonetines apibreztis nepakeistas
cp $DICT_SRC/nonsilence_phones.txt $DICT_DST/
cp $DICT_SRC/silence_phones.txt $DICT_DST/
cp $DICT_SRC/optional_silence.txt $DICT_DST/
cp $DICT_SRC/extra_questions.txt $DICT_DST/

# Esamame leksikone jau yra zodziai is OG mokymo + galbut testo aibe.
# Pridedame tik tuos Wiki zodzius, kuriu dar nera leksikone.
awk '{print $1}' $DICT_SRC/lexicon.txt | sort -u > /tmp/lex_vocab.txt
NEW_WORDS=$(comm -23 /tmp/wiki_vocab.txt /tmp/lex_vocab.txt | wc -l)
echo "  Naujai pridedamu zodziu    : $NEW_WORDS"

# Sukuriame nauja lexicon: senas + grafem-skaldyti naujieji
cp $DICT_SRC/lexicon.txt $DICT_DST/lexicon.txt
comm -23 /tmp/wiki_vocab.txt /tmp/lex_vocab.txt > /tmp/new_words.txt
PYTHONIOENCODING=utf-8 python3 - <<EOF >> $DICT_DST/lexicon.txt
# -*- coding: utf-8 -*-
phones = set(open("$DICT_DST/nonsilence_phones.txt", encoding="utf-8").read().split())
with open("/tmp/new_words.txt", encoding="utf-8") as f:
    for line in f:
        w = line.strip()
        if not w:
            continue
        chars = list(w)
        # Saugojame tik tada, kai visi simboliai yra leksikoniniame fonu rinkinyje
        if all(c in phones for c in chars):
            print(w + " " + " ".join(chars))
EOF

LEX_OLD=$(wc -l < $DICT_SRC/lexicon.txt)
LEX_NEW=$(wc -l < $DICT_DST/lexicon.txt)
echo "  Leksikonas pries           : $LEX_OLD"
echo "  Leksikonas po              : $LEX_NEW (+$((LEX_NEW - LEX_OLD)) eilutes)"

# Atnaujiname lexiconp.txt (jeigu egzistuoja)
if [ -f $DICT_SRC/lexiconp.txt ]; then
  awk '{printf "%s 1.0", $1; for(i=2;i<=NF;i++) printf " %s", $i; printf "\n"}' \
      $DICT_DST/lexicon.txt > $DICT_DST/lexiconp.txt
fi

echo ""
echo "============================================================"
echo "  ETAPAS 5: data/lang_wiki sukurimas (utils/prepare_lang.sh)"
echo "============================================================"
rm -rf $LANG_TMP $LANG_DST
utils/prepare_lang.sh $DICT_DST "<UNK>" $LANG_TMP $LANG_DST

echo ""
echo "============================================================"
echo "  STATISTIKOS SUVESTINE"
echo "============================================================"
{
  echo "Wiki sakiniu po dedup           : $WIKI_LINES"
  echo "Wiki zodziu po dedup            : $WIKI_WORDS"
  echo "CV sakiniu                      : $CV_LINES"
  echo "CV zodziu                       : $CV_WORDS"
  echo "CV unikaliu zodziu              : $CV_VOCAB"
  echo "CV+Wiki sakiniu                 : $TOTAL_LINES"
  echo "CV+Wiki zodziu                  : $TOTAL_WORDS"
  echo "CV+Wiki unikaliu zodziu         : $TOTAL_VOCAB"
  echo "Testo unikaliu zodziu           : $TEST_VOCAB"
  echo "OOV pries (CV)                  : $OOV_CV ($OOV_CV_PCT %)"
  echo "OOV po (CV+Wiki)                : $OOV_WIKI ($OOV_WIKI_PCT %)"
  echo "Leksikonas pries                : $LEX_OLD"
  echo "Leksikonas po                   : $LEX_NEW"
} | tee $STATS

echo ""
echo "Pasiruosima baigta. Toliau galite leisti:"
echo "  ./magistras_bigram_wiki.sh"
echo "  ./magistras_trigram_wiki.sh"
