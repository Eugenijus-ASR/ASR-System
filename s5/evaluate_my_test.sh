#!/bin/bash
# ============================================================
#  4.7 skyriaus evaluation - 4 eksperimentai ant data/my_test/
#
#  | # | Akustinis        | LM                   |
#  |---|------------------|----------------------|
#  | 1 | tri3 (CV-only)   | Trigram_wiki         |
#  | 2 | tri3 (CV-only)   | Trigram_wiki_med     |
#  | 3 | tri3_adapted     | Trigram_wiki         |
#  | 4 | tri3_adapted     | Trigram_wiki_med     |
# ============================================================
. ./path.sh
set -e

TEST_DIR=data/my_test

# Konfiguracijos: AKUSTINIS  LM_GRAPH  PAVADINIMAS
declare -a EXPERIMENTS=(
    "exp/tri3          exp/tri3/graph_trigram_wiki         exp1_baseline"
    "exp/tri3          exp/tri3/graph_trigram_wiki_med     exp2_lm_only"
    "exp/tri3_adapted  exp/tri3_adapted/graph_trigram_wiki  exp3_acoustic_only"
    "exp/tri3_adapted  exp/tri3_adapted/graph_trigram_wiki_med exp4_full_adapt"
)

# Patikrint duomenu aplanka
for f in $TEST_DIR/text $TEST_DIR/wav.scp $TEST_DIR/feats.scp $TEST_DIR/cmvn.scp; do
    [ ! -e "$f" ] && echo "KLAIDA: nera $f. Paleiskite ./prepare_my_train.sh" && exit 1
done

# Patikrint adaptuota modeli
if [ ! -f exp/tri3_adapted/final.mdl ]; then
    echo "KLAIDA: nera exp/tri3_adapted/final.mdl"
    echo "Paleiskite: ./magistras_map_adapt.sh"
    exit 1
fi

echo "============================================================"
echo "  ETAPAS 1: HCLG grafai adaptuotam modeliui"
echo "  (jeigu jau yra - praleidziami)"
echo "============================================================"

# tri3_adapted + Trigram_wiki
if [ ! -f exp/tri3_adapted/graph_trigram_wiki/HCLG.fst ]; then
    echo ""
    echo "--- Statome graph_trigram_wiki adaptuotam modeliui ---"
    rm -rf exp/tri3_adapted/graph_trigram_wiki
    utils/mkgraph.sh data/lang_trigram_wiki exp/tri3_adapted exp/tri3_adapted/graph_trigram_wiki
else
    echo "  exp/tri3_adapted/graph_trigram_wiki - jau yra"
fi

# tri3_adapted + Trigram_wiki_med
if [ ! -f exp/tri3_adapted/graph_trigram_wiki_med/HCLG.fst ]; then
    echo ""
    echo "--- Statome graph_trigram_wiki_med adaptuotam modeliui ---"
    rm -rf exp/tri3_adapted/graph_trigram_wiki_med
    utils/mkgraph.sh data/lang_trigram_wiki_med exp/tri3_adapted exp/tri3_adapted/graph_trigram_wiki_med
else
    echo "  exp/tri3_adapted/graph_trigram_wiki_med - jau yra"
fi

# Funkcija - dekoduoja viena konfiguracija
decode_one() {
    local model_dir=$1
    local graph_dir=$2
    local exp_name=$3
    local decode_dir="${model_dir}/decode_my_test_${exp_name}"

    echo ""
    echo "============================================================"
    echo "  EKSPERIMENTAS: $exp_name"
    echo "  Akustinis: $model_dir"
    echo "  Grafas: $graph_dir"
    echo "============================================================"

    rm -rf "$decode_dir"
    steps/decode_fmllr.sh --nj 1 --cmd "run.pl" --skip-scoring true \
        "$graph_dir" "$TEST_DIR" "$decode_dir" 2>&1 | tail -10

    # Manualinis WER skaiciavimas (apeinant Kaldi vidini score'a)
    local symtab="$graph_dir/words.txt"
    for lmwt in $(seq 7 17); do
        local acwt=$(perl -e "print (1.0/$lmwt);")
        lattice-best-path --acoustic-scale=$acwt --word-symbol-table=$symtab \
            "ark:gunzip -c $decode_dir/lat.*.gz |" \
            ark,t:$decode_dir/hyp_int.${lmwt}.txt 2>/dev/null
        cat $decode_dir/hyp_int.${lmwt}.txt | \
            utils/int2sym.pl -f 2- $symtab > $decode_dir/hyp.${lmwt}.txt
        compute-wer --text --mode=present \
            ark:$TEST_DIR/text \
            ark:$decode_dir/hyp.${lmwt}.txt \
            > $decode_dir/wer.${lmwt} 2>/dev/null
    done

    echo ""
    echo "  REZULTATAS:"
    grep "%WER" $decode_dir/wer.* | utils/best_wer.sh | sed 's/^/    /'
}

echo ""
echo "============================================================"
echo "  ETAPAS 2: 4 eksperimentai"
echo "============================================================"

for entry in "${EXPERIMENTS[@]}"; do
    read -r model graph name <<< "$entry"
    decode_one "$model" "$graph" "$name"
done

echo ""
echo "============================================================"
echo "  GALUTINE 4.7 LENTELE"
echo "============================================================"
printf "%-30s %-15s\n" "Eksperimentas" "Geriausias %WER"
printf "%-30s %-15s\n" "------" "------"
for entry in "${EXPERIMENTS[@]}"; do
    read -r model graph name <<< "$entry"
    local_decode_dir="${model}/decode_my_test_${name}"
    if [ -d "$local_decode_dir" ]; then
        wer=$(grep "%WER" $local_decode_dir/wer.* 2>/dev/null | utils/best_wer.sh 2>/dev/null | grep -oP '%WER \K[0-9.]+')
        printf "%-30s %-15s\n" "$name" "${wer:-N/A}"
    fi
done

echo ""
echo "Issaugota: ${EXPERIMENTS[0]##* }/decode_my_test_*"
echo "Lyginimas su Trigram_wiki ant CV testo: 16.65%"
