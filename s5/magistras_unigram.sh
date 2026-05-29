#!/bin/bash
export LC_ALL=C
. ./path.sh

echo "=== 1. Ruošiame duomenis ==="
rm -rf data/lang_test exp/tri3/graph exp/tri3/decode_test
cp -r data/lang data/lang_test

# Įsitikiname, kad turime #1 simbolį (grafui)
LAST_ID=$(tail -n 1 data/lang_test/words.txt | awk '{print $2}')
if ! grep -q "#1" data/lang_test/words.txt; then
    echo "#1 $((LAST_ID + 1))" >> data/lang_test/words.txt
fi

echo "=== 2. Kuriame G.fst ==="
cut -d' ' -f2- data/train/text > data/local/lm/train_text.txt
cat data/local/lm/train_text.txt | utils/make_unigram_grammar.pl | \
  fstcompile --isymbols=data/lang_test/words.txt --osymbols=data/lang_test/words.txt \
  --keep_isymbols=false --keep_osymbols=false | \
  fstarcsort --sort_type=ilabel > data/lang_test/G.fst

echo "=== 3. Kuriame HCLG grafą ==="
utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph || exit 1

echo "=== 4. Dekodavimas (testiniai duomenys) ==="
# Pridedame --skip-scoring true, kad Kaldi pats nelūžtų pabaigoje
steps/decode_fmllr.sh --nj 1 --cmd "run.pl" --skip-scoring true \
    exp/tri3/graph data/test exp/tri3/decode_test || exit 1

echo "=== 5. RANKINIS WER SKAIČIAVIMAS ==="
# Patys ištraukiame geriausią rezultatą be local/score.sh pagalbos
acwt=0.08333
symtab=exp/tri3/graph/words.txt
dir=exp/tri3/decode_test

# Paverčiame groteles į geriausią sakinių variantą
lattice-best-path --acoustic-scale=$acwt --word-symbol-table=$symtab \
  "ark:gunzip -c $dir/lat.1.gz |" ark,t:$dir/final_hyp.txt

# Sutvarkome formatą skaičiavimui
cat $dir/final_hyp.txt | utils/int2sym.pl -f 2- $symtab > $dir/final_hyp_words.txt

echo "-------------------------------------------------------"
echo "JŪSŲ MODELIO ATPAŽINIMO PAVYZDŽIAI (iš testinio rinkinio):"
head -n 5 $dir/final_hyp_words.txt
echo "-------------------------------------------------------"

# Skaičiuojame klaidų lygį (WER)
compute-wer --text --mode=present \
  ark:data/test/text  ark:$dir/final_hyp_words.txt | tee $dir/wer_result.txt

echo "-------------------------------------------------------"
echo "GALUTINIS REZULTATAS:"
grep "%WER" $dir/wer_result.txt
echo "-------------------------------------------------------"
