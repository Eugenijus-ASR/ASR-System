#!/bin/bash
export LC_ALL=C
. ./path.sh

# 1. Patikriname, ar grafas tikrai egzistuoja
if [ ! -f exp/tri3/graph/HCLG.fst ]; then
    echo "KLAIDA: Grafas nesukurtas. Leidžiame mkgraph..."
    utils/mkgraph.sh data/lang_test exp/tri3 exp/tri3/graph || exit 1
fi

# 2. Svarbu: Sumažiname procesų skaičių iki 1 (kad matytume tikrąją klaidą)
# Taip pat patikriname testinių duomenų skaičių
nj=1
# Jei turite daug duomenų, galite padidinti, bet pradėkime nuo 1 saugumui
rm -rf exp/tri3/decode_test

echo "Pradedamas dekodavimas (tai gali užtrukti)..."
steps/decode_fmllr.sh --nj $nj --cmd "run.pl" \
    exp/tri3/graph data/test exp/tri3/decode_test || {
    echo "DEKODAVIMAS LŪŽO. Tikriname log failą..."
    cat exp/tri3/decode_test/log/decode.1.log | tail -n 20
    exit 1
}

# 3. Rezultatų skaičiavimas
echo "Skaičiuojami rezultatai..."
local/score.sh exp/tri3/decode_test data/lang_test/words.txt

echo "------------------------------------------------"
echo "JEI ŠIS SKAIČIUS NEBE -nan, DARBAS BAIGTAS:"
grep WER exp/tri3/decode_test/wer.LMWT* | utils/best_wer.sh
echo "------------------------------------------------"
