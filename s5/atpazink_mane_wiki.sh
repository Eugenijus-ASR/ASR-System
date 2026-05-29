#!/bin/bash
# ============================================================
#  Asmeniniu balso irasu atpazinimas su Trigram+Wiki modeliu
#  Naudojimas: ./atpazink_mane_wiki.sh
#  - Skenuoja mano_garso_irasai/ aplanka
#  - Leidzia pasirinkti faila is meniu
#  - Atpazina su tri3 + trigram_wiki grafu
#  - Issaugo transkripcija to paties pavadinimo .txt faile
# ============================================================
. ./path.sh

# --- Konfiguracija ---
GRAPH_DIR=exp/tri3/graph_trigram_wiki
INPUT_DIR=mano_garso_irasai
DATA_DIR=data/mano_atpazinimas
DECODE_DIR=exp/tri3/decode_mano_atpazinimas
ACWT=0.0625      # 1/16 - tinka platiems n-gram modeliams (lmwt=16)
                 # Jei prastai veikia, pabandykite 0.0833 (lmwt=12)

# --- Pries-tikrinimai ---
if [ ! -d "$GRAPH_DIR" ]; then
    echo "KLAIDA: nera $GRAPH_DIR direktorijos."
    echo "Pirma paleiskite: ./magistras_trigram_wiki.sh"
    exit 1
fi

if [ ! -f "$GRAPH_DIR/HCLG.fst" ] || [ ! -f "$GRAPH_DIR/words.txt" ]; then
    echo "KLAIDA: $GRAPH_DIR neturi HCLG.fst arba words.txt"
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
    echo "Idekite ten viena ar daugiau audio failu (.wav .mp3 .m4a .ogg .flac)"
    echo "ir paleiskite skripta dar karta."
    exit 0
fi

# --- Pasirinkimo meniu ---
echo "===================================================="
echo "  Rasti audio failai aplanke '$INPUT_DIR':"
echo "===================================================="
PS3=$'\nIveskite numeri (q - ismeta): '
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
OUTPUT_TXT="$INPUT_DIR/${name_no_ext}.txt"

echo ""
echo "Pasirinkote: $chosen"
echo "Transkripcija bus issaugota: $OUTPUT_TXT"
echo ""

# --- Audio paruosimas: konversija i 16kHz mono WAV ---
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
    echo "KLAIDA: CMVN nepavyko, ziurekite $DATA_DIR/cmvn.log"
    exit 1
}
echo "OK"

# --- Dekodavimas ---
echo ""
echo "--- Dekodavimas (tri3 + Trigram+Wiki) ---"
steps/decode_fmllr.sh --nj 1 --cmd "run.pl" --skip-scoring true \
    "$GRAPH_DIR" "$DATA_DIR" "$DECODE_DIR" \
    > "$DECODE_DIR.log" 2>&1 || {
    echo "KLAIDA: Dekodavimas nepavyko, ziurekite $DECODE_DIR.log"
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

# --- Transkripcija (be utt_id pradzioje) ---
utils/int2sym.pl -f 2- "$SYMTAB" "$DECODE_DIR/one_best.tra" | \
    cut -d' ' -f2- > "$OUTPUT_TXT"

echo ""
echo "===================================================="
echo "  ATPAZINTA TRANSKRIPCIJA"
echo "===================================================="
cat "$OUTPUT_TXT"
echo ""
echo "===================================================="
echo "  Issaugota: $OUTPUT_TXT"
echo "===================================================="
