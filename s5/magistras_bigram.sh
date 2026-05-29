#!/bin/bash
export LC_ALL=C
. ./path.sh

# ============================================================
#  Bigram modelio kūrimas su KenLM
#  (modifikuotas Kneser-Ney glodinimas)
# ============================================================

ORDER=2
MODEL_NAME="bigram"

KENLM_BIN=$HOME/kenlm/build/bin/lmplz
[ ! -x "$KENLM_BIN" ] && echo "KLAIDA: KenLM lmplz nerastas: $KENLM_BIN" && exit 1

echo "======================================================"
echo "  Pradedamas BIGRAM modelio kūrimas (order=2)"
echo "  Įrankis: KenLM (modifikuotas Kneser-Ney)"
echo "======================================================"

ARPA=data/local/lm/${MODEL_NAME}.arpa.gz
ARPA_TMP=data/local/lm/${MODEL_NAME}.arpa
LANG_DIR=data/lang_${MODEL_NAME}
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}
TEXT=data/local/lm/train_text.txt
LEXICON=data/local/dict/lexicon.txt

for f in $TEXT $LEXICON data/lang data/test exp/tri3/final.mdl; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f" && exit 1
done

echo ""
echo "--- 1. Generuojame ARPA su KenLM ---"
mkdir -p data/local/lm
$KENLM_BIN -o $ORDER --text $TEXT --arpa $ARPA_TMP \
    --discount_fallback -S 20% -T /tmp || { echo "KLAIDA: KenLM"; exit 1; }
gzip -f $ARPA_TMP
echo "ARPA sukurtas: $ARPA"

echo ""
echo "--- 2. Ruošiame $LANG_DIR ---"
rm -rf $LANG_DIR
cp -r data/lang $LANG_DIR
LAST_ID=$(tail -n 1 $LANG_DIR/words.txt | awk '{print $2}')
grep -q "^#0 " $LANG_DIR/words.txt || echo "#0 $((LAST_ID + 1))" >> $LANG_DIR/words.txt

echo ""
echo "--- 3. ARPA → G.fst ---"
utils/format_lm.sh $LANG_DIR $ARPA $LEXICON $LANG_DIR || exit 1

echo ""
echo "--- 4. HCLG grafas ---"
rm -rf $GRAPH_DIR
utils/mkgraph.sh $LANG_DIR exp/tri3 $GRAPH_DIR || exit 1

echo ""
echo "--- 5. Dekodavimas ---"
rm -rf $DECODE_DIR
steps/decode_fmllr.sh --nj 4 --cmd "run.pl" \
    $GRAPH_DIR data/test $DECODE_DIR || exit 1

echo ""
echo "--- 6. WER skaičiavimas ---"
SYMTAB=$GRAPH_DIR/words.txt
for lmwt in $(seq 7 17); do
    acwt=$(perl -e "print (1.0/$lmwt);")
    lattice-best-path --acoustic-scale=$acwt --word-symbol-table=$SYMTAB \
        "ark:gunzip -c $DECODE_DIR/lat.*.gz |" \
        ark,t:$DECODE_DIR/hyp_int.${lmwt}.txt 2>/dev/null
    cat $DECODE_DIR/hyp_int.${lmwt}.txt | \
        utils/int2sym.pl -f 2- $SYMTAB > $DECODE_DIR/hyp.${lmwt}.txt
    compute-wer --text --mode=present \
        ark:data/test/text \
        ark:$DECODE_DIR/hyp.${lmwt}.txt \
        > $DECODE_DIR/wer.${lmwt} 2>/dev/null
done

echo ""
echo "======================================================"
echo "  GALUTINIS REZULTATAS (BIGRAM):"
grep "%WER" $DECODE_DIR/wer.* | utils/best_wer.sh
echo "======================================================"
