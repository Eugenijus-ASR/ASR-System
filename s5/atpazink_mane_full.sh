#!/bin/bash
# ============================================================
#  Asmeniniu balso irasu atpazinimas - PILNAS modeliu rinkinys
#  Leidzia pasirinkti viena is 4 modeliu konfiguraciju:
#    1) Baseline                       (tri3 + Trigram_wiki)
#    2) LM-adapted                     (tri3 + Trigram_wiki_med)
#    3) Acoustic-adapted               (tri3_adapted + Trigram_wiki)
#    4) Fully adapted (rekomenduoju)   (tri3_adapted + Trigram_wiki_med)
#
#  Naudoja audio failus is mano_garso_irasai/ aplanko.
#  Issaugo transkripcija to paties pavadinimo .txt faile.
# ============================================================
. ./path.sh

# --- Konfiguracija ---
INPUT_DIR=mano_garso_irasai
DATA_DIR=data/mano_atpazinimas
ACWT=0.0625      # 1/16 - tinka platiems n-gram modeliams

# --- Modeliu lentele ---
declare -a MODELS=(
    "Baseline (tri3 + Trigram_wiki)|exp/tri3|exp/tri3/graph_trigram_wiki|CV: 16.65 / M: 30.15"
    "LM-adapted (tri3 + Trigram_wiki_med)|exp/tri3|exp/tri3/graph_trigram_wiki_med|CV: 16.75 / M: 29.01"
    "Acoustic-adapted (tri3_adapted + Trigram_wiki)|exp/tri3_adapted|exp/tri3_adapted/graph_trigram_wiki|M: 25.95"
    "Fully adapted (tri3_adapted + Trigram_wiki_med)|exp/tri3_adapted|exp/tri3_adapted/graph_trigram_wiki_med|M: 23.28"
)

# --- Modelio pasirinkimas ---
echo "===================================================="
echo "  Pasirinkite atpazinimo modeli:"
echo "===================================================="
echo "  WER % (kuo mažesnis tuo geriau)   CV = Common Voice testas, M = Medicinos testas"
echo ""
for i in "${!MODELS[@]}"; do
    IFS='|' read -r name model graph wer <<< "${MODELS[$i]}"
    printf "  %d) %-50s [%s]\n" $((i+1)) "$name" "$wer"
done
echo ""
read -p "Iveskite numeri (1-4) [4]: " MODEL_NUM
MODEL_NUM=${MODEL_NUM:-4}

if [[ ! "$MODEL_NUM" =~ ^[1-4]$ ]]; then
    echo "Neteisingas pasirinkimas. Naudojamas numatytasis: 4."
    MODEL_NUM=4
fi

IFS='|' read -r MODEL_NAME MODEL_DIR GRAPH_DIR MODEL_WER <<< "${MODELS[$((MODEL_NUM-1))]}"

echo ""
echo "Pasirinkta: $MODEL_NAME"
echo "  Akustinis: $MODEL_DIR"
echo "  Grafas:    $GRAPH_DIR"
echo ""

# --- Pries-tikrinimai ---
if [ ! -f "$GRAPH_DIR/HCLG.fst" ]; then
    echo "KLAIDA: nera $GRAPH_DIR/HCLG.fst"
    echo "Patikrinkite ar HCLG grafai yra sugeneruoti."
    exit 1
fi
if [ ! -f "$MODEL_DIR/final.mdl" ]; then
    echo "KLAIDA: nera $MODEL_DIR/final.mdl"
    exit 1
fi

mkdir -p "$INPUT_DIR"

