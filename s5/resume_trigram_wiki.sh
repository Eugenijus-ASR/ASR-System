#!/bin/bash
# ============================================================
#  Trigram_wiki RESUME skriptas
#  Skipps: KenLM (.arpa.gz) ir lang_prep (data/lang_trigram_wiki)
#  Vykdo : mkgraph + decode_fmllr + WER skaiciavimas
# ============================================================
export LC_ALL=C
. ./path.sh

MODEL_NAME="trigram_wiki"
LANG_DIR=data/lang_${MODEL_NAME}
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}

# Tikrinam, kad reikalingos detales jau egzistuoja
for f in $LANG_DIR/G.fst $LANG_DIR/L_disambig.fst $LANG_DIR/words.txt $LANG_DIR/phones.txt exp/tri3/final.mdl exp/tri3/tree; do
    [ ! -f "$f" ] && echo "TRUKSTA: $f. Paleiskite ./magistras_trigram_wiki.sh nuo nulio." && exit 1
done

# Pridedam #0 i words.txt jeigu trūksta
if ! grep -q "^#0 " $LANG_DIR/words.txt; then
    LAST_ID=$(tail -n 1 $LANG_DIR/words.txt | awk '{print $2}')
    echo "#0 $((LAST_ID + 1))" >> $LANG_DIR/words.txt
fi

echo "======================================================"
echo "  RESUME: pradedam nuo HCLG kompozicijos"
echo "======================================================"

# --- 4. HCLG grafas ---
echo ""
echo "--- 4. HCLG grafas (mkgraph) ---"
echo "    (uztruks ~5-10 min, naudos ~15-20 GB RAM)"
rm -rf $GRAPH_DIR
utils/mkgraph.sh $LANG_DIR exp/tri3 $GRAPH_DIR || { echo "KLAIDA: mkgraph"; exit 1; }
echo "OK"

# --- 5. Dekodavimas ---
echo ""
echo "--- 5. Dekodavimas (nj=16) ---"
rm -rf $DECODE_DIR
steps/decode_fmllr.sh --nj 4 --cmd "run.pl" \
    $GRAPH_DIR data/test $DECODE_DIR || { echo "KLAIDA: decode"; exit 1; }
echo "OK"

# --- 6. WER skaiciavimas ---
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
