#!/bin/bash
export LC_ALL=C
. ./path.sh

# ============================================================
#  Bigram / Trigram modelio kūrimo skriptas su KenLM
#  Naudojimas:  ./magistras_ngram.sh [2|3]
#    2 = bigram (numatytasis)
#    3 = trigram
# ============================================================

ORDER=${1:-2}

if [ "$ORDER" == "2" ]; then
  MODEL_NAME="bigram"
elif [ "$ORDER" == "3" ]; then
  MODEL_NAME="trigram"
else
  echo "Naudojimas: $0 [2|3]"
  echo "  2 = bigram"
  echo "  3 = trigram"
  exit 1
fi

# KenLM kelias
KENLM_BIN=$HOME/kenlm/build/bin/lmplz
[ ! -x "$KENLM_BIN" ] && echo "KLAIDA: KenLM lmplz nerastas: $KENLM_BIN" && exit 1

echo "======================================================"
echo "  Pradedamas ${MODEL_NAME} modelio kūrimas (order=$ORDER)"
echo "  Įrankis: KenLM (modifikuotas Kneser-Ney glodinimas)"
echo "======================================================"

ARPA=data/local/lm/${MODEL_NAME}.arpa.gz
ARPA_TMP=data/local/lm/${MODEL_NAME}.arpa
LANG_DIR=data/lang_${MODEL_NAME}
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}
TEXT=data/local/lm/train_text.txt
LEXICON=data/local/dict/lexicon.txt

# --- 1. Patikriname reikalingus failus ---
for f in $TEXT $LEXICON data/lang data/test exp/tri3/final.mdl; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f" && exit 1
done

# --- 2. Generuojame ARPA su KenLM ---
echo ""
echo "--- 1. Generuojame ARPA su KenLM (order=$ORDER) ---"
mkdir -p data/local/lm

# --discount_fallback - reikalingas mažiems korpusams (kur singletonų gali nepakakti)
$KENLM_BIN \
    -o $ORDER \
    --text $TEXT \
    --arpa $ARPA_TMP \
    --discount_fallback \
    -S 20% \
    -T /tmp || { echo "KLAIDA: KenLM nepavyko"; exit 1; }

# Suspaudžiame
gzip -f $ARPA_TMP

echo "ARPA sukurtas: $ARPA"

# --- 3. Ruošiame lang katalogą ---
echo ""
echo "--- 2. Ruošiame $LANG_DIR ---"
rm -rf $LANG_DIR
cp -r data/lang $LANG_DIR

# Užtikriname #0 simbolį
LAST_ID=$(tail -n 1 $LANG_DIR/words.txt | awk '{print $2}')
if ! grep -q "^#0 " $LANG_DIR/words.txt; then
    echo "#0 $((LAST_ID + 1))" >> $LANG_DIR/words.txt
fi

# --- 4. Konvertuojame ARPA → G.fst ---
echo ""
echo "--- 3. Konvertuojame ARPA → G.fst ---"
utils/format_lm.sh $LANG_DIR $ARPA $LEXICON $LANG_DIR || exit 1

# --- 5. Kuriame HCLG grafą ---
echo ""
echo "--- 4. Kuriame HCLG grafą ---"
rm -rf $GRAPH_DIR
utils/mkgraph.sh $LANG_DIR exp/tri3 $GRAPH_DIR || exit 1

# --- 6. Dekodavimas ---
echo ""
echo "--- 5. Dekodavimas (${MODEL_NAME}) ---"
rm -rf $DECODE_DIR
steps/decode_fmllr.sh --nj 4 --cmd "run.pl" \
    $GRAPH_DIR data/test $DECODE_DIR || exit 1

# --- 7. WER skaičiavimas ---
echo ""
echo "--- 6. Skaičiuojamas WER ---"
SYMTAB=$GRAPH_DIR/words.txt
for lmwt in $(seq 7 17); do
    acwt=$(perl -e "print (1.0/$lmwt);")
    # 1. Geriausias kelias iš grotelių (ID formatu)
    lattice-best-path \
        --acoustic-scale=$acwt \
        --word-symbol-table=$SYMTAB \
        "ark:gunzip -c $DECODE_DIR/lat.*.gz |" \
        ark,t:$DECODE_DIR/hyp_int.${lmwt}.txt 2>/dev/null
    # 2. Konvertuojame ID → žodžiai
    cat $DECODE_DIR/hyp_int.${lmwt}.txt | \
        utils/int2sym.pl -f 2- $SYMTAB \
        > $DECODE_DIR/hyp.${lmwt}.txt
    # 3. WER skaičiavimas
    compute-wer --text --mode=present \
        ark:data/test/text \
        ark:$DECODE_DIR/hyp.${lmwt}.txt \
        > $DECODE_DIR/wer.${lmwt} 2>/dev/null
done

echo ""
echo "======================================================"
echo "  GALUTINIS REZULTATAS (${MODEL_NAME}):"
grep "%WER" $DECODE_DIR/wer.* | utils/best_wer.sh
echo "======================================================"
