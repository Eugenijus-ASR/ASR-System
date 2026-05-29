#!/bin/bash
# ============================================================
#  Trigram_wiki TIK dekodavimas + WER
#  Naudoja jau egzistuojanti HCLG.fst (5.3 GB)
#  Saugiai dirba su nj=4 (~30 GB peak RAM)
# ============================================================
export LC_ALL=C
. ./path.sh

MODEL_NAME="trigram_wiki"
GRAPH_DIR=exp/tri3/graph_${MODEL_NAME}
DECODE_DIR=exp/tri3/decode_test_${MODEL_NAME}

if [ ! -f $GRAPH_DIR/HCLG.fst ]; then
    echo "KLAIDA: nera $GRAPH_DIR/HCLG.fst"
    echo "Turetumete pirma paleisti ./magistras_trigram_wiki.sh"
    exit 1
fi

echo "======================================================"
echo "  TRIGRAM CV+Wiki - tik dekodavimas + WER"
echo "  HCLG dydis: $(du -h $GRAPH_DIR/HCLG.fst | cut -f1)"
echo "  nj=4 (saugu didziam HCLG)"
echo "======================================================"

rm -rf $DECODE_DIR ${DECODE_DIR}.si

echo ""
echo "--- 1. Dekodavimas (nj=4) ---"
steps/decode_fmllr.sh --nj 4 --cmd "run.pl" \
    $GRAPH_DIR data/test $DECODE_DIR || { echo "KLAIDA: decode"; exit 1; }
echo "OK"

echo ""
echo "--- 2. WER skaiciavimas ---"
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
