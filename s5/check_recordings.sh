#!/bin/bash
# Patikrina audio + txt poras train/ ir test/ aplankuose

cd "$(dirname "$0")"
TRAIN_DIR="mano_garso_irasai/train"
TEST_DIR="mano_garso_irasai/test"

# Audio plėtinių paieška (ne Zone.Identifier)
audio_exts="wav mp3 m4a ogg flac WAV MP3 M4A OGG FLAC"

count_real() {
    local d=$1
    local e=$2
    ls "$d"/*."$e" 2>/dev/null | grep -v 'Zone.Identifier$' | wc -l
}

list_audio() {
    local d=$1
    for e in $audio_exts; do
        ls "$d"/*."$e" 2>/dev/null | grep -v 'Zone.Identifier$'
    done
}

check_pairs() {
    local d=$1
    local label=$2
    echo "=== $label ($d) ==="

    # Visi audio failai (be plėtinio)
    local audio_basenames=$(list_audio "$d" | xargs -I {} basename {} | sed 's/\.[^.]*$//' | sort -u)
    local txt_basenames=$(ls "$d"/*.txt 2>/dev/null | xargs -I {} basename {} .txt | sort -u)

    local audio_count=$(echo "$audio_basenames" | grep -c .)
    local txt_count=$(echo "$txt_basenames" | grep -c .)

    echo "  Audio failu: $audio_count"
    echo "  TXT failu: $txt_count"

    # Audio be txt
    local missing_txt=$(comm -23 <(echo "$audio_basenames") <(echo "$txt_basenames"))
    if [ -n "$missing_txt" ]; then
        echo "  KLAIDA: audio be .txt:"
        echo "$missing_txt" | sed 's/^/    /'
    fi

    # TXT be audio
    local missing_audio=$(comm -13 <(echo "$audio_basenames") <(echo "$txt_basenames"))
    if [ -n "$missing_audio" ]; then
        echo "  KLAIDA: .txt be audio:"
        echo "$missing_audio" | sed 's/^/    /'
    fi

    if [ -z "$missing_txt" ] && [ -z "$missing_audio" ]; then
        echo "  OK - visi failai turi poras"
    fi

    # Audio formatu suvestine
    echo "  Audio formatai:"
    list_audio "$d" | sed 's/.*\.//' | sort | uniq -c | sed 's/^/    /'

    # Audio dydziu vidurkis
    if [ "$audio_count" -gt 0 ]; then
        local total_size=$(list_audio "$d" | xargs du -b 2>/dev/null | awk '{s+=$1} END {print s}')
        local avg_size=$((total_size / audio_count / 1024))
        echo "  Vidutinis audio dydis: ${avg_size} KB"
    fi
}

check_pairs "$TRAIN_DIR" "TRAIN aibe"
echo ""
check_pairs "$TEST_DIR" "TEST aibe"
echo ""

# Numeravimo kontrolė
echo "=== Numeravimo tarpai ==="
all_nums=$(list_audio "$TRAIN_DIR" "$TEST_DIR" 2>/dev/null | xargs -I {} basename {} | grep -oE 'irasas_[0-9]+' | sed 's/irasas_//' | sort -u)
if [ -z "$all_nums" ]; then
    list_audio "$TRAIN_DIR" > /tmp/train_files.txt
    list_audio "$TEST_DIR" > /tmp/test_files.txt
    cat /tmp/train_files.txt /tmp/test_files.txt | xargs -I {} basename {} | grep -oE 'irasas_[0-9]+' | sed 's/irasas_//' | sort -u > /tmp/all_nums.txt
    all_nums=$(cat /tmp/all_nums.txt)
fi

# Patikrinti spragas
prev=0
gaps=0
for n in $all_nums; do
    n_int=$((10#$n))
    if [ "$prev" -gt 0 ] && [ $((prev + 1)) -ne "$n_int" ]; then
        echo "  Praleistas numeris: nuo $((prev + 1)) iki $((n_int - 1))"
        gaps=$((gaps + 1))
    fi
    prev=$n_int
done
if [ "$gaps" -eq 0 ]; then
    echo "  OK - numeravimas tolygus, nera spragų"
fi