# --- Audio failu skenavimas ---
shopt -s nullglob nocaseglob
files=("$INPUT_DIR"/*.wav "$INPUT_DIR"/*.mp3 "$INPUT_DIR"/*.m4a "$INPUT_DIR"/*.ogg "$INPUT_DIR"/*.flac)
shopt -u nullglob nocaseglob

if [ ${#files[@]} -eq 0 ]; then
    echo "===================================================="
    echo "  Aplankas '$INPUT_DIR' yra tuscias."
    echo "===================================================="
    echo "Idekite ten audio failu (.wav .mp3 .m4a .ogg .flac)"
    echo "ir paleiskite skripta dar karta."
    exit 0
fi

# --- Audio failo pasirinkimas ---
echo "===================================================="
echo "  Rasti audio failai aplanke '$INPUT_DIR':"
echo "===================================================="
PS3=$'\nIveskite audio failo numeri (q - ismeta): '
select chosen in "${files[@]}"; do
    if [ -n "$chosen" ]; then
        break
    fi
    if [ "$REPLY" = "q" ] || [ "$REPLY" = "Q" ]; then
        echo "Atsisakyta."
        exit 0
    fi
    echo "Neteisingas pasirinkimas. Bandykite dar karta."
done

basename=$(basename "$chosen")
name_no_ext="${basename%.*}"
OUTPUT_TXT="$INPUT_DIR/${name_no_ext}_model${MODEL_NUM}.txt"

# DECODE_DIR turi buti decode_fmllr.sh tikisi tree faila tevineje direktorijoje,
# todel decode_dir = <model_dir>/decode_*
DECODE_DIR="${MODEL_DIR}/decode_mano_atpazinimas_model${MODEL_NUM}"

echo ""
echo "Pasirinkote audio: $chosen"
echo "Transkripcija bus issaugota: $OUTPUT_TXT"
echo ""

# --- Audio paruosimas ---
rm -rf "$DATA_DIR" "$DECODE_DIR"
mkdir -p "$DATA_DIR"

WAV_PATH="$(pwd)/$DATA_DIR/audio.wav"
echo "--- Konvertuojama i 16 kHz mono WAV ---"
ffmpeg -y -i "$chosen" -ar 16000 -ac 1 -loglevel error "$WAV_PATH" || {
    echo "KLAIDA: ffmpeg konversija nepavyko"
    exit 1
}
echo "OK ($(du -h "$WAV_PATH" | cut -f1))"

# --- Kaldi data dir ---
UTT_ID="user_$(date +%s)"
echo "$UTT_ID $WAV_PATH" > "$DATA_DIR/wav.scp"
echo "$UTT_ID $UTT_ID" > "$DATA_DIR/utt2spk"
cp "$DATA_DIR/utt2spk" "$DATA_DIR/spk2utt"

# --- MFCC + CMVN ---
echo ""
echo "--- MFCC ekstrakcija ---"
steps/make_mfcc.sh --nj 1 "$DATA_DIR" exp/make_mfcc/mano_atpazinimas mfcc \
    > "$DATA_DIR/mfcc.log" 2>&1 || {
    echo "KLAIDA: MFCC nepavyko, ziurekite $DATA_DIR/mfcc.log"
    exit 1
}
steps/compute_cmvn_stats.sh "$DATA_DIR" exp/make_mfcc/mano_atpazinimas mfcc \
    > "$DATA_DIR/cmvn.log" 2>&1 || {
    echo "KLAIDA: CMVN nepavyko"
    exit 1
}
echo "OK"

# --- Dekodavimas ---
echo ""
echo "--- Dekodavimas su pasirinkta konfiguracija ---"
steps/decode_fmllr.sh --nj 1 --cmd "run.pl" --skip-scoring true \
    "$GRAPH_DIR" "$DATA_DIR" "$DECODE_DIR" \
    > "${DECODE_DIR}.log" 2>&1 || {
    echo "KLAIDA: Dekodavimas nepavyko, ziurekite ${DECODE_DIR}.log"
    exit 1
}
echo "OK"

# --- Geriausio kelio istraukimas ---
echo ""
echo "--- Geriausio kelio istraukimas ---"
SYMTAB="$GRAPH_DIR/words.txt"
lattice-best-path --acoustic-scale=$ACWT --word-symbol-table="$SYMTAB" \
    "ark:gunzip -c $DECODE_DIR/lat.*.gz |" \
    ark,t:"$DECODE_DIR/one_best.tra" 2>/dev/null

if [ ! -s "$DECODE_DIR/one_best.tra" ]; then
    echo "KLAIDA: nesukurtas one_best.tra"
    echo "Tikrinti: $DECODE_DIR/log/decode.1.log"
    exit 1
fi

# --- Transkripcija ---
utils/int2sym.pl -f 2- "$SYMTAB" "$DECODE_DIR/one_best.tra" | \
    cut -d' ' -f2- > "$OUTPUT_TXT"

echo ""
echo "===================================================="
echo "  ATPAZINTA TRANSKRIPCIJA"
echo "  Modelis: $MODEL_NAME"
echo "===================================================="
cat "$OUTPUT_TXT"
echo ""
echo "===================================================="
echo "  Issaugota: $OUTPUT_TXT"
echo "===================================================="
