#!/bin/bash
. ./path.sh

# 1. Konvertuojame (tik jei reikia)
if [ ! -f mano_balsas.wav ]; then
    ffmpeg -i test_failas.mp3 -ar 16000 -ac 1 mano_balsas.wav
fi

# 2. Išvalome senus rezultatus, kad nebūtų painiavos
rm -rf data/mano_testas exp/tri3/decode_mano

# 3. Ruošiame duomenis
mkdir -p data/mano_testas
echo "as1 $(pwd)/mano_balsas.wav" > data/mano_testas/wav.scp
echo "as1 as1" > data/mano_testas/utt2spk
cp data/mano_testas/utt2spk data/mano_testas/spk2utt

# 4. Požymiai
steps/make_mfcc.sh --nj 1 data/mano_testas exp/make_mfcc/mano_testas mfcc || exit 1
steps/compute_cmvn_stats.sh data/mano_testas exp/make_mfcc/mano_testas mfcc || exit 1

# 5. Dekodavimas
steps/decode_fmllr.sh --nj 1 --cmd "run.pl" --skip-scoring true \
    exp/tri3/graph data/mano_testas exp/tri3/decode_mano

# 6. Rankinis rezultato ištraukimas (apeinant score.sh)
echo "------------------------------------------"
echo "IESKOMAS ATPAZINTAS TEKSTAS..."

# Nustatome parametrus
acwt=0.08333
symtab=exp/tri3/graph/words.txt
dir=exp/tri3/decode_mano

# Priverstinai sugeneruojame tekstą iš grotelių
lattice-best-path --acoustic-scale=$acwt --word-symbol-table=$symtab \
  "ark:gunzip -c $dir/lat.*.gz |" ark,t:$dir/one_best.tra 2>/dev/null

# Paverčiame ID į žodžius
if [ -f $dir/one_best.tra ]; then
    utils/int2sym.pl -f 2- $symtab $dir/one_best.tra > atpazinimo_rezultatas.txt
    echo "SEKME! Atpazintas tekstas:"
    cat atpazinimo_rezultatas.txt | cut -d' ' -f2-
else
    echo "KLAIDA: Nepavyko sugeneruoti one_best.tra. Tikrinkite exp/tri3/decode_mano/log/decode.1.log"
fi
echo "------------------------------------------"