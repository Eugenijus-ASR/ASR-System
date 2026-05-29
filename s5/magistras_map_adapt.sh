#!/bin/bash
# ============================================================
#  Akustine adaptacija: tri3 -> tri3_adapted
#  Strategija: SAT (Speaker-Adaptive Training) retrain ant CV + my_train
#  Naudojam esamus tri3 alignment'us is CV ir nauju is my_train.
# ============================================================
. ./path.sh
set -e

LANG_DIR=data/lang_wiki_med
TRAIN_BASE=data/train          # original CV training data
MY_TRAIN=data/my_train         # jusu irasai
COMBINED=data/train_combined   # CV + my_train
ALI_DIR=exp/tri3_ali_combined
OUT=exp/tri3_adapted

NUM_LEAVES=4200      # tas pats kaip tri3
TOT_GAUSS=40000      # tas pats kaip tri3

# Patikrint ar yra reikalingi failai
for d in $TRAIN_BASE $MY_TRAIN $LANG_DIR exp/tri3; do
    [ ! -d "$d" ] && echo "KLAIDA: nera $d" && exit 1
done

echo "============================================================"
echo "  ETAPAS 1: Apjungimas data/train + data/my_train"
echo "============================================================"
rm -rf $COMBINED
utils/combine_data.sh $COMBINED $TRAIN_BASE $MY_TRAIN
utils/fix_data_dir.sh $COMBINED
echo "  Apjungta: $(wc -l < $COMBINED/text) utterances"

echo ""
echo "============================================================"
echo "  ETAPAS 2: MFCC + CMVN apjungtam aplankui"
echo "============================================================"
# Reikia susikurti MFCC apjungtam (Kaldi nori pilno feats.scp)
mfccdir=mfcc
steps/make_mfcc.sh --nj 4 --cmd "run.pl" \
    $COMBINED exp/make_mfcc/train_combined $mfccdir
steps/compute_cmvn_stats.sh \
    $COMBINED exp/make_mfcc/train_combined $mfccdir
utils/fix_data_dir.sh $COMBINED

echo ""
echo "============================================================"
echo "  ETAPAS 3: Forced alignment su esamu tri3"
echo "============================================================"
# Naudoja data/lang (ne wiki_med) - originaliam alignment'ui
# Bet jeigu transkripcijos turi medicinos zodziu - reiks lang_wiki_med
LANG_FOR_ALIGN=$LANG_DIR
[ -d data/lang ] && LANG_FOR_ALIGN=data/lang

# Bandysime su data/lang_wiki_med kuriam yra visi medicinos zodziai
echo "  Naudojam lang dir: $LANG_DIR (turi visus medicinos zodziu)"
rm -rf $ALI_DIR
steps/align_fmllr.sh --nj 4 --cmd "run.pl" \
    $COMBINED $LANG_DIR exp/tri3 $ALI_DIR

echo ""
echo "============================================================"
echo "  ETAPAS 4: SAT retrain (apie 30-90 min)"
echo "============================================================"
rm -rf $OUT
steps/train_sat.sh --cmd "run.pl" \
    $NUM_LEAVES $TOT_GAUSS \
    $COMBINED $LANG_DIR $ALI_DIR $OUT

echo ""
echo "============================================================"
echo "  BAIGTA"
echo "============================================================"
echo "  Naujas akustinis modelis: $OUT/final.mdl"
echo ""
ls -lh $OUT/final.mdl exp/tri3/final.mdl
echo ""
echo "Tolimesnis zingsnis:"
echo "  ./evaluate_my_test.sh   - 4 eksperimentu palyginimas"
