#!/bin/bash
export LC_ALL=C
. ./path.sh

# ============================================================
#  Trigram modelio kurimas su CV + Wiki + Medicinos korpusu
#  KenLM su --prune 0 0 1
# ============================================================

ORDER=3
MODEL_NAME="trigram_wiki_med"

KENLM_BIN=$HOME/kenlm/build/bin/lmplz
[ ! -x "$KENLM_BIN" ] && echo "KLAIDA: KenLM lmplz nerastas: $KENLM_BIN" && exit 1

echo "======================================================"
echo "  TRIGRAM CV+Wiki+Medicinos LM"
echo "  Korpusas: data/local/lm/train_text_wiki_med.txt"
echo "  Lang dir: data/lang_wiki_med"
echo "======================================================"

ARPA=data/local/lm/${MODEL_NAME}.arpa.gz
ARPA_TMP=data/local/lm/${MODEL_NAME}.arpa
LANG_DIR_SRC=data/lang_wiki_med
LANG_DIR=data/lang_${MODEL_NAME}
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}
TEXT=data/local/lm/train_text_wiki_med.txt
LEXICON=data/local/dict_wiki_med/lexicon.txt

for f in $TEXT $LEXICON $LANG_DIR_SRC data/test exp/tri3/final.mdl; do
  [ ! -e "$f" ] && echo "KLAIDA: trūksta $f (paleiskite ./prepare_wiki_med_corpus.sh pirma)" && exit 1
done

echo ""
echo "--- 1. Generuojame ARPA su KenLM (--prune 0 0 1) ---"
mkdir -p data/local/lm
$KENLM_BIN -o $ORDER --prune 0 0 1 --text $TEXT --arpa $ARPA_TMP \
    --discount_fallback -S 70% -T /tmp || { echo "KLAIDA: KenLM"; exit 1; }
gzip -f $ARPA_TMP
echo "ARPA sukurtas: $ARPA"

echo ""
echo "--- 2. Ruosiame $LANG_DIR ---"
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
echo "--- 5. Dekodavimas (nj=4 - saugu didziam HCLG) ---"
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
echo "  GALUTINIS REZULTATAS (TRIGRAM CV+Wiki+Med):"
echo "  ant Common Voice testo aibes (5517 utterances)"
grep "%WER" $DECODE_DIR/wer.* | utils/best_wer.sh
echo "======================================================"
echo ""
echo "PASTABA: sis WER yra ant CV testo (bendrines kalbos)."
echo "Su tikru medicinos audio testu (jusu irasai) WER butu kitokios"
echo "(turi buti zenkliai mazesni nei bendrinis Trigram_wiki)."
