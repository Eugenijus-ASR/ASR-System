#!/bin/bash
# Duomenų ir rezultatų aplankai
data=$1
dir=$3 # Decode aplankas
# $2 gali būti arba words.txt failas, arba lang aplankas
if [ -f "$2" ]; then
  symtab=$2
else
  symtab=$2/words.txt
fi

# Tikriname ar visi argumentai yra
[ -z "$dir" ] && echo "Naudojimas: $0 <data> <symtab> <decode_dir>" && exit 1;

ref=ark:$data/text

echo "Skaičiuojamas WER..."

for lmwt in $(seq 7 17); do
  # Apskaičiuojame akustikos skalę (acwt)
  acwt=$(perl -e "print (1.0/$lmwt);")
  
  # Paverčiame groteles į geriausią kelią (hyp)
  # Pridėtas --ignore-determinizm-error, kad išvengtume fatalų klaidų
  lattice-best-path --acoustic-scale=$acwt --word-symbol-table=$symtab \
    "ark:gunzip -c $dir/lat.*.gz |" ark,t:$dir/hyp.LMWT$lmwt.txt 2>/dev/null
  
  # Skaičiuojame WER tarp ref (originalo) ir hyp (atpažinto)
  compute-wer --text --mode=present "$ref" \
    ark:$dir/hyp.LMWT$lmwt.txt > $dir/wer.$lmwt 2>/dev/null
done

# Išvedame geriausią rezultatą į ekraną
grep WER $dir/wer.* | utils/best_wer.sh