#!/bin/bash
# ============================================================
#  Paruosia data/my_train/ ir data/my_test/ Kaldi formatu
#  is mano_garso_irasai/train/ ir mano_garso_irasai/test/
#  Audio (m4a/wav/mp3/...) bus konvertuojamas i 16kHz mono per ffmpeg pipe.
# ============================================================
. ./path.sh
set -e

INPUT_TRAIN="mano_garso_irasai/train"
INPUT_TEST="mano_garso_irasai/test"
OUT_TRAIN="data/my_train"
OUT_TEST="data/my_test"
SPEAKER="eugen"

# Funkcija: paruosia viena duomenu aplanką
prepare_data_dir() {
    local input="$1"
    local out="$2"
    local label="$3"

    echo "=== $label: $input -> $out ==="
    rm -rf "$out"
    mkdir -p "$out"

    : > "$out/wav.scp"
    : > "$out/text"
    : > "$out/utt2spk"

    local count=0
    local skipped=0

    for txt in $(ls "$input"/*.txt 2>/dev/null | sort); do
        local basename=$(basename "$txt" .txt)
        local audio=""
        for ext in m4a M4A wav WAV mp3 MP3 ogg OGG flac FLAC; do
            if [ -f "$input/$basename.$ext" ]; then
                audio="$input/$basename.$ext"
                break
            fi
        done
        if [ -z "$audio" ]; then
            echo "  IPSEJIMAS: nera audio del $basename - praleidziama"
            skipped=$((skipped + 1))
            continue
        fi

        local utt_id="${SPEAKER}_${basename}"
        local abs_audio="$(readlink -f "$audio")"
        # Transkripcija - vienoje eiluteje, be tabu, normalizuotu tarpu
        local transcription=$(tr -s ' \t\n' ' ' < "$txt" | sed 's/^ *//; s/ *$//')

        # wav.scp - su ffmpeg pipe (m4a -> 16kHz mono WAV stream)
        echo "$utt_id ffmpeg -i $abs_audio -ar 16000 -ac 1 -f wav -loglevel error - |" >> "$out/wav.scp"
        echo "$utt_id $transcription" >> "$out/text"
        echo "$utt_id $SPEAKER" >> "$out/utt2spk"
        count=$((count + 1))
    done

    # spk2utt is utt2spk
    utils/utt2spk_to_spk2utt.pl "$out/utt2spk" > "$out/spk2utt"

    echo "  Sukurta: $count utterances, praleista: $skipped"

    # Patikrinti
    utils/fix_data_dir.sh "$out" 2>&1 | tail -2
    utils/validate_data_dir.sh --no-feats "$out" 2>&1 | tail -3
}

prepare_data_dir "$INPUT_TRAIN" "$OUT_TRAIN" "TRAIN"
echo ""
prepare_data_dir "$INPUT_TEST" "$OUT_TEST" "TEST"

echo ""
echo "============================================================"
echo "  MFCC + CMVN ekstrakcija"
echo "============================================================"
# 1 speaker => nj=1
mfccdir=mfcc
for x in my_train my_test; do
    echo ""
    echo "--- MFCC: $x ---"
    steps/make_mfcc.sh --nj 1 --cmd "run.pl" \
        data/$x exp/make_mfcc/$x $mfccdir
    steps/compute_cmvn_stats.sh \
        data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x
done

echo ""
echo "============================================================"
echo "  OOV testas (ar visi zodziai yra leksikone)"
echo "============================================================"
LEXICON=data/local/dict_wiki_med/lexicon.txt
if [ -f "$LEXICON" ]; then
    awk '{print $1}' $LEXICON | sort -u > /tmp/lex_words.txt
    awk '{ for (i=2;i<=NF;i++) print $i }' "$OUT_TRAIN/text" "$OUT_TEST/text" | sort -u > /tmp/my_words.txt
    OOV_COUNT=$(comm -23 /tmp/my_words.txt /tmp/lex_words.txt | wc -l)
    TOTAL_UNIQUE=$(wc -l < /tmp/my_words.txt)
    echo "  Unikaliu zodziu jusu transkripcijose: $TOTAL_UNIQUE"
    echo "  Zodziu nera leksikone (OOV): $OOV_COUNT"
    if [ "$OOV_COUNT" -gt 0 ]; then
        echo "  Pirmieji 10 OOV zodziu:"
        comm -23 /tmp/my_words.txt /tmp/lex_words.txt | head -10 | sed 's/^/    /'
    fi
fi

echo ""
echo "============================================================"
echo "  BAIGTA"
echo "============================================================"
echo "  data/my_train/ - $(wc -l < $OUT_TRAIN/text) train irasai"
echo "  data/my_test/  - $(wc -l < $OUT_TEST/text) test irasai"
echo ""
echo "Tolimesni zingsniai:"
echo "  ./magistras_map_adapt.sh   - akustinė adaptacija"
echo "  ./evaluate_my_test.sh      - 4 eksperimentai + WER"
