#!/bin/bash
. ./path.sh
. ./cmd.sh

# Nurodome kur tavo paruošti duomenys
raw_data=~/magistras/data/cv_lt_24

echo "--- 1. Kopijuojame duomenis į projekto vidų ---"
mkdir -p data/train data/test data/local/dict
cp $raw_data/kaldi_train/* data/train/
cp $raw_data/kaldi_test/* data/test/
cp $raw_data/lexicon.txt data/local/dict/
cp $raw_data/nonsilence_phones.txt data/local/dict/
cp $raw_data/silence_phones.txt data/local/dict/
cp $raw_data/optional_silence.txt data/local/dict/
cp $raw_data/extra_questions.txt data/local/dict/

echo "--- 2. Tikriname ir sutvarkome duomenų formatus ---"
utils/fix_data_dir.sh data/train
utils/fix_data_dir.sh data/test

echo "--- 3. Ruošiame kalbos modelio (L.fst) struktūras ---"
# Šis skriptas sukuria lang aplanką, kurį Kaldi naudos atpažinimui
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

echo "--- 4. Išskiriame MFCC savybes (tai užtruks) ---"
# mfccdir nurodo, kur fiziškai bus saugomi dideli savybių failai
mfccdir=mfcc
for x in train test; do
  steps/make_mfcc.sh --cmd "$train_cmd" --nj 10 data/$x exp/make_mfcc/$x $mfccdir
  steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done

echo "--- 5. Tikriname, ar savybės išskirtos sėkmingai ---"
utils/fix_data_dir.sh data/train
utils/fix_data_dir.sh data/test

echo "--- MFCC paruošta. Galime pradėti Mono modelio mokymą! ---"

