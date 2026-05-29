#!/bin/bash
export LC_ALL=C
. ./path.sh

# ============================================================
#  Trigram modelio kurimas su prapletu korpusu (CV + Wikipedia)
#  Naudojamas KenLM (modifikuotas Kneser-Ney)
# ============================================================

ORDER=3
MODEL_NAME="trigram_wiki"

KENLM_BIN=$HOME/kenlm/build/bin/lmplz
[ ! -x "$KENLM_BIN" ] && echo "KLAIDA: KenLM lmplz nerastas: $KENLM_BIN" && exit 1

echo "======================================================"
echo "  Pradedamas TRIGRAM modelio (CV+Wiki) kurimas"
echo "  Korpusas: data/local/lm/train_text_wiki.txt"
echo "  Lang dir: data/lang_wiki"
echo "======================================================"

ARPA=data/local/lm/${MODEL_NAME}.arpa.gz
ARPA_TMP=data/local/lm/${MODEL_NAME}.arpa
LANG_DIR_SRC=data/lang_wiki
LANG_DIR=data/lang_${MODEL_NAME}
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}
TEXT=data/local/lm/train_text_wiki.txt
LEXICON=data/local/dict_wiki/lexicon.txt

for f in $TEXT $LEXICON $LANG_DIR_SRC data/test exp/tri3/final.mdl; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f (paleiskite ./prepare_wiki_corpus.sh pirma)" && exit 1
done

echo ""
echo "--- 1. Generuojame ARPA su KenLM (su --prune 0 0 1) ---"
# --prune 0 0 1: paliekam visus unigram/bigram, atmetam vieno panaudojimo trigramus
# Tai apie 50% sumazina trigram FST be reiksmingu WER pasekmiu (standart asr praktika).
mkdir -p data/local/lm
$KENLM_BIN -o $ORDER --prune 0 0 1 --text $TEXT --arpa $ARPA_TMP \
    --discount_fallback -S 70% -T /tmp || { echo "KLAIDA: KenLM"; exit 1; }
gzip -f $ARPA_TMP
echo "ARPA sukurtas: $ARPA"

echo ""
echo "--- 2. Ruosiame $LANG_DIR (kopija is data/lang_wiki) ---"
rm -rf $LANG_DIR
cp -r $LANG_DIR_SRC $LANG_DIR
LAST_ID=$(tail -n 1 $LANG_DIR/words.txt | awk '{print $2}')
grep -q "^#0 " $LANG_DIR/words.txt || echo "#0 $((LAST_ID + 1))" >> $LANG_DIR/words.txt

echo ""
echo "--- 3. ARPA -> G.fst ---"
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
echo "--- 6. WER skaiciavimas ---"
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
echo "  GALUTINIS REZULTATAS (TRIGRAM CV+Wiki):"
grep "%WER" $DECODE_DIR/wer.* | utils/best_wer.sh
echo "======================================================"
